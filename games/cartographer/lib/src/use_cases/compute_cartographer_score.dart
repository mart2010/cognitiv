import '../entities/cartographer_level.dart';
import '../entities/played_puzzle.dart';

/// Seuils d'une Partie. Provisoires : à affiner avec le jeu réel.
class LevelThresholds {
  /// Part du crédit pondéré à atteindre pour franchir le Niveau.
  final double minimumRatioToClearLevel;

  /// Sous cette part, on suggère de descendre d'un Niveau.
  final double lowerBelowRatio;

  const LevelThresholds({this.minimumRatioToClearLevel = 0.7, this.lowerBelowRatio = 0.5});
}

/// Ce que le jeu suggère après une Partie. Jamais imposé : le joueur choisit son Niveau.
enum LevelSuggestion { raise, keep, lower }

class CartographerScoreResult {
  final int score;
  final bool levelCleared;
  final LevelSuggestion suggestion;
  const CartographerScoreResult({required this.score, required this.levelCleared, required this.suggestion});
}

/// Cas d'usage « calculer le score et le verdict niveau franchi » (ADR 0004). Chaque
/// question rapporte les points du Niveau fois son crédit (exact 1, proche 0,5) ; une
/// question du Bilan compte double, puisqu'elle teste la mémoire à plus long terme. Formule
/// provisoire, comme celle de L'atelier. Pas de bonus de vitesse : pas de pression de temps.
///
/// Le verdict « niveau franchi » et la suggestion se jugent sur le **Bilan seul**, pour qu'un
/// débutant qui apprend ne soit pas pénalisé par son point de départ ; sans Bilan (rien à
/// étudier : le joueur connaissait tout), sur le Repérage ; pour une Partie de Plateaux, sur tous
/// les Plateaux (il n'y a ni Repérage ni Bilan). La longueur d'une Partie varie, rien
/// ici ne suppose un nombre fixe de questions.
class ComputeCartographerScore {
  static const delayedWeight = 2.0;

  CartographerScoreResult call(
    List<QuestionOutcome> outcomes, {
    required CartographerLevel level,
    LevelThresholds thresholds = const LevelThresholds(),
  }) {
    var credit = 0.0;
    for (final outcome in outcomes) {
      final weight = outcome.phase == PuzzlePhase.delayed ? delayedWeight : 1.0;
      credit += outcome.verdict.credit * weight;
    }
    final judged = switch (outcomes.map((o) => o.phase).toSet()) {
      final phases when phases.contains(PuzzlePhase.delayed) => outcomes.where((o) => o.phase == PuzzlePhase.delayed),
      final phases when phases.contains(PuzzlePhase.tray) => outcomes.where((o) => o.phase == PuzzlePhase.tray),
      _ => outcomes.where((o) => o.phase == PuzzlePhase.screening),
    };
    final ratio = judged.isEmpty ? 0.0 : judged.map((o) => o.verdict.credit).reduce((a, b) => a + b) / judged.length;
    final cleared = ratio >= thresholds.minimumRatioToClearLevel;
    final suggestion = cleared && CartographerLevels.hasNext(level)
        ? LevelSuggestion.raise
        : ratio < thresholds.lowerBelowRatio && CartographerLevels.hasPrevious(level)
            ? LevelSuggestion.lower
            : LevelSuggestion.keep;
    return CartographerScoreResult(
      score: (credit * level.pointsPerQuestion).round(),
      levelCleared: cleared,
      suggestion: suggestion,
    );
  }
}
