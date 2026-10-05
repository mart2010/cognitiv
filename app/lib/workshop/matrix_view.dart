import 'package:flutter/material.dart';
import 'package:workshop/workshop.dart' as workshop;

import 'workshop_palette.dart';

/// Rend une Matrice. Les deux Rôles de case vide ont volontairement le même rendu
/// (pointillé), pour ne pas trahir la Règle (`games/workshop/CONTEXT.md`).
class MatrixView extends StatelessWidget {
  final workshop.Matrix matrix;
  final double cellSize;

  const MatrixView({super.key, required this.matrix, this.cellSize = 28});

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return CustomPaint(
      size: Size(matrix.columnCount * cellSize, matrix.rowCount * cellSize),
      painter: _MatrixPainter(matrix, outline),
    );
  }
}

class _MatrixPainter extends CustomPainter {
  final workshop.Matrix matrix;
  final Color emptyColor;

  _MatrixPainter(this.matrix, this.emptyColor);

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / matrix.columnCount;
    final cellHeight = size.height / matrix.rowCount;
    for (var r = 0; r < matrix.rowCount; r++) {
      for (var c = 0; c < matrix.columnCount; c++) {
        final bounds = Rect.fromLTWH(c * cellWidth, r * cellHeight, cellWidth, cellHeight)
            .deflate(cellWidth * 0.12);
        _paintCell(canvas, matrix.cellAt(r, c), bounds);
      }
    }
  }

  void _paintCell(Canvas canvas, workshop.Cell cell, Rect bounds) {
    if (cell.isEmpty) {
      _paintDashedRect(canvas, bounds);
      return;
    }
    final paint = Paint()..color = flutterColorOf(cell.color!);
    switch (cell.shape) {
      case workshop.Shape.round:
        canvas.drawOval(bounds, paint);
      case workshop.Shape.square:
        canvas.drawRRect(RRect.fromRectAndRadius(bounds, Radius.circular(bounds.width * 0.12)), paint);
      case workshop.Shape.triangle:
        final path = Path()
          ..moveTo(bounds.center.dx, bounds.top)
          ..lineTo(bounds.right, bounds.bottom)
          ..lineTo(bounds.left, bounds.bottom)
          ..close();
        canvas.drawPath(path, paint);
      case workshop.Shape.empty:
        break;
    }
  }

  void _paintDashedRect(Canvas canvas, Rect bounds) {
    final paint = Paint()
      ..color = emptyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final dash = bounds.width / 5;

    void line(Offset a, Offset b) {
      final delta = b - a;
      final length = delta.distance;
      final direction = delta / length;
      for (var d = 0.0; d < length; d += dash * 2) {
        final end = (d + dash) > length ? length : d + dash;
        canvas.drawLine(a + direction * d, a + direction * end, paint);
      }
    }

    line(bounds.topLeft, bounds.topRight);
    line(bounds.topRight, bounds.bottomRight);
    line(bounds.bottomRight, bounds.bottomLeft);
    line(bounds.bottomLeft, bounds.topLeft);
  }

  @override
  bool shouldRepaint(_MatrixPainter old) => old.matrix != matrix || old.emptyColor != emptyColor;
}
