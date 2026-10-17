import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cognitiv_app/workshop/puzzle_view.dart';
import 'package:cognitiv_app/workshop/workshop_play_screen.dart';
import 'package:workshop/workshop.dart' as workshop;

void main() {
  Widget app({int? seed}) => MaterialApp(
        home: WorkshopPlayScreen(
          generate: workshop.GenerateWorkshopPuzzle(
            catalog: const workshop.RuleCatalog(),
            random: workshop.SystemRandomSource(seed),
          ),
          evaluate: workshop.EvaluateWorkshopAnswer(),
        ),
      );

  testWidgets('affiche une énigme générée puis enchaîne sur la suivante', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(seed: 1));
    expect(find.byType(PuzzleView), findsOneWidget);
    final first = tester.widget<PuzzleView>(find.byType(PuzzleView)).puzzle;

    await tester.tap(find.byKey(const Key('choice-0')));
    await tester.pump();
    await tester.tap(find.text('Suivant'));
    await tester.pump();

    final second = tester.widget<PuzzleView>(find.byType(PuzzleView)).puzzle;
    expect(identical(first, second), isFalse);
    expect(find.text('Suivant'), findsNothing);
  });

  testWidgets('le bouton de mode bascule vers la construction libre', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(seed: 1));
    expect(find.byKey(const Key('choice-0')), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggle-mode')));
    await tester.pump();

    expect(find.byKey(const Key('choice-0')), findsNothing);
    expect(find.byKey(const Key('construct-grid')), findsOneWidget);
  });
}
