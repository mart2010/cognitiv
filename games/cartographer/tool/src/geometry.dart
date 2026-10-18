import 'dart:math' as math;

/// Un point en degrés (longitude, latitude). Les calculs sont plans : suffisant pour
/// simplifier des contours à l'échelle d'une Carte de base.
typedef Point = ({double lon, double lat});

/// Aire (en degrés carrés) d'un anneau, par la formule du lacet. Toujours positive.
double ringArea(List<Point> ring) {
  var sum = 0.0;
  for (var i = 0; i < ring.length - 1; i++) {
    sum += ring[i].lon * ring[i + 1].lat - ring[i + 1].lon * ring[i].lat;
  }
  return sum.abs() / 2;
}

double _distanceToSegment(Point p, Point a, Point b) {
  final dx = b.lon - a.lon;
  final dy = b.lat - a.lat;
  final lengthSquared = dx * dx + dy * dy;
  if (lengthSquared == 0) {
    return math.sqrt(math.pow(p.lon - a.lon, 2) + math.pow(p.lat - a.lat, 2));
  }
  final t = (((p.lon - a.lon) * dx + (p.lat - a.lat) * dy) / lengthSquared).clamp(0.0, 1.0);
  final projLon = a.lon + t * dx;
  final projLat = a.lat + t * dy;
  return math.sqrt(math.pow(p.lon - projLon, 2) + math.pow(p.lat - projLat, 2));
}

/// Douglas-Peucker sur une ligne ouverte. Garde toujours le premier et le dernier point.
List<Point> simplifyLine(List<Point> line, double tolerance) {
  if (line.length <= 2) return List.of(line);
  final keep = List<bool>.filled(line.length, false);
  keep[0] = true;
  keep[line.length - 1] = true;
  final stack = <(int, int)>[(0, line.length - 1)];
  while (stack.isNotEmpty) {
    final (first, last) = stack.removeLast();
    var farthest = -1;
    var maxDistance = tolerance;
    for (var i = first + 1; i < last; i++) {
      final d = _distanceToSegment(line[i], line[first], line[last]);
      if (d > maxDistance) {
        maxDistance = d;
        farthest = i;
      }
    }
    if (farthest != -1) {
      keep[farthest] = true;
      stack.add((first, farthest));
      stack.add((farthest, last));
    }
  }
  return [for (var i = 0; i < line.length; i++) if (keep[i]) line[i]];
}

/// Simplifie un anneau fermé (premier point = dernier point). Un anneau se coupe en deux
/// lignes au point le plus éloigné du départ, sinon Douglas-Peucker voit un segment nul.
/// Renvoie null si l'anneau devient dégénéré (moins de 3 sommets distincts).
List<Point>? simplifyRing(List<Point> ring, double tolerance) {
  if (ring.length < 4) return null;
  var split = 1;
  var maxDistance = -1.0;
  for (var i = 1; i < ring.length - 1; i++) {
    final d = math.sqrt(math.pow(ring[i].lon - ring[0].lon, 2) + math.pow(ring[i].lat - ring[0].lat, 2));
    if (d > maxDistance) {
      maxDistance = d;
      split = i;
    }
  }
  final firstHalf = simplifyLine(ring.sublist(0, split + 1), tolerance);
  final secondHalf = simplifyLine(ring.sublist(split), tolerance);
  final result = [...firstHalf, ...secondHalf.skip(1)];
  return result.length >= 4 ? result : null;
}
