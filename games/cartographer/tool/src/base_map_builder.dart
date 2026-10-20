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
    final population = (props['POP_EST'] as num?)?.round();
    items.add({
      'id': code,
      'category': 'countries',
      'names': _names(props, spec),
      'geometry': {
        'type': 'area',
        'anchor': _round3(props['LABEL_X'] as num, props['LABEL_Y'] as num),
        'polygons': _outline(fullResolution[code]!, spec),
      },
      'attributes': {
        if (population != null) 'population': population,
        'territory': !isCountry,
        // État auquel l'unité appartient (`ADM0_A3`, code ISO ; `SOV_A3` est un code interne
        // de Natural Earth, p. ex. FR1 pour la France).
        'state': props['ADM0_A3'],
      },
      'neighbors': neighbors[code]!.toList()..sort(),
      'containedIn': null,
    });
  }
  items.addAll(_cities(spec, unitFeatures, fullResolution, placeFeatures));

  return {
    'schemaVersion': 2,
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

/// Les villes de la Carte : toutes les capitales des unités (obligatoires), puis les plus
/// peuplées jusqu'à `spec.maxCities`. La population sert de critère de notoriété (Attribut
/// `rank`, 1 = la plus peuplée). Une capitale appartient à l'unité dont elle est la capitale ;
/// une autre ville, à l'unité du même État qui la contient (la plus proche à défaut).
List<Map<String, Object?>> _cities(
  BaseMapSpec spec,
  Map<String, Map<String, Object?>> unitFeatures,
  Map<String, List<Polygon>> fullResolution,
  List<Map<String, Object?>> places,
) {
  final capitalOf = <Map<String, Object?>, ({String unit, String role})>{};
  for (final code in spec.unitCodes) {
    final found = _capitalPlaces(spec, code, _props(unitFeatures[code]!), places);
    if (found.isEmpty) throw StateError('Aucune capitale trouvée pour $code');
    for (final entry in found.entries) {
      if (capitalOf.containsKey(entry.key)) throw StateError('${_props(entry.key)['NAME']} est capitale de deux unités.');
      capitalOf[entry.key] = (unit: code, role: entry.value);
    }
  }

  final states = {for (final code in spec.unitCodes) code: _props(unitFeatures[code]!)['ADM0_A3']};
  final others = [
    for (final place in places)
      if (!capitalOf.containsKey(place) &&
          states.containsValue(_props(place)['ADM0_A3']) &&
          spec.frame.contains((_props(place)['LONGITUDE'] as num).toDouble(), (_props(place)['LATITUDE'] as num).toDouble()))
        place,
  ]..sort((a, b) => ((_props(b)['POP_MAX'] as num?) ?? 0).compareTo((_props(a)['POP_MAX'] as num?) ?? 0));
  final perState = <Object?, int>{};
  for (final place in capitalOf.keys) {
    perState.update(_props(place)['ADM0_A3'], (n) => n + 1, ifAbsent: () => 1);
  }
  final extra = <Map<String, Object?>>[];
  for (final place in others) {
    if (capitalOf.length + extra.length >= spec.maxCities) break;
    final state = _props(place)['ADM0_A3'];
    if ((perState[state] ?? 0) >= spec.maxCitiesPerState) continue;
    perState.update(state, (n) => n + 1, ifAbsent: () => 1);
    extra.add(place);
  }

  final chosen = <Map<String, Object?>, ({String unit, String? role})>{
    for (final entry in capitalOf.entries) entry.key: (unit: entry.value.unit, role: entry.value.role),
    for (final place in extra) place: (unit: _unitOf(spec, place, states, fullResolution), role: null),
  };

  int population(Map<String, Object?> place) => ((_props(place)['POP_MAX'] as num?) ?? 0).round();
  final byPopulation = chosen.keys.toList()
    ..sort((a, b) {
      final byPop = population(b).compareTo(population(a));
      return byPop != 0 ? byPop : (_props(a)['NAME'] as String).compareTo(_props(b)['NAME'] as String);
    });

  final result = <Map<String, Object?>>[];
  final ids = <String>{};
  for (var rank = 1; rank <= byPopulation.length; rank++) {
    final place = byPopulation[rank - 1];
    final props = _props(place);
    final info = chosen[place]!;
    final id = 'city:${_slug((props['NAMEASCII'] ?? props['NAME']) as String)}';
    if (!ids.add(id)) throw StateError('Deux villes ont le même identifiant : $id');
    final fr = props['NAME_FR'] as String;
    final pop = (props['POP_MAX'] as num?)?.round();
    result.add({
      'id': id,
      'category': 'cities',
      'names': {'en': props['NAME_EN'], 'fr': spec.frenchNameFixes[fr] ?? fr},
      'geometry': {
        'type': 'point',
        'position': _round3(props['LONGITUDE'] as num, props['LATITUDE'] as num),
      },
      'attributes': {
        if (pop != null) 'population': pop,
        'rank': rank,
        if (info.role != null) ...{'capital': true, 'capitalRole': info.role},
      },
      'neighbors': <String>[],
      'containedIn': info.unit,
    });
  }
  result.sort((a, b) => (a['id']! as String).compareTo(b['id']! as String));
  return result;
}

/// Les lieux qui sont capitales d'une unité, avec leur rôle (`primary` ou `alt`).
Map<Map<String, Object?>, String> _capitalPlaces(
  BaseMapSpec spec,
  String code,
  Map<String, Object?> unitProps,
  List<Map<String, Object?>> places,
) {
  final override = spec.capitalOverrides[code];
  final found = <Map<String, Object?>, String>{};
  for (final place in places) {
    final p = _props(place);
    if (p['ADM0_A3'] != unitProps['ADM0_A3']) continue;
    if (override != null) {
      if (p['NAME'] == override) found[place] = 'primary';
    } else if (p['ADM0CAP'] == 1) {
      found[place] = 'primary';
    } else if (p['FEATURECLA'] == 'Admin-0 capital alt') {
      found[place] = 'alt';
    }
  }
  return found;
}

/// L'unité d'une ville qui n'est pas une capitale : celle de son État si elle est seule, sinon
/// celle dont le contour la contient (à défaut, la plus proche).
String _unitOf(
  BaseMapSpec spec,
  Map<String, Object?> place,
  Map<String, Object?> states,
  Map<String, List<Polygon>> fullResolution,
) {
  final props = _props(place);
  final candidates = [for (final code in spec.unitCodes) if (states[code] == props['ADM0_A3']) code]..sort();
  if (candidates.length == 1) return candidates.single;
  final point = (lon: (props['LONGITUDE'] as num).toDouble(), lat: (props['LATITUDE'] as num).toDouble());
  for (final code in candidates) {
    if (fullResolution[code]!.any((polygon) => pointInPolygon(point, polygon))) return code;
  }
  double distance(String code) => fullResolution[code]!
      .expand((polygon) => polygon)
      .map((ring) => distanceToRing(point, ring))
      .reduce((a, b) => a < b ? a : b);
  return candidates.reduce((a, b) => distance(a) <= distance(b) ? a : b);
}

String _slug(String name) => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');

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
