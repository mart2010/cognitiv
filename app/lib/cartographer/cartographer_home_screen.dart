import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:flutter/material.dart';

import 'cartographer_run_screen.dart';
import 'cartographer_services.dart';
import 'link_labels.dart';

/// Accueil du Cartographe : le Niveau, ce que le joueur veut travailler (ses genres de Lien) et un
/// bouton pour effacer ce que le jeu retient de lui. Le joueur choisit librement ; le jeu ne change
/// jamais le Niveau.
class CartographerHomeScreen extends StatefulWidget {
  final CartographerServices services;

  const CartographerHomeScreen({super.key, required this.services});

  @override
  State<CartographerHomeScreen> createState() => _CartographerHomeScreenState();
}

class _CartographerHomeScreenState extends State<CartographerHomeScreen> {
  var _levelNumber = 3;
  var _trial = cartographer.Trial.flashStudy;
  var _presentation = cartographer.TrayPresentation.together;

  @override
  void initState() {
    super.initState();
    widget.services.load();
  }

  cartographer.CartographerLevel get _level => cartographer.CartographerLevels.byNumber(_levelNumber);

  String _levelSummary(cartographer.CartographerLevel level, Set<cartographer.Category> categories) {
    final aid = switch (level.aid) {
      cartographer.RecallAid.choices => 'avec propositions',
      cartographer.RecallAid.firstLetter => 'avec la première lettre',
      cartographer.RecallAid.free => 'sans aide',
    };
    final what = switch (categories.length == 1 ? categories.single : null) {
      cartographer.Category.countries => 'pays',
      cartographer.Category.cities => 'villes',
      _ => 'lieux',
    };
    if (_trial == cartographer.Trial.tray) {
      if (_presentation == cartographer.TrayPresentation.oneByOne) {
        return '${level.itemCount} $what par plateau, un toutes les ${cartographer.PrepareTrayPuzzles.secondsPerItem} s, ${level.distractionSeconds} s d\'attente';
      }
      return '${level.itemCount} $what par plateau, ${level.studySeconds} s pour les retenir, ${level.distractionSeconds} s d\'attente';
    }
    return '${level.itemCount} $what par étude, ${level.studySeconds} s pour les retenir, $aid';
  }

  /// Les genres de Lien qui concernent au moins un Élément des Catégories activées : inutile de
  /// proposer « reconnaître à sa forme » quand on ne travaille que les villes.
  List<cartographer.LinkKind> _shownKinds(cartographer.CartographerProfile profile) {
    final baseMap = widget.services.baseMap;
    return [
      for (final kind in playableLinkKinds)
        if (baseMap.items.any((item) => profile.categories.contains(item.category) && kind.appliesTo(baseMap, item))) kind,
    ];
  }

  Future<void> _confirmReset() async {
    final reset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repartir de zéro ?'),
        content: const Text("Le jeu oubliera ce qu'il sait de vous sur cette carte. Votre Niveau et vos réglages restent."),
        actions: [
          TextButton(key: const Key('reset-cancel'), onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(key: const Key('reset-confirm'), onPressed: () => Navigator.of(context).pop(true), child: const Text('Effacer')),
        ],
      ),
    );
    if (reset == true) await widget.services.mastery.resetBaseMap(widget.services.baseMap.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final services = widget.services;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Le cartographe'),
        actions: [
          IconButton(
            key: const Key('reset-progress'),
            tooltip: 'Repartir de zéro',
            icon: const Icon(Icons.restart_alt),
            onPressed: _confirmReset,
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: services.profile,
          builder: (context, _) {
            final profile = services.profile.profile;
            final canPlay = _trial == cartographer.Trial.tray || profile.canAsk(services.baseMap);
            return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Amérique du Sud', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    SegmentedButton<cartographer.Trial>(
                      key: const Key('trial-selector'),
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: cartographer.Trial.flashStudy, label: Text('Étude-éclair')),
                        ButtonSegment(value: cartographer.Trial.tray, label: Text('Plateau')),
                      ],
                      selected: {_trial},
                      onSelectionChanged: (selection) => setState(() => _trial = selection.single),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _trial == cartographer.Trial.tray
                          ? (_presentation == cartographer.TrayPresentation.oneByOne
                              ? 'Des repères montrés un à un, puis tous à replacer.'
                              : 'Des repères montrés ensemble, puis tous à replacer.')
                          : 'Un repérage, puis l\'étude de ce qu\'on ne connaît pas.',
                      key: const Key('trial-summary'),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    Text('Niveau $_levelNumber', key: const Key('level-title'), style: theme.textTheme.titleMedium),
                    Slider(
                      key: const Key('level-slider'),
                      min: 1,
                      max: cartographer.CartographerLevels.all.length.toDouble(),
                      divisions: cartographer.CartographerLevels.all.length - 1,
                      value: _levelNumber.toDouble(),
                      label: '$_levelNumber',
                      onChanged: (v) => setState(() => _levelNumber = v.round()),
                    ),
                    Text(
                      _levelSummary(_level, profile.categories),
                      key: const Key('level-summary'),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    Text('Ce que je veux apprendre', style: theme.textTheme.titleMedium),
                    for (final category in services.baseMap.categories)
                      SwitchListTile(
                        key: Key('category-${category.id}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(category.names.of(services.language)),
                        value: profile.categories.contains(category),
                        onChanged: (on) => services.profile.setCategoryActive(category, on),
                      ),
                    // Les réglages propres à l'Épreuve choisie ; d'autres viendront avec les autres Épreuves.
                    if (_trial == cartographer.Trial.tray) ...[
                      const SizedBox(height: 16),
                      Text('Options', style: theme.textTheme.titleMedium),
                      SwitchListTile(
                        key: const Key('option-simultaneous'),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Affichage en simultané'),
                        subtitle: const Text('Sinon, les repères sont montrés un à un.'),
                        value: _presentation == cartographer.TrayPresentation.together,
                        onChanged: (on) => setState(
                          () => _presentation = on ? cartographer.TrayPresentation.together : cartographer.TrayPresentation.oneByOne,
                        ),
                      ),
                    ],
                    // Un Plateau pose toujours « placer », sans genre de Lien à choisir.
                    if (_trial == cartographer.Trial.flashStudy) ...[
                      const SizedBox(height: 16),
                      Text('Ce que je veux travailler', style: theme.textTheme.titleMedium),
                      for (final kind in _shownKinds(profile))
                        SwitchListTile(
                          key: Key('kind-${kind.cue.name}-${kind.answer.name}'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(linkKindLabel(kind)),
                          value: profile.linkKinds.contains(kind),
                          onChanged: (on) => services.profile.setKindActive(kind, on),
                        ),
                    ],
                  ],
                ),
              ),
              // Le bouton principal reste toujours visible, hors de la liste qui défile.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!canPlay)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Rien à poser avec ces réglages : activez au moins une façon de travailler.',
                          key: const Key('cannot-play'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('start'),
                        onPressed: canPlay
                            ? () => Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (_) => CartographerRunScreen(services: services, level: _level, trial: _trial, presentation: _presentation)),
                              )
                            : null,
                        child: const Text('Jouer'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            );
          },
        ),
      ),
    );
  }
}
