import 'package:test/test.dart';
import 'package:workshop/workshop.dart';

void main() {
  test("l'échelle compte 10 Niveaux numérotés de 1 à 10", () {
    expect([for (final l in WorkshopLevels.all) l.number], [for (var i = 1; i <= 10; i++) i]);
  });

  test('les points par bonne réponse croissent avec le Niveau', () {
    final points = [for (final l in WorkshopLevels.all) l.pointsPerCorrectAnswer];
    for (var i = 1; i < points.length; i++) {
      expect(points[i], greaterThan(points[i - 1]));
    }
  });

  test('byNumber refuse un Niveau inconnu', () {
    expect(() => WorkshopLevels.byNumber(99), throwsArgumentError);
  });

  test('suivant et précédent respectent les bornes', () {
    expect(WorkshopLevels.hasPrevious(WorkshopLevels.first), isFalse);
    expect(WorkshopLevels.hasNext(WorkshopLevels.last), isFalse);
    expect(WorkshopLevels.next(WorkshopLevels.first).number, 2);
    expect(WorkshopLevels.previous(WorkshopLevels.last).number, 9);
  });

  for (final level in WorkshopLevels.all) {
    test('Niveau ${level.number} : une Énigme juste se génère en quelques essais', () {
      final generate = GenerateWorkshopPuzzle(
        catalog: const RuleCatalog(),
        random: SystemRandomSource(level.number),
      );
      var generated = 0;
      for (var attempt = 0; attempt < 10; attempt++) {
        final result = generate(
          GenerateWorkshopPuzzleRequest.forLevel(
            level,
            profile: GenerationProfile.intuitiveDefaults,
          ),
        );
        if (result is GenerationSucceeded) {
          generated++;
          expect(result.puzzle.examples, hasLength(level.exampleCount));
          expect(result.puzzle.appliedRules, hasLength(level.ruleCount));
          expect(result.puzzle.question.rowCount, level.rowCount);
          expect(result.puzzle.question.columnCount, level.columnCount);
        }
      }
      expect(generated, greaterThanOrEqualTo(5));
    });
  }
}
