import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:cognitiv_app/cartographer/study_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cartographer_test_support.dart';

cartographer.FlashStudy _study({int studySeconds = 10, int distractionSeconds = 5}) => cartographer.FlashStudy(
  language: cartographer.NameLanguage.fr,
  studySeconds: studySeconds,
  distractionSeconds: distractionSeconds,
  questions: [
    for (final id in ['PRY', 'URY', 'ECU', 'GUY'])
      cartographer.RecallQuestion(
        itemId: id,
        kind: const cartographer.LinkKind(cartographer.Facet.name, cartographer.Facet.capital),
        aid: cartographer.RecallAid.free,
      ),
  ],
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  usePixel(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: child)),
      ),
    ),
  );
}

void main() {
  final map = loadMap();

  group("annonce d'une Étude", () {
    testWidgets('dit combien de pays et combien de secondes, et attend « Commencer »', (tester) async {
      var started = 0;
      await _pump(tester, StudyIntroView(study: _study(), header: 'Étude 1 sur 2', onStart: () => started++));
      expect(find.text('Étude 1 sur 2'), findsOneWidget);
      expect(find.text('Retenez ces 4 pays'), findsOneWidget);
      expect(find.text('Vous aurez 10 secondes.'), findsOneWidget);
      expect(started, 0);
      await tester.tap(find.byKey(const Key('start-study')));
      expect(started, 1);
    });

    testWidgets('au singulier pour un seul pays', (tester) async {
      final one = cartographer.FlashStudy(
        language: cartographer.NameLanguage.fr,
        studySeconds: 8,
        distractionSeconds: 3,
        questions: [_study().questions.first],
      );
      await _pump(tester, StudyIntroView(study: one, header: 'Étude 1 sur 1', onStart: () {}));
      expect(find.text('Retenez ce pays'), findsOneWidget);
    });
  });

  group('étude chronométrée', () {
    testWidgets('la barre se vide et la fin du temps termine l’étude, une seule fois', (tester) async {
      var done = 0;
      await _pump(tester, StudyView(baseMap: map, study: _study(studySeconds: 10), header: 'Étude 1 sur 2', onDone: () => done++));
      double bar() => tester.widget<LinearProgressIndicator>(find.byKey(const Key('study-bar'))).value!;
      expect(bar(), closeTo(1.0, 0.01));

      await tester.pump(const Duration(seconds: 5));
      expect(bar(), closeTo(0.5, 0.05));
      expect(done, 0);

      await tester.pump(const Duration(seconds: 6));
      expect(done, 1);
      await tester.pump(const Duration(seconds: 5));
      expect(done, 1);
    });

    testWidgets('« Prêt » termine plus tôt, et le temps écoulé ensuite ne le refait pas', (tester) async {
      var done = 0;
      await _pump(tester, StudyView(baseMap: map, study: _study(studySeconds: 10), header: 'Étude 1 sur 2', onDone: () => done++));
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.byKey(const Key('study-ready')));
      expect(done, 1);
      await tester.pump(const Duration(seconds: 20));
      expect(done, 1);
    });

    testWidgets('quitter pendant le décompte ne laisse aucune minuterie', (tester) async {
      await _pump(tester, StudyView(baseMap: map, study: _study(), header: 'Étude 1 sur 2', onDone: () {}));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });

    testWidgets('tient sans débordement ni défilement sur un Pixel', (tester) async {
      await _pump(tester, StudyView(baseMap: map, study: _study(), header: 'Étude 1 sur 2', onDone: () {}));
      expect(tester.takeException(), isNull);
      expect(find.byWidgetPredicate((w) => w is Scrollable), findsNothing);
      expect(tester.getSize(find.byKey(const Key('cartographer-map'))).height, greaterThan(300));
    });
  });

  group('Distraction', () {
    testWidgets('dure le temps demandé puis rend la main, une seule fois', (tester) async {
      var done = 0;
      await _pump(tester, DistractionView(seconds: 5, onDone: () => done++));
      await tester.pump(const Duration(seconds: 4));
      expect(done, 0);
      await tester.pump(const Duration(seconds: 2));
      expect(done, 1);
      await tester.pump(const Duration(seconds: 5));
      expect(done, 1);
    });

    testWidgets('toucher le point compte, le point change de place avec le temps', (tester) async {
      await _pump(tester, DistractionView(seconds: 8, onDone: () {}));
      final first = tester.getCenter(find.byKey(const ValueKey('dot-0')));
      await tester.tap(find.byKey(const ValueKey('dot-0')));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('dot-1')), findsOneWidget);
      expect(tester.getCenter(find.byKey(const ValueKey('dot-1'))), isNot(first));
    });

    testWidgets('tient sans débordement sur un Pixel', (tester) async {
      await _pump(tester, DistractionView(seconds: 5, onDone: () {}));
      expect(tester.takeException(), isNull);
    });
  });
}
