// Point d'entrée d'essai du Cartographe : l'accueil du jeu, sans passer par l'accueil de L'atelier,
// en attendant l'écran d'accueil commun de la plateforme.
// Usage : flutter run -t lib/main_cartographer.dart
import 'dart:convert';

import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'audio/game_sounds.dart';
import 'cartographer/cartographer_home_screen.dart';
import 'cartographer/cartographer_services.dart';
import 'cartographer/storage/cartographer_storage.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final baseMap = cartographer.BaseMapCodec.fromJson(
    jsonDecode(await rootBundle.loadString('assets/maps/south_america.json')) as Map<String, dynamic>,
  );
  runApp(
    CartographerApp(
      services: CartographerServices(
        baseMap: baseMap,
        mastery: CartographerMasteryController(SharedPreferencesMasteryStore()),
        profile: CartographerProfileController(SharedPreferencesCartographerProfileStore()),
        sounds: AudioPlayersGameSounds(),
      ),
    ),
  );
}

class CartographerApp extends StatelessWidget {
  final CartographerServices services;

  const CartographerApp({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Le cartographe',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: CartographerHomeScreen(services: services),
    );
  }
}
