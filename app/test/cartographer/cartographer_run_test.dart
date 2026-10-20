import 'dart:convert';
import 'dart:io';

import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:cognitiv_app/cartographer/cartographer_run.dart';
import 'package:flutter_test/flutter_test.dart';

cartographer.BaseMap _loadMap() => cartographer.BaseMapCodec.fromJson(
  jsonDecode(File('assets/maps/south_america.json').readAsStringSync()) as Map<String, dynamic>,
);

cartographer.CartographerAnswer _right(cartographer.BaseMap map, cartographer.RecallQuestion q, cartographer.Item item) =>
    q.kind.gesture == cartographer.Gesture.place
    ? cartographer.PlacedAnswer(item.anchor)
    : cartographer.TypedAnswer(map.textFor(item, q.kind.answer, cartographer.NameLanguage.fr));

cartographer.CartographerAnswer _wrong(cartographer.RecallQuestion q) => q.kind.gesture == cartographer.Gesture.place
    ? const cartographer.PlacedAnswer(cartographer.GeoPoint(-30, -40)) // en plein Atlantique
    : const cartographer.TypedAnswer('zzzzzz');

/// Fait jouer une Partie entière. [knows] dit si le joueur répond juste à une question selon la
/// phase de l'Énigme ; un joueur qui apprend répond juste après l'Étude.
List<String> _play(CartographerRun run, bool Function(cartographer.CartographerPuzzle puzzle, cartographer.RecallQuestion q) knows) {
  final visited = <String>[];
  var last = '';
  while (run.stage != RunStage.finished) {
    final tag = '${run.current.runtimeType}:${run.stage.name}';
    if (tag != last) visited.add(tag);
    last = tag;
    switch (run.stage) {
      case RunStage.studyIntro:
        run.beginStudy();
      case RunStage.study:
        run.endStudy();
      case RunStage.distraction:
        run.endDistraction();
      case RunStage.questions:
        final q = run.question;
        run.answer(knows(run.current!, q) ? _right(run.baseMap, q, run.questionItem) : _wrong(q));
        run.next();
      case RunStage.trayRecall:
        throw StateError('pas de Plateau dans cette Partie');
      case RunStage.sequence:
        throw StateError('pas de Séquence dans cette Partie');
      case RunStage.finished:
        break;
    }
  }
  return visited;
}

void main() {
  final map = _loadMap();
  final level = cartographer.CartographerLevels.byNumber(3);

  CartographerRun newRun({cartographer.Mastery? mastery, int seed = 1, void Function(cartographer.Mastery)? onFinished}) =>
      CartographerRun(
        baseMap: map,
        level: level,
        profile: cartographer.CartographerProfile.defaults(),
        language: cartographer.NameLanguage.fr,
        masteryBefore: mastery ?? cartographer.Mastery.empty,
        prepare: cartographer.PrepareCartographerPuzzles(random: cartographer.SystemRandomSource(seed)),
        onFinished: onFinished,
      );

  test('une Partie commence par le Repérage, sans Étude', () {
    final run = newRun();
    expect(run.current, isA<cartographer.Screening>());
    expect(run.stage, RunStage.questions);
    expect(run.answered, isFalse);
  });

  test('un débutant : Repérage, puis chaque Étude (intro, étude, distraction, rappel), puis le Bilan', () {
    final saved = <cartographer.Mastery>[];
    final run = newRun(onFinished: saved.add);
    final visited = _play(run, (puzzle, q) => puzzle is! cartographer.Screening); // il apprend ce qu'il étudie

    expect(visited, [
      'Screening:questions',
      'FlashStudy:studyIntro', 'FlashStudy:study', 'FlashStudy:distraction', 'FlashStudy:questions',
      'FlashStudy:studyIntro', 'FlashStudy:study', 'FlashStudy:distraction', 'FlashStudy:questions',
      'DelayedRecall:questions',
    ]);
    expect(run.stage, RunStage.finished);
    expect(run.current, isNull);
    expect(run.history.map((p) => p.puzzle.runtimeType), [cartographer.Screening, cartographer.FlashStudy, cartographer.FlashStudy, cartographer.DelayedRecall]);
    expect(run.missedAtScreening, 13);
    expect(run.result.levelCleared, isTrue, reason: 'le Bilan est réussi');
    expect(saved, hasLength(1), reason: 'onFinished une seule fois');
    expect(saved.single.states, run.masteryAfter.states);
    expect(run.masteryAfter.states.values.toSet(), {cartographer.Knowledge.shaky, cartographer.Knowledge.toLearn});
  });

  test("un expert : tout juste au Repérage, la Partie s'arrête là et suggère d'autres genres de Lien", () {
    final saved = <cartographer.Mastery>[];
    final run = newRun(onFinished: saved.add);
    final visited = _play(run, (_, _) => true);

    expect(visited, ['Screening:questions']);
    expect(run.history, hasLength(1));
    expect(run.missedAtScreening, 0);
    expect(run.exactCount, 13);
    expect(run.result.levelCleared, isTrue);
    expect(run.result.suggestion, cartographer.LevelSuggestion.raise);
    expect(run.masteryAfter.states.values.toSet(), {cartographer.Knowledge.shaky});
    expect(saved, hasLength(1));
  });

  test('le numéro et le total des Études sont connus dès que le Repérage est joué', () {
    final run = newRun();
    while (run.stage == RunStage.questions) {
      final q = run.question;
      run.answer(_wrong(q));
      run.next();
    }
    expect(run.stage, RunStage.studyIntro);
    expect(run.studyNumber, 1);
    expect(run.studyTotal, 2);
    expect(run.study.questions.length, lessThanOrEqualTo(level.itemCount));
  });

  test("une seconde séance reprend la Maîtrise : au moins un pays reçoit un autre genre de Lien", () {
    final first = newRun();
    _play(first, (_, _) => true);
    final second = newRun(mastery: first.masteryAfter, seed: 2);
    final firstKinds = {for (final q in first.history.first.puzzle.questions) q.itemId: q.kind};
    final changed = second.current!.questions.where((q) => firstKinds[q.itemId] != q.kind);
    expect(changed, isNotEmpty, reason: "ce qui est déjà fragile n'est pas toujours reposé");
  });

  group('garde-fous', () {
    test('une réponse par question', () {
      final run = newRun();
      run.answer(_wrong(run.question));
      expect(() => run.answer(_wrong(run.question)), throwsStateError);
    });

    test('next demande une réponse', () {
      expect(() => newRun().next(), throwsStateError);
    });

    test("les étapes d'une Étude se prennent dans l'ordre", () {
      final run = newRun();
      expect(run.beginStudy, throwsStateError);
      expect(run.endStudy, throwsStateError);
      expect(run.endDistraction, throwsStateError);
      while (run.stage == RunStage.questions) {
        run.answer(_wrong(run.question));
        run.next();
      }
      expect(run.endStudy, throwsStateError);
      run.beginStudy();
      expect(run.beginStudy, throwsStateError);
      expect(run.endDistraction, throwsStateError);
    });

    test("une Partie abandonnée n'appelle jamais onFinished", () {
      var called = false;
      final run = newRun(onFinished: (_) => called = true);
      run.answer(_wrong(run.question));
      run.next();
      expect(called, isFalse);
      expect(run.stage, RunStage.questions);
    });
  });

  test("l'objet notifie ses écouteurs à chaque étape", () {
    final run = newRun();
    var notifications = 0;
    run.addListener(() => notifications++);
    run.answer(_wrong(run.question));
    run.next();
    expect(notifications, 2);
  });
}
