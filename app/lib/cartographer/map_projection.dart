import 'dart:math' as math;
import 'dart:ui';

import 'package:cartographer/cartographer.dart' as cartographer;

/// Passage entre les degrés d'une Carte de base et les pixels d'un écran. Projection plane
/// (équirectangulaire) corrigée par le cosinus de la latitude moyenne, pour que les pays
/// gardent des proportions reconnaissables, centrée avec une marge.
class MapProjection {
  final cartographer.GeoFrame frame;
  final Size size;
  final double padding;

  late final double _cosMid = math.cos((frame.south + frame.north) / 2 * math.pi / 180);
  late final double _scale = math.min(
    (size.width - 2 * padding) / (frame.width * _cosMid),
    (size.height - 2 * padding) / frame.height,
  );
  late final double _offsetX = (size.width - frame.width * _cosMid * _scale) / 2;
  late final double _offsetY = (size.height - frame.height * _scale) / 2;

  MapProjection(this.frame, this.size, {this.padding = 8});

  Offset toCanvas(cartographer.GeoPoint point) => Offset(
    _offsetX + (point.lon - frame.west) * _cosMid * _scale,
    _offsetY + (frame.north - point.lat) * _scale,
  );

  cartographer.GeoPoint toGeo(Offset position) => cartographer.GeoPoint(
    frame.west + (position.dx - _offsetX) / (_cosMid * _scale),
    frame.north - (position.dy - _offsetY) / _scale,
  );
}
