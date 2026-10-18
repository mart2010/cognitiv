
import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:cognitiv_app/cartographer/cartographer_shape_view.dart';
import 'package:cognitiv_app/cartographer/question_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cartographer_test_support.dart';

cartographer.RecallQuestion _q(
  String id,
  cartographer.Facet cue,
  cartographer.Facet answer, {
  cartographer.RecallAid aid = cartographer.RecallAid.free,
  List<String> choices = const [],
}) => cartographer.RecallQuestion(itemId: id, kind: cartographer.LinkKind(cue, answer), aid: aid, choices: choices);

void main() {
  final map = loadMap();
  final evaluate = cartographer.EvaluateCartographerAnswer();

  Future<void> pump(
    WidgetTester tester,
    cartographer.RecallQuestion question, {
    RecordingSounds? sounds,
    int Function()? onNext,
  }) async {
    usePixel(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: QuestionView(
                baseMap: map,
                question: question,
                header: 'Première manche · 1 sur 3',
                onAnswer: (answer) => evaluate(map, question, answer),
                onNext: () => onNext?.call(),
                sounds: sounds ?? RecordingSounds(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Placer', () {
    final where = _q('PRY', cartographer.Facet.name, cartographer.Facet.position);

    testWidgets("toucher le bon pays : « Exact ! », succès sonore", (tester) async {
      final sounds = RecordingSounds();
      await pump(tester, where, sounds: sounds);
      expect(find.text('Première manche · 1 sur 3'), findsOneWidget);
      expect(find.text('Où se trouve : Paraguay ?'), findsOneWidget);
      expect(find.byKey(const Key('feedback')), findsNothing);

      await tapMapOn(tester, map, 'PRY');

      expect(find.text('Exact !'), findsOneWidget);
      expect(sounds.events, ['success']);
    });

    testWidgets('toucher un pays éloigné : raté, échec doux', (tester) async {
      final sounds = RecordingSounds();
      await pump(tester, where, sounds: sounds);
      await tapMapOn(tester, map, 'BOL');
      expect(find.text('Raté.'), findsOneWidget);
      expect(sounds.events, ['failure']);
    });

    testWidgets('toucher un voisin proche : « Presque ! »', (tester) async {
      await pump(tester, _q('SUR', cartographer.Facet.name, cartographer.Facet.position));
      await tapMapOn(tester, map, 'GUF');
      expect(find.text('Presque !'), findsOneWidget);
    });

    testWidgets('après la réponse, la carte ne prend plus de toucher', (tester) async {
      final sounds = RecordingSounds();
      await pump(tester, where, sounds: sounds);
      await tapMapOn(tester, map, 'PRY');
      await tapMapOn(tester, map, 'BOL');
      expect(sounds.events, ['success']);
      expect(find.text('Exact !'), findsOneWidget);
    });

    testWidgets('« Suivant » rend la main', (tester) async {
      var next = 0;
      await pump(tester, where, onNext: () => ++next);
      await tapMapOn(tester, map, 'PRY');
      await tester.tap(find.byKey(const Key('next')));
      expect(next, 1);
    });

    testWidgets('capitale → position : la capitale est dans la question', (tester) async {
      await pump(tester, _q('PRY', cartographer.Facet.capital, cartographer.Facet.position));
      expect(find.text('Où se trouve le pays dont la capitale est : Asunción ?'), findsOneWidget);
    });
  });

  group('indices', () {
    testWidgets('position → nom : le pays est surligné sur la carte, sans texte à lire', (tester) async {
      await pump(tester, _q('PRY', cartographer.Facet.position, cartographer.Facet.name, aid: cartographer.RecallAid.free));
      expect(find.text('Quel est ce pays ?'), findsOneWidget);
      expect(find.byKey(const Key('cartographer-map')), findsOneWidget);
      expect(find.byKey(const Key('cue-text')), findsNothing);
    });

    testWidgets('forme → nom : la forme seule, sans carte', (tester) async {
      await pump(tester, _q('PRY', cartographer.Facet.shape, cartographer.Facet.name));
      expect(find.byType(CartographerShapeView), findsOneWidget);
      expect(find.byKey(const Key('cartographer-map')), findsNothing);
    });

    testWidgets('nom → capitale : le nom en grand', (tester) async {
      await pump(tester, _q('ECU', cartographer.Facet.name, cartographer.Facet.capital));
      expect(find.text('Quelle est la capitale de : Équateur ?'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('cue-text'))).data, 'Équateur');
    });

    testWidgets('capitale → nom : la capitale en grand', (tester) async {
      await pump(tester, _q('ECU', cartographer.Facet.capital, cartographer.Facet.name));
      expect(find.text('Quel pays a pour capitale : Quito ?'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('cue-text'))).data, 'Quito');
    });
  });

  group('Nommer avec propositions', () {
    final choices = ['Quito', 'Lima', 'Bogota', 'Caracas'];
    final question = _q('ECU', cartographer.Facet.name, cartographer.Facet.capital, aid: cartographer.RecallAid.choices, choices: choices);

    testWidgets('quatre propositions, pas de champ de saisie', (tester) async {
      await pump(tester, question);
      for (var i = 0; i < 4; i++) {
        expect(find.byKey(Key('choice-$i')), findsOneWidget);
        expect(find.text(choices[i]), findsOneWidget);
      }
      expect(find.byKey(const Key('answer-field')), findsNothing);
    });

    testWidgets('la bonne proposition : exact', (tester) async {
      final sounds = RecordingSounds();
      await pump(tester, question, sounds: sounds);
      await tester.tap(find.byKey(const Key('choice-0')));
      await tester.pump();
      expect(find.text('Exact !'), findsOneWidget);
      expect(sounds.events, ['success']);
    });

    testWidgets("une mauvaise proposition : raté, et la bonne réponse est donnée", (tester) async {
      await pump(tester, question);
      await tester.tap(find.byKey(const Key('choice-1')));
      await tester.pump();
      expect(find.text('Raté. Réponse : Quito'), findsOneWidget);
    });

    testWidgets('après la réponse, les propositions ne répondent plus', (tester) async {
      final sounds = RecordingSounds();
      await pump(tester, question, sounds: sounds);
      await tester.tap(find.byKey(const Key('choice-0')));
      await tester.pump();
      expect(find.byKey(const Key('choice-1')), findsNothing);
      expect(sounds.events, ['success']);
    });
  });

  group('Nommer avec la première lettre', () {
    final question = _q('ECU', cartographer.Facet.name, cartographer.Facet.capital, aid: cartographer.RecallAid.firstLetter);

    testWidgets("l'indice montre la première lettre et la longueur", (tester) async {
      await pump(tester, question);
      expect(tester.widget<Text>(find.byKey(const Key('hint'))).data, 'Q____');
    });

    testWidgets('saisie sans accent ni majuscule acceptée', (tester) async {
      await pump(tester, _q('PRY', cartographer.Facet.name, cartographer.Facet.capital, aid: cartographer.RecallAid.firstLetter));
      await tester.enterText(find.byKey(const Key('answer-field')), 'asuncion');
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pump();
      expect(find.text('Exact !'), findsOneWidget);
    });

    testWidgets('valider au clavier fonctionne comme le bouton', (tester) async {
      await pump(tester, question);
      await tester.enterText(find.byKey(const Key('answer-field')), 'Quito');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text('Exact !'), findsOneWidget);
    });
  });

  group('Nommer sans aide', () {
    final question = _q('BOL', cartographer.Facet.name, cartographer.Facet.capital);

    testWidgets("pas d'indice, et une réponse vide est ignorée", (tester) async {
      final sounds = RecordingSounds();
      await pump(tester, question, sounds: sounds);
      expect(find.byKey(const Key('hint')), findsNothing);
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pump();
      expect(find.byKey(const Key('feedback')), findsNothing);
      expect(sounds.events, isEmpty);
    });

    testWidgets("une réponse fausse donne toutes les capitales principales", (tester) async {
      await pump(tester, question);
      await tester.enterText(find.byKey(const Key('answer-field')), 'Lima');
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pump();
      expect(find.text('Raté. Réponse : La Paz ou Sucre'), findsOneWidget);
    });

    testWidgets("« Guyane » n'est pas accepté pour le Guyana", (tester) async {
      await pump(tester, _q('GUY', cartographer.Facet.position, cartographer.Facet.name));
      await tester.enterText(find.byKey(const Key('answer-field')), 'Guyane');
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pump();
      expect(find.textContaining('Raté'), findsOneWidget);
    });
  });

  group('mise en page', () {
    testWidgets('chaque genre de question tient sans débordement ni défilement sur un Pixel', (tester) async {
      for (final question in [
        _q('PRY', cartographer.Facet.name, cartographer.Facet.position),
        _q('PRY', cartographer.Facet.position, cartographer.Facet.name),
        _q('PRY', cartographer.Facet.shape, cartographer.Facet.name),
        _q('ECU', cartographer.Facet.name, cartographer.Facet.capital, aid: cartographer.RecallAid.choices, choices: ['Quito', 'Lima', 'Bogota', 'Caracas']),
        _q('ECU', cartographer.Facet.name, cartographer.Facet.capital, aid: cartographer.RecallAid.firstLetter),
      ]) {
        await pump(tester, question);
        expect(tester.takeException(), isNull, reason: '${question.kind}');
        expect(
          find.byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical),
          findsNothing,
          reason: '${question.kind}',
        );
      }
    });

    testWidgets("avec le clavier ouvert, le champ et le bouton restent visibles et rien ne déborde", (tester) async {
      await pump(tester, _q('ECU', cartographer.Facet.name, cartographer.Facet.capital, aid: cartographer.RecallAid.firstLetter));
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      expect(tester.takeException(), isNull);
      final field = tester.getRect(find.byKey(const Key('answer-field')));
      final submit = tester.getRect(find.byKey(const Key('submit')));
      expect(field.bottom, lessThanOrEqualTo(pixelSize.height - 320));
      expect(submit.bottom, lessThanOrEqualTo(pixelSize.height - 320));
    });
  });
}
