import 'package:flutter/material.dart';
import 'package:workshop/workshop.dart' as workshop;

import 'workshop_palette.dart';

/// Rend une Matrice. Les deux Rôles de case vide ont volontairement le même rendu
/// (pointillé), pour ne pas trahir la Règle (`games/workshop/CONTEXT.md`).
class MatrixView extends StatelessWidget {
  final workshop.Matrix matrix;
  final double cellSize;

  /// Appelé avec la ligne et la colonne touchées ; null pour une Matrice non interactive.
  final void Function(int row, int column)? onCellTap;

  const MatrixView({super.key, required this.matrix, this.cellSize = 28, this.onCellTap});

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    final paint = CustomPaint(
      size: Size(matrix.columnCount * cellSize, matrix.rowCount * cellSize),
      painter: _MatrixPainter(matrix, outline),
    );
    final onCellTap = this.onCellTap;
    if (onCellTap == null) return paint;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        final row = (details.localPosition.dy / cellSize).floor();
        final column = (details.localPosition.dx / cellSize).floor();
        if (row >= 0 && row < matrix.rowCount && column >= 0 && column < matrix.columnCount) {
          onCellTap(row, column);
        }
      },
      child: paint,
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
        final bounds = Rect.fromLTWH(
          c * cellWidth,
          r * cellHeight,
          cellWidth,
          cellHeight,
        ).deflate(cellWidth * 0.12);
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
        canvas.drawRRect(
          RRect.fromRectAndRadius(bounds, Radius.circular(bounds.width * 0.12)),
          paint,
        );
      case workshop.Shape.cross:
        // Symétrique sous rotation à 90° : une Règle de Rotation ne tourne que la
        // position des Cellules, jamais le glyphe, donc la forme doit rester
        // identique à elle-même peu importe l'angle (`shape.dart`).
        final armThickness = bounds.shortestSide / 3;
        final left = bounds.center.dx - armThickness / 2;
        final right = bounds.center.dx + armThickness / 2;
        final top = bounds.center.dy - armThickness / 2;
        final bottom = bounds.center.dy + armThickness / 2;
        final path = Path()
          ..moveTo(left, bounds.top)
          ..lineTo(right, bounds.top)
          ..lineTo(right, top)
          ..lineTo(bounds.right, top)
          ..lineTo(bounds.right, bottom)
          ..lineTo(right, bottom)
          ..lineTo(right, bounds.bottom)
          ..lineTo(left, bounds.bottom)
          ..lineTo(left, bottom)
          ..lineTo(bounds.left, bottom)
          ..lineTo(bounds.left, top)
          ..lineTo(left, top)
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
