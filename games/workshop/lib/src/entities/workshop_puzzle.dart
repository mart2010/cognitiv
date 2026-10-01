import 'matrix.dart';
import 'rule.dart';

/// Un exemple d'énigme : une entrée et la sortie que la machine en a produite.
class WorkshopExample {
  final Matrix input;
  final Matrix output;
  const WorkshopExample(this.input, this.output);
}

/// Énigme juste (`games/workshop/CONTEXT.md`, ADR 0001) : les Exemples, la Question, les
/// choix de réponse (dont la bonne) et la combinaison de Règles qui l'explique — gardée
/// pour révéler la Famille de règle à la demande, via le bouton d'indice. Value Object,
/// comme la Matrice : son identité dans une Partie vient de sa position dans la liste
/// d'énigmes stockée par la plateforme (ADR 0002), pas d'un identifiant propre.
class WorkshopPuzzle {
  final List<WorkshopExample> examples;
  final Matrix question;
  final List<Matrix> answerChoices;
  final int correctAnswerIndex;
  final List<Rule> appliedRules;

  const WorkshopPuzzle({
    required this.examples,
    required this.question,
    required this.answerChoices,
    required this.correctAnswerIndex,
    required this.appliedRules,
  });

  Matrix get correctAnswer => answerChoices[correctAnswerIndex];
}
