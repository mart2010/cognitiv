import 'dart:convert';

import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

import '../support/real_base_map.dart';

void main() {
  final map = loadSouthAmerica();

  PrepareCartographerRequest request({int level = 3, Set<Category>? categories, Mastery? mastery}) =>
      PrepareCartographerRequest(
        baseMap: map,
        level: CartographerLevels.byNumber(level),
        profile: CartographerProfile.defaults().copyWith(categories: categories ?? {Category.cities}),
        language: NameLanguage.fr,
        mastery: mastery,
      );

  PlayedPuzzle played(CartographerPuzzle puzzle, [int? wrongAt]) => PlayedPuzzle(puzzle, [
    for (var i = 0; i < puzzle.questions.length; i++) i == wrongAt ? AnswerVerdict.wrong : AnswerVerdict.exact,
  ]);

  final prepare = PrepareSequencePuzzles(random: SystemRandomSource(1));

  test('la première manche montre un Élément d\'un jeu de six, à la vitesse du Niveau', () {
    for (final number in [1, 5, 10]) {
      final first = prepare(request(level: number), []).single as Sequence;
      expect(first.length, PrepareSequencePuzzles.startLength);
      expect(first.pool, hasLength(PrepareSequencePuzzles.poolSize));
      expect(first.pool.toSet(), hasLength(first.pool.length), reason: 'pas de doublon dans le jeu');
      expect(first.pool, containsAll(first.steps));
      expect(first.stepMillis, CartographerLevels.byNumber(number).sequenceStepMillis);
    }
  });

  test('la difficulté vient de la vitesse : le jeu a la même taille à tous les Niveaux, l\'affichage accélère', () {
    final speeds = CartographerLevels.all.map((l) => l.sequenceStepMillis).toList();
    expect(speeds, orderedEquals([...speeds]..sort((a, b) => b.compareTo(a))));
    expect(speeds.first, greaterThan(speeds.last));
    expect(
      {for (final l in CartographerLevels.all) (prepare(request(level: l.number), []).single as Sequence).pool.length},
      {PrepareSequencePuzzles.poolSize},
    );
  });

  test('tous les Éléments du jeu viennent d\'une seule Catégorie active', () {
    final first = prepare(request(categories: {Category.countries}), []).single as Sequence;
    expect(first.pool.map((id) => map.itemById(id).category).toSet(), {Category.countries});
  });

  test('une manche réussie reprend la séquence et y ajoute un Élément du jeu', () {
    var history = <PlayedPuzzle>[];
    var current = prepare(request(), history).single as Sequence;
    for (var round = 1; round <= 12; round++) {
      history = [...history, played(current)];
      final next = prepare(request(), history).single as Sequence;
      expect(next.length, current.length + 1);
      expect(next.steps.take(current.length), current.steps);
      expect(next.pool, current.pool);
      expect(next.pool, contains(next.steps.last));
      current = next;
    }
  });

  test('comme au Simon, un même Élément peut revenir dans la séquence', () {
    var history = <PlayedPuzzle>[];
    var current = prepare(request(), history).single as Sequence;
    for (var i = 0; i < 20; i++) {
      history = [...history, played(current)];
      current = prepare(request(), history).single as Sequence;
    }
    expect(current.length, 21);
    expect(current.steps.toSet().length, lessThan(current.length), reason: '21 étapes dans un jeu de 6');
  });

  test('une erreur termine la Partie, à n\'importe quelle position', () {
    final first = prepare(request(), []).single as Sequence;
    expect(prepare(request(), [played(first, 0)]), isEmpty);
    final second = prepare(request(), [played(first)]).single as Sequence;
    expect(prepare(request(), [played(first), played(second, 1)]), isEmpty);
  });

  test('les Éléments les moins connus passent d\'abord dans le jeu', () {
    final cities = map.itemsOf(Category.cities);
    var mastery = Mastery.empty;
    for (final city in cities.take(cities.length - 6)) {
      mastery = mastery.set(MasteryKey(map.id, city.id, Sequence.linkKind), Knowledge.solid);
    }
    final unknown = cities.skip(cities.length - 6).map((c) => c.id).toSet();
    final first = prepare(request(mastery: mastery), []).single as Sequence;
    expect(first.pool.toSet(), unknown);
  });

  test('la Séquence survit à la sérialisation', () {
    var history = <PlayedPuzzle>[];
    var current = prepare(request(), history).single as Sequence;
    for (var i = 0; i < 3; i++) {
      history = [...history, played(current)];
      current = prepare(request(), history).single as Sequence;
    }
    final back = CartographerPuzzleCodec.fromJson(jsonDecode(jsonEncode(current.toJson())) as Map<String, dynamic>) as Sequence;
    expect(back.pool, current.pool);
    expect(back.steps, current.steps);
    expect(back.stepMillis, current.stepMillis);
    expect(back.questions.map((q) => q.itemId), current.questions.map((q) => q.itemId));
  });

  test('une Séquence vide ou qui sort de son jeu est refusée', () {
    expect(() => Sequence(language: NameLanguage.fr, pool: ['a', 'b'], steps: [], stepMillis: 1000), throwsArgumentError);
    expect(() => Sequence(language: NameLanguage.fr, pool: ['a', 'b'], steps: ['a', 'c'], stepMillis: 1000), throwsArgumentError);
  });

  group('le Score', () {
    final level = CartographerLevels.byNumber(3);
    Sequence of(int length) => Sequence(
      language: NameLanguage.fr,
      pool: ['city:lima', 'city:bogota', 'city:santiago'],
      steps: [for (var i = 0; i < length; i++) ['city:lima', 'city:bogota', 'city:santiago'][i % 3]],
      stepMillis: 1000,
    );
    CartographerScoreResult score(int reached, [int? failedLength]) => ComputeSequenceScore()(
      [for (var l = 1; l <= reached; l++) played(of(l)), if (failedLength != null) played(of(failedLength), 0)],
      level: level,
    );

    test('c\'est la plus longue séquence reproduite sans faute, fois les points du Niveau', () {
      final result = score(5, 6);
      expect(result.score, 5 * level.pointsPerQuestion);
      expect(result.levelCleared, isFalse);
      expect(result.suggestion, LevelSuggestion.keep);
    });

    test('le Niveau est franchi à la longueur cible, la même à tous les Niveaux', () {
      final result = score(ComputeSequenceScore.targetLength, ComputeSequenceScore.targetLength + 1);
      expect(result.score, ComputeSequenceScore.targetLength * level.pointsPerQuestion);
      expect(result.levelCleared, isTrue);
      expect(result.suggestion, LevelSuggestion.raise);
    });

    test('rater la première manche : zéro, et on suggère de descendre', () {
      final result = ComputeSequenceScore()([played(of(1), 0)], level: level);
      expect(result.score, 0);
      expect(result.suggestion, LevelSuggestion.lower);
    });
  });
}
