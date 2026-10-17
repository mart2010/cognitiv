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
    final theme = Theme.of(context);
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section(
              context,
              'Exemples',
              Column(
                children: [
                  for (final example in puzzle.examples)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MatrixView(matrix: example.input),
                          _arrow(context),
                          MatrixView(matrix: example.output),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _section(
              context,
              'Nouveau cas à résoudre',
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MatrixView(matrix: puzzle.question, cellSize: 36),
                    _arrow(context),
                    _unknownAnswerPlaceholder(context, puzzle.question, 36),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _section(
              context,
              'Votre réponse',
              widget.mode == AnswerMode.multipleChoice
                  ? Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
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
            const SizedBox(height: 8),
            if (_hintShown)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Indice : ${puzzle.appliedRules.map((r) => r.family.name).join(', ')}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                ),
              )
            else
              TextButton(
                onPressed: () => setState(() => _hintShown = true),
                child: const Text('Indice'),
              ),
            if (_answered) _resultBanner(context),
          ],
        ),
        if (_wasCorrect == true) const Positioned.fill(child: SuccessCelebration()),
      ],
    );
  }

  Widget _section(BuildContext context, String title, Widget child) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.outline,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _arrow(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.outline),
  );

  /// Succès : bandeau qui surgit en grand, avec les confettis (`SuccessCelebration`).
  /// Échec : une ligne discrète, plus la réponse attendue en construction libre.
  Widget _resultBanner(BuildContext context) {
    final theme = Theme.of(context);
    final correct = _wasCorrect!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: Duration(milliseconds: correct ? 600 : 250),
      curve: correct ? Curves.elasticOut : Curves.easeOut,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Column(
        children: [
          Text(
            correct ? 'Bravo !' : 'Raté.',
            textAlign: TextAlign.center,
            style: correct
                ? theme.textTheme.displaySmall?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w700,
                  )
                : theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.outline),
          ),
          if (_constructed != null && !correct) ...[
            const SizedBox(height: 8),
            Text(
              'Réponse attendue',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Center(child: MatrixView(matrix: widget.puzzle.correctAnswer, cellSize: 32)),
          ],
          const SizedBox(height: 12),
          FilledButton(onPressed: widget.onNext, child: const Text('Suivant')),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: isChosen || (_answered && isCorrect) ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: MatrixView(matrix: widget.puzzle.answerChoices[index], cellSize: 32),
      ),
    );
  }
}
