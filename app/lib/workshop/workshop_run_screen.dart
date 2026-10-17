import 'package:flutter/material.dart';
import 'package:workshop/workshop.dart' as workshop;

import 'celebration.dart';
import 'puzzle_view.dart';
import 'workshop_services.dart';

/// Une Partie de L'atelier à un Niveau : enchaîne les Énigmes (générées dès le début),
/// puis montre le résultat et laisse le joueur monter, rejouer ou descendre. Quitter en
/// cours de route est un abandon : rien n'est enregistré et rien n'est pénalisé.
class WorkshopRunScreen extends StatefulWidget {
  final WorkshopServices services;
  final workshop.WorkshopLevel level;
  final AnswerMode mode;

  const WorkshopRunScreen({
    super.key,
    required this.services,
    required this.level,
    required this.mode,
  });

  @override
  State<WorkshopRunScreen> createState() => _WorkshopRunScreenState();
}

class _WorkshopRunScreenState extends State<WorkshopRunScreen> {
  static const _maxAttempts = 20;

  late final List<workshop.WorkshopPuzzle>? _puzzles = _generatePuzzles();
  final _evaluations = <workshop.AnswerEvaluation>[];
  var _index = 0;
  workshop.WorkshopScoreResult? _result;
  var _isNewBest = false;

  List<workshop.WorkshopPuzzle>? _generatePuzzles() {
    final request = workshop.GenerateWorkshopPuzzleRequest.forLevel(
      widget.level,
      profile: widget.services.profile,
    );
    final puzzles = <workshop.WorkshopPuzzle>[];
    while (puzzles.length < widget.level.puzzleCount) {
      workshop.WorkshopPuzzle? puzzle;
      for (var attempt = 0; attempt < _maxAttempts && puzzle == null; attempt++) {
        final result = widget.services.generate(request);
        if (result is workshop.GenerationSucceeded) puzzle = result.puzzle;
      }
      if (puzzle == null) return null;
      puzzles.add(puzzle);
    }
    return puzzles;
  }

  void _onAnswered(bool isCorrect) => _evaluations.add(workshop.AnswerEvaluation(isCorrect));

  void _next() {
    if (_index + 1 < widget.level.puzzleCount) {
      setState(() => _index++);
      return;
    }
    final result = widget.services.computeScore(_evaluations, level: widget.level);
    final previousBest = widget.services.progress.progress.bestScore(widget.level.number);
    widget.services.progress.recordRun(
      level: widget.level.number,
      score: result.score,
      cleared: result.levelCleared,
    );
    setState(() {
      _result = result;
      _isNewBest = previousBest == null || result.score > previousBest;
    });
  }

  /// Rejoue ou change de Niveau en remplaçant l'écran, pour que « retour » ramène à l'accueil.
  void _goToLevel(workshop.WorkshopLevel level) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            WorkshopRunScreen(services: widget.services, level: level, mode: widget.mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puzzles = _puzzles;
    final result = _result;
    return Scaffold(
      appBar: AppBar(
        title: Text('Niveau ${widget.level.number}'),
        actions: [
          if (puzzles != null && result == null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_index + 1} / ${widget.level.puzzleCount}',
                  key: const Key('run-progress'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: puzzles == null
            ? const Center(child: Text('Impossible de générer une énigme à ce niveau.'))
            : result != null
            ? _RunResultView(
                level: widget.level,
                result: result,
                correctCount: _evaluations.where((e) => e.isCorrect).length,
                isNewBest: _isNewBest,
                onGoToLevel: _goToLevel,
                onExit: () => Navigator.of(context).pop(),
              )
            : PuzzleView(
                key: ValueKey(_index),
                puzzle: puzzles[_index],
                evaluate: widget.services.evaluate,
                mode: widget.mode,
                sounds: widget.services.sounds,
                onAnswered: _onAnswered,
                onNext: _next,
              ),
      ),
    );
  }
}

class _RunResultView extends StatelessWidget {
  final workshop.WorkshopLevel level;
  final workshop.WorkshopScoreResult result;
  final int correctCount;
  final bool isNewBest;
  final void Function(workshop.WorkshopLevel level) onGoToLevel;
  final VoidCallback onExit;

  const _RunResultView({
    required this.level,
    required this.result,
    required this.correctCount,
    required this.isNewBest,
    required this.onGoToLevel,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestion = result.suggestion;
    final hasNext = workshop.WorkshopLevels.hasNext(level);
    final hasPrevious = workshop.WorkshopLevels.hasPrevious(level);

    Widget action(String key, String label, VoidCallback onPressed, {required bool highlighted}) {
      final style = ButtonStyle(minimumSize: WidgetStateProperty.all(const Size(260, 48)));
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: highlighted
            ? FilledButton(key: Key(key), onPressed: onPressed, style: style, child: Text(label))
            : OutlinedButton(key: Key(key), onPressed: onPressed, style: style, child: Text(label)),
      );
    }

    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  result.levelCleared ? 'Niveau franchi !' : 'Pas encore franchi',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: result.levelCleared ? Colors.green.shade700 : theme.colorScheme.outline,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${result.score} points',
                  key: const Key('run-score'),
                  style: theme.textTheme.displaySmall,
                ),
                Text(
                  '$correctCount bonnes réponses sur ${level.puzzleCount}',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline),
                ),
                if (isNewBest)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Nouveau record !', style: theme.textTheme.titleMedium),
                  ),
                const SizedBox(height: 16),
                if (hasNext)
                  action(
                    'go-up',
                    'Niveau supérieur (${level.number + 1})',
                    () => onGoToLevel(workshop.WorkshopLevels.next(level)),
                    highlighted: suggestion == workshop.LevelSuggestion.raise,
                  ),
                action(
                  'replay',
                  'Rejouer le niveau ${level.number}',
                  () => onGoToLevel(level),
                  highlighted: suggestion == workshop.LevelSuggestion.keep,
                ),
                if (hasPrevious)
                  action(
                    'go-down',
                    'Niveau inférieur (${level.number - 1})',
                    () => onGoToLevel(workshop.WorkshopLevels.previous(level)),
                    highlighted: suggestion == workshop.LevelSuggestion.lower,
                  ),
                TextButton(
                  key: const Key('exit'),
                  onPressed: onExit,
                  child: const Text('Retour aux niveaux'),
                ),
              ],
            ),
          ),
        ),
        if (result.levelCleared) const Positioned.fill(child: SuccessCelebration()),
      ],
    );
  }
}
