import '../entities/cartographer_puzzle.dart';
import '../entities/facet.dart';
import '../entities/item.dart';
import '../entities/knowledge.dart';
import '../entities/link.dart';
import '../entities/played_puzzle.dart';
import '../entities/recall_aid.dart';
import '../entities/recall_question.dart';
import 'ports/random_source.dart';
import 'puzzle_preparer.dart';

/// Cas d'usage « préparer les Plateaux d'une Partie » (ADR 0004). Toute la Partie se prépare
/// d'un coup : `trayCount` Plateaux, rien d'adaptatif en cours de route. Un Plateau prend des
/// Éléments d'une seule Catégorie, les Catégories activées se partageant les Plateaux à tour de
/// rôle. Les Éléments les moins connus d'après la Maîtrise passent d'abord ; un Élément n'est
/// pas redemandé dans la Partie tant que sa Catégorie en a d'autres.
///
/// Pas de Repérage (ADR 0011) : la Maîtrise seule choisit. Le Profil ne règle ici que les
/// Catégories, jamais les genres de Lien : un Plateau pose toujours « nom → position ».
class PrepareTrayPuzzles implements PuzzlePreparer {
  static const trayCount = 3;
  static const linkKind = LinkKind(Facet.name, Facet.position);

  final RandomSource random;

  PrepareTrayPuzzles({required this.random});

  @override
  List<CartographerPuzzle> call(PrepareCartographerRequest request, List<PlayedPuzzle> history) {
    if (history.isNotEmpty) return [];
    final baseMap = request.baseMap;
    final categories = _shuffled([
      for (final category in baseMap.categories) if (request.profile.categories.contains(category)) category,
    ]);
    if (categories.isEmpty) {
      throw ArgumentError('Aucun Élément de ${baseMap.id} dans les Catégories du Profil.');
    }

    final used = <String>{};
    final trays = <CartographerPuzzle>[];
    for (var i = 0; i < trayCount; i++) {
      final category = categories[i % categories.length];
      final pool = baseMap.itemsOf(category);
      final size = request.level.itemCount < pool.length ? request.level.itemCount : pool.length;
      var candidates = [for (final item in pool) if (!used.contains(item.id)) item];
      if (candidates.length < size) {
        // La Catégorie est épuisée : on la rouvre en entier plutôt que de faire un Plateau plus petit.
        used.removeAll(pool.map((item) => item.id));
        candidates = pool;
      }
      final chosen = _leastKnownFirst(request, candidates).take(size).toList();
      used.addAll(chosen.map((item) => item.id));
      trays.add(
        Tray(
          language: request.language,
          studySeconds: request.level.studySeconds,
          distractionSeconds: request.level.distractionSeconds,
          questions: [
            for (final item in _shuffled(chosen))
              RecallQuestion(itemId: item.id, kind: linkKind, aid: RecallAid.free),
          ],
        ),
      );
    }
    return trays;
  }

  /// Du moins connu au mieux connu, en mélangeant dans chaque état de connaissance.
  List<Item> _leastKnownFirst(PrepareCartographerRequest request, List<Item> items) {
    int rank(Item item) => Knowledge.rank(request.mastery.of(request.baseMap.id, item.id, linkKind));
    return [
      for (var r = 0; r <= 2; r++) ..._shuffled([for (final item in items) if (rank(item) == r) item]),
    ];
  }

  /// Mélange de Fisher-Yates avec le hasard injecté.
  List<T> _shuffled<T>(Iterable<T> source) {
    final list = source.toList();
    for (var i = list.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return list;
  }
}
