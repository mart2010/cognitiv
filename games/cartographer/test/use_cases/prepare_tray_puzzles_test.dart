import 'dart:convert';

import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

import '../support/real_base_map.dart';

void main() {
  final map = loadSouthAmerica();
  const kind = PrepareTrayPuzzles.linkKind;

  PrepareCartographerRequest request({
    int level = 3,
    Set<Category>? categories,
    Mastery? mastery,
    BaseMap? baseMap,
  }) => PrepareCartographerRequest(
    baseMap: baseMap ?? map,
    level: CartographerLevels.byNumber(level),
    profile: CartographerProfile.defaults().copyWith(categories: categories ?? {Category.cities}),
    language: NameLanguage.fr,
    mastery: mastery,
  );

  List<CartographerPuzzle> prepare(int seed, PrepareCartographerRequest request, [List<PlayedPuzzle> history = const []]) =>
      PrepareTrayPuzzles(random: SystemRandomSource(seed)).call(request, history);

  Set<String> ids(CartographerPuzzle puzzle) => puzzle.questions.map((q) => q.itemId).toSet();

  test('une Partie de Plateaux se prépare d\'un coup : trois Plateaux, puis plus rien', () {
    final trays = prepare(1, request());
    expect(trays, hasLength(PrepareTrayPuzzles.trayCount));
    expect(trays, everyElement(isA<Tray>()));
    final played = [for (final t in trays) PlayedPuzzle(t, [for (final _ in t.questions) AnswerVerdict.exact])];
    expect(prepare(1, request(), played), isEmpty);
    expect(prepare(1, request(), played.take(1).toList()), isEmpty);
  });

  test('un Plateau a la taille du Niveau et les durées du Niveau', () {
    for (final number in [1, 3, 8]) {
      final level = CartographerLevels.byNumber(number);
      for (final puzzle in prepare(2, request(level: number))) {
        final tray = puzzle as Tray;
        expect(tray.questions, hasLength(level.itemCount));
        expect(tray.studySeconds, level.studySeconds);
        expect(tray.distractionSeconds, level.distractionSeconds);
      }
    }
  });

  test('chaque question est « nom → position », sans aide : on replace', () {
    for (final puzzle in prepare(3, request())) {
      for (final q in puzzle.questions) {
        expect(q.kind, kind);
        expect(q.kind.gesture, Gesture.place);
        expect(q.aid, RecallAid.free);
        expect(q.choices, isEmpty);
      }
    }
  });

  test('un Plateau ne mêle pas les Catégories, et ne reprend aucun Élément dans une Partie', () {
    final trays = prepare(4, request(level: 2, categories: {Category.countries, Category.cities}));
    final seen = <String>{};
    for (final tray in trays) {
      final categories = {for (final id in ids(tray)) map.itemById(id).category};
      expect(categories, hasLength(1), reason: '$categories');
      expect(seen.intersection(ids(tray)), isEmpty);
      seen.addAll(ids(tray));
    }
  });

  test('avec deux Catégories, elles se partagent les Plateaux à tour de rôle', () {
    final trays = prepare(5, request(categories: {Category.countries, Category.cities}));
    final categories = [for (final t in trays) map.itemById(t.questions.first.itemId).category];
    expect(categories.toSet(), {Category.countries, Category.cities});
    expect(categories[0], categories[2]); // tour de rôle sur deux Catégories : A B A
    expect(categories[0], isNot(categories[1]));
  });

  test('avec les villes seules, jamais un pays', () {
    for (var seed = 0; seed < 10; seed++) {
      for (final tray in prepare(seed, request())) {
        expect(ids(tray).every((id) => id.startsWith('city:')), isTrue);
      }
    }
  });

  test('les Éléments les moins connus passent d\'abord', () {
    // Les 20 premières villes (par identifiant) sont solides ; les 10 autres sont à apprendre.
    final cities = map.itemsOf(Category.cities)..sort((a, b) => a.id.compareTo(b.id));
    final solid = cities.take(20).map((c) => c.id).toSet();
    final mastery = Mastery({for (final id in solid) MasteryKey(map.id, id, kind): Knowledge.solid});
    for (var seed = 0; seed < 10; seed++) {
      final first = prepare(seed, request(level: 6, mastery: mastery)).first;
      // Plateau de 6 ; 10 villes inconnues : tout vient des inconnues.
      expect(ids(first).intersection(solid), isEmpty, reason: 'graine $seed');
    }
  });

  test('un fragile passe avant un solide quand il manque d\'inconnus', () {
    final cities = map.itemsOf(Category.cities).map((c) => c.id).toList()..sort();
    // 4 inconnues, 3 fragiles, le reste solide : un Plateau de 6 prend les 4 inconnues + 2 fragiles.
    final mastery = Mastery({
      for (final id in cities.skip(4).take(3)) MasteryKey(map.id, id, kind): Knowledge.shaky,
      for (final id in cities.skip(7)) MasteryKey(map.id, id, kind): Knowledge.solid,
    });
    final first = prepare(1, request(level: 6, mastery: mastery)).first;
    final unknown = cities.take(4).toSet();
    final shaky = cities.skip(4).take(3).toSet();
    expect(ids(first).containsAll(unknown), isTrue);
    expect(ids(first).intersection(shaky), hasLength(2));
  });

  test('une petite Catégorie donne des Plateaux plus petits que le Niveau, jamais vides', () {
    final tiny = BaseMap(
      id: 'tiny',
      frame: map.frame,
      items: [for (final c in map.itemsOf(Category.cities).take(3)) c],
    );
    final trays = prepare(1, request(level: 8, baseMap: tiny));
    expect(trays, hasLength(PrepareTrayPuzzles.trayCount));
    for (final tray in trays) {
      expect(tray.questions, hasLength(3)); // Catégorie épuisée : on la rouvre en entier
    }
  });

  test('reproductible avec la même graine, différent avec une autre', () {
    List<List<String>> run(int seed) => [for (final t in prepare(seed, request())) t.questions.map((q) => q.itemId).toList()];
    expect(run(7), run(7));
    expect(run(7), isNot(run(8)));
  });

  test('refuse un Profil dont aucune Catégorie n\'est dans la carte', () {
    final onlyCountries = BaseMap(id: 'c', frame: map.frame, items: map.itemsOf(Category.countries));
    expect(() => prepare(1, request(baseMap: onlyCountries)), throwsArgumentError);
  });

  test('un Plateau fait l\'aller-retour du codec, avec ses durées', () {
    final tray = prepare(1, request()).first as Tray;
    final restored = CartographerPuzzleCodec.fromJson(jsonDecode(jsonEncode(tray.toJson())) as Map<String, dynamic>);
    expect(restored, isA<Tray>());
    expect(restored.toJson(), tray.toJson());
    expect((restored as Tray).studySeconds, tray.studySeconds);
  });

  group('évaluation, score et Maîtrise d\'une Partie de Plateaux', () {
    final evaluate = EvaluateCartographerAnswer();

    List<PlayedPuzzle> play(List<CartographerPuzzle> trays, bool Function(int tray, int question) knows) => [
      for (var t = 0; t < trays.length; t++)
        PlayedPuzzle(trays[t], [
          for (var q = 0; q < trays[t].questions.length; q++)
            evaluate(
              map,
              trays[t].questions[q],
              PlacedAnswer(knows(t, q) ? map.itemById(trays[t].questions[q].itemId).anchor : const GeoPoint(-30, -40)),
            ).verdict,
        ]),
    ];

    test('replacer chaque ville à sa place est exact ; en plein océan est faux', () {
      final trays = prepare(1, request());
      final perfect = play(trays, (_, __) => true);
      expect(perfect.expand((p) => p.verdicts), everyElement(AnswerVerdict.exact));
      final lost = play(trays, (_, __) => false);
      expect(lost.expand((p) => p.verdicts), everyElement(AnswerVerdict.wrong));
    });

    test('le Score pèse chaque réponse du Niveau ; le Niveau est franchi sur tous les Plateaux', () {
      final level = CartographerLevels.byNumber(3);
      final trays = prepare(1, request());
      final all = ComputeCartographerScore()(
        [for (final p in play(trays, (_, __) => true)) ...p.outcomes],
        level: level,
      );
      expect(all.score, 3 * level.itemCount * level.pointsPerQuestion);
      expect(all.levelCleared, isTrue);
      expect(all.suggestion, LevelSuggestion.raise);

      final none = ComputeCartographerScore()([for (final p in play(trays, (_, __) => false)) ...p.outcomes], level: level);
      expect(none.score, 0);
      expect(none.levelCleared, isFalse);
      expect(none.suggestion, LevelSuggestion.lower);
    });

    test('la phase d\'un Plateau est « tray », avec un poids simple (pas de Bilan doublé)', () {
      final played = play(prepare(1, request()), (_, __) => true);
      expect(played.map((p) => p.phase).toSet(), {PuzzlePhase.tray});
    });

    test('la Maîtrise : réussi → fragile, puis solide à la Partie suivante ; raté → à apprendre', () {
      final trays = prepare(1, request());
      final first = UpdateMastery()(Mastery.empty, map.id, play(trays, (t, _) => t == 0));
      final shaky = trays.first.questions.map((q) => first.of(map.id, q.itemId, kind)).toSet();
      expect(shaky, {Knowledge.shaky});
      final missed = trays.last.questions.map((q) => first.of(map.id, q.itemId, kind)).toSet();
      expect(missed, {Knowledge.toLearn});

      final second = UpdateMastery()(first, map.id, play(trays, (t, _) => t == 0));
      expect(trays.first.questions.map((q) => second.of(map.id, q.itemId, kind)).toSet(), {Knowledge.solid});
    });
  });

  test('un Plateau de villes porte autant de points bidon que de vraies villes, à tout Niveau', () {
    for (final number in [1, 5, 10]) {
      for (final tray in prepare(2, request(level: number)).cast<Tray>()) {
        expect(tray.decoys, hasLength(tray.questions.length));
      }
    }
  });

  test('un Plateau de pays n\'a pas de point bidon : on touche la Scène librement', () {
    final trays = prepare(2, request(categories: {Category.countries}));
    expect(trays.cast<Tray>(), everyElement(isA<Tray>().having((t) => t.decoys, 'points bidon', isEmpty)));
  });

  test('les points bidon survivent à la sérialisation', () {
    final tray = prepare(3, request()).first as Tray;
    final back = CartographerPuzzleCodec.fromJson(jsonDecode(jsonEncode(tray.toJson())) as Map<String, dynamic>) as Tray;
    expect(back.decoys, tray.decoys);
  });

  test('la présentation successive donne 2 s par Élément, quelle que soit la durée du Niveau', () {
    for (final number in [1, 6, 10]) {
      final level = CartographerLevels.byNumber(number);
      final trays = PrepareTrayPuzzles(random: SystemRandomSource(5), presentation: TrayPresentation.oneByOne)
          .call(request(level: number), [])
          .cast<Tray>();
      for (final tray in trays) {
        expect(tray.presentation, TrayPresentation.oneByOne);
        expect(tray.studySeconds, tray.questions.length * PrepareTrayPuzzles.secondsPerItem);
        expect(tray.distractionSeconds, level.distractionSeconds);
      }
    }
  });

  test('par défaut, tous les Éléments sont montrés ensemble pendant la durée du Niveau', () {
    for (final tray in prepare(5, request(level: 6)).cast<Tray>()) {
      expect(tray.presentation, TrayPresentation.together);
      expect(tray.studySeconds, CartographerLevels.byNumber(6).studySeconds);
    }
  });

  test('la présentation survit à la sérialisation, et un ancien Plateau se relit « ensemble »', () {
    final tray = PrepareTrayPuzzles(random: SystemRandomSource(6), presentation: TrayPresentation.oneByOne).call(request(), []).first as Tray;
    final json = jsonDecode(jsonEncode(tray.toJson())) as Map<String, dynamic>;
    expect((CartographerPuzzleCodec.fromJson(json) as Tray).presentation, TrayPresentation.oneByOne);
    json.remove('presentation');
    expect((CartographerPuzzleCodec.fromJson(json) as Tray).presentation, TrayPresentation.together);
  });
}
