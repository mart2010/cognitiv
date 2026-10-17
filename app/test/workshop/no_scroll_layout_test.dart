import 'package:cognitiv_app/workshop/puzzle_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop/workshop.dart' as workshop;

/// Écran d'un Pixel 8a (412 × 915 dp) moins la barre d'état et la barre de navigation.
const _pixelSize = Size(412, 780);

Future<void> _pump(
  WidgetTester tester, {
  required AnswerMode mode,
  int seed = 3,
  workshop.WorkshopLevel? level,
}) async {
  tester.view.physicalSize = _pixelSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: PuzzleView(
            puzzle: _generate(seed, level),
            evaluate: workshop.EvaluateWorkshopAnswer(),
            mode: mode,
            onNext: () {},
          ),
        ),
      ),
    ),
  );
}

workshop.WorkshopPuzzle _generate(int seed, [workshop.WorkshopLevel? level]) {
  final generate = workshop.GenerateWorkshopPuzzle(
    catalog: const workshop.RuleCatalog(),
    random: workshop.SystemRandomSource(seed),
  );
  for (var i = 0; i < 20; i++) {
    final result = generate(
      level != null
          ? workshop.GenerateWorkshopPuzzleRequest.forLevel(
              level,
              profile: workshop.GenerationProfile.intuitiveDefaults,
            )
          : const workshop.GenerateWorkshopPuzzleRequest(
              rowCount: 3,
              columnCount: 3,
              ruleCount: 1,
              exampleCount: 2,
              profile: workshop.GenerationProfile.intuitiveDefaults,
            ),
    );
    if (result is workshop.GenerationSucceeded) return result.puzzle;
  }
  throw StateError('génération impossible');
}

void main() {
  for (final mode in AnswerMode.values) {
    testWidgets('${mode.name} : tout tient sans défilement ni débordement', (tester) async {
      await _pump(tester, mode: mode);

      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull);
      // Pas réduit de façon sensible : la grille de construction mesure 3 × 44 px.
      if (mode == AnswerMode.freeConstruction) {
        final grid = tester.getSize(find.byKey(const Key('construct-grid')));
        expect(grid.width, greaterThan(132 * 0.85));
      } else {
        final choice = tester.getSize(find.byKey(const Key('choice-0')));
        expect(choice.width, greaterThan(100 * 0.85));
      }
    });
  }

  testWidgets('les libellés sont verticaux, à gauche des puzzles', (tester) async {
    await _pump(tester, mode: AnswerMode.multipleChoice);
    for (final label in ['Exemples', 'Énigme', 'Réponse']) {
      expect(find.text(label), findsOneWidget);
      expect(
        find.ancestor(of: find.text(label), matching: find.byType(RotatedBox)),
        findsOneWidget,
      );
    }
  });

  testWidgets("la barre du bas ne déborde pas avec l'indice et un échec en construction", (
    tester,
  ) async {
    await _pump(tester, mode: AnswerMode.freeConstruction);

    await tester.tap(find.text('Indice'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('submit-construction')));
    await tester.pump(const Duration(seconds: 3));

    expect(tester.takeException(), isNull);
    expect(find.text('Suivant'), findsOneWidget);
  });

  for (final mode in AnswerMode.values) {
    testWidgets('${mode.name} : le plus grand Niveau tient sans défilement ni débordement', (
      tester,
    ) async {
      await _pump(tester, mode: mode, level: workshop.WorkshopLevels.byNumber(9));

      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
