import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

import '../support/real_base_map.dart';
import '../support/scripted_player.dart';

const _kind = LinkKind(Facet.name, Facet.position);

void main() {
  final map = loadSouthAmerica();
  final update = UpdateMastery();
  final profile = CartographerProfile({_kind});

  PrepareCartographerRequest request(Mastery mastery) => PrepareCartographerRequest(
    baseMap: map,
    level: CartographerLevels.byNumber(3),
    profile: profile,
    language: NameLanguage.fr,
    mastery: mastery,
  );

  Knowledge? of(Mastery m, String id) => m.of(map.id, id, _kind);

  /// Une Partie complète : le joueur ne connaît que [known] au Repérage, mais apprend ce qu'il
  /// étudie (il réussit les Rappels et le Bilan).
  Mastery playRun(Mastery before, Set<String> known, {int seed = 1}) {
    final prepare = PrepareCartographerPuzzles(random: SystemRandomSource(seed));
    final history = playWholeRun(
      prepare,
      request(before),
      (puzzle, _) => puzzle is Screening ? knowsOnly(known) : knowsEverything,
    );
    return update(before, map.id, history);
  }

  PlayedPuzzle played(List<AnswerVerdict> verdicts, List<String> ids, {bool screening = true}) {
    final questions = [for (final id in ids) RecallQuestion(itemId: id, kind: _kind, aid: RecallAid.free)];
    final puzzle = screening
        ? Screening(language: NameLanguage.fr, questions: questions) as CartographerPuzzle
        : DelayedRecall(language: NameLanguage.fr, questions: questions);
    return PlayedPuzzle(puzzle, verdicts);
  }

  test('un Lien réussi pour la première fois devient fragile', () {
    final after = update(Mastery.empty, map.id, [played([AnswerVerdict.exact], ['PRY'])]);
    expect(of(after, 'PRY'), Knowledge.shaky);
  });

  test('fragile puis réussi à une Partie suivante : solide ; solide le reste', () {
    var m = update(Mastery.empty, map.id, [played([AnswerVerdict.exact], ['PRY'])]);
    m = update(m, map.id, [played([AnswerVerdict.exact], ['PRY'])]);
    expect(of(m, 'PRY'), Knowledge.solid);
    m = update(m, map.id, [played([AnswerVerdict.exact], ['PRY'])]);
    expect(of(m, 'PRY'), Knowledge.solid);
  });

  test('un raté ramène à « à apprendre », même depuis solide, et « presque » est un raté', () {
    final solid = Mastery({MasteryKey(map.id, 'PRY', _kind): Knowledge.solid});
    expect(of(update(solid, map.id, [played([AnswerVerdict.wrong], ['PRY'])]), 'PRY'), Knowledge.toLearn);
    expect(of(update(solid, map.id, [played([AnswerVerdict.close], ['PRY'])]), 'PRY'), Knowledge.toLearn);
  });

  test('un seul pas par Partie : le dernier verdict compte, pas chaque réponse', () {
    // Raté au Repérage puis réussi au Bilan, à partir de rien : fragile, pas solide.
    final after = update(Mastery.empty, map.id, [
      played([AnswerVerdict.wrong], ['PRY']),
      played([AnswerVerdict.exact], ['PRY'], screening: false),
    ]);
    expect(of(after, 'PRY'), Knowledge.shaky);
    // Raté au Bilan après un Repérage réussi : à apprendre.
    final lost = update(Mastery.empty, map.id, [
      played([AnswerVerdict.exact], ['PRY']),
      played([AnswerVerdict.wrong], ['PRY'], screening: false),
    ]);
    expect(of(lost, 'PRY'), Knowledge.toLearn);
  });

  test('les Liens non posés, et les autres Cartes de base, ne bougent pas', () {
    final before = Mastery({
      MasteryKey(map.id, 'URY', _kind): Knowledge.solid,
      MasteryKey('autre', 'PRY', _kind): Knowledge.shaky,
    });
    final after = update(before, map.id, [played([AnswerVerdict.exact], ['PRY'])]);
    expect(of(after, 'URY'), Knowledge.solid);
    expect(after.of('autre', 'PRY', _kind), Knowledge.shaky);
    expect(of(after, 'PRY'), Knowledge.shaky);
  });

  test("la Maîtrise d'avant n'est pas modifiée", () {
    final before = Mastery.empty;
    update(before, map.id, [played([AnswerVerdict.exact], ['PRY'])]);
    expect(before.isEmpty, isTrue);
  });

  group('sur plusieurs séances', () {
    test("un joueur qui apprend : fragile après la 1re Partie, solide après la 2e", () {
      final known = <String>{};
      final firstRun = playRun(Mastery.empty, known); // il ne connaît rien, il apprend ≤ 8 pays
      final shakyAfterFirst = [for (final id in map.items.map((i) => i.id)) if (of(firstRun, id) == Knowledge.shaky) id];
      expect(shakyAfterFirst, isNotEmpty);
      expect(shakyAfterFirst.length, lessThanOrEqualTo(8)); // 2 Lots de 4 au Niveau 3
      expect(firstRun.states.values.where((k) => k == Knowledge.solid), isEmpty);

      // À la Partie suivante, il connaît désormais ce qu'il a appris.
      final secondRun = playRun(firstRun, shakyAfterFirst.toSet());
      for (final id in shakyAfterFirst) {
        expect(of(secondRun, id), anyOf(Knowledge.solid, Knowledge.shaky), reason: id);
      }
      // Ceux qu'il avait appris et qui ont été reposés au Repérage sont maintenant solides.
      expect(secondRun.states.values.any((k) => k == Knowledge.solid), isTrue);
    });

    test("avec plusieurs genres de Lien, un Lien fragile finit par être confirmé solide", () {
      // Le Profil par défaut a 5 genres : sans tirage entre nouveau et fragile, aucun Lien ne serait
      // jamais reposé avant la 6e Partie.
      final defaults = CartographerProfile.defaults();
      for (final seed in [1, 2, 3]) {
        var m = Mastery.empty;
        for (var run = 0; run < 3; run++) {
          final prepare = PrepareCartographerPuzzles(random: SystemRandomSource(seed + run));
          final history = playWholeRun(
            prepare,
            PrepareCartographerRequest(
              baseMap: map,
              level: CartographerLevels.byNumber(3),
              profile: defaults,
              language: NameLanguage.fr,
              mastery: m,
            ),
            (_, __) => knowsEverything,
          );
          m = update(m, map.id, history);
        }
        expect(m.states.values, contains(Knowledge.solid), reason: 'seed $seed');
      }
    });

    test("le Repérage suivant ne repose pas ce qui est déjà solide, sauf sondage", () {
      final allSolid = Mastery({
        for (final item in map.items) MasteryKey(map.id, item.id, _kind): Knowledge.solid,
      });
      final screening = PrepareCartographerPuzzles(random: SystemRandomSource(1))
          .call(request(allSolid), [])
          .single;
      expect(screening.questions, hasLength(PrepareCartographerPuzzles.solidSpotChecks));
    });

    test('un sondage raté rétrograde un Lien solide', () {
      final allSolid = Mastery({
        for (final item in map.items) MasteryKey(map.id, item.id, _kind): Knowledge.solid,
      });
      final prepare = PrepareCartographerPuzzles(random: SystemRandomSource(1));
      final history = playWholeRun(prepare, request(allSolid), (_, __) => knowsNothing);
      final after = update(allSolid, map.id, history);
      expect(after.states.values.where((k) => k == Knowledge.toLearn), isNotEmpty);
    });
  });
}
