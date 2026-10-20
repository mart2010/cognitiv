import 'package:cartographer/cartographer.dart' as cartographer;

import '../audio/game_sounds.dart';
import 'cartographer_run.dart';
import 'storage/cartographer_storage.dart';

/// Ce que les écrans du Cartographe utilisent : la Carte de base, la Maîtrise et le Profil du
/// joueur, le son et la fabrique de Parties. Regroupé ici plutôt que passé écran par écran.
/// Provisoire : le contrat plateforme/jeu (ADR 0004) le remplacera quand la plateforme existera.
class CartographerServices {
  final cartographer.BaseMap baseMap;
  final CartographerMasteryController mastery;
  final CartographerProfileController profile;
  final GameSounds sounds;
  final cartographer.NameLanguage language;

  /// Un hasard neuf par Partie ; les tests le remplacent par une graine fixe.
  final cartographer.RandomSource Function() randomFactory;

  CartographerServices({
    required this.baseMap,
    required this.mastery,
    required this.profile,
    this.sounds = const SilentGameSounds(),
    this.language = cartographer.NameLanguage.fr,
    cartographer.RandomSource Function()? randomFactory,
  }) : randomFactory = randomFactory ?? cartographer.SystemRandomSource.new;

  /// Charge ce que le joueur a réglé et ce que le jeu sait de lui.
  Future<void> load() => Future.wait([mastery.load(), profile.load()]);

  /// Une Partie neuve à ce Niveau, dans l'Épreuve choisie. La Maîtrise mise à jour est stockée à
  /// la fin, jamais en cas d'abandon.
  CartographerRun newRun(
    cartographer.CartographerLevel level, [
    cartographer.Trial trial = cartographer.Trial.flashStudy,
    cartographer.TrayPresentation presentation = cartographer.TrayPresentation.together,
  ]) =>
      CartographerRun(
        baseMap: baseMap,
        level: level,
        profile: profile.profile,
        language: language,
        masteryBefore: mastery.mastery,
        prepare: switch (trial) {
          cartographer.Trial.flashStudy => cartographer.PrepareCartographerPuzzles(random: randomFactory()),
          cartographer.Trial.tray => cartographer.PrepareTrayPuzzles(random: randomFactory(), presentation: presentation),
        },
        onFinished: mastery.replace,
      );
}
