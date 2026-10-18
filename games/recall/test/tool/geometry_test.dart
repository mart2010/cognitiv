import 'package:test/test.dart';

import '../../tool/src/geometry.dart';

Point p(double lon, double lat) => (lon: lon, lat: lat);

void main() {
  group('ringArea', () {
    test('un carré de 2 degrés de côté vaut 4', () {
      final ring = [p(0, 0), p(2, 0), p(2, 2), p(0, 2), p(0, 0)];
      expect(ringArea(ring), 4);
    });

    test("ne dépend pas du sens de l'anneau", () {
      final ring = [p(0, 0), p(0, 2), p(2, 2), p(2, 0), p(0, 0)];
      expect(ringArea(ring), 4);
    });
  });

  group('simplifyLine', () {
    test('retire les points alignés et garde les extrémités', () {
      final line = [p(0, 0), p(1, 0), p(2, 0), p(3, 0)];
      expect(simplifyLine(line, 0.1), [p(0, 0), p(3, 0)]);
    });

    test('garde un coin plus loin que la tolérance', () {
      final line = [p(0, 0), p(1, 1), p(2, 0)];
      expect(simplifyLine(line, 0.5), line);
      expect(simplifyLine(line, 1.5), [p(0, 0), p(2, 0)]);
    });
  });

  group('simplifyRing', () {
    test("garde les coins d'un carré dont les côtés ont des points intermédiaires", () {
      final ring = [
        p(0, 0), p(1, 0), p(2, 0), p(2, 1), p(2, 2), p(1, 2), p(0, 2), p(0, 1), p(0, 0), //
      ];
      final simplified = simplifyRing(ring, 0.1)!;
      expect(simplified.first, simplified.last);
      expect(simplified.toSet(), {p(0, 0), p(2, 0), p(2, 2), p(0, 2)});
    });

    test('renvoie null pour un anneau dégénéré', () {
      final flat = [p(0, 0), p(1, 0), p(2, 0), p(0, 0)];
      expect(simplifyRing(flat, 0.1), isNull);
    });
  });
}
