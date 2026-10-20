import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:cognitiv_app/cartographer/cartographer_home_screen.dart';
import 'package:cognitiv_app/cartographer/cartographer_map_view.dart';
import 'package:cognitiv_app/cartographer/cartographer_run.dart';
import 'package:cognitiv_app/cartographer/cartographer_run_screen.dart';
import 'package:cognitiv_app/cartographer/map_projection.dart';
import 'package:cognitiv_app/cartographer/study_views.dart';
import 'package:cognitiv_app/cartographer/tray_views.dart';
import 'package:cognitiv_app/cartographer/verdict_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cartographer_test_support.dart';

final _level3 = cartographer.CartographerLevels.byNumber(3);

void main() {
  final map = loadMap();
  final citiesProfile = cartographer.CartographerProfile.defaults().copyWith(categories: {cartographer.Category.cities});
  const wrongPoint = cartographer.GeoPoint(-30, -40); // en plein Atlantique

  CartographerRun newRun({cartographer.Mastery? mastery, int seed = 1, void Function(cartographer.Mastery)? onFinished}) =>
      CartographerRun(
        baseMap: map,
        level: _level3,
        profile: citiesProfile,
        language: cartographer.NameLanguage.fr,
        masteryBefore: mastery ?? cartographer.Mastery.empty,
        prepare: cartographer.PrepareTrayPuzzles(random: cartographer.SystemRandomSource(seed)),
        onFinished: onFinished,
      );

  List<cartographer.CartographerAnswer> perfect(CartographerRun run) => [
    for (final q in run.current!.questions) cartographer.PlacedAnswer(map.itemById(q.itemId).anchor),
  ];

  void toRecall(CartographerRun run) {
    run.beginStudy();
    run.endStudy();
    run.endDistraction();
  }

  group('la Partie (machine à états)', () {
    test('un Plateau : annonce, étude, attente, Rappel de tout, puis le suivant', () {
      final run = newRun();
      expect(run.current, isA<cartographer.Tray>());
      expect(run.isTrayRun, isTrue);
      expect(run.stage, RunStage.studyIntro);
      expect((run.studyNumber, run.studyTotal), (1, 3));
      run.beginStudy();
      expect(run.stage, RunStage.study);
      run.endStudy();
      expect(run.stage, RunStage.distraction);
      run.endDistraction();
      expect(run.stage, RunStage.trayRecall);

      run.answerTray(perfect(run));
      expect(run.answered, isTrue);
      run.next();
      expect(run.stage, RunStage.studyIntro);
      expect((run.studyNumber, run.studyTotal), (2, 3));
      expect(run.history, hasLength(1));
    });

    test('trois Plateaux joués, puis le résultat : score, Maîtrise retenue, aucune suggestion de genre', () {
      final saved = <cartographer.Mastery>[];
      final run = newRun(onFinished: saved.add);
      for (var i = 0; i < 3; i++) {
        toRecall(run);
        run.answerTray(perfect(run));
        run.next();
      }
      expect(run.stage, RunStage.finished);
      expect(run.trayResults, [(exact: 4, total: 4), (exact: 4, total: 4), (exact: 4, total: 4)]);
      expect(run.exactCount, 12);
      expect(run.result.score, 12 * _level3.pointsPerQuestion);
      expect(run.result.levelCleared, isTrue);
      expect(run.suggestedKinds, isEmpty);
      expect(saved, hasLength(1));
      expect(run.masteryAfter.states.values.toSet(), {cartographer.Knowledge.shaky});
    });

    test('des Plateaux ratés : rien d\'exact, niveau non franchi, Éléments à apprendre', () {
      final run = newRun();
      for (var i = 0; i < 3; i++) {
        toRecall(run);
        run.answerTray([for (final _ in run.current!.questions) const cartographer.PlacedAnswer(wrongPoint)]);
        run.next();
      }
      expect(run.exactCount, 0);
      expect(run.result.levelCleared, isFalse);
      expect(run.masteryAfter.states.values.toSet(), {cartographer.Knowledge.toLearn});
    });

    test('un Plateau est évalué d\'un coup : les verdicts suivent chaque réponse', () {
      final run = newRun();
      toRecall(run);
      final answers = perfect(run);
      answers[1] = const cartographer.PlacedAnswer(wrongPoint);
      final evaluations = run.answerTray(answers);
      expect(evaluations.map((e) => e.isCorrect), [true, false, true, true]);
    });

    test('répondre hors du Rappel, deux fois, ou avec le mauvais nombre de réponses est une erreur de l\'app', () {
      final run = newRun();
      expect(() => run.answerTray(perfect(run)), throwsStateError); // encore à l'annonce
      toRecall(run);
      expect(() => run.answerTray([const cartographer.PlacedAnswer(wrongPoint)]), throwsArgumentError);
      run.answerTray(perfect(run));
      expect(() => run.answerTray(perfect(run)), throwsStateError);
      expect(() => newRun().next(), throwsStateError);
    });

    test('le Plateau suivant ne reprend pas les Éléments du précédent', () {
      final run = newRun();
      final seen = <String>{};
      for (var i = 0; i < 3; i++) {
        final ids = run.current!.questions.map((q) => q.itemId).toSet();
        expect(seen.intersection(ids), isEmpty);
        seen.addAll(ids);
        toRecall(run);
        run.answerTray(perfect(run));
        run.next();
      }
    });
  });

  group('le Rappel à l\'écran', () {
    // Trois villes, assez éloignées pour qu'un toucher sur l'une ne soit jamais « proche » d'une autre.
    final tray = cartographer.Tray(
      language: cartographer.NameLanguage.fr,
      studySeconds: 10,
      distractionSeconds: 5,
      questions: [
        for (final id in ['city:lima', 'city:bogota', 'city:santiago'])
          cartographer.RecallQuestion(itemId: id, kind: cartographer.PrepareTrayPuzzles.linkKind, aid: cartographer.RecallAid.free),
      ],
    );
    final evaluate = cartographer.EvaluateCartographerAnswer();

    late List<cartographer.CartographerAnswer> submitted;
    var nexts = 0;

    Future<void> pumpTray(WidgetTester tester, {RecordingSounds? sounds}) async {
      submitted = [];
      nexts = 0;
      usePixel(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TrayRecallView(
                  baseMap: map,
                  tray: tray,
                  header: 'Plateau 1 sur 3 · Rappel',
                  onSubmit: (answers) {
                    submitted = answers;
                    return [for (var i = 0; i < answers.length; i++) evaluate(map, tray.questions[i], answers[i])];
                  },
                  onNext: () => nexts++,
                  sounds: sounds ?? RecordingSounds(),
                ),
              ),
            ),
          ),
        ),
      );
    }

    CartographerMapView mapView(WidgetTester tester) => tester.widget<CartographerMapView>(find.byType(CartographerMapView));

    bool chipSelected(WidgetTester tester, int i) => tester.widget<ChoiceChip>(find.byKey(Key('tray-chip-$i'))).selected;

    testWidgets('au départ : les noms à placer, aucun repère, « Valider » inactif, rien de révélé', (tester) async {
      await pumpTray(tester);
      expect(find.text('Plateau 1 sur 3 · Rappel'), findsOneWidget);
      expect(find.text('Replacez les villes'), findsOneWidget);
      expect(find.text('1 · Lima'), findsOneWidget);
      expect(find.text('2 · Bogota'), findsOneWidget);
      expect(find.text('3 · Santiago'), findsOneWidget);
      expect(mapView(tester).markers, isEmpty);
      expect(mapView(tester).fills, isEmpty);
      expect(mapView(tester).labels, isEmpty);
      expect(chipSelected(tester, 0), isTrue);
      expect(tester.widget<FilledButton>(find.byKey(const Key('tray-submit'))).onPressed, isNull);
    });

    testWidgets('toucher la carte pose le repère du nom choisi, puis passe au nom suivant', (tester) async {
      final sounds = RecordingSounds();
      await pumpTray(tester, sounds: sounds);
      await tapMapOn(tester, map, 'city:lima');
      expect(mapView(tester).markers.map((m) => m.text), ['1']);
      expect(chipSelected(tester, 1), isTrue);
      await tapMapOn(tester, map, 'city:bogota');
      expect(mapView(tester).markers.map((m) => m.text), ['1', '2']);
      expect(chipSelected(tester, 2), isTrue);
      expect(sounds.events, ['tap', 'tap']);
      expect(tester.widget<FilledButton>(find.byKey(const Key('tray-submit'))).onPressed, isNull, reason: 'il en reste un');
      expect(find.byKey(const Key('feedback')), findsNothing, reason: 'aucun verdict avant « Valider »');
    });

    testWidgets('on peut placer dans l\'ordre qu\'on veut : choisir un nom, puis toucher', (tester) async {
      await pumpTray(tester);
      await tester.tap(find.byKey(const Key('tray-chip-2')));
      await tester.pump();
      await tapMapOn(tester, map, 'city:santiago');
      expect(mapView(tester).markers.map((m) => m.text), ['3']);
      expect(chipSelected(tester, 0), isTrue, reason: 'le prochain nom sans repère');
    });

    testWidgets('rechoisir un nom déjà placé déplace son repère, sans en ajouter un', (tester) async {
      await pumpTray(tester);
      await tapMapOn(tester, map, 'city:lima');
      final before = mapView(tester).markers.single.point;
      await tester.tap(find.byKey(const Key('tray-chip-0')));
      await tester.pump();
      await tapMapOn(tester, map, 'city:bogota');
      final markers = mapView(tester).markers;
      expect(markers, hasLength(1));
      expect(markers.single.text, '1');
      expect(markers.single.point, isNot(before));
    });

    testWidgets('tout placé : « Valider » donne les verdicts, les vraies positions et les couleurs', (tester) async {
      final sounds = RecordingSounds();
      await pumpTray(tester, sounds: sounds);
      await tapMapOn(tester, map, 'city:lima');
      await tapMapOn(tester, map, 'city:bogota');
      await tapMapOn(tester, map, 'city:santiago');
      expect(find.text('Tout est placé. Vous pouvez encore déplacer un repère.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tray-submit')));
      await tester.pump();

      expect(submitted, hasLength(3));
      final first = (submitted[0] as cartographer.PlacedAnswer).point;
      final lima = map.itemById('city:lima').anchor;
      expect(first.lon, closeTo(lima.lon, 1e-6));
      expect(first.lat, closeTo(lima.lat, 1e-6));
      expect(find.text('3 sur 3 exactes'), findsOneWidget);
      expect(find.text('Voici où elles étaient'), findsOneWidget);
      expect(sounds.events.last, 'success');
      final view = mapView(tester);
      expect(view.labels, {'city:lima', 'city:bogota', 'city:santiago'});
      expect(view.fills.keys, view.labels);
      expect(view.markers.map((m) => m.color).toSet(), {verdictColor(cartographer.AnswerVerdict.exact)});
      expect(view.onTap, isNull, reason: 'plus rien à placer');
      expect(tester.widget<ChoiceChip>(find.byKey(const Key('tray-chip-0'))).onSelected, isNull);
    });

    testWidgets('un repère faux prend la couleur du raté, les bons restent exacts', (tester) async {
      final sounds = RecordingSounds();
      await pumpTray(tester, sounds: sounds);
      await tapMapOn(tester, map, 'city:lima');
      await tapMapOn(tester, map, 'city:bogota');
      await tapMapOn(tester, map, 'city:montevideo'); // faux pour Santiago
      await tester.tap(find.byKey(const Key('tray-submit')));
      await tester.pump();
      expect(find.text('2 sur 3 exactes'), findsOneWidget);
      expect(mapView(tester).markers.map((m) => m.color).toList(), [
        verdictColor(cartographer.AnswerVerdict.exact),
        verdictColor(cartographer.AnswerVerdict.exact),
        verdictColor(cartographer.AnswerVerdict.wrong),
      ]);
      expect(sounds.events.last, 'tap', reason: 'ni tout juste ni tout faux');
    });

    testWidgets('tout faux : le son d\'échec ; « Suivant » passe à la suite', (tester) async {
      final sounds = RecordingSounds();
      await pumpTray(tester, sounds: sounds);
      for (var i = 0; i < 3; i++) {
        await tapMapOn(tester, map, 'city:buenos-aires');
      }
      await tester.tap(find.byKey(const Key('tray-submit')));
      await tester.pump();
      expect(find.text('0 sur 3 exactes'), findsOneWidget);
      expect(sounds.events.last, 'failure');
      await tester.tap(find.byKey(const Key('next')));
      expect(nexts, 1);
    });
  });

  group('les points candidats', () {
    // Deux points bidon à l'écart des trois villes.
    const decoyA = cartographer.GeoPoint(-60, -10);
    const decoyB = cartographer.GeoPoint(-66, -28);
    final tray = cartographer.Tray(
      language: cartographer.NameLanguage.fr,
      studySeconds: 10,
      distractionSeconds: 5,
      questions: [
        for (final id in ['city:lima', 'city:bogota', 'city:santiago'])
          cartographer.RecallQuestion(itemId: id, kind: cartographer.PrepareTrayPuzzles.linkKind, aid: cartographer.RecallAid.free),
      ],
      decoys: const [decoyA, decoyB],
    );
    final evaluate = cartographer.EvaluateCartographerAnswer();

    late List<cartographer.CartographerAnswer> submitted;

    Future<void> pumpTray(WidgetTester tester) async {
      submitted = [];
      usePixel(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: TrayRecallView(
                baseMap: map,
                tray: tray,
                header: 'Plateau 1 sur 3 · Rappel',
                onSubmit: (answers) {
                  submitted = answers;
                  return [for (var i = 0; i < answers.length; i++) evaluate(map, tray.questions[i], answers[i])];
                },
                onNext: () {},
                sounds: RecordingSounds(),
              ),
            ),
          ),
        ),
      );
    }

    CartographerMapView mapView(WidgetTester tester) => tester.widget<CartographerMapView>(find.byType(CartographerMapView));

    Future<void> tapGeo(WidgetTester tester, cartographer.GeoPoint point) async {
      final finder = find.byKey(const Key('cartographer-map'));
      final projection = MapProjection(map.frame, tester.getSize(finder));
      await tester.tapAt(tester.getTopLeft(finder) + projection.toCanvas(point));
      await tester.pump();
    }

    testWidgets('la carte montre les vraies positions et les points bidon, sans les distinguer', (tester) async {
      await pumpTray(tester);
      final candidates = mapView(tester).candidates;
      expect(candidates, hasLength(5));
      expect(candidates, containsAll([decoyA, decoyB, map.itemById('city:lima').anchor]));
      expect(find.textContaining('touchez un point'), findsOneWidget);
    });

    testWidgets('un toucher dans le vide ne pose rien ; près d\'un candidat, le repère se pose dessus', (tester) async {
      await pumpTray(tester);
      await tapOcean(tester, map);
      expect(mapView(tester).markers, isEmpty);
      final nearLima = cartographer.GeoPoint(map.itemById('city:lima').anchor.lon + 0.4, map.itemById('city:lima').anchor.lat);
      await tapGeo(tester, nearLima);
      expect(mapView(tester).markers.single.point, map.itemById('city:lima').anchor);
    });

    testWidgets('choisir un point bidon donne un verdict faux', (tester) async {
      await pumpTray(tester);
      await tapGeo(tester, decoyA); // Lima
      await tapMapOn(tester, map, 'city:bogota');
      await tapMapOn(tester, map, 'city:santiago');
      await tester.tap(find.byKey(const Key('tray-submit')));
      await tester.pump();
      expect(find.text('2 sur 3 exactes'), findsOneWidget);
      expect((submitted.first as cartographer.PlacedAnswer).point, decoyA);
    });

    testWidgets('un candidat ne porte qu\'un nom : le reprendre libère le premier', (tester) async {
      await pumpTray(tester);
      await tapMapOn(tester, map, 'city:lima'); // nom 1, puis le nom 2 devient le choix
      await tapMapOn(tester, map, 'city:lima'); // nom 2 prend le même point
      expect(mapView(tester).markers.map((m) => m.text), ['2']);
    });

    testWidgets('après « Valider », les candidats disparaissent', (tester) async {
      await pumpTray(tester);
      await tapMapOn(tester, map, 'city:lima');
      await tapMapOn(tester, map, 'city:bogota');
      await tapMapOn(tester, map, 'city:santiago');
      await tester.tap(find.byKey(const Key('tray-submit')));
      await tester.pump();
      expect(mapView(tester).candidates, isEmpty);
    });
  });

  group('la présentation successive', () {
    final tray = cartographer.Tray(
      language: cartographer.NameLanguage.fr,
      studySeconds: 6,
      distractionSeconds: 5,
      presentation: cartographer.TrayPresentation.oneByOne,
      questions: [
        for (final id in ['city:lima', 'city:bogota', 'city:santiago'])
          cartographer.RecallQuestion(itemId: id, kind: cartographer.PrepareTrayPuzzles.linkKind, aid: cartographer.RecallAid.free),
      ],
    );

    testWidgets('un Élément à la fois, 2 s chacun, sans bouton « Prêt »', (tester) async {
      usePixel(tester);
      var done = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudyView(baseMap: map, study: tray, header: 'Plateau 1 sur 3', onDone: () => done++),
          ),
        ),
      );
      CartographerMapView view() => tester.widget<CartographerMapView>(find.byType(CartographerMapView));
      expect(find.byKey(const Key('study-ready')), findsNothing);
      expect(view().labels, {'city:lima'});
      expect(find.text('1 sur 3'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2100));
      expect(view().labels, {'city:bogota'});
      expect(view().focus, {'city:bogota'});
      expect(find.text('2 sur 3'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(view().labels, {'city:santiago'});
      expect(done, 0);
      await tester.pump(const Duration(seconds: 2));
      expect(done, 1);
    });

    testWidgets('l\'annonce dit un à un, 2 secondes chacun', (tester) async {
      usePixel(tester);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: StudyIntroView(study: tray, header: 'Plateau 1 sur 3', onStart: () {}))),
      );
      expect(find.text('Un à un, 2 secondes chacun.'), findsOneWidget);
    });

    testWidgets('à l\'accueil, l\'option n\'apparaît que pour le Plateau, en simultané par défaut', (tester) async {
      final services = newServices(profile: citiesProfile);
      await services.load();
      usePixel(tester);
      await tester.pumpWidget(MaterialApp(home: CartographerHomeScreen(services: services)));
      await tester.pump();
      expect(find.byKey(const Key('option-simultaneous')), findsNothing);
      await tester.tap(find.text('Plateau'));
      await tester.pump();
      final option = find.byKey(const Key('option-simultaneous'));
      await tester.scrollUntilVisible(option, 100, scrollable: find.byType(Scrollable).first);
      expect(tester.widget<SwitchListTile>(option).value, isTrue);
      await tester.tap(option);
      await tester.pump();
      expect(tester.widget<SwitchListTile>(option).value, isFalse);
      expect(find.textContaining('un toutes les 2 s'), findsOneWidget);
    });

    testWidgets('une Partie en présentation successive se joue jusqu\'au Rappel', (tester) async {
      final services = newServices(profile: citiesProfile);
      await services.load();
      usePixel(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: CartographerRunScreen(
            services: services,
            level: _level3,
            trial: cartographer.Trial.tray,
            presentation: cartographer.TrayPresentation.oneByOne,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('start-study')));
      await tester.pump();
      expect(find.byKey(const Key('study-counter')), findsOneWidget);
      await tester.pump(const Duration(seconds: 9)); // 4 villes × 2 s
      await tester.pump();
      expect(find.byKey(const Key('wait-text')), findsOneWidget);
      await tester.pump(Duration(seconds: _level3.distractionSeconds + 1));
      await tester.pump();
      expect(find.byKey(const Key('tray-submit')), findsOneWidget);
    });
  });

  group('la Partie à l\'écran', () {
    testWidgets('trois Plateaux de villes de bout en bout, puis le résultat', (tester) async {
      final services = newServices(profile: citiesProfile);
      await services.load();
      usePixel(tester);
      await tester.pumpWidget(
        MaterialApp(home: CartographerRunScreen(services: services, level: _level3, trial: cartographer.Trial.tray)),
      );

      for (var number = 1; number <= 3; number++) {
        expect(find.text('Plateau $number sur 3'), findsOneWidget);
        expect(find.text('Retenez ces 4 villes'), findsOneWidget);
        expect(find.byKey(const Key('study-note')), findsOneWidget);
        await tester.tap(find.byKey(const Key('start-study')));
        await tester.pump();
        expect(find.byKey(const Key('study-bar')), findsOneWidget);
        await tester.tap(find.byKey(const Key('study-ready')));
        await tester.pump();

        expect(find.byKey(const Key('wait-text')), findsOneWidget);
        expect(find.text('Plateau $number sur 3'), findsOneWidget);
        await tester.pump(Duration(seconds: _level3.distractionSeconds + 1));
        await tester.pump();

        expect(find.text('Plateau $number sur 3 · Rappel'), findsOneWidget);
        final questions = tester.widget<TrayRecallView>(find.byType(TrayRecallView)).tray.questions;
        for (final q in questions) {
          await tapMapOn(tester, map, q.itemId);
        }
        await tester.tap(find.byKey(const Key('tray-submit')));
        await tester.pump();
        expect(find.text('4 sur 4 exactes'), findsOneWidget);
        expect(find.text(number == 3 ? 'Terminer' : 'Suivant'), findsOneWidget);
        await tester.tap(find.byKey(const Key('next')));
        await tester.pump();
      }

      expect(find.text('12 sur 12'), findsOneWidget);
      expect(find.text('Score : ${12 * _level3.pointsPerQuestion}'), findsOneWidget);
      expect(find.text('Plateau 1 : 4 sur 4\nPlateau 2 : 4 sur 4\nPlateau 3 : 4 sur 4'), findsOneWidget);
      expect(find.byKey(const Key('suggestion')), findsNothing);
      expect(services.mastery.mastery.states.values.toSet(), {cartographer.Knowledge.shaky});
      expect(tester.takeException(), isNull);
    });

    testWidgets('quitter un Plateau en cours ne retient rien', (tester) async {
      final services = newServices(profile: citiesProfile);
      await services.load();
      usePixel(tester);
      await tester.pumpWidget(
        MaterialApp(home: CartographerRunScreen(services: services, level: _level3, trial: cartographer.Trial.tray)),
      );
      await tester.tap(find.byKey(const Key('start-study')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('study-ready')));
      await tester.pump();
      final dynamic widgetsAppState = tester.state(find.byType(Navigator));
      await widgetsAppState.maybePop();
      await tester.pump();
      expect(find.text('Quitter la Partie ?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('stay')));
      await tester.pump();
      expect(services.mastery.mastery.isEmpty, isTrue);
    });
  });

  group('l\'accueil', () {
    Future<void> pumpHome(WidgetTester tester, services) async {
      usePixel(tester);
      await tester.pumpWidget(MaterialApp(home: CartographerHomeScreen(services: services)));
      await tester.pump();
    }

    testWidgets('par défaut, l\'Étude-éclair ; choisir le Plateau change le résumé et masque les genres de Lien', (tester) async {
      await pumpHome(tester, newServices());
      expect(find.text('Un repérage, puis l\'étude de ce qu\'on ne connaît pas.'), findsOneWidget);
      expect(find.text('4 pays par étude, 10 s pour les retenir, avec propositions'), findsOneWidget);

      await tester.tap(find.text('Plateau'));
      await tester.pump();
      expect(find.text('Des repères montrés ensemble, puis tous à replacer.'), findsOneWidget);
      expect(find.text('4 pays par plateau, 10 s pour les retenir, 5 s d\'attente'), findsOneWidget);
      expect(find.text('Ce que je veux travailler'), findsNothing);
      expect(find.text('Ce que je veux apprendre'), findsOneWidget);
    });

    testWidgets('« Jouer » reste actif pour un Plateau même si aucun genre ne convient aux villes', (tester) async {
      final onlyCapitals = cartographer.CartographerProfile(
        {const cartographer.LinkKind(cartographer.Facet.name, cartographer.Facet.capital)},
        categories: {cartographer.Category.cities},
      );
      await pumpHome(tester, newServices(profile: onlyCapitals));
      expect(find.byKey(const Key('cannot-play')), findsOneWidget);
      await tester.tap(find.text('Plateau'));
      await tester.pump();
      expect(find.byKey(const Key('cannot-play')), findsNothing);
      expect(tester.widget<FilledButton>(find.byKey(const Key('start'))).onPressed, isNotNull);
    });

    testWidgets('« Jouer » lance un Plateau quand il est choisi', (tester) async {
      await pumpHome(tester, newServices());
      await tester.tap(find.text('Plateau'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('start')));
      await tester.pumpAndSettle();
      expect(find.text('Plateau 1 sur 3'), findsOneWidget);
      expect(find.text('Retenez ces 4 pays'), findsOneWidget);
    });
  });
}
