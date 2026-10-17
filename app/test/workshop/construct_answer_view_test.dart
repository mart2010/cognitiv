import 'package:cognitiv_app/workshop/puzzle_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop/workshop.dart' as workshop;

/// Énigme minimale : miroir horizontal sur une ligne de deux Cellules.
workshop.WorkshopPuzzle _puzzle() {
  workshop.Matrix row(workshop.Shape a, workshop.Shape b) => workshop.Matrix([
    [workshop.Cell.filled(a, workshop.Color.red), workshop.Cell.filled(b, workshop.Color.red)],
  ]);
  final question = row(workshop.Shape.round, workshop.Shape.square);
  return workshop.WorkshopPuzzle(
    examples: [
      workshop.WorkshopExample(question, row(workshop.Shape.square, workshop.Shape.round)),
    ],
    question: question,
    answerChoices: [question, row(workshop.Shape.square, workshop.Shape.round)],
    correctAnswerIndex: 1,
    appliedRules: const [workshop.MirrorRule(workshop.MirrorAxis.horizontal)],
  );
}

Future<void> _pump(WidgetTester tester, {void Function(bool)? onAnswered}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PuzzleView(
          puzzle: _puzzle(),
          evaluate: workshop.EvaluateWorkshopAnswer(),
          mode: AnswerMode.freeConstruction,
          onAnswered: onAnswered,
          onNext: () {},
        ),
      ),
    ),
  );
}

/// Touche la case (row, column) de la grille de construction (cases de 44 px).
Future<void> _tapCell(WidgetTester tester, int row, int column) async {
  final origin = tester.getTopLeft(find.byKey(const Key('construct-grid')));
  await tester.tapAt(origin + Offset(column * 44 + 22, row * 44 + 22));
  await tester.pump();
}

Future<void> _select(WidgetTester tester, String shape, String color) async {
  await tester.tap(find.byKey(Key('brush-shape-$shape')));
  await tester.tap(find.byKey(Key('brush-color-$color')));
  await tester.pump();
}

void main() {
  testWidgets("n'affiche pas les choix, mais une grille vide à construire", (tester) async {
    await _pump(tester);
    expect(find.byKey(const Key('choice-0')), findsNothing);
    expect(find.byKey(const Key('construct-grid')), findsOneWidget);
  });

  testWidgets('une grille correcte construite est évaluée correcte', (tester) async {
    bool? result;
    await _pump(tester, onAnswered: (v) => result = v);

    await _select(tester, 'square', 'red');
    await _tapCell(tester, 0, 0);
    await _select(tester, 'round', 'red');
    await _tapCell(tester, 0, 1);
    await tester.tap(find.byKey(const Key('submit-construction')));
    await tester.pump();

    expect(result, isTrue);
    expect(find.text('Bravo !'), findsOneWidget);
  });

  testWidgets('une grille fausse est incorrecte et la réponse attendue est montrée', (
    tester,
  ) async {
    bool? result;
    await _pump(tester, onAnswered: (v) => result = v);

    await tester.tap(find.byKey(const Key('submit-construction')));
    await tester.pump();

    expect(result, isFalse);
    expect(find.text('Raté.'), findsOneWidget);
    expect(find.text('Réponse attendue'), findsOneWidget);
  });

  testWidgets('la grille est verrouillée après validation', (tester) async {
    var calls = 0;
    await _pump(tester, onAnswered: (_) => calls++);

    await tester.tap(find.byKey(const Key('submit-construction')));
    await tester.pump();

    expect(find.byKey(const Key('submit-construction')), findsNothing);
    expect(calls, 1);
  });

  testWidgets('Tout vider remet la grille à zéro', (tester) async {
    bool? result;
    await _pump(tester, onAnswered: (v) => result = v);

    await _select(tester, 'square', 'red');
    await _tapCell(tester, 0, 0);
    await tester.tap(find.byKey(const Key('clear-grid')));
    await _select(tester, 'square', 'red');
    await _tapCell(tester, 0, 0);
    await _select(tester, 'round', 'red');
    await _tapCell(tester, 0, 1);
    await tester.tap(find.byKey(const Key('submit-construction')));
    await tester.pump();

    expect(result, isTrue);
  });

  testWidgets('retoucher une case avec le même pinceau la vide', (tester) async {
    bool? result;
    await _pump(tester, onAnswered: (v) => result = v);

    await _select(tester, 'square', 'red');
    await _tapCell(tester, 0, 0);
    await _tapCell(tester, 0, 0);
    await _select(tester, 'square', 'red');
    await _tapCell(tester, 0, 0);
    await _select(tester, 'round', 'red');
    await _tapCell(tester, 0, 1);
    await tester.tap(find.byKey(const Key('submit-construction')));
    await tester.pump();

    expect(result, isTrue);
  });

  testWidgets('pas de pinceau vide, et le bouton dit « Valider la réponse »', (tester) async {
    await _pump(tester);
    expect(find.byKey(const Key('brush-shape-empty')), findsNothing);
    expect(find.text('Valider la réponse'), findsOneWidget);
    expect(find.text('Effacer tout'), findsOneWidget);
  });
}
