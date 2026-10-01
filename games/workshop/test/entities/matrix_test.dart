import 'package:test/test.dart';
import 'package:workshop/workshop.dart';

Cell _filled(Shape shape, Color color) => Cell.filled(shape, color);

void main() {
  group('Matrix', () {
    test('refuse des lignes de longueurs différentes', () {
      expect(
        () => Matrix([
          [_filled(Shape.round, Color.red)],
          [_filled(Shape.round, Color.red), _filled(Shape.round, Color.red)],
        ]),
        throwsArgumentError,
      );
    });

    test('égalité par dimensions et contenu', () {
      final a = Matrix.generate(2, 2, (r, c) => _filled(Shape.round, Color.red));
      final b = Matrix.generate(2, 2, (r, c) => _filled(Shape.round, Color.red));
      final c = Matrix.generate(2, 2, (r, c) => _filled(Shape.square, Color.red));
      expect(a, b);
      expect(a, isNot(c));
    });

    test('withCell remplace une seule Cellule', () {
      final matrix = Matrix.generate(2, 2, (r, c) => _filled(Shape.round, Color.red));
      final updated = matrix.withCell(0, 1, _filled(Shape.square, Color.blue));
      expect(updated.cellAt(0, 1), _filled(Shape.square, Color.blue));
      expect(updated.cellAt(0, 0), _filled(Shape.round, Color.red));
      expect(matrix.cellAt(0, 1), _filled(Shape.round, Color.red), reason: 'immuable');
    });
  });
}
