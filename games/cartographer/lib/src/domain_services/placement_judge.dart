import 'dart:math' as math;

import '../entities/cartographer_answer.dart';
import '../entities/geo_point.dart';
import '../entities/item.dart';

/// Juge un point touché sur la Scène (Geste Placer) : dans l'Élément = exact, tout près =
/// proche, sinon faux. « Tout près » vaut une fraction du plus grand côté du cadre, pour
/// qu'une Carte de base large ou petite garde une tolérance proportionnée.
class PlacementJudge {
  final GeoFrame frame;
  final double closeFraction;

  const PlacementJudge(this.frame, {this.closeFraction = 0.04});

  static const _kmPerDegree = 111.0;

  double get closeDistanceKm => math.max(frame.width, frame.height) * closeFraction * _kmPerDegree;

  AnswerVerdict judge(Item item, GeoPoint tap) {
    if (item.outline.any((polygon) => _inside(polygon, tap))) return AnswerVerdict.exact;
    return distanceKm(item, tap) <= closeDistanceKm ? AnswerVerdict.close : AnswerVerdict.wrong;
  }

  /// Distance, en km approximatifs, du point au bord le plus proche de l'Élément.
  double distanceKm(Item item, GeoPoint tap) {
    var best = double.infinity;
    final cosLat = math.cos(tap.lat * math.pi / 180);
    for (final polygon in item.outline) {
      // Tous les anneaux : un point dans une enclave (un trou) est proche du bord du trou.
      for (final ring in polygon) {
        for (var i = 0; i < ring.length - 1; i++) {
          best = math.min(best, _segmentDistanceKm(tap, ring[i], ring[i + 1], cosLat));
        }
      }
    }
    return best;
  }

  static bool _inside(Polygon polygon, GeoPoint p) =>
      _inRing(polygon.first, p) && !polygon.skip(1).any((hole) => _inRing(hole, p));

  /// Lancer de rayon : le point est dedans si un rayon vers l'est coupe un nombre impair
  /// d'arêtes.
  static bool _inRing(Ring ring, GeoPoint p) {
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final a = ring[i];
      final b = ring[j];
      if ((a.lat > p.lat) != (b.lat > p.lat) &&
          p.lon < (b.lon - a.lon) * (p.lat - a.lat) / (b.lat - a.lat) + a.lon) {
        inside = !inside;
      }
    }
    return inside;
  }

  static double _segmentDistanceKm(GeoPoint p, GeoPoint a, GeoPoint b, double cosLat) {
    final px = p.lon * cosLat;
    final ax = a.lon * cosLat;
    final bx = b.lon * cosLat;
    final dx = bx - ax;
    final dy = b.lat - a.lat;
    final lengthSquared = dx * dx + dy * dy;
    final t = lengthSquared == 0 ? 0.0 : (((px - ax) * dx + (p.lat - a.lat) * dy) / lengthSquared).clamp(0.0, 1.0);
    final ex = px - (ax + t * dx);
    final ey = p.lat - (a.lat + t * dy);
    return math.sqrt(ex * ex + ey * ey) * _kmPerDegree;
  }
}
