import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:flutter/material.dart';

import 'cartographer_map_view.dart';
/// Annonce d'une Étude : combien d'Éléments, combien de temps. Le décompte ne démarre qu'au toucher
/// de « Commencer », pour que le temps ne parte pas avant que le joueur regarde la carte. Sans
/// [title], l'annonce parle de pays (l'Étude-éclair d'origine).
class StudyIntroView extends StatelessWidget {
  final cartographer.StudyPuzzle study;
  final String header;
  final VoidCallback onStart;
  final String? title;

  /// Une phrase de plus sous la durée (ex. ce qui est attendu ensuite).
  final String? note;

  const StudyIntroView({super.key, required this.study, required this.header, required this.onStart, this.title, this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = study.questions.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(header, key: const Key('progress'), textAlign: TextAlign.center, style: theme.textTheme.labelLarge),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title ?? (count == 1 ? 'Retenez ce pays' : 'Retenez ces $count pays'),
                  key: const Key('study-intro'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Vous aurez ${study.studySeconds} secondes.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                if (note != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    note!,
                    key: const Key('study-note'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ),
        FilledButton(key: const Key('start-study'), onPressed: onStart, child: const Text('Commencer')),
      ],
    );
  }
}

/// L'étude chronométrée : les pays à retenir sont colorés et nommés sur la carte, les autres mis en
/// retrait, et une barre fine se vide. Finir plus tôt est permis (« Prêt ») et ne rapporte rien.
class StudyView extends StatefulWidget {
  final cartographer.BaseMap baseMap;
  final cartographer.StudyPuzzle study;
  final cartographer.NameLanguage language;
  final String header;
  final VoidCallback onDone;

  const StudyView({
    super.key,
    required this.baseMap,
    required this.study,
    required this.header,
    required this.onDone,
    this.language = cartographer.NameLanguage.fr,
  });

  @override
  State<StudyView> createState() => _StudyViewState();
}

class _StudyViewState extends State<StudyView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.study.studySeconds),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _finish();
    });
  var _done = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Le nom, et la capitale sur une seconde ligne quand le Lien l'utilise.
  Map<String, String> get _labelTexts {
    final texts = <String, String>{};
    for (final q in widget.study.questions) {
      final item = widget.baseMap.itemById(q.itemId);
      final name = item.names.of(widget.language);
      final usesCapital = q.kind.cue == cartographer.Facet.capital || q.kind.answer == cartographer.Facet.capital;
      texts[q.itemId] = usesCapital ? '$name\n${widget.baseMap.textFor(item, cartographer.Facet.capital, widget.language)}' : name;
    }
    return texts;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ids = widget.study.studiedItemIds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.header, key: const Key('progress'), textAlign: TextAlign.center, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(key: const Key('study-bar'), value: 1 - _controller.value, minHeight: 6),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: CartographerMapView(
              baseMap: widget.baseMap,
              focus: ids.toSet(),
              labels: ids.toSet(),
              labelTexts: _labelTexts,
              language: widget.language,
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(key: const Key('study-ready'), onPressed: _finish, child: const Text('Prêt')),
      ],
    );
  }
}

/// La Distraction entre l'Étude et le Rappel : un point qui saute d'un endroit à l'autre, à toucher.
/// Elle occupe l'esprit sans rapport avec la géographie, pour couper le maintien actif en mémoire.
/// Rien n'est compté ni noté.
class DistractionView extends StatefulWidget {
  final int seconds;
  final VoidCallback onDone;

  const DistractionView({super.key, required this.seconds, required this.onDone});

  @override
  State<DistractionView> createState() => _DistractionViewState();
}

class _DistractionViewState extends State<DistractionView> with SingleTickerProviderStateMixin {
  static const _positions = [
    Alignment(-0.7, -0.6), Alignment(0.6, -0.8), Alignment(0.8, 0.2), Alignment(-0.3, 0.7),
    Alignment(0.1, -0.1), Alignment(-0.8, 0.3), Alignment(0.5, 0.8), Alignment(-0.1, -0.9),
  ];
  static const _secondsPerPosition = 0.8;

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
  var _hits = 0;

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
        Text('Une petite pause', key: const Key('progress'), textAlign: TextAlign.center, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Text('Touchez le point', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final step = (_controller.value * widget.seconds / _secondsPerPosition).floor();
                return Align(
                  alignment: _positions[step % _positions.length],
                  child: GestureDetector(
                    key: ValueKey('dot-$step'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _hits++),
                    child: Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primary.withValues(alpha: 0.8)),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('$_hits', key: const Key('distraction-hits'), textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
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
