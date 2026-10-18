import 'dart:math' as math;

import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:flutter/material.dart';

/// Le contour d'un seul Élément, seul sur le fond, centré et agrandi : l'Indice « forme » ne doit
/// rien révéler de sa position ni de ses voisins.
class CartographerShapeView extends StatelessWidget {
  final cartographer.Item item;
  final Color? color;

  const CartographerShapeView({super.key, required this.item, this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      key: const Key('shape-view'),
      painter: _ShapePainter(item, color ?? scheme.primary.withValues(alpha: 0.75), scheme.outline),
      child: const SizedBox.expand(),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final cartographer.Item item;
  final Color fill;
  final Color border;

  _ShapePainter(this.item, this.fill, this.border);

  @override
  void paint(Canvas canvas, Size size) {
    final rings = [for (final polygon in item.outline) ...polygon];
    final points = [for (final polygon in item.outline) ...polygon.first];
    if (points.isEmpty) return;
    final west = points.map((p) => p.lon).reduce(math.min);
    final east = points.map((p) => p.lon).reduce(math.max);
    final south = points.map((p) => p.lat).reduce(math.min);
    final north = points.map((p) => p.lat).reduce(math.max);
    final cosMid = math.cos((south + north) / 2 * math.pi / 180);
    const padding = 24.0;
    final scale = math.min(
      (size.width - 2 * padding) / math.max((east - west) * cosMid, 1e-9),
      (size.height - 2 * padding) / math.max(north - south, 1e-9),
    );
    final offsetX = (size.width - (east - west) * cosMid * scale) / 2;
    final offsetY = (size.height - (north - south) * scale) / 2;
    Offset toCanvas(cartographer.GeoPoint p) =>
        Offset(offsetX + (p.lon - west) * cosMid * scale, offsetY + (north - p.lat) * scale);

    final path = Path()..fillType = PathFillType.evenOdd;
    for (final ring in rings) {
      path.addPolygon([for (final p in ring) toCanvas(p)], true);
    }
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round
        ..color = border,
    );
  }

  @override
  bool shouldRepaint(_ShapePainter old) => old.item != item || old.fill != fill || old.border != border;
}
