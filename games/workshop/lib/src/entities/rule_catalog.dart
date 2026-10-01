import 'color.dart';
import 'rule.dart';
import 'rule_family.dart';
import 'shape.dart';

/// Catalogue de règles : l'ensemble fini des Règles qu'un jeu connaît, groupées en
/// Familles ; le solveur ne cherche que dans ce catalogue (`games/workshop/CONTEXT.md`,
/// ADR 0001). Les Règles localisées (cycle sur une ligne ou une colonne précise) dépendent
/// des dimensions de la Matrice en cours : le catalogue reste fini pour toute Matrice
/// donnée, mais n'est pas une liste statique indépendante des dimensions — `rulesFor`
/// l'énumère pour des dimensions précises plutôt que de le figer une fois pour toutes.
class RuleCatalog {
  final List<Color> colorOrder;
  final List<Shape> shapeOrder;

  const RuleCatalog({
    this.colorOrder = Color.values,
    this.shapeOrder = const [Shape.round, Shape.square, Shape.triangle],
  });

  List<Rule> rulesFor({required int rowCount, required int columnCount}) => [
        const MirrorRule(MirrorAxis.horizontal),
        const MirrorRule(MirrorAxis.vertical),
        const RotationRule(RotationAngle.clockwise90),
        const RotationRule(RotationAngle.counterClockwise90),
        const RotationRule(RotationAngle.half180),
        const TranspositionRule(Diagonal.main),
        const TranspositionRule(Diagonal.secondary),
        const CyclicShiftRule(Axis.row, Direction.up),
        const CyclicShiftRule(Axis.row, Direction.down),
        const CyclicShiftRule(Axis.column, Direction.left),
        const CyclicShiftRule(Axis.column, Direction.right),
        const SlidingRule(Direction.up),
        const SlidingRule(Direction.down),
        const SlidingRule(Direction.left),
        const SlidingRule(Direction.right),
        const GravityRule(Direction.up),
        const GravityRule(Direction.down),
        const GravityRule(Direction.left),
        const GravityRule(Direction.right),
        ColorCycleRule(CycleScope.global, colorOrder),
        for (var r = 0; r < rowCount; r++) ColorCycleRule(CycleScope.singleRow, colorOrder, lineIndex: r),
        for (var c = 0; c < columnCount; c++)
          ColorCycleRule(CycleScope.singleColumn, colorOrder, lineIndex: c),
        ShapeCycleRule(CycleScope.global, shapeOrder),
        for (var r = 0; r < rowCount; r++) ShapeCycleRule(CycleScope.singleRow, shapeOrder, lineIndex: r),
        for (var c = 0; c < columnCount; c++)
          ShapeCycleRule(CycleScope.singleColumn, shapeOrder, lineIndex: c),
        for (final color in colorOrder)
          for (final shape in shapeOrder) ConditionalRule(color, shape),
      ];

  List<Rule> rulesInFamilies(
    Set<RuleFamily> families, {
    required int rowCount,
    required int columnCount,
  }) =>
      rulesFor(rowCount: rowCount, columnCount: columnCount)
          .where((rule) => families.contains(rule.family))
          .toList();
}
