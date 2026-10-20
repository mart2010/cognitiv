import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

import '../support/real_base_map.dart';

void main() {
  group('Item', () {
    test("la Géométrie d'un Élément doit être celle que sa Catégorie impose", () {
      expect(
        () => Item(
          id: 'x',
          category: Category.cities,
          names: const LocalizedText(en: 'X', fr: 'X'),
          geometry: AreaGeometry(polygons: const [], labelAnchor: const GeoPoint(0, 0)),
        ),
        throwsArgumentError,
      );
      expect(
        () => Item(
          id: 'y',
          category: Category.countries,
          names: const LocalizedText(en: 'Y', fr: 'Y'),
          geometry: const PointGeometry(GeoPoint(0, 0)),
        ),
        throwsArgumentError,
      );
    });

    test("l'ancre d'une ville est sa position, celle d'une ligne le milieu de son plus long tracé", () {
      expect(const PointGeometry(GeoPoint(3, 4)).anchor, const GeoPoint(3, 4));
      final line = LineGeometry([
        [const GeoPoint(0, 0), const GeoPoint(1, 0)],
        [const GeoPoint(0, 1), const GeoPoint(1, 1), const GeoPoint(2, 1), const GeoPoint(3, 1)],
      ]);
      expect(line.anchor, const GeoPoint(2, 1));
    });

    test('une Ligne a au moins un tracé de deux points', () {
      expect(() => LineGeometry([]), throwsArgumentError);
      expect(() => LineGeometry([[const GeoPoint(0, 0)]]), throwsArgumentError);
    });
  });

  group('Attributes', () {
    final attributes = Attributes({
      'population': 1200,
      'capital': true,
      'name': 'abc',
      'languages': ['fr', 'en'],
    });

    test('lit chaque type, avec des valeurs neutres quand la clé manque', () {
      expect(attributes.integer('population'), 1200);
      expect(attributes.flag('capital'), isTrue);
      expect(attributes.text('name'), 'abc');
      expect(attributes.list('languages'), ['fr', 'en']);
      expect(attributes.integer('absent'), isNull);
      expect(attributes.text('absent'), isNull);
      expect(attributes.flag('absent'), isFalse);
      expect(attributes.list('absent'), isEmpty);
    });

    test('lire une clé avec le mauvais type est une erreur, pas une valeur silencieuse', () {
      expect(() => attributes.text('population'), throwsStateError);
      expect(() => attributes.flag('name'), throwsStateError);
    });

    test('refuse un type de valeur non pris en charge', () {
      expect(() => Attributes({'x': DateTime(2026)}), throwsArgumentError);
      expect(() => Attributes({'x': [1, 2]}), throwsArgumentError);
    });
  });

  group('Catégorie', () {
    test('une Catégorie impose sa Géométrie : surface pour les pays, point pour les villes', () {
      expect(Category.countries.geometryKind, GeometryKind.area);
      expect(Category.cities.geometryKind, GeometryKind.point);
    });

    test('se retrouve par identifiant, et une Catégorie inconnue est une erreur', () {
      expect(Category.byId('cities'), Category.cities);
      expect(() => Category.byId('volcanoes'), throwsFormatException);
    });
  });

  group('sur la vraie carte', () {
    final map = loadSouthAmerica();

    test("l'ancre de chaque ville est exactement sur elle", () {
      final judge = PlacementJudge(map.frame);
      for (final city in map.itemsOf(Category.cities)) {
        expect(judge.judge(city, city.anchor), AnswerVerdict.exact, reason: city.id);
      }
    });

    test("toucher Lima pour Santiago est faux, Montevideo pour Buenos Aires est proche ou exact", () {
      final judge = PlacementJudge(map.frame);
      expect(judge.judge(map.itemById('city:santiago'), map.itemById('city:lima').anchor), AnswerVerdict.wrong);
      expect(judge.judge(map.itemById('city:buenos-aires'), map.itemById('city:montevideo').anchor), isNot(AnswerVerdict.wrong));
    });
  });
}
