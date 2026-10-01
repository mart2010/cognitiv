import 'package:test/test.dart';
import 'package:workshop/workshop.dart';

Cell _f(Shape shape, Color color) => Cell.filled(shape, color);

void main() {
  final correct = Matrix([[_f(Shape.round, Color.red)]]);
  final wrong = Matrix([[_f(Shape.square, Color.blue)]]);
  final puzzle = WorkshopPuzzle(
    examples: const [],
    question: correct,
    answerChoices: [wrong, correct],
    correctAnswerIndex: 1,
    appliedRules: const [],
  );
  final evaluate = EvaluateWorkshopAnswer();

  test('mode à choix : correct quand l\'index choisi est le bon', () {
    expect(evaluate(puzzle, const ChosenAnswer(1)).isCorrect, isTrue);
    expect(evaluate(puzzle, const ChosenAnswer(0)).isCorrect, isFalse);
  });

  test('mode construction libre : correct quand la Matrice construite égale la bonne réponse', () {
    expect(evaluate(puzzle, ConstructedAnswer(correct)).isCorrect, isTrue);
    expect(evaluate(puzzle, ConstructedAnswer(wrong)).isCorrect, isFalse);
  });
}
