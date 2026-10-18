import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

QuestionOutcome q(AnswerVerdict v, {bool delayed = false}) => QuestionOutcome(v, delayed: delayed);

void main() {
  final compute = ComputeCartographerScore();
  final level3 = CartographerLevels.byNumber(3);

  test('toutes exactes : points du Niveau fois le nombre de questions, Bilan compté double', () {
    final result = compute([
      q(AnswerVerdict.exact), q(AnswerVerdict.exact), q(AnswerVerdict.exact),
      q(AnswerVerdict.exact, delayed: true),
    ], level: level3);
    expect(result.score, 30 * 5); // 3 × 1 + 1 × 2
    expect(result.levelCleared, isTrue);
    expect(result.suggestion, LevelSuggestion.raise);
  });

  test('une réponse proche vaut la moitié', () {
    final result = compute([q(AnswerVerdict.close), q(AnswerVerdict.exact)], level: level3);
    expect(result.score, 45);
  });

  test('le Bilan raté pèse plus que une étude ratée', () {
    final studyMissed = compute([q(AnswerVerdict.wrong), q(AnswerVerdict.exact, delayed: true)], level: level3);
    final delayedMissed = compute([q(AnswerVerdict.exact), q(AnswerVerdict.wrong, delayed: true)], level: level3);
    expect(delayedMissed.score, lessThan(studyMissed.score));
  });

  test('sous le seuil bas on suggère de descendre, sauf au premier Niveau', () {
    final bad = [q(AnswerVerdict.wrong), q(AnswerVerdict.wrong), q(AnswerVerdict.exact)];
    expect(compute(bad, level: level3).suggestion, LevelSuggestion.lower);
    expect(compute(bad, level: CartographerLevels.first).suggestion, LevelSuggestion.keep);
  });

  test('au dernier Niveau, franchir ne suggère pas de monter', () {
    final result = compute([q(AnswerVerdict.exact)], level: CartographerLevels.last);
    expect(result.levelCleared, isTrue);
    expect(result.suggestion, LevelSuggestion.keep);
  });

  test('aucune réponse : score nul, rien de franchi', () {
    final result = compute([], level: level3);
    expect(result.score, 0);
    expect(result.levelCleared, isFalse);
  });
}
