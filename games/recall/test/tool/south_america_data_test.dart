import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

// Vérifie le fichier généré `data/south_america.json` sur des faits géographiques connus.
// Regénérer avec `tool/build_base_map.dart` si ce test échoue après un changement de la spec.
void main() {
  final data = jsonDecode(File('data/south_america.json').readAsStringSync()) as Map<String, dynamic>;
  final items = {
    for (final i in (data['items'] as List).cast<Map<String, dynamic>>()) i['id'] as String: i,
  };

  Set<String> neighborsOf(String id) => (items[id]!['neighbors'] as List).cast<String>().toSet();

  test('contient les 12 États souverains et la Guyane', () {
    expect(items.keys, unorderedEquals(['ARG', 'BOL', 'BRA', 'CHL', 'COL', 'ECU', 'GUY', 'PRY', 'PER', 'SUR', 'URY', 'VEN', 'GUF']));
    expect(items['GUF']!['kind'], 'territory');
    expect(items['GUF']!['belongsTo'], 'FRA');
  });

  test('le voisinage est symétrique', () {
    for (final id in items.keys) {
      for (final other in neighborsOf(id)) {
        expect(neighborsOf(other), contains(id), reason: '$id -> $other');
      }
    }
  });

  test('voisinages connus', () {
    expect(neighborsOf('CHL'), {'ARG', 'BOL', 'PER'});
    expect(neighborsOf('ECU'), {'COL', 'PER'});
    expect(neighborsOf('URY'), {'ARG', 'BRA'});
    expect(neighborsOf('BRA'), {'ARG', 'BOL', 'COL', 'GUF', 'GUY', 'PER', 'PRY', 'SUR', 'URY', 'VEN'});
    // Le Brésil touche la France par la Guyane, sans océan entre les deux.
    expect(neighborsOf('GUF'), {'BRA', 'SUR'});
  });

  test('capitales : la Bolivie en a deux, le Chili une principale et une alternative', () {
    List<Map<String, dynamic>> capitals(String id) => (items[id]!['capitals'] as List).cast<Map<String, dynamic>>();
    String fr(Map<String, dynamic> c) => (c['names'] as Map)['fr'] as String;
    expect(capitals('BOL').map(fr), unorderedEquals(['La Paz', 'Sucre']));
    expect(capitals('CHL').map((c) => '${fr(c)}:${c['role']}'), unorderedEquals(['Santiago:primary', 'Valparaíso:alt']));
    expect(capitals('PRY').single['names'], containsPair('fr', 'Asunción'));
    expect(fr(capitals('GUF').single), 'Cayenne');
  });

  test("chaque Élément a des noms, une ancre dans le cadre et un contour", () {
    final frame = (data['baseMap'] as Map)['frame'] as List;
    for (final item in items.values) {
      expect((item['names'] as Map)['fr'], isNotEmpty);
      expect((item['names'] as Map)['en'], isNotEmpty);
      final anchor = (item['anchor'] as List).cast<num>();
      expect(anchor[0], inInclusiveRange(frame[0], frame[2]), reason: item['id'] as String);
      expect(anchor[1], inInclusiveRange(frame[1], frame[3]), reason: item['id'] as String);
      expect(item['outline'], isNotEmpty);
    }
  });
}
