import 'matrix.dart';

/// Réponse du joueur à une Énigme de L'atelier, selon le mode de réponse choisi
/// (`docs/PLAN.md`) : à choix parmi les `answerChoices` de la Matrice, ou construite
/// librement sur une grille vide.
sealed class WorkshopAnswer {
  const WorkshopAnswer();
}

final class ChosenAnswer extends WorkshopAnswer {
  final int choiceIndex;
  const ChosenAnswer(this.choiceIndex);
}

final class ConstructedAnswer extends WorkshopAnswer {
  final Matrix matrix;
  const ConstructedAnswer(this.matrix);
}
