import 'package:test/test.dart';
import 'package:workshop/workshop.dart';

import '../support/fake_random_source.dart';

void main() {
  const catalog = RuleCatalog();
  const mirrorOnly = GenerationProfile({RuleFamily.mirror});

  test('génère une Énigme juste avec les exemples, la question et les choix attendus', () {
    final generator = GenerateWorkshopPuzzle(
      catalog: catalog,
      random: FakeRandomSource(
        ints: const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 4, 0, 2, 4, 1, 3, 0],
        doubles: const [0.9],
      ),
    );

    final result = generator(const GenerateWorkshopPuzzleRequest(
      rowCount: 2,
      columnCount: 2,
      ruleCount: 1,
      exampleCount: 2,
      profile: mirrorOnly,
    ));

    expect(result, isA<GenerationSucceeded>());
    final puzzle = (result as GenerationSucceeded).puzzle;

    // Auto-cohérence : la combinaison de Règles renvoyée explique bien les exemples et la
    // question, sans dépendre des valeurs exactes tirées par le hasard.
    for (final example in puzzle.examples) {
      expect(puzzle.appliedRules.applyTo(example.input), example.output);
    }
    expect(puzzle.appliedRules.applyTo(puzzle.question), puzzle.correctAnswer);

    expect(puzzle.answerChoices, hasLength(4));
    expect(puzzle.answerChoices[puzzle.correctAnswerIndex], puzzle.correctAnswer);
    for (final choice in puzzle.answerChoices) {
      expect(choice.rowCount, puzzle.correctAnswer.rowCount);
      expect(choice.columnCount, puzzle.correctAnswer.columnCount);
    }
  });

  test('échoue proprement quand le Profil actif ne peut pas atteindre la complexité visée', () {
    final generator = GenerateWorkshopPuzzle(
      catalog: catalog,
      random: FakeRandomSource(ints: const [0], doubles: const [0.9]),
    );

    final result = generator(const GenerateWorkshopPuzzleRequest(
      rowCount: 2,
      columnCount: 2,
      ruleCount: 5, // la Famille Miroir n'offre que 2 Règles distinctes
      exampleCount: 1,
      profile: mirrorOnly,
    ));

    expect(result, isA<GenerationFailed>());
  });

  test('un seul Rôle de case vide par Énigme, et Actif pour la Gravité et le Taquin', () {
    final generator = GenerateWorkshopPuzzle(catalog: catalog, random: SystemRandomSource(42));
    for (var i = 0; i < 100; i++) {
      final result = generator(const GenerateWorkshopPuzzleRequest(
        rowCount: 4,
        columnCount: 4,
        ruleCount: 1,
        exampleCount: 3,
        profile: GenerationProfile({RuleFamily.sliding, RuleFamily.gravity}),
      ));
      if (result is! GenerationSucceeded) continue;
      final puzzle = result.puzzle;
      final roles = <EmptyCellRole>{};
      for (final matrix in [puzzle.question, for (final e in puzzle.examples) e.input]) {
        for (var r = 0; r < matrix.rowCount; r++) {
          for (var c = 0; c < matrix.columnCount; c++) {
            final role = matrix.cellAt(r, c).emptyRole;
            if (role != null) roles.add(role);
          }
        }
      }
      expect(roles.length, lessThanOrEqualTo(1));
      expect(roles, {EmptyCellRole.active}, reason: 'Gravité et Taquin imposent le Rôle Actif');
      final questionHasActive = [
        for (var r = 0; r < puzzle.question.rowCount; r++)
          for (var c = 0; c < puzzle.question.columnCount; c++) puzzle.question.cellAt(r, c).emptyRole,
      ].contains(EmptyCellRole.active);
      expect(questionHasActive, isTrue, reason: 'la Question contient au moins une case Active');
    }
  });

  test('la Règle a un effet visible sur chaque Exemple et sur la Question', () {
    final generator = GenerateWorkshopPuzzle(catalog: catalog, random: SystemRandomSource(7));
    var generated = 0;
    for (var i = 0; i < 100; i++) {
      final result = generator(const GenerateWorkshopPuzzleRequest(
        rowCount: 3,
        columnCount: 3,
        ruleCount: 1,
        exampleCount: 2,
        profile: GenerationProfile({RuleFamily.sliding, RuleFamily.gravity, RuleFamily.mirror}),
      ));
      if (result is! GenerationSucceeded) continue;
      generated++;
      final puzzle = result.puzzle;
      for (final example in puzzle.examples) {
        expect(example.output, isNot(example.input));
      }
      expect(puzzle.correctAnswer, isNot(puzzle.question));
    }
    expect(generated, greaterThan(50));
  });

  Set<Color> colorsUsedBy(RuleCatalog catalog) {
    final generator = GenerateWorkshopPuzzle(catalog: catalog, random: SystemRandomSource(5));
    final used = <Color>{};
    for (var i = 0; i < 40; i++) {
      final result = generator(const GenerateWorkshopPuzzleRequest(
        rowCount: 3,
        columnCount: 3,
        ruleCount: 1,
        exampleCount: 2,
        profile: GenerationProfile.intuitiveDefaults,
      ));
      if (result is! GenerationSucceeded) continue;
      for (final matrix in [result.puzzle.question, ...result.puzzle.answerChoices]) {
        for (var r = 0; r < matrix.rowCount; r++) {
          for (var c = 0; c < matrix.columnCount; c++) {
            final color = matrix.cellAt(r, c).color;
            if (color != null) used.add(color);
          }
        }
      }
    }
    return used;
  }

  test('par défaut, seules les trois Couleurs de la palette par défaut sont utilisées', () {
    expect(colorsUsedBy(const RuleCatalog()), {Color.blue, Color.yellow, Color.red});
  });

  test('une palette plus large augmente le nombre de Couleurs sans toucher au domaine', () {
    final used = colorsUsedBy(const RuleCatalog(colorOrder: Color.values));
    expect(used, containsAll([Color.green, Color.purple]));
  });
}
