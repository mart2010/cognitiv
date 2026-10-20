import 'dart:math' as math;

import '../entities/cartographer_answer.dart';
import '../entities/geo_point.dart';
import '../entities/geometry.dart';
import '../entities/item.dart';

/// Juge un point touché sur la Scène (Geste Placer). Pour un Polygone : dans l'Élément = exact,
/// tout près = proche, sinon faux. Pour un Point ou une Ligne, que le doigt ne peut pas viser
/// pile : exact à moins de `exactFraction` du plus grand côté du cadre, proche à moins de
/// `pointCloseFraction`. Les fractions, plutôt que des kilomètres, gardent une tolérance
/// proportionnée à une Carte de base large ou petite.
class PlacementJudge {
  final GeoFrame frame;
  final double closeFraction;
  final double pointExactFraction;
  final double pointCloseFraction;

  const PlacementJudge(
    this.frame, {
    this.closeFraction = 0.04,
    this.pointExactFraction = 0.03,
    this.pointCloseFraction = 0.06,
  });

  static const _kmPerDegree = 111.0;

  double get _frameKm => math.max(frame.width, frame.height) * _kmPerDegree;

  double get closeDistanceKm => _frameKm * closeFraction;

  double get pointExactDistanceKm => _frameKm * pointExactFraction;

  double get pointCloseDistanceKm => _frameKm * pointCloseFraction;

  AnswerVerdict judge(Item item, GeoPoint tap) => switch (item.geometry) {
        AreaGeometry(:final polygons) when polygons.any((polygon) => insidePolygon(polygon, tap)) => AnswerVerdict.exact,
        AreaGeometry() => distanceKm(item, tap) <= closeDistanceKm ? AnswerVerdict.close : AnswerVerdict.wrong,
        PointGeometry() || LineGeometry() => _byDistance(distanceKm(item, tap)),
      };

  AnswerVerdict _byDistance(double km) => km <= pointExactDistanceKm
      ? AnswerVerdict.exact
      : km <= pointCloseDistanceKm
          ? AnswerVerdict.close
          : AnswerVerdict.wrong;

  /// Distance, en km approximatifs, du point à l'Élément : son bord le plus proche pour un
  /// Polygone, lui-même pour un Point, son tracé le plus proche pour une Ligne.
  double distanceKm(Item item, GeoPoint tap) {
    final cosLat = math.cos(tap.lat * math.pi / 180);
    switch (item.geometry) {
      case AreaGeometry(:final polygons):
        var best = double.infinity;
        for (final polygon in polygons) {
          // Tous les anneaux : un point dans une enclave (un trou) est proche du bord du trou.
          for (final ring in polygon) {
            best = math.min(best, _pathDistanceKm(tap, ring, cosLat));
          }
        }
        return best;
      case PointGeometry(:final position):
        return _segmentDistanceKm(tap, position, position, cosLat);
      case LineGeometry(:final lines):
        return lines.map((line) => _pathDistanceKm(tap, line, cosLat)).reduce(math.min);
    }
  }

  static double _pathDistanceKm(GeoPoint tap, List<GeoPoint> path, double cosLat) {
    var best = double.infinity;
    for (var i = 0; i < path.length - 1; i++) {
      best = math.min(best, _segmentDistanceKm(tap, path[i], path[i + 1], cosLat));
    }
    return best;
  }

  /// Le point est-il dans le Polygone (son anneau extérieur, hors trous) ?
  static bool insidePolygon(Polygon polygon, GeoPoint p) =>
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
