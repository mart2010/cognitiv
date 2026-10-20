import 'dart:math' as math;

import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

import '../support/real_base_map.dart';

void main() {
  final map = loadSouthAmerica();
  final cities = map.itemsOf(Category.cities);

  double distance(GeoPoint a, GeoPoint b) => math.sqrt(math.pow(a.lon - b.lon, 2) + math.pow(a.lat - b.lat, 2));

  test('pose le nombre demandé de points bidon, tous distincts des vraies positions', () {
    final tray = cities.take(5).toList();
    final decoys = DecoyPlacer(SystemRandomSource(1)).place(map, tray, 12);
    expect(decoys, hasLength(12));
    for (final d in decoys) {
      expect(tray.map((i) => i.geometry.anchor), isNot(contains(d)));
    }
  });

  test('chaque point candidat reste à l\'écart des autres, pour pouvoir être visé au doigt', () {
    for (final seed in [1, 2, 3]) {
      final tray = cities.skip(seed).take(8).toList();
      final decoys = DecoyPlacer(SystemRandomSource(seed)).place(map, tray, 20);
      final all = [...tray.map((i) => i.geometry.anchor), ...decoys];
      final minimum = math.max(map.frame.width, map.frame.height) * 0.035;
      // Les vraies villes peuvent être proches entre elles (Buenos Aires, Montevideo) : seul un
      // point bidon doit rester à l'écart de tous les autres.
      for (final d in decoys) {
        for (final other in all.where((p) => p != d)) {
          expect(distance(d, other), greaterThanOrEqualTo(minimum), reason: 'seed $seed : $d et $other');
        }
      }
    }
  });

  test('les points bidon tirés au hasard tombent sur les terres', () {
    final decoys = DecoyPlacer(SystemRandomSource(4)).place(map, cities.take(3).toList(), 25);
    final cityAnchors = {for (final c in cities) c.geometry.anchor};
    final land = [for (final i in map.items) if (i.geometry is AreaGeometry) ...(i.geometry as AreaGeometry).polygons];
    for (final d in decoys.where((d) => !cityAnchors.contains(d))) {
      expect(land.any((p) => PlacementJudge.insidePolygon(p, d)), isTrue, reason: '$d');
    }
  });

  test('la graine fixe le résultat', () {
    final tray = cities.take(4).toList();
    expect(DecoyPlacer(SystemRandomSource(9)).place(map, tray, 10), DecoyPlacer(SystemRandomSource(9)).place(map, tray, 10));
  });
}
