import 'dart:convert';

import 'package:test/test.dart';
import 'package:workshop/workshop.dart';

void main() {
  final rules = <Rule>[
    const MirrorRule(MirrorAxis.horizontal),
    const RotationRule(RotationAngle.half180),
    const TranspositionRule(Diagonal.secondary),
    const CyclicShiftRule(Axis.row, Direction.down, steps: 2),
    const SlidingRule(Direction.left),
    const PackingRule(Direction.up),
    ColorCycleRule(CycleScope.singleRow, const [Color.red, Color.blue], lineIndex: 1, steps: 2),
    ShapeCycleRule(CycleScope.global, const [Shape.round, Shape.square, Shape.cross]),
    const ConditionalRule(Color.green, Shape.cross),
  ];

  for (final rule in rules) {
    test('aller-retour JSON préserve ${rule.family.name}', () {
      final roundTripped = jsonDecode(jsonEncode(rule.toJson())) as Map<String, dynamic>;
      expect(RuleCodec.fromJson(roundTripped), rule);
    });
  }
}
