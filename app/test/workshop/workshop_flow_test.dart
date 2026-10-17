import 'package:cognitiv_app/workshop/progress/workshop_progress.dart';
import 'package:cognitiv_app/workshop/puzzle_view.dart';
import 'package:cognitiv_app/workshop/workshop_home_screen.dart';
import 'package:cognitiv_app/workshop/workshop_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop/workshop.dart' as workshop;

WorkshopServices _services({int seed = 1}) => WorkshopServices(
  generate: workshop.GenerateWorkshopPuzzle(
    catalog: const workshop.RuleCatalog(),
    random: workshop.SystemRandomSource(seed),
  ),
  evaluate: workshop.EvaluateWorkshopAnswer(),
  progress: WorkshopProgressController(InMemoryProgressStore()),
);

Future<void> _pumpHome(WidgetTester tester, WorkshopServices services) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: WorkshopHomeScreen(services: services)));
  await tester.pump();
}

/// Répond à l'Énigme affichée (bien ou mal) puis passe à la suivante.
Future<void> _answerCurrent(WidgetTester tester, {required bool correct}) async {
  final puzzle = tester.widget<PuzzleView>(find.byType(PuzzleView)).puzzle;
  final index = correct
      ? puzzle.correctAnswerIndex
      : (puzzle.correctAnswerIndex + 1) % puzzle.answerChoices.length;
  await tester.tap(find.byKey(Key('choice-$index')));
  await tester.pump();
  await tester.tap(find.text('Suivant'));
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _playRun(WidgetTester tester, {required bool correct}) async {
  for (var i = 0; i < 5; i++) {
    await _answerCurrent(tester, correct: correct);
  }
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  testWidgets("l'accueil liste les 10 Niveaux, tous accessibles, le premier est suggéré", (
    tester,
  ) async {
    await _pumpHome(tester, _services());

    for (var n = 1; n <= 10; n++) {
      expect(find.byKey(Key('level-$n'), skipOffstage: false), findsOneWidget);
    }
    expect(find.text('Suggéré'), findsOneWidget);
  });

  testWidgets('une Partie parfaite franchit le Niveau, donne le Score pondéré et le mémorise', (
    tester,
  ) async {
    final services = _services();
    await _pumpHome(tester, services);

    await tester.tap(find.byKey(const Key('level-1')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 5'), findsOneWidget);

    await _playRun(tester, correct: true);

    expect(find.text('Niveau franchi !'), findsOneWidget);
    expect(find.text('50 points'), findsOneWidget);
    expect(find.text('Nouveau record !'), findsOneWidget);
    expect(services.progress.progress.isCleared(1), isTrue);

    await tester.tap(find.byKey(const Key('exit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('best-1')), findsOneWidget);
    expect(find.text('50 / 50'), findsOneWidget);
  });

  testWidgets('après une réussite on peut monter au Niveau suivant', (tester) async {
    await _pumpHome(tester, _services());
    await tester.tap(find.byKey(const Key('level-1')));
    await tester.pumpAndSettle();
    await _playRun(tester, correct: true);

    await tester.tap(find.byKey(const Key('go-up')));
    await tester.pumpAndSettle();

    expect(find.text('Niveau 2'), findsOneWidget);
    expect(find.text('1 / 5'), findsOneWidget);
  });

  testWidgets('une Partie ratée ne franchit pas le Niveau et propose de rejouer', (tester) async {
    final services = _services();
    await _pumpHome(tester, services);
    await tester.tap(find.byKey(const Key('level-1')));
    await tester.pumpAndSettle();

    await _playRun(tester, correct: false);

    expect(find.text('Pas encore franchi'), findsOneWidget);
    expect(find.text('0 points'), findsOneWidget);
    expect(services.progress.progress.isCleared(1), isFalse);
    expect(find.byKey(const Key('go-down')), findsNothing, reason: 'rien sous le Niveau 1');
    expect(find.byKey(const Key('replay')), findsOneWidget);
  });

  testWidgets('une Partie abandonnée en cours ne laisse aucune trace', (tester) async {
    final services = _services();
    await _pumpHome(tester, services);
    await tester.tap(find.byKey(const Key('level-1')));
    await tester.pumpAndSettle();
    await _answerCurrent(tester, correct: true);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('level-1')), findsOneWidget);
    expect(services.progress.progress.bestScore(1), isNull);
  });

  testWidgets('le mode de réponse choisi à l\'accueil est celui de la Partie', (tester) async {
    await _pumpHome(tester, _services());
    await tester.tap(find.text('Construction'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('level-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('construct-grid')), findsOneWidget);
    expect(find.byKey(const Key('choice-0')), findsNothing);
  });
}
