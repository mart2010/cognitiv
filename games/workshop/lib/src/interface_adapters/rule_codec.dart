import '../entities/color.dart';
import '../entities/rule.dart';
import '../entities/rule_family.dart';
import '../entities/shape.dart';

/// Traduit une Règle vers une donnée sérialisable, avec `family` comme discriminant.
/// Le `switch` exhaustif sur la hiérarchie scellée de `Rule` fait que l'ajout d'une
/// nouvelle sous-classe (une nouvelle Famille) sans mettre ce codec à jour est une erreur
/// de compilation, pas un oubli silencieux découvert en test.
extension RuleJsonEncoding on Rule {
  Map<String, dynamic> toJson() => switch (this) {
        MirrorRule(axis: final axis) => {'family': 'mirror', 'axis': axis.name},
        RotationRule(angle: final angle) => {'family': 'rotation', 'angle': angle.name},
        TranspositionRule(diagonal: final diagonal) => {
            'family': 'transposition',
            'diagonal': diagonal.name,
          },
        CyclicShiftRule(axis: final axis, direction: final direction, steps: final steps) => {
            'family': 'cyclicShift',
            'axis': axis.name,
            'direction': direction.name,
            'steps': steps,
          },
        SlidingRule(direction: final direction) => {'family': 'sliding', 'direction': direction.name},
        PackingRule(direction: final direction) => {'family': 'packing', 'direction': direction.name},
        ColorCycleRule(scope: final scope, order: final order, lineIndex: final lineIndex, steps: final steps) => {
            'family': 'colorCycle',
            'scope': scope.name,
            'order': [for (final color in order) color.name],
            'lineIndex': lineIndex,
            'steps': steps,
          },
        ShapeCycleRule(scope: final scope, order: final order, lineIndex: final lineIndex, steps: final steps) => {
            'family': 'shapeCycle',
            'scope': scope.name,
            'order': [for (final shape in order) shape.name],
            'lineIndex': lineIndex,
            'steps': steps,
          },
        ConditionalRule(triggerColor: final triggerColor, resultShape: final resultShape) => {
            'family': 'conditional',
            'triggerColor': triggerColor.name,
            'resultShape': resultShape.name,
          },
      };
}

class RuleCodec {
  static Rule fromJson(Map<String, dynamic> json) {
    final family = RuleFamily.values.byName(json['family'] as String);
    return switch (family) {
      RuleFamily.mirror => MirrorRule(MirrorAxis.values.byName(json['axis'] as String)),
      RuleFamily.rotation => RotationRule(RotationAngle.values.byName(json['angle'] as String)),
      RuleFamily.transposition => TranspositionRule(Diagonal.values.byName(json['diagonal'] as String)),
      RuleFamily.cyclicShift => CyclicShiftRule(
          Axis.values.byName(json['axis'] as String),
          Direction.values.byName(json['direction'] as String),
          steps: json['steps'] as int,
        ),
      RuleFamily.sliding => SlidingRule(Direction.values.byName(json['direction'] as String)),
      RuleFamily.packing => PackingRule(Direction.values.byName(json['direction'] as String)),
      RuleFamily.colorCycle => ColorCycleRule(
          CycleScope.values.byName(json['scope'] as String),
          [for (final name in json['order'] as List) Color.values.byName(name as String)],
          lineIndex: json['lineIndex'] as int?,
          steps: json['steps'] as int,
        ),
      RuleFamily.shapeCycle => ShapeCycleRule(
          CycleScope.values.byName(json['scope'] as String),
          [for (final name in json['order'] as List) Shape.values.byName(name as String)],
          lineIndex: json['lineIndex'] as int?,
          steps: json['steps'] as int,
        ),
      RuleFamily.conditional => ConditionalRule(
          Color.values.byName(json['triggerColor'] as String),
          Shape.values.byName(json['resultShape'] as String),
        ),
    };
  }
}
