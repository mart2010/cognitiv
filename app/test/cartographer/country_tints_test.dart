import 'dart:convert';
import 'dart:io';

import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:cognitiv_app/cartographer/country_tints.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

cartographer.BaseMap _load() => cartographer.BaseMapCodec.fromJson(
  jsonDecode(File('assets/maps/south_america.json').readAsStringSync()) as Map<String, dynamic>,
);

cartographer.Item _item(String id, Set<String> neighbors) => cartographer.Item(
  id: id,
  category: cartographer.Category.countries,
  names: cartographer.LocalizedText(en: id, fr: id),
  geometry: cartographer.AreaGeometry(polygons: const [], labelAnchor: const cartographer.GeoPoint(0, 0)),
  neighbors: neighbors,
);

void main() {
  test('deux voisins ne partagent jamais la même teinte sur la vraie carte', () {
    final map = _load();
    final tints = tintIndices(map);
    expect(tints.keys.toSet(), map.items.map((i) => i.id).toSet());
    for (final item in map.items) {
      for (final other in item.neighbors) {
        expect(tints[item.id], isNot(tints[other]), reason: '${item.id} / $other');
      }
    }
  });

  test('la répartition est déterministe', () {
    expect(tintIndices(_load()), tintIndices(_load()));
  });

  test('le Brésil, le plus connecté, prend la première teinte', () {
    expect(tintIndices(_load())['BRA'], 0);
  });

  test("trop peu de teintes pour les voisins : erreur claire, pas deux voisins identiques", () {
    final triangle = cartographer.BaseMap(
      id: 't',
      frame: const cartographer.GeoFrame(west: 0, south: 0, east: 1, north: 1),
      items: [_item('A', {'B', 'C'}), _item('B', {'A', 'C'}), _item('C', {'A', 'B'})],
    );
    expect(tintIndices(triangle, tintCount: 3), hasLength(3));
    expect(() => tintIndices(triangle, tintCount: 2), throwsStateError);
  });

  test('les teintes sont toutes différentes mais gardent la luminosité du neutre', () {
    for (final neutral in const [Color(0xFFE3E3E8), Color(0xFF34363C)]) {
      final tints = softTints(neutral);
      expect(tints.toSet(), hasLength(5));
      final baseLightness = HSLColor.fromColor(neutral).lightness;
      for (final tint in tints) {
        expect(HSLColor.fromColor(tint).lightness, closeTo(baseLightness, 0.02));
      }
    }
  });
}
