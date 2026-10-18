import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:flutter/material.dart';

import '../audio/game_sounds.dart';
import 'cartographer_map_view.dart';

/// Entraînement au Geste Placer, sans Étude ni Distraction : on donne le nom d'un pays, le
/// joueur le touche sur la carte. C'est la forme du Repérage (première manche d'une Partie) ;
/// sert à valider le toucher sur un vrai téléphone avant de construire l'Étude-éclair complète. Les questions viennent du domaine ; l'évaluation et
/// le Score aussi.
class CartographerPlaceScreen extends StatefulWidget {
  final cartographer.BaseMap baseMap;
  final cartographer.CartographerLevel level;

  /// Fabrique la suite de questions d'une session ; rappelée à « Recommencer ».
  final List<cartographer.RecallQuestion> Function() buildQuestions;
  final cartographer.EvaluateCartographerAnswer evaluate;
  final cartographer.ComputeCartographerScore computeScore;
  final GameSounds sounds;

  CartographerPlaceScreen({
    super.key,
    required this.baseMap,
    required this.buildQuestions,
    cartographer.CartographerLevel? level,
    cartographer.EvaluateCartographerAnswer? evaluate,
    cartographer.ComputeCartographerScore? computeScore,
    this.sounds = const SilentGameSounds(),
  }) : level = level ?? cartographer.CartographerLevels.first,
       evaluate = evaluate ?? cartographer.EvaluateCartographerAnswer(),
       computeScore = computeScore ?? cartographer.ComputeCartographerScore();

  @override
  State<CartographerPlaceScreen> createState() => _CartographerPlaceScreenState();
}

class _CartographerPlaceScreenState extends State<CartographerPlaceScreen> {
  static const _exact = Color(0xFF4CAF7A);
  static const _close = Color(0xFFE8B84A);
  static const _wrong = Color(0xFFD9695F);

  late List<cartographer.RecallQuestion> _questions = widget.buildQuestions();
  final _outcomes = <cartographer.QuestionOutcome>[];
  var _index = 0;
  cartographer.AnswerVerdict? _verdict;
  cartographer.GeoPoint? _tap;

  bool get _finished => _index >= _questions.length;
  cartographer.RecallQuestion get _question => _questions[_index];

  void _onTap(cartographer.GeoPoint point) {
    if (_verdict != null || _finished) return;
    final evaluation = widget.evaluate(widget.baseMap, _question, cartographer.PlacedAnswer(point));
    evaluation.isCorrect ? widget.sounds.success() : widget.sounds.failure();
    setState(() {
      _tap = point;
      _verdict = evaluation.verdict;
      _outcomes.add(cartographer.QuestionOutcome(evaluation.verdict, phase: cartographer.PuzzlePhase.screening));
    });
  }

  void _next() => setState(() {
    _index++;
    _verdict = null;
    _tap = null;
  });

  void _restart() => setState(() {
    _questions = widget.buildQuestions();
    _outcomes.clear();
    _index = 0;
    _verdict = null;
    _tap = null;
  });

  Color _colorOf(cartographer.AnswerVerdict verdict) => switch (verdict) {
    cartographer.AnswerVerdict.exact => _exact,
    cartographer.AnswerVerdict.close => _close,
    cartographer.AnswerVerdict.wrong => _wrong,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Le cartographe')),
      body: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: _finished ? _result() : _play())),
    );
  }

  Widget _play() {
    final item = widget.baseMap.itemById(_question.itemId);
    final verdict = _verdict;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Question ${_index + 1} sur ${_questions.length}',
          key: const Key('progress'),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Où se trouve : ${item.names.fr} ?',
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
              fills: verdict == null ? const {} : {item.id: _colorOf(verdict).withValues(alpha: 0.75)},
              labels: verdict == null ? const {} : {item.id},
              marker: _tap,
              onTap: verdict == null ? _onTap : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: verdict == null
              ? Center(
                  child: Text(
                    'Touchez la carte. Pincez pour zoomer.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      switch (verdict) {
                        cartographer.AnswerVerdict.exact => 'Exact !',
                        cartographer.AnswerVerdict.close => 'Presque !',
                        cartographer.AnswerVerdict.wrong => 'Raté.',
                      },
                      key: const Key('feedback'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(color: _colorOf(verdict)),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      key: const Key('next'),
                      onPressed: _next,
                      child: Text(_index + 1 < _questions.length ? 'Suivant' : 'Terminer'),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _result() {
    final result = widget.computeScore(_outcomes, level: widget.level);
    final exact = _outcomes.where((o) => o.verdict == cartographer.AnswerVerdict.exact).length;
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$exact sur ${_outcomes.length}', key: const Key('result-count'), style: theme.textTheme.displaySmall),
          const SizedBox(height: 4),
          Text('exactes', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          Text('Score : ${result.score}', key: const Key('result-score'), style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          FilledButton(key: const Key('restart'), onPressed: _restart, child: const Text('Recommencer')),
        ],
      ),
    );
  }
}
