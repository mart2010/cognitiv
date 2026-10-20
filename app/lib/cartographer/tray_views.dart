import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:flutter/material.dart';

import '../audio/game_sounds.dart';
import 'cartographer_map_view.dart';
import 'verdict_colors.dart';

/// La page d'attente entre l'Étude et le Rappel d'un Plateau. Volontairement presque vide : la
/// Distraction est suspendue (`games/cartographer/CONTEXT.md`) et se reprendra en expérimentant.
/// Une barre fine se vide ; rien n'est compté.
class WaitView extends StatefulWidget {
  final int seconds;
  final String header;
  final VoidCallback onDone;

  const WaitView({super.key, required this.seconds, required this.header, required this.onDone});

  @override
  State<WaitView> createState() => _WaitViewState();
}

class _WaitViewState extends State<WaitView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.seconds),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed && !_done) {
        _done = true;
        widget.onDone();
      }
    });
  var _done = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.header, key: const Key('progress'), textAlign: TextAlign.center, style: theme.textTheme.labelLarge),
        Expanded(
          child: Center(
            child: Text(
              'Gardez-les en tête…',
              key: const Key('wait-text'),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: 1 - _controller.value, minHeight: 6),
          ),
        ),
        const SizedBox(height: 56),
      ],
    );
  }
}

/// Le Rappel d'un Plateau : tous les Éléments à replacer sur la carte, dans l'ordre que le joueur
/// veut. Il choisit un nom, touche la carte, et un repère numéroté s'y pose ; toucher un autre
/// endroit après avoir rechoisi le nom le déplace. Aucun verdict avant « Valider » : le joueur n'a
/// pas de repère exact pour placer les suivants. Après, les vraies positions apparaissent, nommées,
/// et chaque repère prend la couleur de son verdict.
class TrayRecallView extends StatefulWidget {
  final cartographer.BaseMap baseMap;
  final cartographer.Tray tray;
  final cartographer.NameLanguage language;
  final String header;

  /// Évalue d'un coup les réponses du joueur, une par question et dans l'ordre des questions.
  final List<cartographer.AnswerEvaluation> Function(List<cartographer.CartographerAnswer> answers) onSubmit;
  final VoidCallback onNext;
  final String nextLabel;
  final GameSounds sounds;

  const TrayRecallView({
    super.key,
    required this.baseMap,
    required this.tray,
    required this.header,
    required this.onSubmit,
    required this.onNext,
    required this.sounds,
    this.language = cartographer.NameLanguage.fr,
    this.nextLabel = 'Suivant',
  });

  @override
  State<TrayRecallView> createState() => _TrayRecallViewState();
}

class _TrayRecallViewState extends State<TrayRecallView> {
  final _placements = <int, cartographer.GeoPoint>{};
  var _selected = 0;
  List<cartographer.AnswerEvaluation>? _evaluations;

  List<cartographer.RecallQuestion> get _questions => widget.tray.questions;
  bool get _allPlaced => _placements.length == _questions.length;
  bool get _revealed => _evaluations != null;

  String _name(int index) => widget.baseMap.itemById(_questions[index].itemId).names.of(widget.language);

  void _place(cartographer.GeoPoint point) {
    if (_revealed) return;
    widget.sounds.tap();
    setState(() {
      _placements[_selected] = point;
      // Le nom suivant à placer : le prochain sans repère, en repartant du début si besoin.
      for (var step = 1; step <= _questions.length; step++) {
        final candidate = (_selected + step) % _questions.length;
        if (!_placements.containsKey(candidate)) {
          _selected = candidate;
          break;
        }
      }
    });
  }

  void _submit() {
    if (!_allPlaced || _revealed) return;
    final evaluations = widget.onSubmit([
      for (var i = 0; i < _questions.length; i++) cartographer.PlacedAnswer(_placements[i]!),
    ]);
    final exact = evaluations.where((e) => e.isCorrect).length;
    exact == evaluations.length
        ? widget.sounds.success()
        : exact == 0
            ? widget.sounds.failure()
            : widget.sounds.tap();
    setState(() => _evaluations = evaluations);
  }

  List<MapMarker> _markers(ColorScheme scheme) => [
    for (final entry in _placements.entries)
      MapMarker(
        point: entry.value,
        text: '${entry.key + 1}',
        color: _revealed
            ? verdictColor(_evaluations![entry.key].verdict)
            : (entry.key == _selected ? scheme.tertiary : scheme.primary),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noun = placeNoun(widget.baseMap, widget.tray.studiedItemIds);
    final ids = widget.tray.studiedItemIds;
    final evaluations = _evaluations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.header, key: const Key('progress'), textAlign: TextAlign.center, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(
          evaluations == null ? 'Replacez les ${noun.many}' : 'Voici où elles étaient',
          key: const Key('prompt'),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: CartographerMapView(
              baseMap: widget.baseMap,
              markers: _markers(theme.colorScheme),
              fills: evaluations == null
                  ? const {}
                  : {for (var i = 0; i < ids.length; i++) ids[i]: verdictColor(evaluations[i].verdict).withValues(alpha: 0.75)},
              labels: evaluations == null ? const {} : ids.toSet(),
              language: widget.language,
              onTap: evaluations == null ? _place : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            for (var i = 0; i < _questions.length; i++)
              ChoiceChip(
                key: Key('tray-chip-$i'),
                label: Text('${i + 1} · ${_name(i)}'),
                avatar: !_placements.containsKey(i) || evaluations != null ? null : const Icon(Icons.check, size: 16),
                selected: evaluations == null && _selected == i,
                backgroundColor: evaluations == null ? null : verdictColor(evaluations[i].verdict).withValues(alpha: 0.35),
                onSelected: evaluations == null ? (_) => setState(() => _selected = i) : null,
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (evaluations == null) ...[
          Text(
            _allPlaced
                ? 'Tout est placé. Vous pouvez encore déplacer un repère.'
                : 'Choisissez un nom, puis touchez la carte. Pincez pour zoomer.',
            key: const Key('tray-hint'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          FilledButton(key: const Key('tray-submit'), onPressed: _allPlaced ? _submit : null, child: const Text('Valider')),
        ] else ...[
          Text(
            '${evaluations.where((e) => e.isCorrect).length} sur ${evaluations.length} exactes',
            key: const Key('feedback'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          FilledButton(key: const Key('next'), onPressed: widget.onNext, child: Text(widget.nextLabel)),
        ],
      ],
    );
  }
}
