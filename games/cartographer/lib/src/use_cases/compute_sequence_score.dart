import '../entities/cartographer_answer.dart';
import '../entities/cartographer_level.dart';
import '../entities/cartographer_puzzle.dart';
import '../entities/played_puzzle.dart';
import 'compute_cartographer_score.dart';

/// Cas d'usage « calculer le score et le verdict niveau franchi » d'une Partie de Séquences
/// (ADR 0004). Le Score est la longueur de la plus longue séquence reproduite sans faute, fois les
/// points du Niveau : les manches se recouvrent (chacune rejoue le début de la précédente), compter
/// chaque Élément touché compterait plusieurs fois les mêmes. Le Niveau est franchi à `targetLength`
/// Éléments, le même à tous les Niveaux puisque seule la vitesse change ; on suggère de descendre
/// sous la moitié. Formule et seuils provisoires, comme ceux des autres Épreuves.
class ComputeSequenceScore {
  static const targetLength = 8;

  CartographerScoreResult call(
    List<PlayedPuzzle> history, {
    required CartographerLevel level,
    LevelThresholds thresholds = const LevelThresholds(),
  }) {
    var longest = 0;
    for (final played in history) {
      final puzzle = played.puzzle;
      if (puzzle is Sequence && played.verdicts.every((v) => v == AnswerVerdict.exact) && puzzle.length > longest) {
        longest = puzzle.length;
      }
    }
    final cleared = longest >= targetLength;
    final suggestion = cleared && CartographerLevels.hasNext(level)
        ? LevelSuggestion.raise
        : longest < targetLength * thresholds.lowerBelowRatio && CartographerLevels.hasPrevious(level)
            ? LevelSuggestion.lower
            : LevelSuggestion.keep;
    return CartographerScoreResult(score: longest * level.pointsPerQuestion, levelCleared: cleared, suggestion: suggestion);
  }
}
