import '../domain_services/decoy_placer.dart';
import '../domain_services/item_picker.dart';
import '../entities/cartographer_puzzle.dart';
import '../entities/facet.dart';
import '../entities/geometry.dart';
import '../entities/link.dart';
import '../entities/played_puzzle.dart';
import '../entities/recall_aid.dart';
import '../entities/recall_question.dart';
import '../entities/trial.dart';
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

  /// Temps montré à chaque Élément en présentation successive.
  static const secondsPerItem = 2;

  final RandomSource random;
  final ItemPicker picker;
  final TrayPresentation presentation;

  PrepareTrayPuzzles({required this.random, this.presentation = TrayPresentation.together}) : picker = ItemPicker(random);

  @override
  List<CartographerPuzzle> call(PrepareCartographerRequest request, List<PlayedPuzzle> history) {
    if (history.isNotEmpty) return [];
    final baseMap = request.baseMap;
    final categories = picker.shuffled([
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
      final chosen = picker.leastKnownFirst(request, linkKind, candidates).take(size).toList();
      used.addAll(chosen.map((item) => item.id));
      trays.add(
        Tray(
          language: request.language,
          presentation: presentation,
          studySeconds: presentation == TrayPresentation.oneByOne ? chosen.length * secondsPerItem : request.level.studySeconds,
          distractionSeconds: request.level.distractionSeconds,
          questions: [
            for (final item in picker.shuffled(chosen))
              RecallQuestion(itemId: item.id, kind: linkKind, aid: RecallAid.free),
          ],
          // Des points candidats seulement quand les Éléments sont des Points (villes).
          decoys: chosen.every((item) => item.geometry is PointGeometry)
              ? DecoyPlacer(random).place(baseMap, chosen, request.level.decoysFor(chosen.length))
              : const [],
        ),
      );
    }
    return trays;
  }
}
