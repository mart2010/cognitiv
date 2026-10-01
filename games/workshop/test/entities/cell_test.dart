import 'package:test/test.dart';
import 'package:workshop/workshop.dart';

void main() {
  group('Cell', () {
    test('une Cellule remplie porte une Forme non vide et une Couleur', () {
      final cell = Cell.filled(Shape.round, Color.red);
      expect(cell.isEmpty, isFalse);
      expect(cell.shape, Shape.round);
      expect(cell.color, Color.red);
      expect(cell.emptyRole, isNull);
    });

    test('une Cellule vide porte un Rôle de case vide et aucune Couleur', () {
      final cell = Cell.empty(EmptyCellRole.active);
      expect(cell.isEmpty, isTrue);
      expect(cell.shape, Shape.empty);
      expect(cell.color, isNull);
      expect(cell.emptyRole, EmptyCellRole.active);
    });

    test('Cell.filled refuse Shape.empty', () {
      expect(() => Cell.filled(Shape.empty, Color.red), throwsArgumentError);
    });

    test('égalité par valeur', () {
      expect(Cell.filled(Shape.round, Color.red), Cell.filled(Shape.round, Color.red));
      expect(Cell.empty(EmptyCellRole.active), isNot(Cell.empty(EmptyCellRole.fixed)));
    });
  });
}
