import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workshop/workshop.dart' as workshop;

import '../audio/game_sounds.dart';
import 'celebration.dart';
import 'construct_answer_view.dart';
import 'matrix_view.dart';

/// Mode de réponse (`docs/PLAN.md`) : choisir parmi 4 grilles, ou construire la grille.
enum AnswerMode { multipleChoice, freeConstruction }

/// Une Énigme : Exemples, Question, puis, selon le mode, les grilles-réponses à choisir
/// ou une grille vide à construire.
/// L'évaluation passe par le Cas d'usage injecté ; la Famille de règle n'est révélée que
/// sur demande (bouton d'indice), car elle trahit la réponse (`docs/PLAN.md`).
class PuzzleView extends StatefulWidget {
  final workshop.WorkshopPuzzle puzzle;
  final workshop.EvaluateWorkshopAnswer evaluate;
  final void Function(bool isCorrect)? onAnswered;
  final VoidCallback onNext;
  final AnswerMode mode;
  final GameSounds sounds;

  const PuzzleView({
    super.key,
    required this.puzzle,
    required this.evaluate,
    required this.onNext,
    this.mode = AnswerMode.multipleChoice,
    this.sounds = const SilentGameSounds(),
    this.onAnswered,
  });

  @override
  State<PuzzleView> createState() => _PuzzleViewState();
}

class _PuzzleViewState extends State<PuzzleView> {
  int? _chosenIndex;
  workshop.Matrix? _constructed;
  bool? _wasCorrect;
  bool _hintShown = false;

  bool get _answered => _wasCorrect != null;

  void _choose(int index) {
    if (_answered) return;
    widget.sounds.tap();
    final evaluation = widget.evaluate(widget.puzzle, workshop.ChosenAnswer(index));
    setState(() {
      _chosenIndex = index;
      _wasCorrect = evaluation.isCorrect;
    });
    _giveFeedback(evaluation.isCorrect);
    widget.onAnswered?.call(evaluation.isCorrect);
  }

  /// Sobre quand c'est raté, fort quand c'est réussi (`docs/PLAN.md`).
  void _giveFeedback(bool isCorrect) {
    if (isCorrect) {
      widget.sounds.success();
      HapticFeedback.heavyImpact();
    } else {
      widget.sounds.failure();
      HapticFeedback.lightImpact();
    }
  }

  void _submitConstruction(workshop.Matrix answer) {
    if (_answered) return;
    final evaluation = widget.evaluate(widget.puzzle, workshop.ConstructedAnswer(answer));
    setState(() {
      _constructed = answer;
      _wasCorrect = evaluation.isCorrect;
    });
    _giveFeedback(evaluation.isCorrect);
    widget.onAnswered?.call(evaluation.isCorrect);
  }

  /// Les Rôles de case vide sont uniques dans une Énigme (`GenerateWorkshopPuzzle`) : on
  /// reprend celui des vides visibles, Fixe par défaut s'il n'y en a aucun (il ne
  /// compte alors pas, la réponse n'en contenant pas non plus).
  workshop.EmptyCellRole get _emptyRole {
    for (final matrix in [
      widget.puzzle.question,
      for (final e in widget.puzzle.examples) e.input,
    ]) {
      for (var r = 0; r < matrix.rowCount; r++) {
        for (var c = 0; c < matrix.columnCount; c++) {
          final role = matrix.cellAt(r, c).emptyRole;
          if (role != null) return role;
        }
      }
    }
    return workshop.EmptyCellRole.fixed;
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = widget.puzzle;
    // Tout tient à l'écran sans défilement : le contenu des cartes est réduit au besoin
    // (FittedBox) plutôt que scrollé, et la barre du bas reste toujours visible.
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _section(
                              context,
                              'Exemples',
                              Column(
                                children: [
                                  for (final example in puzzle.examples)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          MatrixView(
                                            matrix: example.input,
                                            cellSize: _exampleCell(example.input),
                                          ),
                                          _arrow(context),
                                          MatrixView(
                                            matrix: example.output,
                                            cellSize: _exampleCell(example.output),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            _section(
                              context,
                              'Énigme',
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  MatrixView(
                                    matrix: puzzle.question,
                                    cellSize: _questionCell(puzzle.question),
                                  ),
                                  _arrow(context),
                                  _unknownAnswerPlaceholder(
                                    context,
                                    puzzle.question,
                                    _questionCell(puzzle.question),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            _section(
                              context,
                              widget.mode == AnswerMode.multipleChoice ? 'Réponse' : null,
                              widget.mode == AnswerMode.multipleChoice
                                  ? Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        for (var i = 0; i < puzzle.answerChoices.length; i++)
                                          _choiceTile(context, i),
                                      ],
                                    )
                                  : ConstructAnswerView(
                                      rowCount: puzzle.question.rowCount,
                                      columnCount: puzzle.question.columnCount,
                                      emptyRole: _emptyRole,
                                      enabled: !_answered,
                                      sounds: widget.sounds,
                                      onSubmit: _submitConstruction,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _bottomBar(context),
          ],
        ),
        if (_wasCorrect == true) const Positioned.fill(child: SuccessCelebration()),
      ],
    );
  }

  /// Barre fixe du bas : indice à la demande, puis le résultat avec « Suivant » une fois
  /// la réponse donnée.
  Widget _bottomBar(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 112,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_hintShown)
              Text(
                'Indice : ${widget.puzzle.appliedRules.map((r) => r.family.name).join(', ')}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              )
            else if (!_answered)
              TextButton(
                onPressed: () => setState(() => _hintShown = true),
                child: const Text('Indice'),
              ),
            if (_answered) FittedBox(fit: BoxFit.scaleDown, child: _resultBanner(context)),
          ],
        ),
      ),
    );
  }

  /// Titre à la verticale à gauche du contenu, pour gagner de la hauteur.
  Widget _section(BuildContext context, String? title, Widget child) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.fromLTRB(title == null ? 14 : 6, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (title != null)
              SizedBox(
                width: 24,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.outline,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            Expanded(child: Center(child: child)),
          ],
        ),
      ),
    );
  }

  Widget _arrow(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.outline),
  );

  /// Succès : « Bravo ! » en grand avec un rebond, plus les confettis
  /// (`SuccessCelebration`). Échec : sobre, avec la réponse attendue en construction libre.
  Widget _resultBanner(BuildContext context) {
    final theme = Theme.of(context);
    final correct = _wasCorrect!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: Duration(milliseconds: correct ? 600 : 250),
      curve: correct ? Curves.elasticOut : Curves.easeOut,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            correct ? 'Bravo !' : 'Raté.',
            style: correct
                ? theme.textTheme.displaySmall?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w700,
                  )
                : theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.outline),
          ),
          if (_constructed != null && !correct) ...[
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Réponse attendue', style: theme.textTheme.labelSmall),
                const SizedBox(height: 4),
                MatrixView(matrix: widget.puzzle.correctAnswer, cellSize: 20),
              ],
            ),
          ],
          const SizedBox(width: 16),
          FilledButton(
            onPressed: widget.onNext,
            style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
            child: const Text('Suivant'),
          ),
        ],
      ),
    );
  }

  /// Taille de case réduite pour que les grandes Matrices (jusqu'à 4×5) tiennent dans la
  /// largeur et la hauteur disponibles ; les petites gardent la taille de base.
  double _fit(double base, workshop.Matrix m, double maxWidth, double maxHeight) {
    final fitted = [
      base,
      maxWidth / m.columnCount,
      maxHeight / m.rowCount,
    ].reduce((a, b) => a < b ? a : b);
    return fitted.floorToDouble();
  }

  double _exampleCell(workshop.Matrix m) => _fit(28, m, 136, 110);
  double _questionCell(workshop.Matrix m) => _fit(36, m, 136, 120);

  /// Case inconnue à droite de la flèche, à la place de la sortie attendue.
  /// Dimensionnée sur la Question (pas sur la vraie réponse) pour ne jamais
  /// trahir un changement de dimensions avant que les choix ne soient regardés.
  Widget _unknownAnswerPlaceholder(
    BuildContext context,
    workshop.Matrix sizeLike,
    double cellSize,
  ) {
    final outline = Theme.of(context).colorScheme.outline;
    return Container(
      width: sizeLike.columnCount * cellSize,
      height: sizeLike.rowCount * cellSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: outline, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('?', style: Theme.of(context).textTheme.headlineMedium),
    );
  }

  Widget _choiceTile(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    final isChosen = _chosenIndex == index;
    final isCorrect = widget.puzzle.correctAnswerIndex == index;
    final borderColor = !_answered
        ? scheme.outlineVariant
        : isCorrect
        ? Colors.green
        : isChosen
        ? scheme.error
        : scheme.outlineVariant;
    return InkWell(
      key: Key('choice-$index'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => _choose(index),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: isChosen || (_answered && isCorrect) ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: MatrixView(
          matrix: widget.puzzle.answerChoices[index],
          cellSize: _fit(30, widget.puzzle.answerChoices[index], 130, 100),
        ),
      ),
    );
  }
}
