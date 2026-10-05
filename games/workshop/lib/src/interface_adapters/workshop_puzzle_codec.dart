import '../entities/rule.dart';
import '../entities/workshop_puzzle.dart';
import 'matrix_codec.dart';
import 'rule_codec.dart';

/// Traduit une Énigme (et ses Exemples) vers une donnée sérialisable : une Partie stocke
/// ses énigmes générées telles quelles, pas une graine (ADR 0002).
extension WorkshopExampleJsonEncoding on WorkshopExample {
  Map<String, dynamic> toJson() => {'input': input.toJson(), 'output': output.toJson()};
}

extension WorkshopPuzzleJsonEncoding on WorkshopPuzzle {
  Map<String, dynamic> toJson() => {
        'examples': [for (final example in examples) example.toJson()],
        'question': question.toJson(),
        'answerChoices': [for (final choice in answerChoices) choice.toJson()],
        'correctAnswerIndex': correctAnswerIndex,
        'appliedRules': [for (final rule in appliedRules) rule.toJson()],
      };
}

class WorkshopPuzzleCodec {
  static WorkshopExample exampleFromJson(Map<String, dynamic> json) => WorkshopExample(
        MatrixCodec.fromJson(json['input'] as Map<String, dynamic>),
        MatrixCodec.fromJson(json['output'] as Map<String, dynamic>),
      );

  static WorkshopPuzzle fromJson(Map<String, dynamic> json) => WorkshopPuzzle(
        examples: [
          for (final example in json['examples'] as List)
            exampleFromJson(example as Map<String, dynamic>),
        ],
        question: MatrixCodec.fromJson(json['question'] as Map<String, dynamic>),
        answerChoices: [
          for (final choice in json['answerChoices'] as List)
            MatrixCodec.fromJson(choice as Map<String, dynamic>),
        ],
        correctAnswerIndex: json['correctAnswerIndex'] as int,
        appliedRules: <Rule>[
          for (final rule in json['appliedRules'] as List) RuleCodec.fromJson(rule as Map<String, dynamic>),
        ],
      );
}
