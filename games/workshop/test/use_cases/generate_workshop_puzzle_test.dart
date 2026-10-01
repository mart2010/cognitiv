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
}
