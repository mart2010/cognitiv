import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

QuestionOutcome q(AnswerVerdict v, PuzzlePhase phase) => QuestionOutcome(v, phase: phase);

const screening = PuzzlePhase.screening;
const study = PuzzlePhase.study;
const delayed = PuzzlePhase.delayed;

void main() {
  final compute = ComputeCartographerScore();
  final level3 = CartographerLevels.byNumber(3);

  test('toutes exactes : points du Niveau par question, Bilan compté double', () {
    final result = compute([
      q(AnswerVerdict.exact, screening), q(AnswerVerdict.exact, study), q(AnswerVerdict.exact, study),
      q(AnswerVerdict.exact, delayed),
    ], level: level3);
    expect(result.score, 30 * 5); // 1 + 1 + 1 + 2
    expect(result.levelCleared, isTrue);
    expect(result.suggestion, LevelSuggestion.raise);
  });

  test('une réponse proche vaut la moitié', () {
    final result = compute([q(AnswerVerdict.close, screening), q(AnswerVerdict.exact, screening)], level: level3);
    expect(result.score, 45);
  });

  test('un Bilan raté pèse plus qu\'une étude ratée', () {
    final studyMissed = compute([q(AnswerVerdict.wrong, study), q(AnswerVerdict.exact, delayed)], level: level3);
    final delayedMissed = compute([q(AnswerVerdict.exact, study), q(AnswerVerdict.wrong, delayed)], level: level3);
    expect(delayedMissed.score, lessThan(studyMissed.score));
  });

  group('niveau franchi : jugé sur le Bilan seul', () {
    test("un débutant qui a tout raté au Repérage mais réussit le Bilan franchit le Niveau", () {
      final result = compute([
        for (var i = 0; i < 13; i++) q(AnswerVerdict.wrong, screening),
        for (var i = 0; i < 4; i++) q(AnswerVerdict.exact, study),
        for (var i = 0; i < 4; i++) q(AnswerVerdict.exact, delayed),
      ], level: level3);
      expect(result.levelCleared, isTrue);
      expect(result.suggestion, LevelSuggestion.raise);
    });

    test('un excellent Repérage ne sauve pas un Bilan raté', () {
      final result = compute([
        for (var i = 0; i < 13; i++) q(AnswerVerdict.exact, screening),
        for (var i = 0; i < 4; i++) q(AnswerVerdict.wrong, delayed),
      ], level: level3);
      expect(result.levelCleared, isFalse);
      expect(result.suggestion, LevelSuggestion.lower);
    });

    test("sans Bilan (tout connu), le Repérage fait foi", () {
      final result = compute([for (var i = 0; i < 13; i++) q(AnswerVerdict.exact, screening)], level: level3);
      expect(result.levelCleared, isTrue);
    });
  });

  test('sous le seuil bas on suggère de descendre, sauf au premier Niveau', () {
    final bad = [q(AnswerVerdict.wrong, delayed), q(AnswerVerdict.wrong, delayed), q(AnswerVerdict.exact, delayed)];
    expect(compute(bad, level: level3).suggestion, LevelSuggestion.lower);
    expect(compute(bad, level: CartographerLevels.first).suggestion, LevelSuggestion.keep);
  });

  test('au dernier Niveau, franchir ne suggère pas de monter', () {
    final result = compute([q(AnswerVerdict.exact, delayed)], level: CartographerLevels.last);
    expect(result.levelCleared, isTrue);
    expect(result.suggestion, LevelSuggestion.keep);
  });

  test('aucune réponse : score nul, rien de franchi', () {
    final result = compute([], level: level3);
    expect(result.score, 0);
    expect(result.levelCleared, isFalse);
  });
}
