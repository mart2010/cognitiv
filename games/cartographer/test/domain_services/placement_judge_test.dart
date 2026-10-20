import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

import '../support/real_base_map.dart';

Item square() => Item(
      id: 'SQ',
      category: Category.countries,
      names: const LocalizedText(en: 'Square', fr: 'Carré'),
      geometry: AreaGeometry(
        labelAnchor: const GeoPoint(5, 5),
        polygons: const [
          [
            [GeoPoint(0, 0), GeoPoint(10, 0), GeoPoint(10, 10), GeoPoint(0, 10), GeoPoint(0, 0)],
            // un trou au centre
            [GeoPoint(4, 4), GeoPoint(6, 4), GeoPoint(6, 6), GeoPoint(4, 6), GeoPoint(4, 4)],
          ],
        ],
      ),
    );

Item city(GeoPoint position) => Item(
      id: 'city:x',
      category: Category.cities,
      names: const LocalizedText(en: 'X', fr: 'X'),
      geometry: PointGeometry(position),
    );

void main() {
  const frame = GeoFrame(west: 0, south: 0, east: 50, north: 50);
  const judge = PlacementJudge(frame);

  test('un point dans le polygone est exact, hors des trous', () {
    expect(judge.judge(square(), const GeoPoint(1, 1)), AnswerVerdict.exact);
    expect(judge.judge(square(), const GeoPoint(5, 5)), isNot(AnswerVerdict.exact)); // dans le trou
  });

  test('proche = dans la tolérance du cadre, sinon faux', () {
    // Tolérance : 4 % de 50° = 2° ≈ 222 km.
    expect(judge.closeDistanceKm, closeTo(222, 1));
    expect(judge.judge(square(), const GeoPoint(11, 5)), AnswerVerdict.close); // ~110 km
    expect(judge.judge(square(), const GeoPoint(20, 5)), AnswerVerdict.wrong);
  });

  test('un trou compte comme proche du bord du trou', () {
    expect(judge.judge(square(), const GeoPoint(5, 5)), AnswerVerdict.close);
  });

  group('Point et Ligne', () {
    // Cadre de 50° : exact à 3 % = 1,5° ≈ 167 km, proche à 6 % = 3° ≈ 333 km.
    test('une ville : exact tout près, proche un peu plus loin, sinon faux', () {
      expect(judge.pointExactDistanceKm, closeTo(166.5, 1));
      expect(judge.pointCloseDistanceKm, closeTo(333, 1));
      final x = city(const GeoPoint(20, 20));
      expect(judge.judge(x, const GeoPoint(20, 20)), AnswerVerdict.exact);
      expect(judge.judge(x, const GeoPoint(21, 20)), AnswerVerdict.exact); // ~104 km
      expect(judge.judge(x, const GeoPoint(22, 20)), AnswerVerdict.close); // ~208 km
      expect(judge.judge(x, const GeoPoint(30, 20)), AnswerVerdict.wrong);
    });

    test('une ligne se juge à son tracé le plus proche, pas à ses extrémités', () {
      final river = Item(
        id: 'river',
        category: const Category(id: 'rivers', names: LocalizedText(en: 'Rivers', fr: 'Fleuves'), geometryKind: GeometryKind.line),
        names: const LocalizedText(en: 'River', fr: 'Fleuve'),
        geometry: LineGeometry([
          [const GeoPoint(0, 10), const GeoPoint(40, 10)],
        ]),
      );
      expect(judge.judge(river, const GeoPoint(20, 10.5)), AnswerVerdict.exact); // au milieu du tracé
      expect(judge.judge(river, const GeoPoint(20, 12)), AnswerVerdict.close);
      expect(judge.judge(river, const GeoPoint(20, 30)), AnswerVerdict.wrong);
    });
  });

  group('sur la vraie carte', () {
    final map = loadSouthAmerica();
    final judgeSa = PlacementJudge(map.frame);

    test("l'ancre de chaque Élément est dans son propre contour", () {
      for (final item in map.items) {
        expect(judgeSa.judge(item, item.anchor), AnswerVerdict.exact, reason: item.id);
      }
    });

    test('toucher la Bolivie pour le Paraguay est faux, la Guyane pour le Suriname est proche', () {
      final paraguay = map.itemById('PRY');
      expect(judgeSa.judge(paraguay, map.itemById('BOL').anchor), AnswerVerdict.wrong);
      expect(judgeSa.judge(map.itemById('SUR'), map.itemById('GUF').anchor), AnswerVerdict.close);
    });

    test("l'océan lointain est faux", () {
      expect(judgeSa.judge(map.itemById('BRA'), const GeoPoint(-30, -40)), AnswerVerdict.wrong);
    });
  });
}
