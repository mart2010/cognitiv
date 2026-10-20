import '../domain_services/item_picker.dart';
import '../entities/cartographer_answer.dart';
import '../entities/cartographer_puzzle.dart';
import '../entities/played_puzzle.dart';
import 'ports/random_source.dart';
import 'puzzle_preparer.dart';

/// Cas d'usage « préparer les manches d'une Séquence » (ADR 0004, 0010), comme au Simon. La
/// première manche montre `startLength` Élément ; chaque manche réussie reprend la même séquence et
/// y ajoute un Élément tiré au hasard dans le jeu, le même pouvant revenir. Une erreur termine la
/// Partie : sans elle, la séquence s'allonge sans fin.
///
/// Le jeu est de `poolSize` Éléments d'une seule Catégorie, les moins connus d'abord (Maîtrise,
/// ADR 0011). Sa taille ne change pas avec le Niveau : la difficulté vient de la vitesse du
/// visionnage (`CartographerLevel.sequenceStepMillis`).
class PrepareSequencePuzzles implements PuzzlePreparer {
  static const startLength = 1;
  static const poolSize = 6;

  final RandomSource random;
  final ItemPicker picker;

  PrepareSequencePuzzles({required this.random}) : picker = ItemPicker(random);

  @override
  List<CartographerPuzzle> call(PrepareCartographerRequest request, List<PlayedPuzzle> history) {
    if (history.isEmpty) return [_first(request)];
    final puzzle = history.last.puzzle;
    if (puzzle is! Sequence) {
      throw ArgumentError('L\'historique d\'une Séquence ne contient que des Séquences.');
    }
    if (!history.last.verdicts.every((v) => v == AnswerVerdict.exact)) return [];
    return [
      Sequence(
        language: puzzle.language,
        pool: puzzle.pool,
        steps: [...puzzle.steps, puzzle.pool[random.nextInt(puzzle.pool.length)]],
        stepMillis: puzzle.stepMillis,
      ),
    ];
  }

  Sequence _first(PrepareCartographerRequest request) {
    final baseMap = request.baseMap;
    final categories = picker.shuffled([
      for (final category in baseMap.categories) if (request.profile.categories.contains(category)) category,
    ]);
    if (categories.isEmpty) {
      throw ArgumentError('Aucun Élément de ${baseMap.id} dans les Catégories du Profil.');
    }
    final candidates = baseMap.itemsOf(categories.first);
    final chosen = picker.leastKnownFirst(request, Sequence.linkKind, candidates).take(poolSize);
    final pool = picker.shuffled(chosen).map((item) => item.id).toList();
    return Sequence(
      language: request.language,
      pool: pool,
      steps: [for (var i = 0; i < startLength; i++) pool[random.nextInt(pool.length)]],
      stepMillis: request.level.sequenceStepMillis,
    );
  }
}
