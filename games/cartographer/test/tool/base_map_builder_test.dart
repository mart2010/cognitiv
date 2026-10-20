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

Map<String, Object?> placeAt(
  String name,
  String adm0, {
  int adm0Cap = 0,
  String featureClass = 'Populated place',
  double lon = 1.0,
  double lat = 1.0,
  int population = 500,
}) =>
    {
      'type': 'Feature',
      'properties': {
        'NAME': name,
        'NAME_EN': name,
        'NAME_FR': name == 'Asuncion' ? 'Asuncion' : name,
        'ADM0_A3': adm0,
        'ADM0CAP': adm0Cap,
        'FEATURECLA': featureClass,
        'LONGITUDE': lon,
        'LATITUDE': lat,
        'POP_MAX': population,
      },
      'geometry': null,
    };

Map<String, Object?> place(String name, String adm0, {int adm0Cap = 0, String featureClass = 'Populated place'}) =>
    placeAt(name, adm0, adm0Cap: adm0Cap, featureClass: featureClass);

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

List<Map<String, Object?>> cities(Map<String, Object?> map) =>
    ((map['items']! as List).cast<Map<String, Object?>>()).where((i) => i['category'] == 'cities').toList();

Map<String, Object?> attributes(Map<String, Object?> item) => (item['attributes']! as Map).cast<String, Object?>();

List<String> countryIds(Map<String, Object?> map) => [
      for (final i in (map['items']! as List).cast<Map<String, Object?>>())
        if (i['category'] == 'countries') i['id']! as String,
    ];

void main() {
  test('ne garde que les unités de la liste, triées par identifiant', () {
    expect(countryIds(build()), ['AAA', 'BBB', 'CCC', 'TTT']);
  });

  test('le schéma est le 2', () {
    expect(build()['schemaVersion'], 2);
  });

  test('deux unités qui partagent un côté sont voisines, symétriquement', () {
    final map = build();
    expect(item(map, 'AAA')['neighbors'], contains('BBB'));
    expect(item(map, 'BBB')['neighbors'], contains('AAA'));
    expect(item(map, 'CCC')['neighbors'], isEmpty);
  });

  test('un territoire est distinct de son État souverain mais reste voisin de ses limitrophes', () {
    final map = build();
    final territory = item(map, 'TTT');
    expect(attributes(territory)['territory'], isTrue);
    expect(attributes(territory)['state'], 'AAA');
    expect(territory['neighbors'], ['AAA']);
    expect(attributes(item(map, 'AAA'))['territory'], isFalse);
  });

  test('un pays est un Élément de la Catégorie des pays, à Géométrie en surface', () {
    final aaa = item(build(), 'AAA');
    expect(aaa['category'], 'countries');
    expect((aaa['geometry']! as Map)['type'], 'area');
    expect(aaa['containedIn'], isNull);
  });

  test("la capitale vient de ADM0CAP, la capitale alternative est marquée 'alt'", () {
    final map = build();
    final bolivia = [for (final c in cities(map)) if (c['containedIn'] == 'BBB' && attributes(c)['capital'] == true) c];
    expect({for (final c in bolivia) (c['names']! as Map)['en']: attributes(c)['capitalRole']}, {'Bcity': 'primary', 'Bold': 'alt'});
  });

  test('un territoire utilise la capitale désignée par la spécification', () {
    final map = build();
    final tville = item(map, 'city:tville');
    expect(tville['containedIn'], 'TTT');
    expect(attributes(tville)['capital'], isTrue);
    expect(tville['names'], {'en': 'Tville', 'fr': 'Tville'});
    // Même État que AAA mais une autre unité : Acity reste la capitale de AAA.
    expect(item(map, 'city:acity')['containedIn'], 'AAA');
  });

  test('une ville ordinaire est un Point, sans rôle de capitale, dans l\'unité qui la contient', () {
    final autre = item(build(), 'city:autre');
    expect(autre['category'], 'cities');
    expect((autre['geometry']! as Map)['type'], 'point');
    expect(attributes(autre).containsKey('capital'), isFalse);
    expect(autre['containedIn'], 'AAA'); // son État a deux unités (AAA, TTT) : celle qui la contient
  });

  test('une ville dont l\'État a deux unités va à celle qui la contient', () {
    final map = build(places: [
      place('Acity', 'AAA', adm0Cap: 1),
      place('Bcity', 'BBB', adm0Cap: 1),
      place('Ccity', 'CCC', adm0Cap: 1),
      place('Tville', 'AAA'),
      placeAt('Nordique', 'AAA', lon: 5, lat: 15), // dans TTT (0..10 x 10..20)
    ]);
    expect(item(map, 'city:nordique')['containedIn'], 'TTT');
  });

  test('les accents manquants des noms français sont corrigés', () {
    final map = build(places: [place('Asuncion', 'AAA', adm0Cap: 1), place('B', 'BBB', adm0Cap: 1), place('C', 'CCC', adm0Cap: 1), place('Tville', 'AAA')]);
    expect((item(map, 'city:asuncion')['names']! as Map)['fr'], 'Asunción');
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
    expect((item(map, 'CCC')['geometry']! as Map)['polygons'], isEmpty);
    expect((item(map, 'TTT')['geometry']! as Map)['polygons'], isEmpty); // aire 0,01 < 0,02
    expect((item(map, 'AAA')['geometry']! as Map)['polygons'], hasLength(1));
  });

  group('sélection des villes', () {
    List<Map<String, Object?>> crowd(String adm0, int count, {int firstPopulation = 1000}) => [
          for (var i = 0; i < count; i++) placeAt('${adm0.toLowerCase()}$i', adm0, population: firstPopulation - i),
        ];

    BaseMapSpec custom({required int maxCities, required int maxPerState}) => BaseMapSpec(
          id: 't',
          unitCodes: spec.unitCodes,
          frame: spec.frame,
          capitalOverrides: spec.capitalOverrides,
          maxCities: maxCities,
          maxCitiesPerState: maxPerState,
        );

    Map<String, Object?> buildWith(BaseMapSpec custom, List<Map<String, Object?>> places) => buildBaseMap(
          spec: custom,
          mapUnits: {
            'features': [
              square('AAA', 0, 0, 10),
              square('BBB', 10, 0, 10),
              square('CCC', 20, 20, 5),
              square('TTT', 0, 10, 10, type: 'Geo unit', sov: 'AAA'),
            ],
          },
          places: {'features': places},
        );

    final capitals = [place('Acity', 'AAA', adm0Cap: 1), place('Bcity', 'BBB', adm0Cap: 1), place('Ccity', 'CCC', adm0Cap: 1), place('Tville', 'AAA')];

    test('les capitales sont toujours retenues, même plus petites que les autres villes', () {
      final map = buildWith(custom(maxCities: 5, maxPerState: 10), [...capitals, ...crowd('BBB', 20, firstPopulation: 9000)]);
      final ids = cities(map).map((c) => c['id']).toSet();
      expect(ids, containsAll(['city:acity', 'city:bcity', 'city:ccity', 'city:tville']));
      expect(cities(map), hasLength(5));
    });

    test('au-delà des capitales, les plus peuplées gagnent, avec leur rang', () {
      final map = buildWith(custom(maxCities: 6, maxPerState: 10), [...capitals, ...crowd('BBB', 20, firstPopulation: 9000)]);
      expect(cities(map).map((c) => c['id']), containsAll(['city:bbb0', 'city:bbb1']));
      expect(attributes(item(map, 'city:bbb0'))['rank'], 1);
      expect(attributes(item(map, 'city:bbb1'))['rank'], 2);
    });

    test('le plafond par État empêche le plus peuplé de tout prendre', () {
      final map = buildWith(custom(maxCities: 30, maxPerState: 3), [...capitals, ...crowd('BBB', 20, firstPopulation: 9000)]);
      expect(cities(map).where((c) => c['containedIn'] == 'BBB'), hasLength(3)); // Bcity + 2
    });

    test('une ville hors du cadre ou d\'un autre État est écartée', () {
      final map = buildWith(spec, [
        ...capitals,
        placeAt('Loin', 'AAA', lon: 100, lat: 100),
        placeAt('Etranger', 'ZZZ', lon: 5, lat: 5),
      ]);
      final ids = cities(map).map((c) => c['id']);
      expect(ids, isNot(contains('city:loin')));
      expect(ids, isNot(contains('city:etranger')));
    });

    test('deux villes de même nom sont une erreur, pas un écrasement silencieux', () {
      expect(() => buildWith(spec, [...capitals, place('Doublon', 'AAA'), place('Doublon', 'AAA')]), throwsStateError);
    });
  });
}
