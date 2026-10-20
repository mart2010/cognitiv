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
  final countries = {for (final e in items.entries) if (e.value['category'] == 'countries') e.key: e.value};
  final cities = {for (final e in items.entries) if (e.value['category'] == 'cities') e.key: e.value};

  Set<String> neighborsOf(String id) => (items[id]!['neighbors'] as List).cast<String>().toSet();
  Map<String, dynamic> attributes(String id) => items[id]!['attributes'] as Map<String, dynamic>;
  String fr(Map<String, dynamic> item) => (item['names'] as Map)['fr'] as String;

  test('contient les 12 États souverains et la Guyane', () {
    expect(countries.keys, unorderedEquals(['ARG', 'BOL', 'BRA', 'CHL', 'COL', 'ECU', 'GUY', 'PRY', 'PER', 'SUR', 'URY', 'VEN', 'GUF']));
    expect(attributes('GUF')['territory'], isTrue);
    expect(attributes('GUF')['state'], 'FRA');
    expect(attributes('ARG')['territory'], isFalse);
  });

  test('le voisinage est symétrique', () {
    for (final id in countries.keys) {
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
    List<Map<String, dynamic>> capitals(String country) => [
          for (final city in cities.values)
            if (city['containedIn'] == country && (city['attributes'] as Map)['capital'] == true) city,
        ];
    String role(Map<String, dynamic> c) => (c['attributes'] as Map)['capitalRole'] as String;
    expect(capitals('BOL').map(fr), unorderedEquals(['La Paz', 'Sucre']));
    expect(capitals('CHL').map((c) => '${fr(c)}:${role(c)}'), unorderedEquals(['Santiago:primary', 'Valparaíso:alt']));
    expect(fr(capitals('PRY').single), 'Asunción');
    expect(fr(capitals('GUF').single), 'Cayenne');
    for (final country in countries.keys) {
      expect(capitals(country), isNotEmpty, reason: country);
    }
  });

  test('chaque pays a des noms, une ancre dans le cadre et un contour', () {
    final frame = (data['baseMap'] as Map)['frame'] as List;
    for (final item in countries.values) {
      expect((item['names'] as Map)['fr'], isNotEmpty);
      expect((item['names'] as Map)['en'], isNotEmpty);
      final geometry = item['geometry'] as Map;
      expect(geometry['type'], 'area');
      final anchor = (geometry['anchor'] as List).cast<num>();
      expect(anchor[0], inInclusiveRange(frame[0], frame[2]), reason: item['id'] as String);
      expect(anchor[1], inInclusiveRange(frame[1], frame[3]), reason: item['id'] as String);
      expect(geometry['polygons'], isNotEmpty);
    }
  });

  group('villes', () {
    test('30 villes, toutes des Points dans le cadre et dans un pays de la Carte', () {
      final frame = (data['baseMap'] as Map)['frame'] as List;
      expect(cities, hasLength(30));
      for (final city in cities.values) {
        final geometry = city['geometry'] as Map;
        expect(geometry['type'], 'point');
        final position = (geometry['position'] as List).cast<num>();
        expect(position[0], inInclusiveRange(frame[0], frame[2]), reason: city['id'] as String);
        expect(position[1], inInclusiveRange(frame[1], frame[3]), reason: city['id'] as String);
        expect(countries.keys, contains(city['containedIn']), reason: city['id'] as String);
      }
    });

    test('des villes connues y sont, avec le bon pays', () {
      const expected = {
        'city:sao-paulo': 'BRA',
        'city:rio-de-janeiro': 'BRA',
        'city:buenos-aires': 'ARG',
        'city:lima': 'PER',
        'city:bogota': 'COL',
        'city:santiago': 'CHL',
        'city:quito': 'ECU',
        'city:montevideo': 'URY',
        'city:cayenne': 'GUF',
      };
      for (final entry in expected.entries) {
        expect(cities[entry.key]?['containedIn'], entry.value, reason: entry.key);
      }
    });

    test('le rang de notoriété suit la population, sans trou ni doublon', () {
      final ranked = cities.values.toList()
        ..sort((a, b) => ((a['attributes'] as Map)['rank'] as int).compareTo((b['attributes'] as Map)['rank'] as int));
      expect([for (final c in ranked) (c['attributes'] as Map)['rank']], [for (var i = 1; i <= 30; i++) i]);
      final populations = [for (final c in ranked) (c['attributes'] as Map)['population'] as int];
      expect(populations, orderedEquals([...populations]..sort((a, b) => b.compareTo(a))));
      expect(ranked.first['id'], 'city:sao-paulo');
    });

    test('aucun État ne prend plus de 4 villes', () {
      final perState = <String, int>{};
      for (final city in cities.values) {
        final state = (items[city['containedIn']]!['attributes'] as Map)['state'] as String;
        perState.update(state, (n) => n + 1, ifAbsent: () => 1);
      }
      expect(perState.values.every((n) => n <= 4), isTrue, reason: '$perState');
    });
  });
}
