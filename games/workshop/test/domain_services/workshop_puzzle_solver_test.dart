import 'package:test/test.dart';
import 'package:workshop/workshop.dart';

Cell _f(Shape shape, Color color) => Cell.filled(shape, color);

void main() {
  final input = Matrix([
    [_f(Shape.round, Color.red), _f(Shape.square, Color.blue)],
    [_f(Shape.triangle, Color.green), _f(Shape.round, Color.yellow)],
  ]);
  final solver = WorkshopPuzzleSolver();

  test('trouve toutes les combinaisons compatibles avec les exemples', () {
    const horizontal = MirrorRule(MirrorAxis.horizontal);
    const vertical = MirrorRule(MirrorAxis.vertical);
    final example = WorkshopExample(input, horizontal.apply(input));

    final combos = solver.findConsistentCombos(
      availableRules: const [horizontal, vertical],
      examples: [example],
      maxRuleCount: 1,
    );

    expect(combos, hasLength(1));
    expect(combos.first, [horizontal]);
  });

  test('une règle qui échoue sur un exemple est écartée', () {
    const horizontal = MirrorRule(MirrorAxis.horizontal);
    const vertical = MirrorRule(MirrorAxis.vertical);
    final example = WorkshopExample(input, horizontal.apply(input));

    expect(solver.isConsistentWithExamples([vertical], [example]), isFalse);
    expect(solver.isConsistentWithExamples([horizontal], [example]), isTrue);
  });

  test('explore les combinaisons de plusieurs règles', () {
    const horizontal = MirrorRule(MirrorAxis.horizontal);
    const vertical = MirrorRule(MirrorAxis.vertical);
    final output = vertical.apply(horizontal.apply(input));
    final example = WorkshopExample(input, output);

    final combos = solver.findConsistentCombos(
      availableRules: const [horizontal, vertical],
      examples: [example],
      maxRuleCount: 2,
    );

    expect(combos.any((c) => c.length == 2 && c[0] == horizontal && c[1] == vertical), isTrue);
  });
}
