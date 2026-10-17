import 'package:flutter/material.dart';
import 'package:workshop/workshop.dart' as workshop;

import 'matrix_view.dart';
import 'rule_labels.dart';
import 'workshop_services.dart';

/// Réglage du Profil de génération (ADR 0008) : quelles Familles de règles L'atelier peut
/// utiliser. Sert aussi de rappel visuel de ce que permet le catalogue : chaque Famille
/// montre un exemple avant / après sur une même grille.
class WorkshopRulesScreen extends StatelessWidget {
  final WorkshopServices services;

  const WorkshopRulesScreen({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    final controller = services.profileController;
    return Scaffold(
      appBar: AppBar(title: const Text('Règles de l’atelier')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final profile = controller.profile;
            final available = services.levelAvailability.availableLevels(profile);
            final onlyOne = profile.activeFamilies.length == 1;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Choisis les types de règles que la machine peut utiliser. '
                  'Les familles marquées « avancée » sont plus difficiles à deviner.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                for (final family in workshop.RuleFamily.values)
                  _FamilyTile(
                    family: family,
                    active: profile.isActive(family),
                    locked: onlyOne && profile.isActive(family),
                    onChanged: (value) => controller.setFamilyActive(family, value),
                  ),
                const SizedBox(height: 4),
                if (onlyOne)
                  Text(
                    'Au moins une famille doit rester active.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                _AvailabilityNote(availableCount: available.length),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      key: const Key('reset-profile'),
                      onPressed: controller.resetToDefaults,
                      child: const Text('Réglage par défaut'),
                    ),
                    OutlinedButton(
                      key: const Key('activate-all'),
                      onPressed: controller.activateAll,
                      child: const Text('Tout activer'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AvailabilityNote extends StatelessWidget {
  final int availableCount;

  const _AvailabilityNote({required this.availableCount});

  @override
  Widget build(BuildContext context) {
    final total = workshop.WorkshopLevels.all.length;
    final theme = Theme.of(context);
    final allAvailable = availableCount == total;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        allAvailable
            ? 'Tous les niveaux sont jouables.'
            : '$availableCount niveaux sur $total jouables avec ces règles. '
                  'Active d’autres familles pour débloquer les autres.',
        key: const Key('availability-note'),
        style: theme.textTheme.bodySmall?.copyWith(
          color: allAvailable ? theme.colorScheme.outline : theme.colorScheme.error,
        ),
      ),
    );
  }
}

class _FamilyTile extends StatelessWidget {
  final workshop.RuleFamily family;
  final bool active;
  final bool locked;
  final ValueChanged<bool> onChanged;

  const _FamilyTile({
    required this.family,
    required this.active,
    required this.locked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = labelOf(family);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            children: [
              Opacity(
                opacity: active ? 1 : 0.45,
                child: _FamilyPreview(family: family),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(label.name, style: theme.textTheme.titleMedium)),
                        if (label.advanced) ...[
                          const SizedBox(width: 8),
                          Text(
                            'avancée',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label.description,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
              Switch(
                key: Key('family-${family.name}'),
                value: active,
                onChanged: locked ? null : onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Exemple avant / après d'une Famille, sur une grille d'exemple commune : la première
/// Règle de la Famille qui change vraiment cette grille.
class _FamilyPreview extends StatelessWidget {
  final workshop.RuleFamily family;

  const _FamilyPreview({required this.family});

  static final workshop.Matrix sample = workshop.Matrix([
    [
      workshop.Cell.filled(workshop.Shape.round, workshop.Color.blue),
      workshop.Cell.filled(workshop.Shape.square, workshop.Color.yellow),
      workshop.Cell.filled(workshop.Shape.cross, workshop.Color.red),
    ],
    [
      workshop.Cell.filled(workshop.Shape.square, workshop.Color.red),
      workshop.Cell.empty(workshop.EmptyCellRole.active),
      workshop.Cell.filled(workshop.Shape.round, workshop.Color.blue),
    ],
    [
      workshop.Cell.filled(workshop.Shape.cross, workshop.Color.yellow),
      workshop.Cell.filled(workshop.Shape.round, workshop.Color.red),
      workshop.Cell.filled(workshop.Shape.square, workshop.Color.blue),
    ],
  ]);

  workshop.Matrix? _after() {
    final rules = const workshop.RuleCatalog().rulesInFamilies(
      {family},
      rowCount: sample.rowCount,
      columnCount: sample.columnCount,
    );
    for (final rule in rules) {
      final result = rule.apply(sample);
      if (result != sample) return result;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final after = _after();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MatrixView(matrix: sample, cellSize: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.arrow_forward, size: 14, color: Theme.of(context).colorScheme.outline),
        ),
        if (after != null) MatrixView(matrix: after, cellSize: 16) else const SizedBox(width: 48),
      ],
    );
  }
}
