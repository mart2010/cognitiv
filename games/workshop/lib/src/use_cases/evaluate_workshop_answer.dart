import '../entities/workshop_answer.dart';
import '../entities/workshop_puzzle.dart';

/// Verdict de `EvaluateWorkshopAnswer` : la réponse du joueur est-elle correcte ?
class AnswerEvaluation {
  final bool isCorrect;
  const AnswerEvaluation(this.isCorrect);
}

/// Cas d'usage « évaluer une réponse à une énigme » du contrat jeu/plateforme
/// (ADR 0004). Fonction pure et sans état : la Partie et sa reprise appartiennent à la
/// plateforme, pas à L'atelier.
class EvaluateWorkshopAnswer {
  AnswerEvaluation call(WorkshopPuzzle puzzle, WorkshopAnswer answer) {
    final isCorrect = switch (answer) {
      ChosenAnswer(choiceIndex: final index) => index == puzzle.correctAnswerIndex,
      ConstructedAnswer(matrix: final matrix) => matrix == puzzle.correctAnswer,
    };
    return AnswerEvaluation(isCorrect);
  }
}
