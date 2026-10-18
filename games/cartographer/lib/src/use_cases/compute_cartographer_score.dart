import '../entities/cartographer_answer.dart';
import '../entities/cartographer_level.dart';

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

/// Le résultat d'une question, pour le calcul du Score. `delayed` : question du Bilan.
class QuestionOutcome {
  final AnswerVerdict verdict;
  final bool delayed;
  const QuestionOutcome(this.verdict, {required this.delayed});
}

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
class ComputeCartographerScore {
  static const delayedWeight = 2.0;

  CartographerScoreResult call(
    List<QuestionOutcome> outcomes, {
    required CartographerLevel level,
    LevelThresholds thresholds = const LevelThresholds(),
  }) {
    var credit = 0.0;
    var maxCredit = 0.0;
    for (final outcome in outcomes) {
      final weight = outcome.delayed ? delayedWeight : 1.0;
      credit += outcome.verdict.credit * weight;
      maxCredit += weight;
    }
    final ratio = maxCredit == 0 ? 0.0 : credit / maxCredit;
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
