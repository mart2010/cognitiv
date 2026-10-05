import 'cell.dart';
import 'color.dart';
import 'empty_cell_role.dart';
import 'matrix.dart';
import 'rule_family.dart';
import 'shape.dart';

enum Axis { row, column }

enum MirrorAxis { horizontal, vertical }

enum RotationAngle { clockwise90, counterClockwise90, half180 }

enum Diagonal { main, secondary }

enum Direction { up, down, left, right }

enum CycleScope { global, singleRow, singleColumn }

int _mod(int value, int modulus) => ((value % modulus) + modulus) % modulus;

(int, int) _delta(Direction direction) => switch (direction) {
      Direction.up => (-1, 0),
      Direction.down => (1, 0),
      Direction.left => (0, -1),
      Direction.right => (0, 1),
    };

/// Égalité profonde : un champ de `Rule` peut lui-même être une `List` (l'ordre de
/// `ColorCycleRule`/`ShapeCycleRule`), que `List.==` ne compare que par référence.
bool _deepEquals(Object? a, Object? b) {
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

bool _listEquals(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_deepEquals(a[i], b[i])) return false;
  }
  return true;
}

/// Règle : une transformation précise que la machine applique à la Matrice, l'élément
/// atomique et fini du Catalogue de règles (`games/workshop/CONTEXT.md`). Une Règle est
/// le couple (Famille, paramètres) : chaque sous-classe porte ses propres paramètres
/// (ADR 0008). Égalité structurelle par sous-type + paramètres, pour détecter deux
/// Règles identiques dans un combo.
sealed class Rule {
  const Rule();

  RuleFamily get family;
  Matrix apply(Matrix input);
  List<Object?> get fields;

  @override
  bool operator ==(Object other) =>
      other is Rule && other.runtimeType == runtimeType && _listEquals(fields, other.fields);

  @override
  int get hashCode => Object.hash(runtimeType, Object.hashAll(fields.map(_deepHash)));
}

int _deepHash(Object? value) => value is List ? Object.hashAll(value.map(_deepHash)) : value.hashCode;

/// Applique une combinaison ordonnée de Règles à une Matrice (fold séquentiel).
extension RuleComboApplication on List<Rule> {
  Matrix applyTo(Matrix input) => fold(input, (matrix, rule) => rule.apply(matrix));
}

/// Miroir : inverse la Matrice selon son axe horizontal ou vertical.
final class MirrorRule extends Rule {
  final MirrorAxis axis;
  const MirrorRule(this.axis);

  @override
  RuleFamily get family => RuleFamily.mirror;

  @override
  List<Object?> get fields => [axis];

  @override
  Matrix apply(Matrix input) => switch (axis) {
        MirrorAxis.horizontal => Matrix.generate(
            input.rowCount, input.columnCount, (r, c) => input.cellAt(input.rowCount - 1 - r, c)),
        MirrorAxis.vertical => Matrix.generate(
            input.rowCount, input.columnCount, (r, c) => input.cellAt(r, input.columnCount - 1 - c)),
      };

  @override
  String toString() => 'MirrorRule($axis)';
}

/// Rotation : tourne la Matrice de 90° (sens horaire ou antihoraire) ou de 180°, nommée
/// explicitement plutôt que composée implicitement de deux Miroirs.
final class RotationRule extends Rule {
  final RotationAngle angle;
  const RotationRule(this.angle);

  @override
  RuleFamily get family => RuleFamily.rotation;

  @override
  List<Object?> get fields => [angle];

  @override
  Matrix apply(Matrix input) => switch (angle) {
        RotationAngle.clockwise90 => Matrix.generate(input.columnCount, input.rowCount,
            (r, c) => input.cellAt(input.rowCount - 1 - c, r)),
        RotationAngle.counterClockwise90 => Matrix.generate(input.columnCount, input.rowCount,
            (r, c) => input.cellAt(c, input.columnCount - 1 - r)),
        RotationAngle.half180 => Matrix.generate(input.rowCount, input.columnCount,
            (r, c) => input.cellAt(input.rowCount - 1 - r, input.columnCount - 1 - c)),
      };

  @override
  String toString() => 'RotationRule($angle)';
}

/// Transposition : reflète la Matrice selon sa diagonale principale ou secondaire
/// (anti-diagonale). Change les dimensions d'une Matrice rectangulaire.
final class TranspositionRule extends Rule {
  final Diagonal diagonal;
  const TranspositionRule(this.diagonal);

  @override
  RuleFamily get family => RuleFamily.transposition;

  @override
  List<Object?> get fields => [diagonal];

  @override
  Matrix apply(Matrix input) => switch (diagonal) {
        Diagonal.main =>
          Matrix.generate(input.columnCount, input.rowCount, (r, c) => input.cellAt(c, r)),
        Diagonal.secondary => Matrix.generate(input.columnCount, input.rowCount,
            (r, c) => input.cellAt(input.rowCount - 1 - c, input.columnCount - 1 - r)),
      };

  @override
  String toString() => 'TranspositionRule($diagonal)';
}

/// Décalage cyclique : décale les lignes ou les colonnes de la Matrice entière en boucle
/// (façon tore), sans dépendre de cases vides. Fonctionne même sur une grille pleine.
final class CyclicShiftRule extends Rule {
  final Axis axis;
  final Direction direction;
  final int steps;

  const CyclicShiftRule(this.axis, this.direction, {this.steps = 1})
      : assert(steps > 0),
        assert((axis == Axis.row && (direction == Direction.up || direction == Direction.down)) ||
            (axis == Axis.column && (direction == Direction.left || direction == Direction.right)));

  @override
  RuleFamily get family => RuleFamily.cyclicShift;

  @override
  List<Object?> get fields => [axis, direction, steps];

  @override
  Matrix apply(Matrix input) {
    final rows = input.rowCount, columns = input.columnCount;
    if (axis == Axis.row) {
      final sign = direction == Direction.down ? 1 : -1;
      return Matrix.generate(rows, columns, (r, c) => input.cellAt(_mod(r - sign * steps, rows), c));
    }
    final sign = direction == Direction.right ? 1 : -1;
    return Matrix.generate(rows, columns, (r, c) => input.cellAt(r, _mod(c - sign * steps, columns)));
  }

  @override
  String toString() => 'CyclicShiftRule($axis, $direction, steps: $steps)';
}

/// Taquin : chaque case vide Active se déplace d'une position dans la direction donnée,
/// en échangeant sa place avec la Cellule remplie qui s'y trouvait. Ne franchit jamais le
/// bord de la Matrice, et ne touche jamais une autre case vide (Active ou Fixe) : une case
/// vide Fixe agit comme un mur, comme pour la Gravité, et deux cases vides Actives adjacentes
/// ne se déplacent pas l'une dans l'autre (ça n'aurait de toute façon aucun effet visible).
final class SlidingRule extends Rule {
  final Direction direction;
  const SlidingRule(this.direction);

  @override
  RuleFamily get family => RuleFamily.sliding;

  @override
  List<Object?> get fields => [direction];

  @override
  Matrix apply(Matrix input) {
    final (dr, dc) = _delta(direction);
    final rows = input.rowCount, columns = input.columnCount;
    final result = [
      for (var r = 0; r < rows; r++) [for (var c = 0; c < columns; c++) input.cellAt(r, c)],
    ];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < columns; c++) {
        final cell = input.cellAt(r, c);
        if (cell.isEmpty && cell.emptyRole == EmptyCellRole.active) {
          final targetRow = r + dr, targetCol = c + dc;
          final inBounds = targetRow >= 0 && targetRow < rows && targetCol >= 0 && targetCol < columns;
          final target = inBounds ? input.cellAt(targetRow, targetCol) : null;
          if (target != null && !target.isEmpty) {
            result[r][c] = target;
            result[targetRow][targetCol] = cell;
          }
        }
      }
    }
    return Matrix(result);
  }

  @override
  String toString() => 'SlidingRule($direction)';
}

/// Gravité : les Cellules non vides tombent vers un bord de la Matrice, comblant les
/// cases vides Actives sur leur passage ; une case vide Fixe arrête la chute comme un mur
/// et découpe la ligne ou la colonne en segments indépendants.
final class GravityRule extends Rule {
  final Direction direction;
  const GravityRule(this.direction);

  @override
  RuleFamily get family => RuleFamily.gravity;

  @override
  List<Object?> get fields => [direction];

  @override
  Matrix apply(Matrix input) {
    final rows = input.rowCount, columns = input.columnCount;
    final result = [
      for (var r = 0; r < rows; r++) [for (var c = 0; c < columns; c++) input.cellAt(r, c)],
    ];
    final vertical = direction == Direction.up || direction == Direction.down;
    final lineCount = vertical ? columns : rows;
    final lineLength = vertical ? rows : columns;
    final towardStart = direction == Direction.up || direction == Direction.left;

    for (var line = 0; line < lineCount; line++) {
      Cell at(int i) => vertical ? input.cellAt(i, line) : input.cellAt(line, i);
      void set(int i, Cell cell) {
        if (vertical) {
          result[i][line] = cell;
        } else {
          result[line][i] = cell;
        }
      }

      var segmentStart = 0;
      for (var i = 0; i <= lineLength; i++) {
        final isBoundary = i == lineLength || (at(i).isEmpty && at(i).emptyRole == EmptyCellRole.fixed);
        if (isBoundary) {
          final segment = [for (var j = segmentStart; j < i; j++) at(j)];
          final ordered = _collapseSegment(segment, towardStart);
          for (var offset = 0; offset < ordered.length; offset++) {
            set(segmentStart + offset, ordered[offset]);
          }
          segmentStart = i + 1;
        }
      }
    }
    return Matrix(result);
  }

  List<Cell> _collapseSegment(List<Cell> segment, bool towardStart) {
    final filled = segment.where((cell) => !cell.isEmpty).toList();
    final activeEmptyCount = segment.length - filled.length;
    final emptyCells = List.generate(activeEmptyCount, (_) => Cell.empty(EmptyCellRole.active));
    return towardStart ? [...filled, ...emptyCells] : [...emptyCells, ...filled];
  }

  @override
  String toString() => 'GravityRule($direction)';
}

/// Cycle de couleur : avance la Couleur d'une ou plusieurs Cellules d'un cran dans un
/// ordre fixe, globalement ou limitée à une ligne ou une colonne. Les cases vides ne sont
/// jamais affectées.
final class ColorCycleRule extends Rule {
  final CycleScope scope;
  final List<Color> order;
  final int? lineIndex;
  final int steps;

  const ColorCycleRule(this.scope, this.order, {this.lineIndex, this.steps = 1})
      : assert(scope == CycleScope.global || lineIndex != null);

  @override
  RuleFamily get family => RuleFamily.colorCycle;

  @override
  List<Object?> get fields => [scope, lineIndex, steps, order];

  @override
  Matrix apply(Matrix input) => Matrix.generate(input.rowCount, input.columnCount, (r, c) {
        final cell = input.cellAt(r, c);
        if (cell.isEmpty || !_affects(r, c)) return cell;
        final nextIndex = _mod(order.indexOf(cell.color!) + steps, order.length);
        return Cell.filled(cell.shape, order[nextIndex]);
      });

  bool _affects(int r, int c) => switch (scope) {
        CycleScope.global => true,
        CycleScope.singleRow => r == lineIndex,
        CycleScope.singleColumn => c == lineIndex,
      };

  @override
  String toString() => 'ColorCycleRule($scope, line: $lineIndex, steps: $steps)';
}

/// Cycle de forme : avance la Forme d'une ou plusieurs Cellules d'un cran dans un ordre
/// fixe (jamais vers ou depuis Vide), globalement ou limitée à une ligne ou une colonne.
final class ShapeCycleRule extends Rule {
  final CycleScope scope;
  final List<Shape> order;
  final int? lineIndex;
  final int steps;

  const ShapeCycleRule(this.scope, this.order, {this.lineIndex, this.steps = 1})
      : assert(scope == CycleScope.global || lineIndex != null);

  @override
  RuleFamily get family => RuleFamily.shapeCycle;

  @override
  List<Object?> get fields => [scope, lineIndex, steps, order];

  @override
  Matrix apply(Matrix input) => Matrix.generate(input.rowCount, input.columnCount, (r, c) {
        final cell = input.cellAt(r, c);
        if (cell.isEmpty || !_affects(r, c)) return cell;
        final nextIndex = _mod(order.indexOf(cell.shape) + steps, order.length);
        return Cell.filled(order[nextIndex], cell.color!);
      });

  bool _affects(int r, int c) => switch (scope) {
        CycleScope.global => true,
        CycleScope.singleRow => r == lineIndex,
        CycleScope.singleColumn => c == lineIndex,
      };

  @override
  String toString() => 'ShapeCycleRule($scope, line: $lineIndex, steps: $steps)';
}

/// Conditionnelle : toute Cellule d'une Couleur donnée devient une Forme donnée (la
/// Couleur ne change pas). Les cases vides, sans Couleur, ne sont jamais déclenchées.
final class ConditionalRule extends Rule {
  final Color triggerColor;
  final Shape resultShape;

  const ConditionalRule(this.triggerColor, this.resultShape) : assert(resultShape != Shape.empty);

  @override
  RuleFamily get family => RuleFamily.conditional;

  @override
  List<Object?> get fields => [triggerColor, resultShape];

  @override
  Matrix apply(Matrix input) => Matrix.generate(input.rowCount, input.columnCount, (r, c) {
        final cell = input.cellAt(r, c);
        if (!cell.isEmpty && cell.color == triggerColor) {
          return Cell.filled(resultShape, triggerColor);
        }
        return cell;
      });

  @override
  String toString() => 'ConditionalRule($triggerColor -> $resultShape)';
}
