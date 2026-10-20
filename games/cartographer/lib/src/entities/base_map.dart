import 'attributes.dart';
import 'category.dart';
import 'facet.dart';
import 'geo_point.dart';
import 'geometry.dart';
import 'item.dart';
import 'name_language.dart';

/// Carte de base : une Scène géographique cadrée et ses Éléments à un niveau donné
/// (`games/cartographer/CONTEXT.md`). Construite par le script de build à partir de Natural Earth.
///
/// Elle lit aussi les Facettes d'un Élément, parce que certaines passent par ses Relations : la
/// capitale d'un pays est la ville qu'il contient et dont l'Attribut `capitale` est vrai.
class BaseMap {
  final String id;
  final GeoFrame frame;
  final List<Item> items;

  BaseMap({required this.id, required this.frame, required List<Item> items}) : items = List.unmodifiable(items);

  Item itemById(String id) =>
      items.firstWhere((item) => item.id == id, orElse: () => throw ArgumentError('Élément inconnu : $id'));

  /// Les Catégories présentes dans cette Carte, dans l'ordre des Catégories connues.
  List<Category> get categories => [
        for (final category in Category.known)
          if (items.any((item) => item.category == category)) category,
      ];

  List<Item> itemsOf(Category category) => [for (final item in items) if (item.category == category) item];

  /// Les capitales d'un pays : les villes qu'il contient dont l'Attribut `capitale` est vrai,
  /// classées par nom anglais pour un ordre stable.
  List<Item> capitalsOf(Item country) => [
        for (final item in items)
          if (item.containedIn == country.id && item.isCapital) item,
      ]..sort((a, b) => a.names.en.compareTo(b.names.en));

  List<Item> primaryCapitalsOf(Item country) =>
      [for (final capital in capitalsOf(country)) if (capital.capitalRole == CapitalRole.primary) capital];

  bool hasFacet(Item item, Facet facet) => switch (facet) {
        Facet.name || Facet.position => true,
        Facet.capital => capitalsOf(item).isNotEmpty,
        Facet.shape => item.geometry is AreaGeometry && item.outline.isNotEmpty,
        Facet.flag => item.attributes.has(AttributeKey.flag),
      };

  /// Le texte affiché pour une Facette textuelle (la première capitale principale s'il y
  /// en a plusieurs).
  String textFor(Item item, Facet facet, NameLanguage language) => switch (facet) {
        Facet.name => item.names.of(language),
        Facet.capital => _capitalFor(item).names.of(language),
        _ => throw ArgumentError('${facet.name} n\'est pas une Facette textuelle.'),
      };

  /// Tous les textes acceptés comme réponse pour une Facette textuelle, dans les deux
  /// langues, toutes capitales (principales et alternatives) confondues.
  Set<String> acceptedTexts(Item item, Facet facet) => switch (facet) {
        Facet.name => item.names.all,
        Facet.capital => {for (final capital in capitalsOf(item)) ...capital.names.all},
        _ => throw ArgumentError('${facet.name} n\'est pas une Facette textuelle.'),
      };

  Item _capitalFor(Item country) {
    final primary = primaryCapitalsOf(country);
    return (primary.isNotEmpty ? primary : capitalsOf(country)).first;
  }
}
