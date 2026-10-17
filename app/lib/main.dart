import 'package:flutter/material.dart';
import 'package:workshop/workshop.dart' as workshop;

import 'audio/game_sounds.dart';
import 'theme/app_theme.dart';
import 'workshop/workshop_play_screen.dart';

void main() {
  runApp(const CognitivApp());
}

class CognitivApp extends StatelessWidget {
  const CognitivApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cognitiv',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: WorkshopPlayScreen(
        sounds: AudioPlayersGameSounds(),
        generate: workshop.GenerateWorkshopPuzzle(
          catalog: const workshop.RuleCatalog(),
          random: workshop.SystemRandomSource(),
        ),
        evaluate: workshop.EvaluateWorkshopAnswer(),
      ),
    );
  }
}
