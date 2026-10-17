import '../entities/workshop_level.dart';
import 'evaluate_workshop_answer.dart';

/// Seuils d'une Partie. Provisoires : à affiner avec le jeu réel.
class LevelThresholds {
  /// Part de bonnes réponses à atteindre pour franchir le Niveau.
  final double minimumCorrectRatioToClearLevel;

  /// Sous cette part, on suggère de descendre d'un Niveau.
  final double lowerBelowCorrectRatio;

  const LevelThresholds({
    this.minimumCorrectRatioToClearLevel = 0.7,
    this.lowerBelowCorrectRatio = 0.5,
  });
}

/// Ce que le jeu suggère après une Partie. Jamais imposé : le joueur choisit son Niveau
/// librement, et la difficulté ne s'adapte jamais en secret.
enum LevelSuggestion { raise, keep, lower }

/// Résultat de `ComputeWorkshopScore` : le Score (`platform/CONTEXT.md`), le verdict
/// Niveau franchi et la suggestion de Niveau, calculés par le jeu selon ses propres règles.
class WorkshopScoreResult {
  final int score;
  final bool levelCleared;
  final LevelSuggestion suggestion;
  const WorkshopScoreResult({
    required this.score,
    required this.levelCleared,
    required this.suggestion,
  });
}

/// Cas d'usage « calculer le score et le verdict niveau franchi » du contrat
/// jeu/plateforme (ADR 0004). Le Score vaut les points du Niveau par bonne réponse
/// (`WorkshopLevel.pointsPerCorrectAnswer`), donc réussir un Niveau plus difficile
/// rapporte plus. La suggestion monte si le Niveau est franchi (et qu'il en reste un
/// au-dessus), descend sous le seuil bas (s'il en reste un en dessous), sinon reste.
class ComputeWorkshopScore {
  WorkshopScoreResult call(
    List<AnswerEvaluation> evaluations, {
    required WorkshopLevel level,
    LevelThresholds thresholds = const LevelThresholds(),
  }) {
    final correctCount = evaluations.where((e) => e.isCorrect).length;
    final ratio = evaluations.isEmpty ? 0.0 : correctCount / evaluations.length;
    final cleared = ratio >= thresholds.minimumCorrectRatioToClearLevel;

    final suggestion = cleared && WorkshopLevels.hasNext(level)
        ? LevelSuggestion.raise
        : ratio < thresholds.lowerBelowCorrectRatio && WorkshopLevels.hasPrevious(level)
            ? LevelSuggestion.lower
            : LevelSuggestion.keep;

    return WorkshopScoreResult(
      score: correctCount * level.pointsPerCorrectAnswer,
      levelCleared: cleared,
      suggestion: suggestion,
    );
  }
}
