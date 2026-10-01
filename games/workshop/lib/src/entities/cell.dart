import 'color.dart';
import 'empty_cell_role.dart';
import 'shape.dart';

/// Cellule : une case de la Matrice, portant une Forme et, si elle n'est pas vide, une
/// Couleur ; si elle est vide, un Rôle de case vide (`games/workshop/CONTEXT.md`).
class Cell {
  final Shape shape;
  final Color? color;
  final EmptyCellRole? emptyRole;

  const Cell._(this.shape, this.color, this.emptyRole);

  factory Cell.filled(Shape shape, Color color) {
    if (shape == Shape.empty) {
      throw ArgumentError('Une Cellule remplie ne peut pas avoir Shape.empty ; utiliser Cell.empty.');
    }
    return Cell._(shape, color, null);
  }

  factory Cell.empty(EmptyCellRole role) => Cell._(Shape.empty, null, role);

  bool get isEmpty => shape == Shape.empty;

  @override
  bool operator ==(Object other) =>
      other is Cell && other.shape == shape && other.color == color && other.emptyRole == emptyRole;

  @override
  int get hashCode => Object.hash(shape, color, emptyRole);

  @override
  String toString() => isEmpty ? 'Cell.empty($emptyRole)' : 'Cell.filled($shape, $color)';
}
