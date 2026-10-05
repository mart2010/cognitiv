import 'dart:convert';

import 'package:test/test.dart';
import 'package:workshop/workshop.dart';

void main() {
  final matrix = Matrix([
    [Cell.filled(Shape.round, Color.red), Cell.empty(EmptyCellRole.active)],
    [Cell.empty(EmptyCellRole.fixed), Cell.filled(Shape.triangle, Color.green)],
  ]);

  test('aller-retour toJson/fromJson préserve la Matrice', () {
    final decoded = MatrixCodec.fromJson(matrix.toJson());
    expect(decoded, matrix);
  });

  test('la donnée produite est réellement compatible JSON (dart:convert)', () {
    final roundTripped = jsonDecode(jsonEncode(matrix.toJson())) as Map<String, dynamic>;
    expect(MatrixCodec.fromJson(roundTripped), matrix);
  });
}
