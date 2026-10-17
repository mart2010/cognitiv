import 'package:flutter/material.dart';
import 'package:workshop/workshop.dart' as workshop;

import 'audio/game_sounds.dart';
import 'theme/app_theme.dart';
import 'workshop/progress/workshop_progress.dart';
import 'workshop/workshop_home_screen.dart';
import 'workshop/workshop_services.dart';

void main() {
  runApp(
    CognitivApp(
      services: WorkshopServices(
        generate: workshop.GenerateWorkshopPuzzle(
          catalog: const workshop.RuleCatalog(),
          random: workshop.SystemRandomSource(),
        ),
        evaluate: workshop.EvaluateWorkshopAnswer(),
        progress: WorkshopProgressController(SharedPreferencesProgressStore()),
        sounds: AudioPlayersGameSounds(),
      ),
    ),
  );
}

class CognitivApp extends StatelessWidget {
  final WorkshopServices services;

  const CognitivApp({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cognitiv',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: WorkshopHomeScreen(services: services),
    );
  }
}
