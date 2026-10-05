import 'dart:convert';

import 'package:test/test.dart';
import 'package:workshop/workshop.dart';

import '../support/fake_random_source.dart';

void main() {
  test('aller-retour JSON préserve une Énigme générée par le vrai générateur', () {
    final generator = GenerateWorkshopPuzzle(
      catalog: const RuleCatalog(),
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
      profile: GenerationProfile({RuleFamily.mirror}),
    ));
    final puzzle = (result as GenerationSucceeded).puzzle;

    final roundTripped = jsonDecode(jsonEncode(puzzle.toJson())) as Map<String, dynamic>;
    final decoded = WorkshopPuzzleCodec.fromJson(roundTripped);

    expect(decoded.examples.length, puzzle.examples.length);
    for (var i = 0; i < puzzle.examples.length; i++) {
      expect(decoded.examples[i].input, puzzle.examples[i].input);
      expect(decoded.examples[i].output, puzzle.examples[i].output);
    }
    expect(decoded.question, puzzle.question);
    expect(decoded.answerChoices, puzzle.answerChoices);
    expect(decoded.correctAnswerIndex, puzzle.correctAnswerIndex);
    expect(decoded.appliedRules, puzzle.appliedRules);
  });
}
