import 'dart:async';
import 'dart:math' as math;

import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:flutter/material.dart';

import '../audio/game_sounds.dart';
import 'cartographer_map_view.dart';
import 'verdict_colors.dart';

/// Une manche de Séquence, à la Simon : les Éléments sont surlignés et nommés un à un, puis le
/// joueur les touche dans le même ordre. Chaque Élément touché s'allume à son tour, vert s'il est
/// juste, rouge sinon, et la faute arrête la Partie. La manche réussie enchaîne seule sur la
/// suivante, plus longue d'un Élément. Un Élément de Point (ville) se choisit parmi des ronds
/// neutres, ceux du jeu, et garde le nom du dernier touché ; un Élément de Polygone (pays) se touche
/// à même la carte, n'importe lequel (hors du jeu, c'est une faute). Les pays restent pâles d'un bout
/// à l'autre : seul l'Élément allumé reprend sa teinte, sans que le fond change.
class SequenceView extends StatefulWidget {
  /// Avant le premier Élément, et entre deux Éléments.
  static const leadIn = Duration(milliseconds: 700);

  /// Après une manche réussie, avant d'enchaîner.
  static const successPause = Duration(milliseconds: 800);

  /// Combien de temps un Élément touché reste allumé.
  static const flash = Duration(milliseconds: 350);

  /// Le silence entre deux Éléments surlignés : un quart de leur durée, sans descendre sous 100 ms.
  static Duration gapFor(int stepMillis) => Duration(milliseconds: math.max(100, stepMillis ~/ 4));

  final cartographer.BaseMap baseMap;
  final cartographer.Sequence sequence;
  final cartographer.NameLanguage language;
  final String header;

  /// Juge un toucher contre la question `index`, sans rien enregistrer.
  final cartographer.AnswerEvaluation Function(int index, cartographer.CartographerAnswer answer) judge;

  /// Enregistre la manche : les réponses données, une par Élément touché (moins que de questions
  /// après une faute).
  final void Function(List<cartographer.CartographerAnswer> answers) onSubmit;
  final VoidCallback onNext;
  final GameSounds sounds;

  const SequenceView({
    super.key,
    required this.baseMap,
    required this.sequence,
    required this.header,
    required this.judge,
    required this.onSubmit,
    required this.onNext,
    required this.sounds,
    this.language = cartographer.NameLanguage.fr,
  });

  @override
  State<SequenceView> createState() => _SequenceViewState();
}

class _SequenceViewState extends State<SequenceView> {
  /// Ce que la carte montre pendant le visionnage : l'Élément en cours, ou rien entre deux.
  String? _shown;
  var _watching = true;
  final _answers = <cartographer.CartographerAnswer>[];
  final _verdicts = <cartographer.AnswerVerdict>[];

  /// L'Élément touché qui est allumé, et sa couleur de verdict ; effacé après `flash`, sauf pour la faute.
  String? _lit;

  /// Le dernier Élément touché, qui garde son nom affiché (pour des Points) jusqu'au toucher suivant.
  String? _last;
  Color? _litColor;
  var _finished = false;
  Timer? _timer;
  Timer? _flashTimer;

  List<cartographer.Item> get _pool => [for (final id in widget.sequence.pool) widget.baseMap.itemById(id)];
  bool get _pointsGame => _pool.every((item) => item.geometry is cartographer.PointGeometry);
  List<String> get _expected => widget.sequence.steps;
  bool get _failed => _verdicts.any((v) => v != cartographer.AnswerVerdict.exact);

  @override
  void initState() {
    super.initState();
    _timer = Timer(SequenceView.leadIn, () => _show(0));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  void _show(int index) {
    if (!mounted) return;
    setState(() => _shown = _expected[index]);
    _timer = Timer(Duration(milliseconds: widget.sequence.stepMillis), () {
      if (!mounted) return;
      setState(() => _shown = null);
      _timer = Timer(SequenceView.gapFor(widget.sequence.stepMillis), () {
        if (index + 1 < _expected.length) {
          _show(index + 1);
        } else if (mounted) {
          setState(() => _watching = false);
        }
      });
    });
  }

  /// L'Élément que le toucher désigne : le rond du jeu le plus proche (Points), ou le pays touché
  /// (Polygones), même hors du jeu. Rien si le toucher ne vise aucun Élément.
  cartographer.Item? _resolve(cartographer.GeoPoint tap) {
    if (_pointsGame) {
      final frame = widget.baseMap.frame;
      final reach = math.max(frame.width, frame.height) * 0.05;
      cartographer.Item? best;
      var bestDistance = reach;
      for (final item in _pool) {
        final anchor = item.geometry.anchor;
        final d = math.sqrt(math.pow(anchor.lon - tap.lon, 2) + math.pow(anchor.lat - tap.lat, 2));
        if (d <= bestDistance) {
          best = item;
          bestDistance = d;
        }
      }
      return best;
    }
    final judge = cartographer.PlacementJudge(widget.baseMap.frame);
    for (final item in widget.baseMap.itemsOf(_pool.first.category)) {
      if (judge.judge(item, tap) == cartographer.AnswerVerdict.exact) return item;
    }
    return null;
  }

  void _touch(cartographer.GeoPoint tap) {
    if (_watching || _finished) return;
    final item = _resolve(tap);
    if (item == null) return;
    final index = _answers.length;
    // Un pays se juge au toucher lui-même ; une ville, à son rond.
    final answer = cartographer.PlacedAnswer(_pointsGame ? item.geometry.anchor : tap);
    final verdict = widget.judge(index, answer).verdict;
    widget.sounds.tap();
    _flashTimer?.cancel();
    setState(() {
      _answers.add(answer);
      _verdicts.add(verdict);
      _lit = item.id;
      _last = item.id;
      _litColor = verdictColor(verdict).withValues(alpha: 0.85);
      if (verdict != cartographer.AnswerVerdict.exact || _answers.length == _expected.length) _finished = true;
    });
    if (!_failed) {
      _flashTimer = Timer(SequenceView.flash, () {
        if (mounted) setState(() => _lit = null);
      });
    }
    if (!_finished) return;
    widget.onSubmit(List.of(_answers));
    if (_failed) {
      widget.sounds.failure();
    } else {
      widget.sounds.success();
      _timer = Timer(SequenceView.successPause, () {
        if (mounted) widget.onNext();
      });
    }
  }

  /// Ce qui est mis en avant : l'Élément surligné pendant le visionnage, l'Élément touché tant qu'il
  /// est allumé, et après une faute celui qu'il fallait toucher.
  Set<String> get _highlight => {
    if (_watching) ?_shown,
    if (_failed) _expected[_answers.length - 1],
    ?_lit,
  };

  /// Ce qui porte son nom : l'Élément surligné, celui qu'il fallait toucher après une faute, et pour
  /// des villes le dernier touché, jusqu'au toucher suivant.
  Set<String> get _named => {
    if (_watching) ?_shown,
    if (_failed) _expected[_answers.length - 1],
    if (_pointsGame) ?_last,
  };

  /// Les teintes de verdict : l'Élément touché, et après une faute le bon Élément en vert.
  Map<String, Color> get _fills => {
    if (_failed) _expected[_answers.length - 1]: verdictColor(cartographer.AnswerVerdict.exact).withValues(alpha: 0.85),
    ?_lit: ?_litColor,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlight = _highlight;
    // Des pays : le fond reste pâle d'un bout à l'autre, seul l'Élément allumé reprend sa teinte.
    // Des villes : les pays restent normaux, il n'y a rien à mettre en retrait.
    final focus = _pointsGame ? (highlight.isEmpty ? null : highlight) : highlight;
    final prompt = _watching
        ? 'Regardez…'
        : _failed
            ? 'Raté : c’était celui-ci'
            : _finished
                ? 'Bravo !'
                : 'À vous : ${_answers.length + 1} sur ${_expected.length}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.header, key: const Key('progress'), textAlign: TextAlign.center, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(prompt, key: const Key('prompt'), textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: CartographerMapView(
              baseMap: widget.baseMap,
              focus: focus,
              dimUnfocused: !_pointsGame,
              labels: _named,
              fills: _fills,
              candidates: _pointsGame && !_failed ? [for (final item in _pool) item.geometry.anchor] : const [],
              language: widget.language,
              onTap: _watching || _finished ? null : _touch,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_failed)
          FilledButton(key: const Key('next'), onPressed: widget.onNext, child: const Text('Terminer'))
        else
          Text(
            _watching ? 'Retenez l’ordre.' : 'Touchez dans le même ordre. Pincez pour zoomer.',
            key: const Key('sequence-hint'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
      ],
    );
  }
}
