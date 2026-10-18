import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

import '../support/fake_random_source.dart';
import '../support/real_base_map.dart';

void main() {
  final map = loadSouthAmerica();
  final profile = CartographerProfile.defaults();

  GenerateCartographerRequest request({int level = 3, CartographerProfile? profile_, NameLanguage language = NameLanguage.fr}) =>
      GenerateCartographerRequest(
        baseMap: map,
        level: CartographerLevels.byNumber(level),
        profile: profile_ ?? profile,
        language: language,
      );

  List<CartographerPuzzle> generate(int seed, {int level = 3, CartographerProfile? profile_}) =>
      GenerateCartographerPuzzles(random: SystemRandomSource(seed)).call(request(level: level, profile_: profile_));

  test('une Partie = les Études-éclair du Niveau puis un Bilan', () {
    final puzzles = generate(1, level: 4);
    final level = CartographerLevels.byNumber(4);
    expect(puzzles, hasLength(level.studyCount + 1));
    expect(puzzles.take(level.studyCount), everyElement(isA<FlashStudy>()));
    expect(puzzles.last, isA<DelayedRecall>());
  });

  test('chaque Étude a le bon nombre d\'Éléments distincts et reprend les réglages du Niveau', () {
    for (var seed = 0; seed < 30; seed++) {
      for (final level in [1, 5, 10]) {
        final l = CartographerLevels.byNumber(level);
        for (final study in generate(seed, level: level).whereType<FlashStudy>()) {
          expect(study.questions, hasLength(l.itemCount));
          expect(study.studiedItemIds.toSet(), hasLength(l.itemCount), reason: 'seed $seed niveau $level');
          expect(study.studySeconds, l.studySeconds);
          expect(study.distractionSeconds, l.distractionSeconds);
        }
      }
    }
  });

  test('les genres de Lien respectent le Profil et les Facettes disponibles', () {
    final onlyFlags = CartographerProfile({const LinkKind(Facet.flag, Facet.name), const LinkKind(Facet.name, Facet.capital)});
    for (var seed = 0; seed < 20; seed++) {
      for (final puzzle in generate(seed, profile_: onlyFlags)) {
        for (final q in puzzle.questions) {
          // Aucun drapeau dans les données : seul « nom -> capitale » est posable.
          expect(q.kind, const LinkKind(Facet.name, Facet.capital));
        }
      }
    }
  });

  test('un Profil sans aucun Élément compatible est refusé', () {
    final onlyFlags = CartographerProfile({const LinkKind(Facet.flag, Facet.name)});
    expect(() => generate(1, profile_: onlyFlags), throwsArgumentError);
  });

  test('une Carte trop petite pour le Niveau est refusée', () {
    final small = BaseMap(id: 'small', frame: map.frame, items: map.items.take(2).toList());
    final generator = GenerateCartographerPuzzles(random: SystemRandomSource(1));
    expect(
      () => generator(GenerateCartographerRequest(baseMap: small, level: CartographerLevels.byNumber(3), profile: profile, language: NameLanguage.en)),
      throwsArgumentError,
    );
  });

  test("le Bilan redemande les mêmes Liens que ceux étudiés, sans doublon d'Élément", () {
    for (var seed = 0; seed < 30; seed++) {
      final puzzles = generate(seed, level: 3);
      final studied = <String, LinkKind>{};
      for (final study in puzzles.whereType<FlashStudy>()) {
        for (final q in study.questions) {
          studied[q.itemId] = q.kind;
        }
      }
      final bilan = puzzles.whereType<DelayedRecall>().single;
      expect(bilan.questions.map((q) => q.itemId).toSet(), hasLength(bilan.questions.length));
      for (final q in bilan.questions) {
        expect(studied[q.itemId], q.kind, reason: 'seed $seed ${q.itemId}');
      }
    }
  });

  test('le Bilan privilégie les Éléments des premières Études', () {
    final puzzles = generate(7, level: 1); // 3 Éléments par Étude, 3 Études, 13 Éléments au total
    final lastStudy = puzzles.whereType<FlashStudy>().last.studiedItemIds.toSet();
    final bilan = puzzles.last.questions.map((q) => q.itemId).toList();
    final earlierCount = puzzles.whereType<FlashStudy>().take(2).expand((s) => s.studiedItemIds).toSet().difference(lastStudy).length;
    final fromEarlier = bilan.where((id) => !lastStudy.contains(id)).length;
    expect(fromEarlier, bilan.length < earlierCount ? bilan.length : earlierCount);
  });

  group('Aide au rappel', () {
    test('choices : 4 propositions dont la bonne, uniques, pour une Réponse textuelle', () {
      for (var seed = 0; seed < 20; seed++) {
        for (final puzzle in generate(seed, level: 1)) {
          for (final q in puzzle.questions) {
            final item = map.itemById(q.itemId);
            if (q.kind.gesture == Gesture.naming) {
              expect(q.aid, RecallAid.choices);
              expect(q.choices, hasLength(4));
              expect(q.choices.toSet(), hasLength(4));
              expect(q.choices, contains(item.textFor(q.kind.answer, NameLanguage.fr)));
            } else {
              expect(q.choices, isEmpty);
              expect(q.aid, RecallAid.free);
            }
          }
        }
      }
    });

    test('une proposition ne reprend jamais un texte que la bonne réponse accepte', () {
      for (var seed = 0; seed < 30; seed++) {
        for (final q in generate(seed, level: 2).expand((p) => p.questions).where((q) => q.choices.isNotEmpty)) {
          final accepted = map.itemById(q.itemId).acceptedTexts(q.kind.answer).map(TextMatcher.normalize);
          final correct = TextMatcher.normalize(map.itemById(q.itemId).textFor(q.kind.answer, NameLanguage.fr));
          for (final choice in q.choices.where((c) => TextMatcher.normalize(c) != correct)) {
            expect(accepted, isNot(contains(TextMatcher.normalize(choice))));
          }
        }
      }
    });

    test('firstLetter et free : pas de propositions', () {
      for (final level in [4, 7]) {
        for (final q in generate(3, level: level).expand((p) => p.questions)) {
          expect(q.choices, isEmpty);
        }
      }
      final level7 = generate(3, level: 7).expand((p) => p.questions).where((q) => q.kind.gesture == Gesture.naming);
      expect(level7.map((q) => q.aid).toSet(), {RecallAid.free});
    });
  });

  test('reproductible avec la même graine, différent avec une autre', () {
    String fingerprint(List<CartographerPuzzle> puzzles) => puzzles.map((p) => p.toJson().toString()).join('|');
    expect(fingerprint(generate(42)), fingerprint(generate(42)));
    expect(fingerprint(generate(42)), isNot(fingerprint(generate(43))));
  });

  test('la langue demandée est celle des propositions', () {
    final fr = GenerateCartographerPuzzles(random: SystemRandomSource(1)).call(request(level: 1, language: NameLanguage.fr));
    final en = GenerateCartographerPuzzles(random: SystemRandomSource(1)).call(request(level: 1, language: NameLanguage.en));
    final frChoices = fr.expand((p) => p.questions).expand((q) => q.choices).toSet();
    final enChoices = en.expand((p) => p.questions).expand((q) => q.choices).toSet();
    expect(frChoices.union(enChoices), containsAll(['Brésil', 'Brazil']));
    expect(frChoices, isNot(contains('Brazil')));
    expect(enChoices, isNot(contains('Brésil')));
  });

  test('marche avec la doublure déterministe', () {
    final puzzles = GenerateCartographerPuzzles(random: FakeRandomSource(ints: [0, 1, 2, 3])).call(request(level: 3));
    expect(puzzles, hasLength(4));
  });
}
