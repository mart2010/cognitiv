import 'cell.dart';

/// Matrice : la grille de Cellules que la machine transforme, de dimensions m×n fixées
/// par le niveau (`games/workshop/CONTEXT.md`). Value Object : deux Matrices sont égales
/// quand leurs dimensions et leurs Cellules le sont, sans identité propre.
class Matrix {
  final List<List<Cell>> _rows;

  Matrix(List<List<Cell>> rows) : _rows = List.unmodifiable(rows.map(List<Cell>.unmodifiable)) {
    if (rows.isEmpty || rows.first.isEmpty) {
      throw ArgumentError('Une Matrice doit avoir au moins une ligne et une colonne.');
    }
    final columnCount = rows.first.length;
    if (rows.any((row) => row.length != columnCount)) {
      throw ArgumentError('Toutes les lignes d\'une Matrice doivent avoir le même nombre de colonnes.');
    }
  }

  factory Matrix.generate(int rowCount, int columnCount, Cell Function(int row, int column) builder) {
    return Matrix([
      for (var r = 0; r < rowCount; r++) [for (var c = 0; c < columnCount; c++) builder(r, c)],
    ]);
  }

  int get rowCount => _rows.length;
  int get columnCount => _rows.first.length;

  Cell cellAt(int row, int column) => _rows[row][column];

  Matrix withCell(int row, int column, Cell cell) {
    final updated = _rows.map((r) => List<Cell>.from(r)).toList();
    updated[row][column] = cell;
    return Matrix(updated);
  }

  List<Cell> get cells => [for (final row in _rows) ...row];

  @override
  bool operator ==(Object other) {
    if (other is! Matrix || other.rowCount != rowCount || other.columnCount != columnCount) {
      return false;
    }
    for (var r = 0; r < rowCount; r++) {
      for (var c = 0; c < columnCount; c++) {
        if (_rows[r][c] != other._rows[r][c]) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(rowCount, columnCount, Object.hashAll(cells));

  @override
  String toString() => _rows.map((r) => r.join(' | ')).join('\n');
}
