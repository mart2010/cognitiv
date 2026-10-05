import 'package:test/test.dart';
import 'package:workshop/workshop.dart';

Cell _f(Shape shape, Color color) => Cell.filled(shape, color);
Cell _e(EmptyCellRole role) => Cell.empty(role);

void main() {
  final abc = Matrix([
    [_f(Shape.round, Color.red), _f(Shape.square, Color.blue), _f(Shape.triangle, Color.green)],
    [_f(Shape.square, Color.green), _f(Shape.triangle, Color.red), _f(Shape.round, Color.blue)],
  ]);

  group('MirrorRule', () {
    test('horizontal échange les lignes', () {
      final result = const MirrorRule(MirrorAxis.horizontal).apply(abc);
      expect(result.cellAt(0, 0), abc.cellAt(1, 0));
      expect(result.cellAt(1, 0), abc.cellAt(0, 0));
      expect(result.cellAt(0, 2), abc.cellAt(1, 2));
    });

    test('vertical inverse chaque ligne', () {
      final result = const MirrorRule(MirrorAxis.vertical).apply(abc);
      expect(result.cellAt(0, 0), abc.cellAt(0, 2));
      expect(result.cellAt(0, 2), abc.cellAt(0, 0));
    });
  });

  group('RotationRule', () {
    test('90° horaire change les dimensions', () {
      final result = const RotationRule(RotationAngle.clockwise90).apply(abc);
      expect(result.rowCount, abc.columnCount);
      expect(result.columnCount, abc.rowCount);
      expect(result.cellAt(0, 0), abc.cellAt(1, 0));
      expect(result.cellAt(0, 1), abc.cellAt(0, 0));
    });

    test('180° garde les dimensions et inverse les deux axes', () {
      final result = const RotationRule(RotationAngle.half180).apply(abc);
      expect(result.rowCount, abc.rowCount);
      expect(result.columnCount, abc.columnCount);
      expect(result.cellAt(0, 0), abc.cellAt(1, 2));
    });
  });

  group('TranspositionRule', () {
    test('diagonale principale', () {
      final result = const TranspositionRule(Diagonal.main).apply(abc);
      expect(result.rowCount, abc.columnCount);
      expect(result.cellAt(0, 0), abc.cellAt(0, 0));
      expect(result.cellAt(0, 1), abc.cellAt(1, 0));
    });

    test('diagonale secondaire', () {
      final result = const TranspositionRule(Diagonal.secondary).apply(abc);
      expect(result.cellAt(0, 0), abc.cellAt(1, 2));
      expect(result.cellAt(2, 1), abc.cellAt(0, 0));
    });
  });

  group('CyclicShiftRule', () {
    test('décale les lignes vers le bas, avec retour en boucle', () {
      final column = Matrix([
        [_f(Shape.round, Color.red)],
        [_f(Shape.square, Color.blue)],
        [_f(Shape.triangle, Color.green)],
      ]);
      final result = const CyclicShiftRule(Axis.row, Direction.down).apply(column);
      expect(result.cellAt(0, 0), column.cellAt(2, 0));
      expect(result.cellAt(1, 0), column.cellAt(0, 0));
      expect(result.cellAt(2, 0), column.cellAt(1, 0));
    });
  });

  group('SlidingRule', () {
    test('une case vide Active se déplace d\'une position et échange sa place', () {
      final column = Matrix([
        [_f(Shape.round, Color.red)],
        [_e(EmptyCellRole.active)],
        [_f(Shape.square, Color.blue)],
      ]);
      final result = const SlidingRule(Direction.down).apply(column);
      expect(result.cellAt(0, 0), _f(Shape.round, Color.red), reason: 'non touchée');
      expect(result.cellAt(1, 0), _f(Shape.square, Color.blue), reason: 'la cellule du dessous remonte');
      expect(result.cellAt(2, 0), _e(EmptyCellRole.active), reason: 'la case vide descend');
    });

    test('une case vide Fixe agit comme un mur, comme pour la Gravité', () {
      final column = Matrix([
        [_e(EmptyCellRole.active)],
        [_e(EmptyCellRole.fixed)],
        [_f(Shape.round, Color.red)],
      ]);
      final result = const SlidingRule(Direction.down).apply(column);
      expect(result, column, reason: 'le mur bloque le glissement, rien ne bouge');
    });

    test('ne franchit jamais le bord de la Matrice', () {
      final column = Matrix([
        [_e(EmptyCellRole.active)],
        [_f(Shape.round, Color.red)],
      ]);
      final result = const SlidingRule(Direction.up).apply(column);
      expect(result, column, reason: 'déjà au bord, aucun déplacement possible');
    });
  });

  group('GravityRule', () {
    test('les Cellules non vides tombent, les cases Actives bullent', () {
      final column = Matrix([
        [_f(Shape.round, Color.red)],
        [_e(EmptyCellRole.active)],
        [_f(Shape.square, Color.blue)],
        [_e(EmptyCellRole.active)],
      ]);
      final result = const GravityRule(Direction.down).apply(column);
      expect(result.cellAt(0, 0), _e(EmptyCellRole.active));
      expect(result.cellAt(1, 0), _e(EmptyCellRole.active));
      expect(result.cellAt(2, 0), _f(Shape.round, Color.red), reason: 'ordre relatif conservé');
      expect(result.cellAt(3, 0), _f(Shape.square, Color.blue));
    });

    test('une case vide Fixe arrête la chute comme un mur', () {
      final column = Matrix([
        [_f(Shape.round, Color.red)],
        [_e(EmptyCellRole.fixed)],
        [_f(Shape.square, Color.blue)],
        [_e(EmptyCellRole.active)],
        [_f(Shape.triangle, Color.green)],
      ]);
      final result = const GravityRule(Direction.down).apply(column);
      expect(result.cellAt(0, 0), _f(Shape.round, Color.red), reason: 'seule dans son segment');
      expect(result.cellAt(1, 0), _e(EmptyCellRole.fixed), reason: 'le mur ne se déplace jamais');
      expect(result.cellAt(2, 0), _e(EmptyCellRole.active));
      expect(result.cellAt(3, 0), _f(Shape.square, Color.blue));
      expect(result.cellAt(4, 0), _f(Shape.triangle, Color.green));
    });
  });

  group('ColorCycleRule', () {
    test('avance la Couleur dans l\'ordre donné, en boucle', () {
      final matrix = Matrix([
        [_f(Shape.round, Color.red), _f(Shape.square, Color.green)],
      ]);
      final rule = ColorCycleRule(CycleScope.global, const [Color.red, Color.blue, Color.green]);
      final result = rule.apply(matrix);
      expect(result.cellAt(0, 0), _f(Shape.round, Color.blue));
      expect(result.cellAt(0, 1), _f(Shape.square, Color.red), reason: 'retour en boucle');
    });

    test('ignore les cases vides', () {
      final matrix = Matrix([[_e(EmptyCellRole.active)]]);
      final rule = ColorCycleRule(CycleScope.global, const [Color.red, Color.blue]);
      expect(rule.apply(matrix), matrix);
    });
  });

  group('ShapeCycleRule', () {
    test('limité à une seule ligne', () {
      final matrix = Matrix([
        [_f(Shape.round, Color.red), _f(Shape.round, Color.red)],
        [_f(Shape.round, Color.red), _f(Shape.round, Color.red)],
      ]);
      final rule = ShapeCycleRule(CycleScope.singleRow, const [Shape.round, Shape.square], lineIndex: 0);
      final result = rule.apply(matrix);
      expect(result.cellAt(0, 0), _f(Shape.square, Color.red));
      expect(result.cellAt(1, 0), _f(Shape.round, Color.red), reason: 'ligne 1 non ciblée');
    });
  });

  group('ConditionalRule', () {
    test('change la Forme des Cellules d\'une Couleur donnée, sans changer la Couleur', () {
      final matrix = Matrix([
        [_f(Shape.round, Color.red), _f(Shape.round, Color.blue)],
      ]);
      final rule = const ConditionalRule(Color.red, Shape.triangle);
      final result = rule.apply(matrix);
      expect(result.cellAt(0, 0), _f(Shape.triangle, Color.red));
      expect(result.cellAt(0, 1), _f(Shape.round, Color.blue), reason: 'couleur non déclenchée');
    });
  });
}
