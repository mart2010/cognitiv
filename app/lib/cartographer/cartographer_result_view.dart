import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:flutter/material.dart';

import 'cartographer_run.dart';
import 'link_labels.dart';

/// La fin d'une Partie : ce qui a été retenu, le Score, une suggestion de Niveau et, si le joueur
/// connaissait tout, une proposition d'autres genres de Lien. Aucun commentaire sur ce qu'il ne
/// savait pas : le Repérage est une manche de jeu, pas un examen.
class CartographerResultView extends StatefulWidget {
  final CartographerRun run;
  final VoidCallback onReplay;
  final VoidCallback onHome;

  /// Le joueur accepte d'ajouter ce genre de Lien à son Profil.
  final void Function(cartographer.LinkKind kind) onAcceptKind;

  const CartographerResultView({
    super.key,
    required this.run,
    required this.onReplay,
    required this.onHome,
    required this.onAcceptKind,
  });

  @override
  State<CartographerResultView> createState() => _CartographerResultViewState();
}

class _CartographerResultViewState extends State<CartographerResultView> {
  var _suggestionAnswered = false;
  var _accepted = false;

  CartographerRun get run => widget.run;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studied = run.history
        .where((p) => p.puzzle is cartographer.FlashStudy)
        .fold<int>(0, (sum, p) => sum + p.puzzle.questions.length);
    final nextLevel = run.level.number + 1;
    final previousLevel = run.level.number - 1;
    final levelHint = switch (run.result.suggestion) {
      cartographer.LevelSuggestion.raise => 'Vous pouvez essayer le niveau $nextLevel.',
      cartographer.LevelSuggestion.lower => 'Le niveau $previousLevel serait peut-être plus confortable.',
      cartographer.LevelSuggestion.keep => null,
    };
    final kind = run.suggestedKinds.isEmpty ? null : run.suggestedKinds.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${run.exactCount} sur ${run.outcomes.length}', key: const Key('result-count'), style: theme.textTheme.displaySmall),
                const SizedBox(height: 4),
                Text('réponses exactes', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 12),
                Text('Score : ${run.result.score}', key: const Key('result-score'), style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Text(
                  run.isTrayRun
                      ? [
                          for (var i = 0; i < run.trayResults.length; i++)
                            'Plateau ${i + 1} : ${run.trayResults[i].exact} sur ${run.trayResults[i].total}',
                        ].join('\n')
                      : run.missedAtScreening == 0
                      ? 'Vous connaissiez déjà tout ça !'
                      : (studied == 1 ? 'Vous avez étudié 1 pays.' : 'Vous avez étudié $studied pays.'),
                  key: const Key('result-summary'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                if (levelHint != null) ...[
                  const SizedBox(height: 8),
                  Text(levelHint, key: const Key('level-hint'), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                ],
                if (kind != null) ...[const SizedBox(height: 20), _suggestion(theme, kind)],
              ],
            ),
          ),
        ),
        FilledButton(key: const Key('replay'), onPressed: widget.onReplay, child: const Text('Rejouer')),
        const SizedBox(height: 8),
        TextButton(key: const Key('home'), onPressed: widget.onHome, child: const Text('Accueil')),
      ],
    );
  }

  Widget _suggestion(ThemeData theme, cartographer.LinkKind kind) {
    if (_suggestionAnswered) {
      return Text(
        _accepted ? 'Ajouté : ${linkKindLabel(kind).toLowerCase()}.' : 'Vous gardez vos réglages.',
        key: const Key('suggestion-answer'),
        style: theme.textTheme.bodyMedium,
        textAlign: TextAlign.center,
      );
    }
    return Card(
      key: const Key('suggestion'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Vous connaissez tout ça.', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Essayer aussi : ${linkKindLabel(kind).toLowerCase()} ?', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  key: const Key('suggest-stay'),
                  onPressed: () => setState(() {
                    _suggestionAnswered = true;
                    _accepted = false;
                  }),
                  child: const Text('Rester'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('suggest-accept'),
                  style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
                  onPressed: () {
                    widget.onAcceptKind(kind);
                    setState(() {
                      _suggestionAnswered = true;
                      _accepted = true;
                    });
                  },
                  child: const Text('Essayer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
