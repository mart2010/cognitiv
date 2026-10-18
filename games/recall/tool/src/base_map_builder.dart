import 'base_map_spec.dart';
import 'geometry.dart';

/// Construit le JSON d'une Carte de base à partir des données Natural Earth (GeoJSON) :
/// Éléments, capitales, contours simplifiés et voisinage. Fonction pure, sans fichier ni
/// horloge : le script `tool/build_base_map.dart` lit et écrit les fichiers.
Map<String, Object?> buildBaseMap({
  required BaseMapSpec spec,
  required Map<String, Object?> mapUnits,
  required Map<String, Object?> places,
}) {
  final unitFeatures = <String, Map<String, Object?>>{};
  for (final feature in _features(mapUnits)) {
    final code = _props(feature)['GU_A3'] as String?;
    if (code != null && spec.unitCodes.contains(code)) unitFeatures[code] = feature;
  }
  final missing = spec.unitCodes.where((c) => !unitFeatures.containsKey(c)).toList();
  if (missing.isNotEmpty) throw StateError('Unités absentes des données : $missing');

  final fullResolution = {
    for (final entry in unitFeatures.entries) entry.key: _polygons(entry.value),
  };
  final neighbors = _neighbors(fullResolution);
  final placeFeatures = _features(places);

  final items = <Map<String, Object?>>[];
  for (final code in spec.unitCodes.toList()..sort()) {
    final props = _props(unitFeatures[code]!);
    final isCountry = props['TYPE'] == 'Sovereign country';
    items.add({
      'id': code,
      'kind': isCountry ? 'country' : 'territory',
      // État auquel l'unité appartient (`ADM0_A3`, code ISO ; `SOV_A3` est un code interne
      // de Natural Earth, p. ex. FR1 pour la France).
      'belongsTo': props['ADM0_A3'],
      'names': _names(props, spec),
      'population': (props['POP_EST'] as num?)?.round(),
      'anchor': _round3(props['LABEL_X'] as num, props['LABEL_Y'] as num),
      'capitals': _capitals(spec, code, props, placeFeatures),
      'neighbors': neighbors[code]!.toList()..sort(),
      'outline': _outline(fullResolution[code]!, spec),
    });
  }

  return {
    'schemaVersion': 1,
    'source': 'Natural Earth 1:10m (domaine public)',
    'baseMap': {
      'id': spec.id,
      'frame': [spec.frame.west, spec.frame.south, spec.frame.east, spec.frame.north],
    },
    'items': items,
  };
}

List<Map<String, Object?>> _features(Map<String, Object?> collection) =>
    (collection['features']! as List).cast<Map<String, Object?>>();

Map<String, Object?> _props(Map<String, Object?> feature) =>
    (feature['properties']! as Map).cast<String, Object?>();

/// Un polygone = liste d'anneaux (extérieur, puis trous).
typedef Polygon = List<List<Point>>;

List<Polygon> _polygons(Map<String, Object?> feature) {
  final geometry = (feature['geometry']! as Map).cast<String, Object?>();
  final coordinates = geometry['coordinates']! as List;
  final raw = switch (geometry['type']) {
    'Polygon' => [coordinates],
    'MultiPolygon' => coordinates,
    final other => throw StateError('Géométrie non gérée : $other'),
  };
  return [
    for (final polygon in raw)
      [
        for (final ring in polygon as List)
          [for (final p in ring as List) (lon: (p[0] as num).toDouble(), lat: (p[1] as num).toDouble())],
      ],
  ];
}

/// Deux unités sont voisines si leurs contours partagent au moins deux sommets : les
/// frontières de Natural Earth sont topologiquement cohérentes (mêmes coordonnées de
/// part et d'autre), ce que les tests vérifient sur des cas connus. Calculé sur les
/// contours complets, avant simplification.
Map<String, Set<String>> _neighbors(Map<String, List<Polygon>> unitsPolygons) {
  final vertices = {
    for (final entry in unitsPolygons.entries)
      entry.key: {
        for (final polygon in entry.value)
          for (final ring in polygon)
            for (final p in ring) '${p.lon},${p.lat}',
      },
  };
  final result = {for (final code in unitsPolygons.keys) code: <String>{}};
  final codes = unitsPolygons.keys.toList();
  for (var i = 0; i < codes.length; i++) {
    for (var j = i + 1; j < codes.length; j++) {
      final shared = vertices[codes[i]]!.intersection(vertices[codes[j]]!).length;
      if (shared >= 2) {
        result[codes[i]]!.add(codes[j]);
        result[codes[j]]!.add(codes[i]);
      }
    }
  }
  return result;
}

Map<String, String> _names(Map<String, Object?> props, BaseMapSpec spec) {
  final fr = props['NAME_FR'] as String;
  return {'en': props['NAME_EN'] as String, 'fr': spec.frenchNameFixes[fr] ?? fr};
}

List<Map<String, Object?>> _capitals(
  BaseMapSpec spec,
  String code,
  Map<String, Object?> unitProps,
  List<Map<String, Object?>> places,
) {
  final override = spec.capitalOverrides[code];
  final found = <Map<String, Object?>>[];
  for (final place in places) {
    final p = _props(place);
    if (p['ADM0_A3'] != unitProps['ADM0_A3']) continue;
    final String? role;
    if (override != null) {
      role = p['NAME'] == override ? 'primary' : null;
    } else if (p['ADM0CAP'] == 1) {
      role = 'primary';
    } else if (p['FEATURECLA'] == 'Admin-0 capital alt') {
      role = 'alt';
    } else {
      role = null;
    }
    if (role == null) continue;
    final fr = p['NAME_FR'] as String;
    found.add({
      'role': role,
      'names': {'en': p['NAME_EN'], 'fr': spec.frenchNameFixes[fr] ?? fr},
      'position': _round3(p['LONGITUDE'] as num, p['LATITUDE'] as num),
      'population': (p['POP_MAX'] as num?)?.round(),
    });
  }
  if (found.isEmpty) throw StateError('Aucune capitale trouvée pour $code');
  found.sort((a, b) => ((a['names']! as Map)['en'] as String).compareTo(((b['names']! as Map)['en']) as String));
  return found;
}

List<double> _round3(num lon, num lat) => [_r3(lon), _r3(lat)];

double _r3(num v) => (v * 1000).round() / 1000;

/// Contours simplifiés : garde les polygones dont le centre est dans le cadre et dont l'aire
/// dépasse le seuil, simplifie chaque anneau, écarte les trous dégénérés.
List<List<List<List<double>>>> _outline(List<Polygon> polygons, BaseMapSpec spec) {
  final result = <List<List<List<double>>>>[];
  for (final polygon in polygons) {
    final outer = polygon.first;
    final lons = outer.map((p) => p.lon);
    final lats = outer.map((p) => p.lat);
    final centerLon = (lons.reduce((a, b) => a < b ? a : b) + lons.reduce((a, b) => a > b ? a : b)) / 2;
    final centerLat = (lats.reduce((a, b) => a < b ? a : b) + lats.reduce((a, b) => a > b ? a : b)) / 2;
    if (!spec.frame.contains(centerLon, centerLat)) continue;
    if (ringArea(outer) < spec.minPolygonArea) continue;
    final simplifiedOuter = simplifyRing(outer, spec.simplifyTolerance);
    if (simplifiedOuter == null) continue;
    final holes = [
      for (final hole in polygon.skip(1)) simplifyRing(hole, spec.simplifyTolerance),
    ];
    result.add([
      for (final ring in [simplifiedOuter, ...holes])
        if (ring != null) [for (final p in ring) _round3(p.lon, p.lat)],
    ]);
  }
  return result;
}
