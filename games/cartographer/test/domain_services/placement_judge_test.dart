import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

import '../support/real_base_map.dart';

Item square() => const Item(
      id: 'SQ',
      kind: ItemKind.country,
      belongsTo: 'SQ',
      names: LocalizedText(en: 'Square', fr: 'Carré'),
      capitals: [],
      anchor: GeoPoint(5, 5),
      outline: [
        [
          [GeoPoint(0, 0), GeoPoint(10, 0), GeoPoint(10, 10), GeoPoint(0, 10), GeoPoint(0, 0)],
          // un trou au centre
          [GeoPoint(4, 4), GeoPoint(6, 4), GeoPoint(6, 6), GeoPoint(4, 6), GeoPoint(4, 4)],
        ],
      ],
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
