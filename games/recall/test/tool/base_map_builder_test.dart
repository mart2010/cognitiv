import 'package:test/test.dart';

import '../../tool/src/base_map_builder.dart';
import '../../tool/src/base_map_spec.dart';

Map<String, Object?> square(String code, double west, double south, double size, {String type = 'Sovereign country', String? sov}) => {
      'type': 'Feature',
      'properties': {
        'GU_A3': code,
        'ADM0_A3': sov ?? code,
        'SOV_A3': sov ?? code,
        'TYPE': type,
        'NAME_EN': 'Land $code',
        'NAME_FR': 'Terre $code',
        'POP_EST': 1000,
        'LABEL_X': west + size / 2,
        'LABEL_Y': south + size / 2,
      },
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [west, south],
            [west + size, south],
            [west + size, south + size],
            [west, south + size],
            [west, south],
          ],
        ],
      },
    };

Map<String, Object?> place(String name, String adm0, {int adm0Cap = 0, String featureClass = 'Populated place'}) => {
      'type': 'Feature',
      'properties': {
        'NAME': name,
        'NAME_EN': name,
        'NAME_FR': name == 'Asuncion' ? 'Asuncion' : name,
        'ADM0_A3': adm0,
        'ADM0CAP': adm0Cap,
        'FEATURECLA': featureClass,
        'LONGITUDE': 1.0,
        'LATITUDE': 1.0,
        'POP_MAX': 500,
      },
      'geometry': null,
    };

const spec = BaseMapSpec(
  id: 'test',
  unitCodes: ['AAA', 'BBB', 'CCC', 'TTT'],
  frame: Frame(west: -10, south: -10, east: 30, north: 30),
  capitalOverrides: {'TTT': 'Tville'},
  frenchNameFixes: {'Asuncion': 'Asunción'},
);

Map<String, Object?> build({List<Map<String, Object?>>? units, List<Map<String, Object?>>? places}) => buildBaseMap(
      spec: spec,
      mapUnits: {
        'features': units ??
            [
              square('AAA', 0, 0, 10),
              square('BBB', 10, 0, 10), // partage un côté avec AAA
              square('CCC', 20, 20, 5), // isolé
              square('TTT', 0, 10, 10, type: 'Geo unit', sov: 'AAA'), // partage un côté avec AAA
              square('ZZZ', 25, 25, 1), // hors de la liste
            ],
      },
      places: {
        'features': places ??
            [
              place('Acity', 'AAA', adm0Cap: 1),
              place('Bcity', 'BBB', adm0Cap: 1),
              place('Bold', 'BBB', featureClass: 'Admin-0 capital alt'),
              place('Ccity', 'CCC', adm0Cap: 1),
              place('Tville', 'AAA'),
              place('Autre', 'AAA'),
            ],
      },
    );

Map<String, Object?> item(Map<String, Object?> map, String id) =>
    ((map['items']! as List).cast<Map<String, Object?>>()).firstWhere((i) => i['id'] == id);

void main() {
  test('ne garde que les unités de la liste, triées par identifiant', () {
    final ids = ((build()['items']! as List).cast<Map<String, Object?>>()).map((i) => i['id']);
    expect(ids, ['AAA', 'BBB', 'CCC', 'TTT']);
  });

  test('deux unités qui partagent un côté sont voisines, symétriquement', () {
    final map = build();
    expect(item(map, 'AAA')['neighbors'], contains('BBB'));
    expect(item(map, 'BBB')['neighbors'], contains('AAA'));
    expect(item(map, 'CCC')['neighbors'], isEmpty);
  });

  test("un territoire est distinct de son État souverain mais reste voisin de ses limitrophes", () {
    final map = build();
    final territory = item(map, 'TTT');
    expect(territory['kind'], 'territory');
    expect(territory['belongsTo'], 'AAA');
    expect(territory['neighbors'], ['AAA']);
    expect(item(map, 'AAA')['kind'], 'country');
  });

  test("la capitale vient de ADM0CAP, la capitale alternative est marquée 'alt'", () {
    final capitals = (item(build(), 'BBB')['capitals']! as List).cast<Map<String, Object?>>();
    expect(capitals.map((c) => (c['names']! as Map)['en']), ['Bcity', 'Bold']);
    expect(capitals.map((c) => c['role']), ['primary', 'alt']);
  });

  test('un territoire utilise la capitale désignée par la spécification', () {
    final capitals = (item(build(), 'TTT')['capitals']! as List).cast<Map<String, Object?>>();
    expect(capitals.single['names'], {'en': 'Tville', 'fr': 'Tville'});
  });

  test('les accents manquants des noms français sont corrigés', () {
    final map = build(places: [place('Asuncion', 'AAA', adm0Cap: 1), place('B', 'BBB', adm0Cap: 1), place('C', 'CCC', adm0Cap: 1), place('Tville', 'AAA')]);
    final capitals = (item(map, 'AAA')['capitals']! as List).cast<Map<String, Object?>>();
    expect((capitals.single['names']! as Map)['fr'], 'Asunción');
  });

  test('une unité sans capitale est une erreur, pas un trou silencieux', () {
    expect(() => build(places: [place('Acity', 'AAA', adm0Cap: 1)]), throwsStateError);
  });

  test('une unité absente des données est une erreur', () {
    expect(() => build(units: [square('AAA', 0, 0, 10)]), throwsStateError);
  });

  test('un polygone hors du cadre est écarté, un îlot sous le seuil aussi', () {
    final far = square('CCC', 100, 100, 5); // hors cadre
    final map = build(units: [square('AAA', 0, 0, 10), square('BBB', 10, 0, 10), far, square('TTT', 0, 10, 0.1, sov: 'AAA')]);
    expect(item(map, 'CCC')['outline'], isEmpty);
    expect(item(map, 'TTT')['outline'], isEmpty); // aire 0,01 < 0,02
    expect(item(map, 'AAA')['outline'], hasLength(1));
  });
}
