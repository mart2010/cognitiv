import '../entities/item.dart';
import '../entities/knowledge.dart';
import '../entities/link.dart';
import '../use_cases/puzzle_preparer.dart';
import '../use_cases/ports/random_source.dart';

/// Le choix des Éléments d'une Énigme par la Maîtrise (ADR 0009, 0011), commun aux Épreuves qui
/// posent « nom → position » : du moins connu au mieux connu, en mélangeant dans chaque état.
class ItemPicker {
  final RandomSource random;
  const ItemPicker(this.random);

  List<Item> leastKnownFirst(PrepareCartographerRequest request, LinkKind kind, List<Item> items) {
    int rank(Item item) => Knowledge.rank(request.mastery.of(request.baseMap.id, item.id, kind));
    return [
      for (var r = 0; r <= 2; r++) ...shuffled([for (final item in items) if (rank(item) == r) item]),
    ];
  }

  /// Mélange de Fisher-Yates avec le hasard injecté.
  List<T> shuffled<T>(Iterable<T> source) {
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
