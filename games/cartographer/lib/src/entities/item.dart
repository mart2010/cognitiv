import 'attributes.dart';
import 'category.dart';
import 'geo_point.dart';
import 'geometry.dart';
import 'name_language.dart';

enum CapitalRole {
  /// Capitale d'État (la Bolivie en a deux principales : La Paz et Sucre).
  primary,

  /// Capitale alternative (ex. Valparaíso pour le Chili, siège du Parlement).
  alt,
}

/// Élément géographique à apprendre : un pays, une ville, un fleuve
/// (`games/cartographer/CONTEXT.md`). Il appartient à une Catégorie, qui impose le type de sa
/// Géométrie, et porte des Attributs. Ses Relations avec les autres Éléments sont des
/// identifiants : le voisinage (symétrique) et l'inclusion (une ville dans son pays).
class Item {
  final String id;
  final Category category;
  final LocalizedText names;
  final Geometry geometry;
  final Attributes attributes;
  final Set<String> neighbors;

  /// L'Élément qui contient celui-ci (le pays d'une ville), s'il y en a un.
  final String? containedIn;

  Item({
    required this.id,
    required this.category,
    required this.names,
    required this.geometry,
    Attributes? attributes,
    this.neighbors = const {},
    this.containedIn,
  }) : attributes = attributes ?? Attributes.empty {
    if (geometry.kind != category.geometryKind) {
      throw ArgumentError(
        'Élément $id : la Catégorie ${category.id} veut une Géométrie ${category.geometryKind.name}, pas ${geometry.kind.name}.',
      );
    }
  }

  GeoPoint get anchor => geometry.anchor;

  /// Les polygones de l'Élément, vides s'il n'a pas de Géométrie en surface.
  List<Polygon> get outline => switch (geometry) {
        AreaGeometry(:final polygons) => polygons,
        _ => const [],
      };

  int? get population => attributes.integer(AttributeKey.population);

  String? get flagAsset => attributes.text(AttributeKey.flag);

  bool get isCapital => attributes.flag(AttributeKey.capital);

  CapitalRole get capitalRole => CapitalRole.values.byName(attributes.text(AttributeKey.capitalRole) ?? 'primary');
}
