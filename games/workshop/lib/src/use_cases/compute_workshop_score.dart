import 'evaluate_workshop_answer.dart';

/// Seuil de réussite d'un Niveau. Provisoire : aucune formule de score n'a encore été
/// décidée pour L'atelier (pas de bonus de temps, de série, etc.) — seul le nombre de
/// bonnes réponses compte pour l'instant, à affiner avec une vraie décision de jeu.
class LevelThresholds {
  final double minimumCorrectRatioToClearLevel;
  const LevelThresholds({this.minimumCorrectRatioToClearLevel = 0.7});
}

/// Résultat de `ComputeWorkshopScore` : le Score (`platform/CONTEXT.md`) et le verdict
/// Niveau franchi, calculés par le jeu selon ses propres règles.
class WorkshopScoreResult {
  final int score;
  final bool levelCleared;
  const WorkshopScoreResult({required this.score, required this.levelCleared});
}

/// Cas d'usage « calculer le score et le verdict niveau franchi » du contrat
/// jeu/plateforme (ADR 0004).
class ComputeWorkshopScore {
  WorkshopScoreResult call(
    List<AnswerEvaluation> evaluations, {
    LevelThresholds thresholds = const LevelThresholds(),
  }) {
    final correctCount = evaluations.where((e) => e.isCorrect).length;
    final ratio = evaluations.isEmpty ? 0.0 : correctCount / evaluations.length;
    return WorkshopScoreResult(
      score: correctCount,
      levelCleared: ratio >= thresholds.minimumCorrectRatioToClearLevel,
    );
  }
}
