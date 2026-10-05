import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cognitiv_app/workshop/puzzle_view.dart';
import 'package:workshop/workshop.dart' as workshop;

/// Énigme minimale : miroir horizontal sur une ligne de deux Cellules ; la bonne
/// réponse est à l'indice 1.
workshop.WorkshopPuzzle _puzzle() {
  workshop.Matrix row(workshop.Shape a, workshop.Shape b) => workshop.Matrix([
        [workshop.Cell.filled(a, workshop.Color.red), workshop.Cell.filled(b, workshop.Color.blue)],
      ]);
  final question = row(workshop.Shape.round, workshop.Shape.square);
  return workshop.WorkshopPuzzle(
    examples: [
      workshop.WorkshopExample(question, question),
    ],
    question: question,
    answerChoices: [
      row(workshop.Shape.round, workshop.Shape.square),
      row(workshop.Shape.square, workshop.Shape.round),
    ],
    correctAnswerIndex: 1,
    appliedRules: const [workshop.MirrorRule(workshop.MirrorAxis.horizontal)],
  );
}

Future<void> _pump(WidgetTester tester, {void Function(bool)? onAnswered, VoidCallback? onNext}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: PuzzleView(
        puzzle: _puzzle(),
        evaluate: workshop.EvaluateWorkshopAnswer(),
        onAnswered: onAnswered,
        onNext: onNext ?? () {},
      ),
    ),
  ));
}

void main() {
  testWidgets('une bonne réponse est évaluée correcte et affiche Bravo', (tester) async {
    bool? result;
    await _pump(tester, onAnswered: (v) => result = v);

    await tester.tap(find.byKey(const Key('choice-1')));
    await tester.pump();

    expect(result, isTrue);
    expect(find.text('Bravo !'), findsOneWidget);
  });

  testWidgets('une mauvaise réponse est évaluée incorrecte', (tester) async {
    bool? result;
    await _pump(tester, onAnswered: (v) => result = v);

    await tester.tap(find.byKey(const Key('choice-0')));
    await tester.pump();

    expect(result, isFalse);
    expect(find.text('Raté.'), findsOneWidget);
  });

  testWidgets('la réponse est verrouillée après un premier choix', (tester) async {
    var calls = 0;
    await _pump(tester, onAnswered: (_) => calls++);

    await tester.tap(find.byKey(const Key('choice-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('choice-1')));
    await tester.pump();

    expect(calls, 1);
  });

  testWidgets("la Famille de règle est cachée jusqu'à l'indice", (tester) async {
    await _pump(tester);
    expect(find.textContaining('mirror'), findsNothing);

    await tester.tap(find.text('Indice'));
    await tester.pump();

    expect(find.textContaining('mirror'), findsOneWidget);
  });

  testWidgets('Suivant apparaît seulement après une réponse et appelle onNext', (tester) async {
    var next = 0;
    await _pump(tester, onNext: () => next++);
    expect(find.text('Suivant'), findsNothing);

    await tester.tap(find.byKey(const Key('choice-1')));
    await tester.pump();
    await tester.tap(find.text('Suivant'));

    expect(next, 1);
  });
}
