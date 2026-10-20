import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:cognitiv_app/cartographer/cartographer_home_screen.dart';
import 'package:cognitiv_app/cartographer/cartographer_map_view.dart';
import 'package:cognitiv_app/cartographer/cartographer_run.dart';
import 'package:cognitiv_app/cartographer/cartographer_services.dart';
import 'package:cognitiv_app/cartographer/question_view.dart';
import 'package:cognitiv_app/cartographer/storage/cartographer_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cartographer_test_support.dart';

void main() {
  final map = loadMap();
  final placeAndName = {
    cartographer.LinkKind(cartographer.Facet.position, cartographer.Facet.name),
    cartographer.LinkKind(cartographer.Facet.name, cartographer.Facet.position),
  };
  final citiesProfile = cartographer.CartographerProfile(placeAndName, categories: {cartographer.Category.cities});

  group('accueil', () {
    Future<void> pumpHome(WidgetTester tester, CartographerServices services) async {
      usePixel(tester);
      await tester.pumpWidget(MaterialApp(home: CartographerHomeScreen(services: services)));
      await tester.pump();
    }

    testWidgets('un interrupteur par Catégorie de la carte : les pays sont allumés, les villes éteintes', (tester) async {
      await pumpHome(tester, newServices());
      expect(tester.widget<SwitchListTile>(find.byKey(const Key('category-countries'))).value, isTrue);
      expect(tester.widget<SwitchListTile>(find.byKey(const Key('category-cities'))).value, isFalse);
    });

    testWidgets('allumer les villes les ajoute au Profil, et le résumé parle de lieux', (tester) async {
      final services = newServices();
      await pumpHome(tester, services);
      await tester.tap(find.byKey(const Key('category-cities')));
      await tester.pump();
      expect(services.profile.profile.categories, {cartographer.Category.countries, cartographer.Category.cities});
      expect(find.text('4 lieux par étude, 10 s pour les retenir, avec propositions'), findsOneWidget);
    });

    testWidgets('éteindre les pays avec les villes allumées laisse les villes seules', (tester) async {
      final services = newServices(profile: citiesProfile.copyWith(categories: {cartographer.Category.countries, cartographer.Category.cities}));
      await pumpHome(tester, services);
      await tester.tap(find.byKey(const Key('category-countries')));
      await tester.pump();
      expect(services.profile.profile.categories, {cartographer.Category.cities});
      expect(find.text('4 villes par étude, 10 s pour les retenir, avec propositions'), findsOneWidget);
    });

    testWidgets('éteindre la dernière Catégorie est refusé', (tester) async {
      final services = newServices();
      await pumpHome(tester, services);
      await tester.tap(find.byKey(const Key('category-countries')));
      await tester.pump();
      expect(services.profile.profile.categories, {cartographer.Category.countries});
    });

    testWidgets('avec les villes seules, seuls les genres qui leur conviennent sont proposés', (tester) async {
      await pumpHome(tester, newServices(profile: citiesProfile));
      await tester.scrollUntilVisible(find.byKey(const Key('kind-name-position')), 100, scrollable: find.byType(Scrollable).first);
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pump();
      expect(find.byKey(const Key('kind-position-name')), findsOneWidget);
      expect(find.byKey(const Key('kind-name-position')), findsOneWidget);
      expect(find.byKey(const Key('kind-shape-name')), findsNothing);
      expect(find.byKey(const Key('kind-name-capital')), findsNothing);
    });

    testWidgets('villes seules et aucun genre qui leur convienne : « Jouer » est désactivé et le dit', (tester) async {
      final onlyCapitals = cartographer.CartographerProfile(
        {const cartographer.LinkKind(cartographer.Facet.name, cartographer.Facet.capital)},
        categories: {cartographer.Category.cities},
      );
      await pumpHome(tester, newServices(profile: onlyCapitals));
      expect(find.byKey(const Key('cannot-play')), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('start'))).onPressed, isNull);
    });

    testWidgets('« Jouer » est actif et rien n\'est signalé dans le cas normal', (tester) async {
      await pumpHome(tester, newServices());
      expect(find.byKey(const Key('cannot-play')), findsNothing);
      expect(tester.widget<FilledButton>(find.byKey(const Key('start'))).onPressed, isNotNull);
    });
  });

  group('une ville en question', () {
    final evaluate = cartographer.EvaluateCartographerAnswer();

    Future<void> pumpQuestion(WidgetTester tester, cartographer.RecallQuestion question) async {
      usePixel(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: QuestionView(
                baseMap: map,
                question: question,
                onAnswer: (answer) => evaluate(map, question, answer),
                onNext: () {},
                sounds: RecordingSounds(),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('placer : l\'énoncé nomme la ville, toucher sa position est exact', (tester) async {
      final question = cartographer.RecallQuestion(
        itemId: 'city:lima',
        kind: const cartographer.LinkKind(cartographer.Facet.name, cartographer.Facet.position),
        aid: cartographer.RecallAid.free,
      );
      await pumpQuestion(tester, question);
      expect(find.text('Où se trouve : Lima ?'), findsOneWidget);
      await tapMapOn(tester, map, 'city:lima');
      expect(find.text('Exact !'), findsOneWidget);
    });

    testWidgets('placer : toucher une autre ville est raté', (tester) async {
      final question = cartographer.RecallQuestion(
        itemId: 'city:lima',
        kind: const cartographer.LinkKind(cartographer.Facet.name, cartographer.Facet.position),
        aid: cartographer.RecallAid.free,
      );
      await pumpQuestion(tester, question);
      await tapMapOn(tester, map, 'city:buenos-aires');
      expect(find.text('Raté.'), findsOneWidget);
    });

    testWidgets('nommer : « Quelle est cette ville ? » avec des propositions de villes', (tester) async {
      final question = cartographer.RecallQuestion(
        itemId: 'city:lima',
        kind: const cartographer.LinkKind(cartographer.Facet.position, cartographer.Facet.name),
        aid: cartographer.RecallAid.choices,
        choices: const ['Lima', 'Quito', 'Bogota', 'Caracas'],
      );
      await pumpQuestion(tester, question);
      expect(find.text('Quelle est cette ville ?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('choice-0')));
      await tester.pump();
      expect(find.text('Exact !'), findsOneWidget);
    });

    testWidgets('la carte ne montre pas la ville demandée avant la réponse', (tester) async {
      final question = cartographer.RecallQuestion(
        itemId: 'city:lima',
        kind: const cartographer.LinkKind(cartographer.Facet.name, cartographer.Facet.position),
        aid: cartographer.RecallAid.free,
      );
      await pumpQuestion(tester, question);
      final view = tester.widget<CartographerMapView>(find.byType(CartographerMapView));
      expect(view.fills, isEmpty);
      expect(view.labels, isEmpty);
    });
  });

  group('la carte', () {
    Future<void> pumpMap(WidgetTester tester, {Set<String> labels = const {}, Set<String>? focus, Map<String, Color> fills = const {}}) async {
      usePixel(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: pixelSize.width,
              height: 500,
              child: CartographerMapView(baseMap: map, labels: labels, focus: focus, fills: fills),
            ),
          ),
        ),
      );
    }

    testWidgets('se dessine avec des villes mises en avant, nommées ou colorées, sans erreur', (tester) async {
      await pumpMap(
        tester,
        labels: {'city:lima', 'city:bogota', 'city:quito'},
        focus: {'city:lima', 'city:bogota', 'city:quito'},
        fills: {'city:santiago': Colors.green},
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('se dessine avec toutes les villes et tous les pays nommés à la fois, sans erreur', (tester) async {
      await pumpMap(tester, labels: {for (final item in map.items) item.id});
      expect(tester.takeException(), isNull);
    });
  });

  group('une Partie de villes', () {
    test('se joue de bout en bout : seulement des villes, jamais un pays', () {
      final seen = <String>{};
      final run = CartographerRun(
        baseMap: map,
        level: cartographer.CartographerLevels.byNumber(3),
        profile: citiesProfile,
        language: cartographer.NameLanguage.fr,
        masteryBefore: cartographer.Mastery.empty,
        prepare: cartographer.PrepareCartographerPuzzles(random: cartographer.SystemRandomSource(2)),
      );
      var guard = 0;
      while (run.stage != RunStage.finished && guard++ < 500) {
        switch (run.stage) {
          case RunStage.studyIntro:
            run.beginStudy();
          case RunStage.study:
            run.endStudy();
          case RunStage.distraction:
            run.endDistraction();
          case RunStage.questions:
            final item = run.questionItem;
            seen.add(item.id);
            run.answer(
              run.question.kind.gesture == cartographer.Gesture.place
                  ? cartographer.PlacedAnswer(item.anchor)
                  : cartographer.TypedAnswer(map.textFor(item, run.question.kind.answer, cartographer.NameLanguage.fr)),
            );
            run.next();
          case RunStage.trayRecall:
            throw StateError('pas de Plateau dans cette Partie');
          case RunStage.sequence:
            throw StateError('pas de Séquence dans cette Partie');
          case RunStage.finished:
            break;
        }
      }
      expect(run.stage, RunStage.finished);
      expect(seen, isNotEmpty);
      expect(seen.every((id) => id.startsWith('city:')), isTrue, reason: '$seen');
    });
  });

  group('stockage du Profil', () {
    test('une Catégorie allumée est retenue, la dernière ne s\'éteint pas', () async {
      final store = InMemoryCartographerProfileStore();
      final controller = CartographerProfileController(store);
      await controller.setCategoryActive(cartographer.Category.cities, true);
      expect(controller.profile.categories, {cartographer.Category.countries, cartographer.Category.cities});
      expect((await store.load()).categories, {cartographer.Category.countries, cartographer.Category.cities});

      await controller.setCategoryActive(cartographer.Category.countries, false);
      await controller.setCategoryActive(cartographer.Category.cities, false);
      expect(controller.profile.categories, {cartographer.Category.cities});
    });

    test('allumer un genre de Lien ne fait pas perdre les Catégories', () async {
      final controller = CartographerProfileController(InMemoryCartographerProfileStore(citiesProfile));
      await controller.load();
      await controller.setKindActive(const cartographer.LinkKind(cartographer.Facet.name, cartographer.Facet.capital), true);
      expect(controller.profile.categories, {cartographer.Category.cities});
    });
  });
}
