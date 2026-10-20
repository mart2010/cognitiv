/// Cadre géographique d'une Carte de base, en degrés.
class Frame {
  final double west;
  final double south;
  final double east;
  final double north;

  const Frame({required this.west, required this.south, required this.east, required this.north});

  bool contains(double lon, double lat) => lon >= west && lon <= east && lat >= south && lat <= north;
}

/// Description d'une Carte de base à extraire de Natural Earth (`games/cartographer/CONTEXT.md`).
class BaseMapSpec {
  final String id;

  /// Codes `GU_A3` des unités cartographiques retenues (fichier `admin_0_map_units`).
  /// On part des unités plutôt que des pays pour pouvoir séparer un territoire d'outre-mer
  /// (la Guyane est une unité de la France, pas un pays du fichier `admin_0_countries`).
  final List<String> unitCodes;

  final Frame frame;

  /// Aire minimale (degrés carrés) d'un contour conservé : écarte les îlots.
  final double minPolygonArea;

  /// Tolérance de simplification des contours, en degrés.
  final double simplifyTolerance;

  /// Nom (`NAME`) de la ville capitale pour les unités sans capitale d'État (territoires),
  /// clé = code `GU_A3` de l'unité.
  final Map<String, String> capitalOverrides;

  /// Nombre de villes de la Carte, capitales comprises (toujours retenues) ; le reste va aux
  /// plus peuplées, ce qui sert de critère de notoriété.
  final int maxCities;

  /// Plafond de villes par État, capitales comprises : sans lui, le plus peuplé (le Brésil)
  /// prend la moitié de la Carte.
  final int maxCitiesPerState;

  /// Corrections des noms français de Natural Earth (accents manquants), clé = valeur brute.
  final Map<String, String> frenchNameFixes;

  const BaseMapSpec({
    required this.id,
    required this.unitCodes,
    required this.frame,
    this.minPolygonArea = 0.02,
    this.simplifyTolerance = 0.05,
    this.maxCities = 30,
    this.maxCitiesPerState = 4,
    this.capitalOverrides = const {},
    this.frenchNameFixes = const {},
  });
}

/// Première Carte de base : l'Amérique du Sud. Choix de première tranche, documentés dans
/// `docs/PLAN.md` : les 12 États souverains, plus la Guyane (territoire de la France).
/// Exclues : les îles Malouines (statut disputé, règle à trancher), l'Ilha Brasileira et le
/// champ de glace de Patagonie (statut indéterminé).
const southAmerica = BaseMapSpec(
  id: 'south_america',
  unitCodes: [
    'ARG', 'BOL', 'BRA', 'CHL', 'COL', 'ECU', 'GUY', 'PRY', 'PER', 'SUR', 'URY', 'VEN',
    'GUF',
  ],
  // Cadre sans les îles du Pacifique lointain (Pâques, Galápagos, Juan Fernández).
  frame: Frame(west: -82, south: -57, east: -32, north: 13),
  capitalOverrides: {'GUF': 'Cayenne'},
  frenchNameFixes: {'Asuncion': 'Asunción'},
);

const baseMapSpecs = {'south_america': southAmerica};
