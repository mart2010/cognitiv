import '../domain_services/workshop_puzzle_solver.dart';
import '../entities/cell.dart';
import '../entities/color.dart';
import '../entities/empty_cell_role.dart';
import '../entities/generation_profile.dart';
import '../entities/matrix.dart';
import '../entities/rule.dart';
import '../entities/rule_catalog.dart';
import '../entities/rule_family.dart';
import '../entities/shape.dart';
import '../entities/workshop_puzzle.dart';
import 'ports/random_source.dart';

/// Entrée de `GenerateWorkshopPuzzle` : les dimensions et la complexité visées par le
/// Niveau (`platform/CONTEXT.md`), et le Profil de génération du joueur (ADR 0008).
class GenerateWorkshopPuzzleRequest {
  final int rowCount;
  final int columnCount;
  final int ruleCount;
  final int exampleCount;
  final GenerationProfile profile;
  final int choiceCount;

  const GenerateWorkshopPuzzleRequest({
    required this.rowCount,
    required this.columnCount,
    required this.ruleCount,
    required this.exampleCount,
    required this.profile,
    this.choiceCount = 4,
  });
}

sealed class GenerationResult {
  const GenerationResult();
}

final class GenerationSucceeded extends GenerationResult {
  final WorkshopPuzzle puzzle;
  const GenerationSucceeded(this.puzzle);
}

/// Échec propre de la génération (ADR 0008) : le combo Niveau × Profil de génération
/// était insuffisant pour produire une Énigme juste, plutôt que d'en livrer une injuste.
final class GenerationFailed extends GenerationResult {
  final String reason;
  const GenerationFailed(this.reason);
}

/// Cas d'usage « préparer les énigmes d'un niveau » du contrat jeu/plateforme
/// (ADR 0004), pour L'atelier. Orchestre le Catalogue de règles et le Solveur ; le hasard
/// passe toujours par le port `RandomSource` (ADR 0005), jamais par `dart:math` direct.
///
/// Les probabilités de case vide ci-dessous sont un premier jet, à équilibrer avec le
/// jeu réel plutôt qu'une vraie décision de conception.
class GenerateWorkshopPuzzle {
  static const double _emptyCellProbability = 0.15;
  static const double _activeRoleProbability = 0.5;
  static const int _maxEffectAttempts = 50;

  final RuleCatalog catalog;
  final RandomSource random;
  final WorkshopPuzzleSolver solver;

  GenerateWorkshopPuzzle({
    required this.catalog,
    required this.random,
    WorkshopPuzzleSolver? solver,
  }) : solver = solver ?? WorkshopPuzzleSolver();

  GenerationResult call(GenerateWorkshopPuzzleRequest request) {
    final availableRules = catalog.rulesInFamilies(
      request.profile.activeFamilies,
      rowCount: request.rowCount,
      columnCount: request.columnCount,
    );

    final combo = _pickRandomCombo(availableRules, request.ruleCount);
    if (combo == null) {
      return GenerationFailed(
        'Profil de génération actif insuffisant pour combiner ${request.ruleCount} '
        'règle(s) distincte(s) sur une matrice ${request.rowCount}x${request.columnCount}.',
      );
    }

    final emptyRole = _pickEmptyRole(combo);
    final examples = <WorkshopExample>[];
    for (var i = 0; i < request.exampleCount; i++) {
      final input = _randomMatrixWithEffect(combo, request, emptyRole);
      if (input == null) return _noEffectFailure(request);
      examples.add(WorkshopExample(input, combo.applyTo(input)));
    }
    final question = _randomMatrixWithEffect(combo, request, emptyRole);
    if (question == null) return _noEffectFailure(request);
    final correctAnswer = combo.applyTo(question);

    final consistentCombos = solver.findConsistentCombos(
      availableRules: availableRules,
      examples: examples,
      maxRuleCount: request.ruleCount,
    );
    final allAgreeOnQuestion = consistentCombos.every((c) => c.applyTo(question) == correctAnswer);
    if (!allAgreeOnQuestion) {
      return const GenerationFailed(
        'Énigme ambiguë : plusieurs règles plausibles sont compatibles avec les exemples '
        'mais désaccordent sur la réponse à la question (ADR 0001).',
      );
    }

    final distractors = _generateDistractors(
      availableRules: availableRules,
      consistentCombos: consistentCombos,
      examples: examples,
      question: question,
      correctAnswer: correctAnswer,
      count: request.choiceCount - 1,
    );

    final choices = [...distractors, correctAnswer];
    _shuffleInPlace(choices);

    return GenerationSucceeded(WorkshopPuzzle(
      examples: examples,
      question: question,
      answerChoices: choices,
      correctAnswerIndex: choices.indexOf(correctAnswer),
      appliedRules: combo,
    ));
  }

  List<Rule>? _pickRandomCombo(List<Rule> availableRules, int ruleCount) {
    if (availableRules.length < ruleCount) return null;
    final pool = List<Rule>.from(availableRules);
    final combo = <Rule>[];
    for (var i = 0; i < ruleCount; i++) {
      combo.add(pool.removeAt(random.nextInt(pool.length)));
    }
    return combo;
  }

  bool _dependsOnActiveEmptyCells(Rule rule) =>
      rule.family == RuleFamily.sliding || rule.family == RuleFamily.gravity;

  /// Sans case vide Active dans la Question, la Gravité et le Taquin n'ont aucun effet :
  /// la bonne réponse serait identique à la Question. On en force donc au moins une.
  Matrix _withActiveEmptyCell(Matrix matrix) {
    for (var r = 0; r < matrix.rowCount; r++) {
      for (var c = 0; c < matrix.columnCount; c++) {
        if (matrix.cellAt(r, c).emptyRole == EmptyCellRole.active) return matrix;
      }
    }
    return matrix.withCell(
      random.nextInt(matrix.rowCount),
      random.nextInt(matrix.columnCount),
      Cell.empty(EmptyCellRole.active),
    );
  }

  /// Un seul Rôle de case vide par Énigme (Exemples et Question), jamais un mélange : en
  /// construction libre, deux Rôles au rendu identique laisseraient le joueur remplir une
  /// case Fixe comme une Active sans s'être trompé sur la Règle (`docs/PLAN.md`). La
  /// Gravité et le Taquin n'agissent que sur des cases Actives, donc ils l'imposent ;
  /// sinon, tirage au sort.
  EmptyCellRole _pickEmptyRole(List<Rule> combo) {
    if (combo.any(_dependsOnActiveEmptyCells)) return EmptyCellRole.active;
    return random.nextDouble() < _activeRoleProbability ? EmptyCellRole.active : EmptyCellRole.fixed;
  }

  /// Tire une Matrice sur laquelle la combinaison de Règles a un effet visible : une
  /// transformation sans effet (réponse identique à l'entrée) rendrait l'Exemple ou la
  /// Question peu parlants. Si la combinaison dépend des cases vides Actives, on en force
  /// au moins une. Renvoie null si aucun tirage n'y parvient dans la limite d'essais.
  Matrix? _randomMatrixWithEffect(
    List<Rule> combo,
    GenerateWorkshopPuzzleRequest request,
    EmptyCellRole emptyRole,
  ) {
    for (var attempt = 0; attempt < _maxEffectAttempts; attempt++) {
      var matrix = _randomMatrix(request.rowCount, request.columnCount, emptyRole);
      if (combo.any(_dependsOnActiveEmptyCells)) matrix = _withActiveEmptyCell(matrix);
      if (combo.applyTo(matrix) != matrix) return matrix;
    }
    return null;
  }

  GenerationFailed _noEffectFailure(GenerateWorkshopPuzzleRequest request) => GenerationFailed(
        'Aucune matrice ${request.rowCount}x${request.columnCount} tirée sur laquelle la '
        'combinaison de règles ait un effet visible.',
      );

  Matrix _randomMatrix(int rowCount, int columnCount, EmptyCellRole emptyRole) {
    final shapes = Shape.values.where((s) => s != Shape.empty).toList();
    final colors = Color.values;
    return Matrix.generate(rowCount, columnCount, (r, c) {
      if (random.nextDouble() < _emptyCellProbability) {
        return Cell.empty(emptyRole);
      }
      return Cell.filled(shapes[random.nextInt(shapes.length)], colors[random.nextInt(colors.length)]);
    });
  }

  /// Chaque mauvaise réponse vient d'une règle plausible qui échoue sur au moins un
  /// exemple (ADR 0001) ; les candidates qui ne gardent pas les dimensions de la bonne
  /// réponse sont écartées (piège de conception identifié dans `docs/PLAN.md`). Si le
  /// catalogue actif n'en fournit pas assez, on complète par une mutation locale de la
  /// bonne réponse (toujours aux mêmes dimensions).
  List<Matrix> _generateDistractors({
    required List<Rule> availableRules,
    required List<List<Rule>> consistentCombos,
    required List<WorkshopExample> examples,
    required Matrix question,
    required Matrix correctAnswer,
    required int count,
  }) {
    final candidates = <Matrix>[];

    for (final rule in availableRules) {
      if (candidates.length >= count) break;
      final isConsistentAlone = consistentCombos.any((c) => c.length == 1 && c.first == rule);
      if (isConsistentAlone) continue;
      final failsAnExample = examples.any((example) => rule.apply(example.input) != example.output);
      if (!failsAnExample) continue;

      final candidate = rule.apply(question);
      final sameDimensions =
          candidate.rowCount == correctAnswer.rowCount && candidate.columnCount == correctAnswer.columnCount;
      if (sameDimensions && candidate != correctAnswer && !candidates.contains(candidate)) {
        candidates.add(candidate);
      }
    }

    var mutationAttempts = 0;
    while (candidates.length < count && mutationAttempts < 50) {
      mutationAttempts++;
      final mutated = _mutateOneCell(correctAnswer);
      if (mutated != correctAnswer && !candidates.contains(mutated)) {
        candidates.add(mutated);
      }
    }

    return candidates.take(count).toList();
  }

  Matrix _mutateOneCell(Matrix source) {
    final row = random.nextInt(source.rowCount);
    final column = random.nextInt(source.columnCount);
    final shapes = Shape.values.where((s) => s != Shape.empty).toList();
    final colors = Color.values;
    final newCell = Cell.filled(shapes[random.nextInt(shapes.length)], colors[random.nextInt(colors.length)]);
    return source.withCell(row, column, newCell);
  }

  void _shuffleInPlace<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}
