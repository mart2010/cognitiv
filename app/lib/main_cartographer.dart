// Point d'entrée d'essai du Cartographe : l'écran de la carte seule (Geste Placer), sans
// passer par l'accueil de L'atelier, en attendant l'écran d'accueil commun de la plateforme.
// Usage : flutter run -t lib/main_cartographer.dart
import 'dart:convert';

import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'audio/game_sounds.dart';
import 'cartographer/cartographer_place_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final baseMap = cartographer.BaseMapCodec.fromJson(
    jsonDecode(await rootBundle.loadString('assets/maps/south_america.json')) as Map<String, dynamic>,
  );
  runApp(CartographerPlaceApp(baseMap: baseMap, sounds: AudioPlayersGameSounds()));
}

/// Les questions d'entraînement viennent du domaine : profil réduit à « nom → position »,
/// puis les questions des Études-éclair mises bout à bout (le Bilan n'a pas de sens ici).
List<cartographer.RecallQuestion> placeQuestions(cartographer.BaseMap baseMap, cartographer.CartographerLevel level, [int? seed]) {
  final puzzles = cartographer.GenerateCartographerPuzzles(random: cartographer.SystemRandomSource(seed)).call(
    cartographer.GenerateCartographerRequest(
      baseMap: baseMap,
      level: level,
      profile: cartographer.CartographerProfile({const cartographer.LinkKind(cartographer.Facet.name, cartographer.Facet.position)}),
      language: cartographer.NameLanguage.fr,
    ),
  );
  return [for (final puzzle in puzzles.whereType<cartographer.FlashStudy>()) ...puzzle.questions];
}

class CartographerPlaceApp extends StatelessWidget {
  final cartographer.BaseMap baseMap;
  final GameSounds sounds;

  const CartographerPlaceApp({super.key, required this.baseMap, this.sounds = const SilentGameSounds()});

  @override
  Widget build(BuildContext context) {
    final level = cartographer.CartographerLevels.byNumber(3);
    return MaterialApp(
      title: 'Le cartographe',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: CartographerPlaceScreen(
        baseMap: baseMap,
        level: level,
        buildQuestions: () => placeQuestions(baseMap, level),
        sounds: sounds,
      ),
    );
  }
}
