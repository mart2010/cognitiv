import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:cognitiv_app/cartographer/cartographer_run_screen.dart';
import 'package:cognitiv_app/cartographer/question_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cartographer_test_support.dart';

final _level3 = cartographer.CartographerLevels.byNumber(3);

Future<void> _pumpRun(WidgetTester tester, services) async {
  await services.load(); // l'accueil le fait en vrai ; ici on ouvre la Partie directement
  usePixel(tester);
  await tester.pumpWidget(MaterialApp(home: CartographerRunScreen(services: services, level: _level3)));
}

/// Répond aux questions affichées, une à une, jusqu'à ce qu'il n'y en ait plus à l'écran, ou après
/// [max] réponses (deux énigmes de questions peuvent se suivre : le Rappel d'une Étude puis le Bilan).
Future<int> _answerAll(WidgetTester tester, cartographer.BaseMap map, {required bool correct, int? max}) async {
  var count = 0;
  while (find.byType(QuestionView).evaluate().isNotEmpty && (max == null || count < max)) {
    await answerCurrent(tester, map, correct: correct);
    expect(find.byKey(const Key('feedback')), findsOneWidget);
    await tester.tap(find.byKey(const Key('next')));
    await tester.pump();
    count++;
  }
  return count;
}

/// Une Étude jusqu'au Rappel : annonce, étude (terminée au toucher de « Prêt »), Distraction.
Future<void> _studyThroughDistraction(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('start-study')));
  await tester.pump();
  expect(find.byKey(const Key('study-bar')), findsOneWidget);
  await tester.tap(find.byKey(const Key('study-ready')));
  await tester.pump();
  expect(find.text('Une petite pause'), findsOneWidget);
  await tester.pump(Duration(seconds: _level3.distractionSeconds + 1));
  await tester.pump();
}

void main() {
  final map = loadMap();

  testWidgets('avec les genres par défaut, une Partie tout juste ne suffit pas à tout connaître : pas de suggestion', (tester) async {
    final services = newServices();
    await _pumpRun(tester, services);
    await _answerAll(tester, map, correct: true);
    expect(find.text('Vous connaissiez déjà tout ça !'), findsOneWidget);
    expect(find.byKey(const Key('suggestion')), findsNothing);
  });

  testWidgets('un débutant : Repérage, deux Études avec Rappel, Bilan, résultat, Maîtrise retenue', (tester) async {
    final services = newServices();
    await _pumpRun(tester, services);
    expect(find.text('Première manche · 1 sur 13'), findsOneWidget);

    // Il ne connaît rien au Repérage.
    expect(await _answerAll(tester, map, correct: false), 13);

    expect(find.text('Étude 1 sur 2'), findsOneWidget);
    expect(find.text('Retenez ces 4 pays'), findsOneWidget);
    await _studyThroughDistraction(tester);
    expect(find.text('Étude 1 sur 2 · Rappel 1 sur 4'), findsOneWidget);
    expect(await _answerAll(tester, map, correct: true, max: 4), 4);

    expect(find.text('Étude 2 sur 2'), findsOneWidget);
    await _studyThroughDistraction(tester);
    expect(find.text('Étude 2 sur 2 · Rappel 1 sur 4'), findsOneWidget);
    expect(await _answerAll(tester, map, correct: true, max: 4), 4);

    // Le Bilan : il le réussit, et le dernier bouton dit « Terminer ».
    expect(find.text('Bilan · 1 sur 5'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await answerCurrent(tester, map, correct: true);
      expect(find.text('Suivant'), findsOneWidget);
      await tester.tap(find.byKey(const Key('next')));
      await tester.pump();
    }
    await answerCurrent(tester, map, correct: true);
    expect(find.text('Terminer'), findsOneWidget);
    await tester.tap(find.byKey(const Key('next')));
    await tester.pump();

    // Résultat.
    expect(find.text('Vous avez étudié 8 pays.'), findsOneWidget);
    expect(find.byKey(const Key('result-score')), findsOneWidget);
    expect(find.byKey(const Key('level-hint')), findsOneWidget, reason: 'Bilan réussi : suggestion de monter');
    expect(find.byKey(const Key('suggestion')), findsNothing, reason: "il n'a pas tout connu au départ");
    expect(services.mastery.mastery.isEmpty, isFalse, reason: 'la Maîtrise est retenue à la fin');
    expect(services.mastery.mastery.states.values, contains(cartographer.Knowledge.shaky));
    expect(tester.takeException(), isNull);
  });

  // Un seul genre de Lien dans le Profil : une Partie tout juste suffit à connaître tous ses Liens.
  // Avec les 5 genres par défaut, une Partie n'en couvre qu'un par pays et la suggestion vient plus tard.
  final onlyPositions = cartographer.CartographerProfile({
    const cartographer.LinkKind(cartographer.Facet.name, cartographer.Facet.position),
  });

  testWidgets('un expert : tout juste au Repérage, rien à étudier, suggestion d’un autre genre de Lien', (tester) async {
    final services = newServices(profile: onlyPositions);
    await _pumpRun(tester, services);

    expect(await _answerAll(tester, map, correct: true), 13);

    expect(find.byKey(const Key('start-study')), findsNothing);
    expect(find.text('Vous connaissiez déjà tout ça !'), findsOneWidget);
    expect(find.text('13 sur 13'), findsOneWidget);
    expect(find.byKey(const Key('suggestion')), findsOneWidget);
    expect(find.text('Essayer aussi : nommer ce qui est montré sur la carte ?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('suggest-accept')));
    await tester.pump();
    const added = cartographer.LinkKind(cartographer.Facet.position, cartographer.Facet.name);
    expect(services.profile.profile.linkKinds, contains(added));
    expect(find.byKey(const Key('suggestion-answer')), findsOneWidget);
    expect(find.byKey(const Key('suggest-accept')), findsNothing);
  });

  testWidgets('« Rester » garde le Profil tel quel', (tester) async {
    final services = newServices(profile: onlyPositions);
    await _pumpRun(tester, services);
    final before = services.profile.profile.linkKinds;
    expect(before, onlyPositions.linkKinds);
    await _answerAll(tester, map, correct: true);
    await tester.tap(find.byKey(const Key('suggest-stay')));
    await tester.pump();
    expect(services.profile.profile.linkKinds, before);
    expect(find.text('Vous gardez vos réglages.'), findsOneWidget);
  });

  testWidgets('« Rejouer » lance une Partie neuve qui tient compte de la Maîtrise', (tester) async {
    final services = newServices();
    await _pumpRun(tester, services);
    await _answerAll(tester, map, correct: true);
    expect(services.mastery.mastery.isEmpty, isFalse);

    await tester.tap(find.byKey(const Key('replay')));
    await tester.pump();
    expect(find.textContaining('Première manche · 1 sur'), findsOneWidget);
    expect(find.byKey(const Key('result-count')), findsNothing);
  });

  group('quitter en cours de Partie', () {
    Future<void> openRun(WidgetTester tester, services) async {
      await services.load();
      usePixel(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  key: const Key('open'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => CartographerRunScreen(services: services, level: _level3)),
                  ),
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
    }

    testWidgets('le retour demande confirmation, « Rester » reprend là où on en était', (tester) async {
      final services = newServices();
      await openRun(tester, services);
      await answerCurrent(tester, map, correct: true);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Quitter la Partie ?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('stay')));
      await tester.pumpAndSettle();
      expect(find.text('Quitter la Partie ?'), findsNothing);
      expect(find.byKey(const Key('feedback')), findsOneWidget, reason: 'la question répondue est toujours là');
    });

    testWidgets('« Quitter » ferme la Partie sans rien retenir', (tester) async {
      final services = newServices();
      await openRun(tester, services);
      for (var i = 0; i < 3; i++) {
        await answerCurrent(tester, map, correct: true);
        await tester.tap(find.byKey(const Key('next')));
        await tester.pump();
      }

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('open')), findsOneWidget);
      expect(services.mastery.mastery.isEmpty, isTrue, reason: 'un abandon ne touche pas la Maîtrise');
    });

    testWidgets('une fois la Partie finie, le retour ne demande plus rien', (tester) async {
      final services = newServices();
      await openRun(tester, services);
      await _answerAll(tester, map, correct: true);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Quitter la Partie ?'), findsNothing);
      expect(find.byKey(const Key('open')), findsOneWidget);
    });
  });
}
