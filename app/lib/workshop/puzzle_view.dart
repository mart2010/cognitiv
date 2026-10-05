import 'package:flutter/material.dart';
import 'package:workshop/workshop.dart' as workshop;

import 'matrix_view.dart';

/// Une Énigme en mode « choix multiple » : Exemples, Question, puis les grilles-réponses.
/// L'évaluation passe par le Cas d'usage injecté ; la Famille de règle n'est révélée que
/// sur demande (bouton d'indice), car elle trahit la réponse (`docs/PLAN.md`).
class PuzzleView extends StatefulWidget {
  final workshop.WorkshopPuzzle puzzle;
  final workshop.EvaluateWorkshopAnswer evaluate;
  final void Function(bool isCorrect)? onAnswered;
  final VoidCallback onNext;

  const PuzzleView({
    super.key,
    required this.puzzle,
    required this.evaluate,
    required this.onNext,
    this.onAnswered,
  });

  @override
  State<PuzzleView> createState() => _PuzzleViewState();
}

class _PuzzleViewState extends State<PuzzleView> {
  int? _chosenIndex;
  bool? _wasCorrect;
  bool _hintShown = false;

  bool get _answered => _chosenIndex != null;

  void _choose(int index) {
    if (_answered) return;
    final evaluation = widget.evaluate(widget.puzzle, workshop.ChosenAnswer(index));
    setState(() {
      _chosenIndex = index;
      _wasCorrect = evaluation.isCorrect;
    });
    widget.onAnswered?.call(evaluation.isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = widget.puzzle;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Exemples', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final example in puzzle.examples)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MatrixView(matrix: example.input),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.arrow_forward)),
                MatrixView(matrix: example.output),
              ],
            ),
          ),
        const Divider(height: 32),
        Text('Nouveau cas à résoudre', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MatrixView(matrix: puzzle.question, cellSize: 36),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.arrow_forward)),
              _unknownAnswerPlaceholder(context, puzzle.question, 36),
            ],
          ),
        ),
        const Divider(height: 32),
        Text('Votre réponse', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            for (var i = 0; i < puzzle.answerChoices.length; i++) _choiceTile(context, i),
          ],
        ),
        const SizedBox(height: 16),
        if (_hintShown)
          Text(
            'Indice : ${puzzle.appliedRules.map((r) => r.family.name).join(', ')}',
            textAlign: TextAlign.center,
          )
        else
          TextButton(onPressed: () => setState(() => _hintShown = true), child: const Text('Indice')),
        if (_answered) ...[
          Text(
            _wasCorrect! ? 'Bravo !' : 'Raté.',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: widget.onNext, child: const Text('Suivant')),
        ],
      ],
    );
  }

  /// Case inconnue à droite de la flèche, à la place de la sortie attendue.
  /// Dimensionnée sur la Question (pas sur la vraie réponse) pour ne jamais
  /// trahir un changement de dimensions avant que les choix ne soient regardés.
  Widget _unknownAnswerPlaceholder(BuildContext context, workshop.Matrix sizeLike, double cellSize) {
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
          border: Border.all(color: borderColor, width: isChosen || (_answered && isCorrect) ? 3 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: MatrixView(matrix: widget.puzzle.answerChoices[index], cellSize: 32),
      ),
    );
  }
}
