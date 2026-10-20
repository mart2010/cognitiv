import 'dart:math' as math;

import '../entities/base_map.dart';
import '../entities/geo_point.dart';
import '../entities/geometry.dart';
import '../entities/item.dart';
import '../use_cases/ports/random_source.dart';
import 'placement_judge.dart';

/// Pose les points bidon d'un Plateau de Points : des positions plausibles, réparties sur la
/// carte, qui ne sont pas celles des Éléments à replacer. D'abord les positions d'autres Éléments
/// de la Carte de base (de vrais lieux que le joueur peut connaître), puis des points tirés sur
/// les terres. Chaque point reste à `minSpacingFraction` du plus grand côté du cadre de tous les
/// autres, pour qu'on puisse en viser un au doigt sans toucher son voisin.
class DecoyPlacer {
  final RandomSource random;
  final double minSpacingFraction;
  final int maxAttempts;

  const DecoyPlacer(this.random, {this.minSpacingFraction = 0.035, this.maxAttempts = 400});

  List<GeoPoint> place(BaseMap baseMap, List<Item> trayItems, int count) {
    final frame = baseMap.frame;
    final minSpacing = (frame.width > frame.height ? frame.width : frame.height) * minSpacingFraction;
    final taken = <GeoPoint>[for (final item in trayItems) item.geometry.anchor];
    final decoys = <GeoPoint>[];

    bool free(GeoPoint p) => taken.every((t) => _distance(t, p) >= minSpacing);
    void keep(GeoPoint p) {
      taken.add(p);
      decoys.add(p);
    }

    final trayIds = {for (final item in trayItems) item.id};
    final others = _shuffled([
      for (final item in baseMap.items)
        if (!trayIds.contains(item.id) && item.geometry is PointGeometry) item.geometry.anchor,
    ]);
    for (final p in others) {
      if (decoys.length == count) break;
      if (free(p)) keep(p);
    }

    final land = [
      for (final item in baseMap.items)
        if (item.geometry is AreaGeometry) ...(item.geometry as AreaGeometry).polygons,
    ];
    for (var attempt = 0; attempt < maxAttempts && decoys.length < count; attempt++) {
      final p = GeoPoint(
        frame.west + random.nextDouble() * frame.width,
        frame.south + random.nextDouble() * frame.height,
      );
      if (land.any((polygon) => PlacementJudge.insidePolygon(polygon, p)) && free(p)) keep(p);
    }
    return decoys;
  }

  static double _distance(GeoPoint a, GeoPoint b) => math.sqrt(math.pow(a.lon - b.lon, 2) + math.pow(a.lat - b.lat, 2));

  /// Mélange de Fisher-Yates avec le hasard injecté.
  List<T> _shuffled<T>(Iterable<T> source) {
    final list = source.toList();
    for (var i = list.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return list;
  }
}
