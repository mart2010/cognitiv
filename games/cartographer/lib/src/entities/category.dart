import 'geometry.dart';
import 'name_language.dart';

/// Le genre d'un Élément (pays, villes, fleuves…) (`games/cartographer/CONTEXT.md`). Impose le
/// type de Géométrie de ses Éléments. Le joueur active des Catégories : elles décident des
/// Éléments sur lesquels il s'exerce.
class Category {
  final String id;
  final LocalizedText names;
  final GeometryKind geometryKind;

  const Category({required this.id, required this.names, required this.geometryKind});

  static const countries = Category(
    id: 'countries',
    names: LocalizedText(en: 'Countries', fr: 'Pays'),
    geometryKind: GeometryKind.area,
  );

  static const cities = Category(
    id: 'cities',
    names: LocalizedText(en: 'Cities', fr: 'Villes'),
    geometryKind: GeometryKind.point,
  );

  /// Les Catégories que les données sauront porter ; s'allonge avec les Packs de contenu.
  static const known = [countries, cities];

  static Category byId(String id) => known.firstWhere(
        (category) => category.id == id,
        orElse: () => throw FormatException('Catégorie inconnue : $id'),
      );

  @override
  bool operator ==(Object other) => other is Category && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Category($id)';
}
