import 'package:flutter/material.dart';
import 'package:workshop/workshop.dart' as workshop;

import 'puzzle_view.dart';

/// Écran de jeu de L'atelier : enchaîne des Énigmes générées, en mode choix multiple.
/// Paramètres de niveau codés en dur : aucun contrat plateforme/jeu pour l'instant.
class WorkshopPlayScreen extends StatefulWidget {
  final workshop.GenerateWorkshopPuzzle generate;
  final workshop.EvaluateWorkshopAnswer evaluate;
  final workshop.GenerationProfile profile;

  const WorkshopPlayScreen({
    super.key,
    required this.generate,
    required this.evaluate,
    this.profile = workshop.GenerationProfile.intuitiveDefaults,
  });

  @override
  State<WorkshopPlayScreen> createState() => _WorkshopPlayScreenState();
}

class _WorkshopPlayScreenState extends State<WorkshopPlayScreen> {
  static const _maxAttempts = 20;

  late workshop.WorkshopPuzzle? _puzzle = _nextPuzzle();
  var _round = 0;

  workshop.WorkshopPuzzle? _nextPuzzle() {
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final result = widget.generate(workshop.GenerateWorkshopPuzzleRequest(
        rowCount: 3,
        columnCount: 3,
        ruleCount: 1,
        exampleCount: 2,
        profile: widget.profile,
      ));
      if (result is workshop.GenerationSucceeded) return result.puzzle;
    }
    return null;
  }

  void _next() => setState(() {
        _puzzle = _nextPuzzle();
        _round++;
      });

  @override
  Widget build(BuildContext context) {
    final puzzle = _puzzle;
    return Scaffold(
      appBar: AppBar(title: const Text("L'atelier de transformations")),
      body: SafeArea(
        child: puzzle == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Impossible de générer une énigme avec ce profil.'),
                    TextButton(onPressed: _next, child: const Text('Réessayer')),
                  ],
                ),
              )
            : PuzzleView(
                key: ValueKey(_round),
                puzzle: puzzle,
                evaluate: widget.evaluate,
                onNext: _next,
              ),
      ),
    );
  }
}
