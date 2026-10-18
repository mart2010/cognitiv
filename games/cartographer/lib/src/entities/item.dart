import 'facet.dart';
import 'geo_point.dart';
import 'name_language.dart';

enum ItemKind { country, territory }

enum CapitalRole {
  /// Capitale d'État (une Bolivie a deux capitales principales : La Paz et Sucre).
  primary,

  /// Capitale alternative (ex. Valparaíso pour le Chili, siège du Parlement).
  alt,
}

class Capital {
  final LocalizedText names;
  final GeoPoint position;
  final CapitalRole role;
  final int? population;
  const Capital({required this.names, required this.position, required this.role, this.population});
}

/// Élément géographique à apprendre : un pays ou un territoire (`games/recall/CONTEXT.md`).
class Item {
  final String id;
  final ItemKind kind;

  /// Code de l'État auquel il appartient (le sien pour un pays, FRA pour la Guyane).
  final String belongsTo;
  final LocalizedText names;
  final List<Capital> capitals;

  /// Point d'ancrage de l'étiquette sur la Scène.
  final GeoPoint anchor;
  final List<Polygon> outline;
  final Set<String> neighbors;
  final int? population;

  /// Clé de l'image du drapeau, absente tant que les drapeaux ne sont pas dans les données.
  final String? flagAsset;

  const Item({
    required this.id,
    required this.kind,
    required this.belongsTo,
    required this.names,
    required this.capitals,
    required this.anchor,
    required this.outline,
    this.neighbors = const {},
    this.population,
    this.flagAsset,
  });

  bool hasFacet(Facet facet) => switch (facet) {
        Facet.name => true,
        Facet.capital => capitals.isNotEmpty,
        Facet.position || Facet.shape => outline.isNotEmpty,
        Facet.flag => flagAsset != null,
      };

  List<Capital> get primaryCapitals => capitals.where((c) => c.role == CapitalRole.primary).toList();

  /// Le texte affiché pour une Facette textuelle (la première capitale principale s'il y
  /// en a plusieurs).
  String textFor(Facet facet, NameLanguage language) => switch (facet) {
        Facet.name => names.of(language),
        Facet.capital => (primaryCapitals.isNotEmpty ? primaryCapitals : capitals).first.names.of(language),
        _ => throw ArgumentError('${facet.name} n\'est pas une Facette textuelle.'),
      };

  /// Tous les textes acceptés comme réponse pour une Facette textuelle, dans les deux
  /// langues, toutes capitales (principales et alternatives) confondues.
  Set<String> acceptedTexts(Facet facet) => switch (facet) {
        Facet.name => names.all,
        Facet.capital => {for (final capital in capitals) ...capital.names.all},
        _ => throw ArgumentError('${facet.name} n\'est pas une Facette textuelle.'),
      };
}
