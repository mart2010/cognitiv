import 'package:test/test.dart';
import 'package:workshop/workshop.dart';

void main() {
  final compute = ComputeWorkshopScore();
  final level1 = WorkshopLevels.byNumber(1);
  final level5 = WorkshopLevels.byNumber(5);

  List<AnswerEvaluation> answers(int correct, int total) => [
        for (var i = 0; i < total; i++) AnswerEvaluation(i < correct),
      ];

  test('le score vaut les points du Niveau par bonne réponse', () {
    expect(compute(answers(3, 5), level: level1).score, 3 * level1.pointsPerCorrectAnswer);
  });

  test('une bonne réponse rapporte plus à un Niveau plus difficile', () {
    expect(
      compute(answers(4, 5), level: level5).score,
      greaterThan(compute(answers(4, 5), level: level1).score),
    );
  });

  test('le score maximal correspond à une partie parfaite', () {
    expect(compute(answers(5, 5), level: level5).score, level5.maxScore);
  });

  test('le niveau est franchi au-delà du seuil', () {
    final result = compute(
      answers(2, 3),
      level: level1,
      thresholds: const LevelThresholds(minimumCorrectRatioToClearLevel: 0.6),
    );
    expect(result.levelCleared, isTrue);
  });

  test("le niveau n'est pas franchi sous le seuil", () {
    final result = compute(
      answers(1, 3),
      level: level1,
      thresholds: const LevelThresholds(minimumCorrectRatioToClearLevel: 0.6),
    );
    expect(result.levelCleared, isFalse);
  });

  group('suggestion de Niveau', () {
    test('monter quand le Niveau est franchi', () {
      expect(compute(answers(4, 5), level: level5).suggestion, LevelSuggestion.raise);
    });

    test('rester quand le Niveau est raté de peu', () {
      expect(compute(answers(3, 5), level: level5).suggestion, LevelSuggestion.keep);
    });

    test('descendre quand le résultat est très bas', () {
      expect(compute(answers(1, 5), level: level5).suggestion, LevelSuggestion.lower);
    });

    test('ne propose pas de monter au dernier Niveau', () {
      expect(compute(answers(5, 5), level: WorkshopLevels.last).suggestion, LevelSuggestion.keep);
    });

    test('ne propose pas de descendre au premier Niveau', () {
      expect(compute(answers(0, 5), level: WorkshopLevels.first).suggestion, LevelSuggestion.keep);
    });
  });
}
