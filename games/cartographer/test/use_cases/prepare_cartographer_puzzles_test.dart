import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

import '../support/real_base_map.dart';
import '../support/scripted_player.dart';

const _positionOfName = LinkKind(Facet.name, Facet.position);
const _capitalOfName = LinkKind(Facet.name, Facet.capital);

void main() {
  final map = loadSouthAmerica();
  final allIds = map.items.map((i) => i.id).toSet();

  PrepareCartographerRequest request({
    int level = 3,
    CartographerProfile? profile,
    Mastery? mastery,
    NameLanguage language = NameLanguage.fr,
    BaseMap? baseMap,
  }) => PrepareCartographerRequest(
    baseMap: baseMap ?? map,
    level: CartographerLevels.byNumber(level),
    profile: profile ?? CartographerProfile.defaults(),
    language: language,
    mastery: mastery,
  );

  PrepareCartographerPuzzles prepareWith(int seed) => PrepareCartographerPuzzles(random: SystemRandomSource(seed));

  Screening screening(int seed, {int level = 3, CartographerProfile? profile, Mastery? mastery}) =>
      prepareWith(seed).call(request(level: level, profile: profile, mastery: mastery), []).single as Screening;

  group('Repérage (historique vide)', () {
    test("une seule Énigme : le Repérage, une question par Élément, tous distincts", () {
      final puzzles = prepareWith(1).call(request(), []);
      expect(puzzles, hasLength(1));
      final s = puzzles.single as Screening;
      expect(s.questions.map((q) => q.itemId).toSet(), allIds);
      expect(s.questions, hasLength(13));
    });

    test('les genres de Lien respectent le Profil et les Facettes disponibles', () {
      final profile = CartographerProfile({const LinkKind(Facet.flag, Facet.name), _capitalOfName});
      for (var seed = 0; seed < 20; seed++) {
        for (final q in screening(seed, profile: profile).questions) {
          // Aucun drapeau dans les données : seul « nom -> capitale » est posable.
          expect(q.kind, _capitalOfName);
        }
      }
    });

    test('un Profil sans aucun Élément compatible est refusé', () {
      final onlyFlags = CartographerProfile({const LinkKind(Facet.flag, Facet.name)});
      expect(() => screening(1, profile: onlyFlags), throwsArgumentError);
    });

    test("l'ordre des questions varie avec la graine, pas le contenu", () {
      final a = screening(1).questions.map((q) => q.itemId).toList();
      final b = screening(2).questions.map((q) => q.itemId).toList();
      expect(a.toSet(), b.toSet());
      expect(a, isNot(b));
    });

    test("les Éléments solides ne sont recontrôlés que par sondage, les moins connus passent d'abord", () {
      final profile = CartographerProfile({_positionOfName});
      final mastery = Mastery({
        for (final item in map.items)
          MasteryKey(map.id, item.id, _positionOfName): item.id == 'PRY' ? Knowledge.toLearn : Knowledge.solid,
      });
      for (var seed = 0; seed < 20; seed++) {
        final ids = screening(seed, profile: profile, mastery: mastery).questions.map((q) => q.itemId).toList();
        expect(ids, contains('PRY'), reason: 'seed $seed');
        expect(ids, hasLength(1 + PrepareCartographerPuzzles.solidSpotChecks));
      }
    });

    test('un Élément fragile est posé avant un solide', () {
      final profile = CartographerProfile({_positionOfName});
      final mastery = Mastery({
        for (final item in map.items)
          MasteryKey(map.id, item.id, _positionOfName): item.id == 'URY' ? Knowledge.shaky : Knowledge.solid,
      });
      for (var seed = 0; seed < 10; seed++) {
        expect(screening(seed, profile: profile, mastery: mastery).questions.map((q) => q.itemId), contains('URY'));
      }
    });

    test("un joueur qui connaît déjà les positions se voit poser les capitales, sans changer de Profil", () {
      final profile = CartographerProfile({_positionOfName, _capitalOfName});
      final mastery = Mastery({
        for (final item in map.items) MasteryKey(map.id, item.id, _positionOfName): Knowledge.solid,
      });
      for (final q in screening(4, profile: profile, mastery: mastery).questions) {
        expect(q.kind, _capitalOfName);
      }
    });

    test('entre un genre nouveau et un genre fragile, les deux peuvent être posés', () {
      final profile = CartographerProfile({_positionOfName, _capitalOfName});
      final mastery = Mastery({
        for (final item in map.items) MasteryKey(map.id, item.id, _positionOfName): Knowledge.shaky,
      });
      final asked = <LinkKind>{};
      for (var seed = 0; seed < 30; seed++) {
        asked.addAll(screening(seed, profile: profile, mastery: mastery).questions.map((q) => q.kind));
      }
      expect(asked, {_positionOfName, _capitalOfName});
    });

    test('au-delà de la limite, un échantillon des moins connus', () {
      Item fake(int i) => Item(
            id: 'X$i',
            kind: ItemKind.country,
            belongsTo: 'X$i',
            names: LocalizedText(en: 'Land $i', fr: 'Terre $i'),
            capitals: [
              Capital(
                names: LocalizedText(en: 'Cap $i', fr: 'Cap $i'),
                position: const GeoPoint(0, 0),
                role: CapitalRole.primary,
              ),
            ],
            anchor: const GeoPoint(0, 0),
            outline: const [],
          );
      final big = BaseMap(id: 'big', frame: map.frame, items: [for (var i = 0; i < 30; i++) fake(i)]);
      final profile = CartographerProfile({_capitalOfName});
      // 5 Éléments fragiles, 25 inconnus : les 20 questions viennent des inconnus.
      final mastery = Mastery({for (var i = 0; i < 5; i++) MasteryKey('big', 'X$i', _capitalOfName): Knowledge.shaky});
      final ids = PrepareCartographerPuzzles(random: SystemRandomSource(3))
          .call(request(profile: profile, mastery: mastery, baseMap: big), [])
          .single
          .questions
          .map((q) => q.itemId)
          .toList();
      expect(ids, hasLength(PrepareCartographerPuzzles.screeningLimit));
      expect(ids.toSet(), hasLength(20));
      expect(ids.where((id) => int.parse(id.substring(1)) < 5), isEmpty);
    });
  });

  group('Études-éclair et Bilan (Repérage joué)', () {
    List<CartographerPuzzle> afterScreening(int seed, Verdicts verdicts, {int level = 3}) {
      final prepare = prepareWith(seed);
      final req = request(level: level);
      final played = play(prepare(req, []).single, verdicts);
      return prepare(req, [played]);
    }

    test('tout raté : deux Lots du Niveau puis le Bilan, le reste est laissé de côté', () {
      final puzzles = afterScreening(1, knowsNothing); // niveau 3 : lots de 4, 2 cycles max
      expect(puzzles.map((p) => p.runtimeType), [FlashStudy, FlashStudy, DelayedRecall]);
      final studied = puzzles.whereType<FlashStudy>().expand((p) => p.studiedItemIds).toList();
      expect(studied, hasLength(8));
      expect(studied.toSet(), hasLength(8));
    });

    test("quelques ratés seulement : un seul Lot, de la taille des ratés, et un Bilan", () {
      final missed = {'PRY', 'URY', 'ECU'};
      final puzzles = afterScreening(2, knowsOnly(allIds.difference(missed)));
      expect(puzzles.map((p) => p.runtimeType), [FlashStudy, DelayedRecall]);
      expect((puzzles.first as FlashStudy).studiedItemIds.toSet(), missed);
      expect(puzzles.last.questions.map((q) => q.itemId).toSet(), missed);
    });

    test('« raté, c\'est raté » : un placement presque juste est étudié comme un autre', () {
      final prepare = prepareWith(1);
      final req = request();
      final s = prepare(req, []).single;
      final played = PlayedPuzzle(s, [for (final _ in s.questions) AnswerVerdict.close]);
      expect(prepare(req, [played]).whereType<FlashStudy>(), isNotEmpty);
    });

    test("le joueur qui a tout reconnu n'étudie rien : la Partie est terminée", () {
      expect(afterScreening(1, knowsEverything), isEmpty);
    });

    test('les Études gardent le genre de Lien du Repérage et les réglages du Niveau', () {
      final prepare = prepareWith(5);
      final req = request(level: 3);
      final s = prepare(req, []).single;
      final kinds = {for (final q in s.questions) q.itemId: q.kind};
      final level = CartographerLevels.byNumber(3);
      for (final puzzle in prepare(req, [play(s, knowsNothing)])) {
        for (final q in puzzle.questions) {
          expect(q.kind, kinds[q.itemId], reason: q.itemId);
        }
        if (puzzle is FlashStudy) {
          expect(puzzle.studySeconds, level.studySeconds);
          expect(puzzle.distractionSeconds, level.distractionSeconds);
          expect(puzzle.questions.length, lessThanOrEqualTo(level.itemCount));
        }
      }
    });

    test('le Bilan privilégie le premier Lot, le plus ancien', () {
      for (var seed = 0; seed < 20; seed++) {
        final puzzles = afterScreening(seed, knowsNothing);
        final firstBatch = (puzzles[0] as FlashStudy).studiedItemIds.toSet();
        final bilanIds = puzzles.last.questions.map((q) => q.itemId).toList();
        expect(bilanIds, hasLength(5)); // delayedRecallCount du niveau 3
        expect(firstBatch.difference(bilanIds.toSet()), isEmpty, reason: 'seed $seed');
      }
    });

    test("un historique qui ne commence pas par le Repérage est une erreur de l'app", () {
      final prepare = prepareWith(1);
      final study = FlashStudy(language: NameLanguage.fr, questions: const [], studySeconds: 1, distractionSeconds: 1);
      expect(() => prepare(request(), [PlayedPuzzle(study, [])]), throwsArgumentError);
    });
  });

  group('Fin de Partie', () {
    test('après le Bilan, la préparation rend une liste vide, et reste vide', () {
      final prepare = prepareWith(7);
      final history = playWholeRun(prepare, request(), (_, __) => knowsNothing);
      expect(history.last.puzzle, isA<DelayedRecall>());
      expect(prepare(request(), history), isEmpty);
      expect(prepare(request(), history), isEmpty);
    });

    test("une Partie sans rien à étudier se termine après le Repérage", () {
      final history = playWholeRun(prepareWith(7), request(), (_, __) => knowsEverything);
      expect(history.map((p) => p.puzzle.runtimeType), [Screening]);
    });

    test('la Partie complète est reproductible avec la même graine', () {
      String fingerprint(int seed) => playWholeRun(prepareWith(seed), request(), (_, __) => knowsNothing)
          .map((p) => p.puzzle.toJson().toString())
          .join('|');
      expect(fingerprint(42), fingerprint(42));
      expect(fingerprint(42), isNot(fingerprint(43)));
    });
  });

  group('Aide au rappel', () {
    List<RecallQuestion> allQuestions(int seed, int level) => [
      for (final p in playWholeRun(prepareWith(seed), request(level: level), (_, __) => knowsNothing)) ...p.puzzle.questions,
    ];

    test('choices : 4 propositions dont la bonne, uniques, pour une Réponse textuelle', () {
      for (var seed = 0; seed < 15; seed++) {
        for (final q in allQuestions(seed, 1)) {
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
    });

    test('une proposition ne reprend jamais un texte que la bonne réponse accepte', () {
      for (var seed = 0; seed < 20; seed++) {
        for (final q in allQuestions(seed, 2).where((q) => q.choices.isNotEmpty)) {
          final item = map.itemById(q.itemId);
          final accepted = item.acceptedTexts(q.kind.answer).map(TextMatcher.normalize);
          final correct = TextMatcher.normalize(item.textFor(q.kind.answer, NameLanguage.fr));
          for (final choice in q.choices.where((c) => TextMatcher.normalize(c) != correct)) {
            expect(accepted, isNot(contains(TextMatcher.normalize(choice))));
          }
        }
      }
    });

    test('firstLetter et free : pas de propositions', () {
      for (final level in [4, 7]) {
        expect(allQuestions(3, level).expand((q) => q.choices), isEmpty);
      }
      expect(
        allQuestions(3, 7).where((q) => q.kind.gesture == Gesture.naming).map((q) => q.aid).toSet(),
        {RecallAid.free},
      );
    });

    test('la langue demandée est celle des propositions', () {
      List<String> choices(NameLanguage l) => [
        for (final p in playWholeRun(prepareWith(1), request(level: 1, language: l), (_, __) => knowsNothing))
          ...p.puzzle.questions.expand((q) => q.choices),
      ];
      expect(choices(NameLanguage.fr), isNot(contains('Brazil')));
      expect(choices(NameLanguage.en), isNot(contains('Brésil')));
    });
  });
}
