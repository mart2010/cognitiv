import 'package:flutter/material.dart';
import 'package:workshop/workshop.dart' as workshop;

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
      theme: ThemeData(colorSchemeSeed: const Color(0xFF4A7BD0), useMaterial3: true),
      home: WorkshopPlayScreen(
        generate: workshop.GenerateWorkshopPuzzle(
          catalog: const workshop.RuleCatalog(),
          random: workshop.SystemRandomSource(),
        ),
        evaluate: workshop.EvaluateWorkshopAnswer(),
      ),
    );
  }
}
