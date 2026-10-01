import 'package:test/test.dart';
import 'package:workshop/workshop.dart';

void main() {
  final compute = ComputeWorkshopScore();

  test('le score est le nombre de bonnes réponses', () {
    final result = compute(const [
      AnswerEvaluation(true),
      AnswerEvaluation(true),
      AnswerEvaluation(false),
    ]);
    expect(result.score, 2);
  });

  test('le niveau est franchi au-delà du seuil', () {
    final result = compute(
      const [AnswerEvaluation(true), AnswerEvaluation(true), AnswerEvaluation(false)],
      thresholds: const LevelThresholds(minimumCorrectRatioToClearLevel: 0.6),
    );
    expect(result.levelCleared, isTrue);
  });

  test('le niveau n\'est pas franchi sous le seuil', () {
    final result = compute(
      const [AnswerEvaluation(true), AnswerEvaluation(false), AnswerEvaluation(false)],
      thresholds: const LevelThresholds(minimumCorrectRatioToClearLevel: 0.6),
    );
    expect(result.levelCleared, isFalse);
  });
}
