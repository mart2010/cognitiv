import 'package:flutter/material.dart';
import 'package:workshop/workshop.dart' as workshop;

import 'puzzle_view.dart';
import 'workshop_run_screen.dart';
import 'workshop_services.dart';

/// Accueil de L'atelier : le mode de réponse et la liste des Niveaux, tous accessibles.
/// Le joueur choisit librement sa difficulté ; le Niveau suggéré est seulement mis en avant.
class WorkshopHomeScreen extends StatefulWidget {
  final WorkshopServices services;

  const WorkshopHomeScreen({super.key, required this.services});

  @override
  State<WorkshopHomeScreen> createState() => _WorkshopHomeScreenState();
}

class _WorkshopHomeScreenState extends State<WorkshopHomeScreen> {
  var _mode = AnswerMode.multipleChoice;

  @override
  void initState() {
    super.initState();
    widget.services.progress.load();
  }

  void _play(workshop.WorkshopLevel level) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkshopRunScreen(services: widget.services, level: level, mode: _mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("L'atelier de transformations")),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.services.progress,
          builder: (context, _) {
            final progress = widget.services.progress.progress;
            final suggested = progress.suggestedLevel(workshop.WorkshopLevels.last.number);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<AnswerMode>(
                  key: const Key('answer-mode'),
                  segments: const [
                    ButtonSegment(
                      value: AnswerMode.multipleChoice,
                      label: Text('Choix multiple'),
                      icon: Icon(Icons.grid_view),
                    ),
                    ButtonSegment(
                      value: AnswerMode.freeConstruction,
                      label: Text('Construction'),
                      icon: Icon(Icons.edit),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) => setState(() => _mode = selection.first),
                ),
                const SizedBox(height: 16),
                for (final level in workshop.WorkshopLevels.all)
                  _LevelTile(
                    level: level,
                    cleared: progress.isCleared(level.number),
                    bestScore: progress.bestScore(level.number),
                    suggested: level.number == suggested,
                    onTap: () => _play(level),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final workshop.WorkshopLevel level;
  final bool cleared;
  final int? bestScore;
  final bool suggested;
  final VoidCallback onTap;

  const _LevelTile({
    required this.level,
    required this.cleared,
    required this.bestScore,
    required this.suggested,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rules = level.ruleCount == 1 ? '1 règle' : '${level.ruleCount} règles';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: suggested ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.5),
            width: suggested ? 2 : 1,
          ),
        ),
        child: InkWell(
          key: Key('level-${level.number}'),
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: cleared ? Colors.green.shade600 : scheme.surfaceContainerHighest,
                  foregroundColor: cleared ? Colors.white : scheme.onSurface,
                  child: cleared ? const Icon(Icons.check) : Text('${level.number}'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Niveau ${level.number}', style: theme.textTheme.titleMedium),
                          if (suggested) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Suggéré',
                              style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${level.rowCount}×${level.columnCount} · $rules · ${level.exampleCount} exemples',
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
                      ),
                    ],
                  ),
                ),
                if (bestScore != null)
                  Text(
                    '$bestScore / ${level.maxScore}',
                    key: Key('best-${level.number}'),
                    style: theme.textTheme.labelLarge,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
