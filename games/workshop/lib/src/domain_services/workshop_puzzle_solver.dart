import '../entities/matrix.dart';
import '../entities/rule.dart';
import '../entities/workshop_puzzle.dart';

/// Solveur de L'atelier : cherche, dans un catalogue de Règles fini donné, toutes les
/// combinaisons compatibles avec les Exemples d'une Énigme (`games/workshop/CONTEXT.md`,
/// ADR 0001). Service de domaine pur : aucune dépendance externe, aucun port — seulement
/// des Entités.
class WorkshopPuzzleSolver {
  List<List<Rule>> findConsistentCombos({
    required List<Rule> availableRules,
    required List<WorkshopExample> examples,
    required int maxRuleCount,
  }) {
    final consistent = <List<Rule>>[];
    for (var size = 1; size <= maxRuleCount; size++) {
      for (final combo in _combinationsOfSize(availableRules, size)) {
        if (_isConsistentWithExamples(combo, examples)) {
          consistent.add(combo);
        }
      }
    }
    return consistent;
  }

  bool isConsistentWithExamples(List<Rule> combo, List<WorkshopExample> examples) =>
      _isConsistentWithExamples(combo, examples);

  bool _isConsistentWithExamples(List<Rule> combo, List<WorkshopExample> examples) =>
      examples.every((example) => _applyCombo(combo, example.input) == example.output);

  Matrix _applyCombo(List<Rule> combo, Matrix input) =>
      combo.fold(input, (matrix, rule) => rule.apply(matrix));

  Iterable<List<Rule>> _combinationsOfSize(List<Rule> rules, int size) sync* {
    if (size == 0) {
      yield const [];
      return;
    }
    for (var i = 0; i <= rules.length - size; i++) {
      for (final rest in _combinationsOfSize(rules.sublist(i + 1), size - 1)) {
        yield [rules[i], ...rest];
      }
    }
  }
}
