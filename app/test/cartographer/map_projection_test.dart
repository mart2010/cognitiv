import 'dart:ui';

import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:cognitiv_app/cartographer/map_projection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const frame = cartographer.GeoFrame(west: -82, south: -57, east: -32, north: 13);
  final projection = MapProjection(frame, const Size(400, 700));

  test("l'aller-retour pixels/degrés redonne le point de départ", () {
    for (final point in const [
      cartographer.GeoPoint(-60, -10),
      cartographer.GeoPoint(-75.5, -33),
      cartographer.GeoPoint(-35, 5),
    ]) {
      final back = projection.toGeo(projection.toCanvas(point));
      expect(back.lon, closeTo(point.lon, 1e-9));
      expect(back.lat, closeTo(point.lat, 1e-9));
    }
  });

  test('le nord est en haut, l\'ouest à gauche', () {
    final nw = projection.toCanvas(const cartographer.GeoPoint(-82, 13));
    final se = projection.toCanvas(const cartographer.GeoPoint(-32, -57));
    expect(nw.dy, lessThan(se.dy));
    expect(nw.dx, lessThan(se.dx));
  });

  test('tout le cadre tient dans la taille, avec la marge', () {
    final nw = projection.toCanvas(const cartographer.GeoPoint(-82, 13));
    final se = projection.toCanvas(const cartographer.GeoPoint(-32, -57));
    for (final corner in [nw, se]) {
      expect(corner.dx, inInclusiveRange(8, 392));
      expect(corner.dy, inInclusiveRange(8, 692));
    }
  });

  test('un degré de longitude est plus étroit que un de latitude (cosinus de la latitude)', () {
    final origin = projection.toCanvas(const cartographer.GeoPoint(-60, -22));
    final east = projection.toCanvas(const cartographer.GeoPoint(-59, -22));
    final north = projection.toCanvas(const cartographer.GeoPoint(-60, -21));
    expect((east.dx - origin.dx).abs(), lessThan((north.dy - origin.dy).abs()));
  });
}
