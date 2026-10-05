import '../entities/cell.dart';
import '../entities/color.dart';
import '../entities/empty_cell_role.dart';
import '../entities/matrix.dart';
import '../entities/shape.dart';

/// Traduit une Cellule vers une donnée sérialisable (compatible `dart:convert`), pour que
/// la plateforme puisse stocker une Énigme comme donnée opaque (ADR 0002). Volontairement
/// hors de `Cell` elle-même : la traduction vers un format externe est un souci
/// d'Interface Adapter, pas de l'Entité (règle de dépendance, `CLAUDE.md`).
extension CellJsonEncoding on Cell {
  Map<String, dynamic> toJson() => isEmpty
      ? {'shape': shape.name, 'emptyRole': emptyRole!.name}
      : {'shape': shape.name, 'color': color!.name};
}

class CellCodec {
  static Cell fromJson(Map<String, dynamic> json) {
    final shape = Shape.values.byName(json['shape'] as String);
    if (shape == Shape.empty) {
      return Cell.empty(EmptyCellRole.values.byName(json['emptyRole'] as String));
    }
    return Cell.filled(shape, Color.values.byName(json['color'] as String));
  }
}

extension MatrixJsonEncoding on Matrix {
  Map<String, dynamic> toJson() => {
        'cells': [
          for (var r = 0; r < rowCount; r++)
            [for (var c = 0; c < columnCount; c++) cellAt(r, c).toJson()],
        ],
      };
}

class MatrixCodec {
  static Matrix fromJson(Map<String, dynamic> json) {
    final rows = json['cells'] as List;
    return Matrix([
      for (final row in rows)
        [for (final cell in row as List) CellCodec.fromJson(cell as Map<String, dynamic>)],
    ]);
  }
}
