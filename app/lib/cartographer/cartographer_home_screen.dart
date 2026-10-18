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

  @override
  void initState() {
    super.initState();
    widget.services.load();
  }

  cartographer.CartographerLevel get _level => cartographer.CartographerLevels.byNumber(_levelNumber);

  String _levelSummary(cartographer.CartographerLevel level) {
    final aid = switch (level.aid) {
      cartographer.RecallAid.choices => 'avec propositions',
      cartographer.RecallAid.firstLetter => 'avec la première lettre',
      cartographer.RecallAid.free => 'sans aide',
    };
    return '${level.itemCount} pays par étude, ${level.studySeconds} s pour les retenir, $aid';
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
          builder: (context, _) => Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Amérique du Sud', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
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
                    Text(_levelSummary(_level), key: const Key('level-summary'), style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 24),
                    Text('Ce que je veux travailler', style: theme.textTheme.titleMedium),
                    for (final kind in playableLinkKinds)
                      SwitchListTile(
                        key: Key('kind-${kind.cue.name}-${kind.answer.name}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(linkKindLabel(kind)),
                        value: services.profile.profile.linkKinds.contains(kind),
                        onChanged: (on) => services.profile.setKindActive(kind, on),
                      ),
                  ],
                ),
              ),
              // Le bouton principal reste toujours visible, hors de la liste qui défile.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('start'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => CartographerRunScreen(services: services, level: _level)),
                    ),
                    child: const Text('Jouer'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
