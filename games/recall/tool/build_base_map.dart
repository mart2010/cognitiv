// Script de build (Frameworks & Drivers) : lit les GeoJSON Natural Earth 1:10m (domaine
// public) et écrit le JSON d'une Carte de base. Les calculs spatiaux (voisinage, simplification
// des contours) se font ici, hors ligne ; l'app n'embarque que le résultat.
//
// Usage :
//   dart run tool/build_base_map.dart --base-map south_america \
//     --map-units ne_10m_admin_0_map_units.geojson \
//     --places ne_10m_populated_places.geojson \
//     --out data/south_america.json
import 'dart:convert';
import 'dart:io';

import 'src/base_map_builder.dart';
import 'src/base_map_spec.dart';

void main(List<String> args) {
  final options = _parse(args);
  final spec = baseMapSpecs[options['base-map']];
  if (spec == null) {
    stderr.writeln('Carte de base inconnue : ${options['base-map']} (connues : ${baseMapSpecs.keys.join(', ')})');
    exit(64);
  }
  final result = buildBaseMap(
    spec: spec,
    mapUnits: _readJson(options['map-units']),
    places: _readJson(options['places']),
  );
  final out = File(options['out']!)..createSync(recursive: true);
  out.writeAsStringSync('${jsonEncode(result)}\n');
  final items = result['items']! as List;
  print('${items.length} Éléments écrits dans ${out.path} (${out.lengthSync()} octets).');
}

Map<String, String> _parse(List<String> args) {
  final options = <String, String>{};
  for (var i = 0; i + 1 < args.length; i += 2) {
    options[args[i].replaceFirst('--', '')] = args[i + 1];
  }
  for (final key in ['base-map', 'map-units', 'places', 'out']) {
    if (!options.containsKey(key)) {
      stderr.writeln('Option manquante : --$key');
      exit(64);
    }
  }
  return options;
}

Map<String, Object?> _readJson(String? path) =>
    (jsonDecode(File(path!).readAsStringSync()) as Map).cast<String, Object?>();
