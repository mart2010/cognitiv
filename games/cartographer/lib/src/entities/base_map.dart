import 'geo_point.dart';
import 'item.dart';

/// Carte de base : une Scène géographique cadrée et ses Éléments à un niveau donné
/// (`games/recall/CONTEXT.md`). Construite par le script de build à partir de Natural Earth.
class BaseMap {
  final String id;
  final GeoFrame frame;
  final List<Item> items;

  BaseMap({required this.id, required this.frame, required List<Item> items}) : items = List.unmodifiable(items);

  Item itemById(String id) =>
      items.firstWhere((item) => item.id == id, orElse: () => throw ArgumentError('Élément inconnu : $id'));
}
