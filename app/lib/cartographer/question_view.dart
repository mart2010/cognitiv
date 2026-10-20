import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:flutter/material.dart';

import '../audio/game_sounds.dart';
import 'cartographer_map_view.dart';
import 'cartographer_shape_view.dart';
import 'verdict_colors.dart';

/// Une question de Rappel, quel que soit son genre de Lien : l'Indice (un texte, une forme, un
/// pays surligné sur la carte), puis la réponse (toucher la carte pour Placer, ou nommer avec
/// l'Aide du Niveau : propositions, première lettre, saisie libre). Après la réponse, la couleur
/// du verdict, la bonne réponse et « Suivant ». L'état se remet à zéro en changeant la clé du widget.
class QuestionView extends StatefulWidget {
  final cartographer.BaseMap baseMap;
  final cartographer.RecallQuestion question;
  final cartographer.NameLanguage language;

  /// Ligne d'en-tête (« Première manche · 3 sur 13 »).
  final String? header;
  final cartographer.AnswerEvaluation Function(cartographer.CartographerAnswer answer) onAnswer;
  final VoidCallback onNext;
  final String nextLabel;
  final GameSounds sounds;

  const QuestionView({
    super.key,
    required this.baseMap,
    required this.question,
    required this.onAnswer,
    required this.onNext,
    this.language = cartographer.NameLanguage.fr,
    this.header,
    this.nextLabel = 'Suivant',
    this.sounds = const SilentGameSounds(),
  });

  @override
  State<QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends State<QuestionView> {

  final _field = TextEditingController();
  cartographer.AnswerVerdict? _verdict;
  cartographer.GeoPoint? _tap;

  cartographer.LinkKind get _kind => widget.question.kind;
  cartographer.Item get _item => widget.baseMap.itemById(widget.question.itemId);
  bool get _placing => _kind.gesture == cartographer.Gesture.place;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _answer(cartographer.CartographerAnswer answer, {cartographer.GeoPoint? tap}) {
    if (_verdict != null) return;
    final evaluation = widget.onAnswer(answer);
    evaluation.isCorrect ? widget.sounds.success() : widget.sounds.failure();
    setState(() {
      _verdict = evaluation.verdict;
      _tap = tap;
    });
  }

  void _submitText(String text) {
    if (text.trim().isEmpty) return;
    _answer(cartographer.TypedAnswer(text));
  }

  Color _colorOf(cartographer.AnswerVerdict v) => verdictColor(v);

  String _text(cartographer.Facet facet) => widget.baseMap.textFor(_item, facet, widget.language);

  String get _prompt {
    final item = _item;
    final name = item.names.of(widget.language);
    return switch ((_kind.cue, _kind.answer)) {
      (cartographer.Facet.name, cartographer.Facet.position) => 'Où se trouve : $name ?',
      (cartographer.Facet.capital, cartographer.Facet.position) =>
        'Où se trouve le pays dont la capitale est : ${_text(cartographer.Facet.capital)} ?',
      (cartographer.Facet.name, cartographer.Facet.capital) => 'Quelle est la capitale de : $name ?',
      (cartographer.Facet.capital, cartographer.Facet.name) =>
        'Quel pays a pour capitale : ${_text(cartographer.Facet.capital)} ?',
      (cartographer.Facet.position, cartographer.Facet.capital) => 'Quelle est la capitale de ce pays ?',
      _ => item.category == cartographer.Category.cities ? 'Quelle est cette ville ?' : 'Quel est ce pays ?',
    };
  }

  /// Ce qu'on affiche comme bonne réponse : toutes les capitales principales (la Bolivie en a deux).
  String get _expected => switch (_kind.answer) {
    cartographer.Facet.capital =>
      (widget.baseMap.primaryCapitalsOf(_item).isNotEmpty
              ? widget.baseMap.primaryCapitalsOf(_item)
              : widget.baseMap.capitalsOf(_item))
          .map((c) => c.names.of(widget.language))
          .join(' ou '),
    _ => _text(cartographer.Facet.name),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.header != null)
          Text(widget.header!, key: const Key('progress'), textAlign: TextAlign.center, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(_prompt, key: const Key('prompt'), textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Expanded(child: Card(clipBehavior: Clip.antiAlias, child: _stage(theme))),
        const SizedBox(height: 12),
        _bottom(theme),
      ],
    );
  }

  Widget _stage(ThemeData theme) {
    final verdictColor = _verdict == null ? theme.colorScheme.primary.withValues(alpha: 0.7) : _colorOf(_verdict!).withValues(alpha: 0.75);
    final highlight = {_item.id: verdictColor};
    return switch (_kind.cue) {
      cartographer.Facet.shape => CartographerShapeView(item: _item, color: verdictColor),
      cartographer.Facet.position => CartographerMapView(
        baseMap: widget.baseMap,
        fills: highlight,
        labels: _verdict == null ? const {} : {_item.id},
        language: widget.language,
      ),
      _ when _placing => CartographerMapView(
        baseMap: widget.baseMap,
        fills: _verdict == null ? const {} : highlight,
        labels: _verdict == null ? const {} : {_item.id},
        marker: _tap,
        language: widget.language,
        onTap: _verdict == null ? (point) => _answer(cartographer.PlacedAnswer(point), tap: point) : null,
      ),
      _ => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _text(_kind.cue),
            key: const Key('cue-text'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
        ),
      ),
    };
  }

  Widget _bottom(ThemeData theme) {
    final verdict = _verdict;
    if (verdict != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            switch (verdict) {
              cartographer.AnswerVerdict.exact => 'Exact !',
              cartographer.AnswerVerdict.close => 'Presque !',
              cartographer.AnswerVerdict.wrong => _placing ? 'Raté.' : 'Raté. Réponse : $_expected',
            },
            key: const Key('feedback'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: _colorOf(verdict)),
          ),
          const SizedBox(height: 8),
          FilledButton(key: const Key('next'), onPressed: widget.onNext, child: Text(widget.nextLabel)),
        ],
      );
    }
    if (_placing) {
      return SizedBox(
        height: 56,
        child: Center(
          child: Text(
            'Touchez la carte. Pincez pour zoomer.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return _namingInput(theme);
  }

  Widget _namingInput(ThemeData theme) {
    final aid = widget.question.aid;
    if (aid == cartographer.RecallAid.choices && widget.question.choices.isNotEmpty) {
      final choices = widget.question.choices;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row = 0; row < choices.length; row += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  for (var i = row; i < row + 2 && i < choices.length; i++) ...[
                    if (i > row) const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        key: Key('choice-$i'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                        onPressed: () => _answer(cartographer.TypedAnswer(choices[i])),
                        child: Text(choices[i], textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (aid == cartographer.RecallAid.firstLetter)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              cartographer.HintBuilder.firstLetter(_expected.split(' ou ').first),
              key: const Key('hint'),
              style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 4, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('answer-field'),
                controller: _field,
                autofocus: true,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.words,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(hintText: 'Votre réponse', border: OutlineInputBorder()),
                onSubmitted: _submitText,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const Key('submit'),
              style: FilledButton.styleFrom(minimumSize: const Size(96, 52)),
              onPressed: () => _submitText(_field.text),
              child: const Text('Valider'),
            ),
          ],
        ),
      ],
    );
  }
}
