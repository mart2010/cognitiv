import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:cognitiv_app/cartographer/cartographer_home_screen.dart';
import 'package:cognitiv_app/cartographer/cartographer_map_view.dart';
import 'package:cognitiv_app/cartographer/cartographer_run.dart';
import 'package:cognitiv_app/cartographer/cartographer_run_screen.dart';
import 'package:cognitiv_app/cartographer/sequence_views.dart';
import 'package:cognitiv_app/cartographer/verdict_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cartographer_test_support.dart';

final _level3 = cartographer.CartographerLevels.byNumber(3); // 1 s par repère

void main() {
  final map = loadMap();
  final citiesProfile = cartographer.CartographerProfile.defaults().copyWith(categories: {cartographer.Category.cities});
  const wrongPoint = cartographer.GeoPoint(-30, -40); // en plein Atlantique

  CartographerRun newRun({int seed = 1, void Function(cartographer.Mastery)? onFinished}) => CartographerRun(
    baseMap: map,
    level: _level3,
    profile: citiesProfile,
    language: cartographer.NameLanguage.fr,
    masteryBefore: cartographer.Mastery.empty,
    prepare: cartographer.PrepareSequencePuzzles(random: cartographer.SystemRandomSource(seed)),
    onFinished: onFinished,
  );

  List<cartographer.CartographerAnswer> perfect(CartographerRun run) => [
    for (final q in run.current!.questions) cartographer.PlacedAnswer(map.itemById(q.itemId).anchor),
  ];

  /// Réussit les manches jusqu'à ce que la séquence ait `length` Éléments (la manche de cette longueur reste à jouer).
  void playUntil(CartographerRun run, int length) {
    while (run.sequence.length < length) {
      run.answerSequence(perfect(run));
      run.next();
    }
  }

  group('la Partie (machine à états)', () {
    test('on commence à un Élément, puis la séquence s\'allonge d\'un Élément à chaque réussite', () {
      final run = newRun();
      expect(run.stage, RunStage.sequence);
      expect(run.isSequenceRun, isTrue);
      expect(run.sequence.length, 1);
      for (var expected = 2; expected <= 12; expected++) {
        final before = run.sequence.steps;
        run.answerSequence(perfect(run));
        run.next();
        expect(run.stage, RunStage.sequence, reason: 'tant qu\'on réussit, la Partie continue');
        expect(run.sequence.length, expected);
        expect(run.sequence.steps.take(before.length), before);
      }
    });

    test('une faute arrête la Partie : le reste de la manche compte pour raté, le Score est la dernière longueur réussie', () {
      cartographer.Mastery? saved;
      final run = newRun(onFinished: (m) => saved = m);
      playUntil(run, 4);
      final steps = run.sequence.steps;
      // Bon, bon, puis une faute au troisième : le quatrième n'est pas tenté.
      run.answerSequence([
        cartographer.PlacedAnswer(map.itemById(steps[0]).anchor),
        cartographer.PlacedAnswer(map.itemById(steps[1]).anchor),
        const cartographer.PlacedAnswer(wrongPoint),
      ]);
      run.next();
      expect(run.stage, RunStage.finished);
      expect(run.longestSequence, 3);
      expect(run.result.score, 3 * _level3.pointsPerQuestion);
      expect(run.result.levelCleared, isFalse);
      expect(run.history.last.verdicts, [
        cartographer.AnswerVerdict.exact,
        cartographer.AnswerVerdict.exact,
        cartographer.AnswerVerdict.wrong,
        cartographer.AnswerVerdict.wrong,
      ]);
      expect(run.suggestedKinds, isEmpty);
      expect(saved, isNotNull);
    });

    test('réussir jusqu\'à la longueur cible franchit le Niveau', () {
      final run = newRun();
      playUntil(run, cartographer.ComputeSequenceScore.targetLength + 1);
      run.answerSequence([const cartographer.PlacedAnswer(wrongPoint)]);
      run.next();
      expect(run.stage, RunStage.finished);
      expect(run.longestSequence, cartographer.ComputeSequenceScore.targetLength);
      expect(run.result.levelCleared, isTrue);
    });

    test('on ne répond qu\'une fois, et pas plus de réponses que d\'Éléments', () {
      final run = newRun();
      expect(() => run.answerSequence([...perfect(run), ...perfect(run)]), throwsArgumentError);
      run.answerSequence(perfect(run));
      expect(() => run.answerSequence(perfect(run)), throwsStateError);
    });
  });

  group('la manche à l\'écran', () {
    final evaluate = cartographer.EvaluateCartographerAnswer();
    final green = verdictColor(cartographer.AnswerVerdict.exact).withValues(alpha: 0.85);
    final red = verdictColor(cartographer.AnswerVerdict.wrong).withValues(alpha: 0.85);

    // Un jeu de quatre villes ; Lima revient dans la séquence, comme au Simon.
    cartographer.Sequence of(List<String> pool, List<String> steps) =>
        cartographer.Sequence(language: cartographer.NameLanguage.fr, pool: pool, steps: steps, stepMillis: 1000);
    final cityPool = ['city:lima', 'city:bogota', 'city:santiago', 'city:caracas'];
    final cities = of(cityPool, ['city:lima', 'city:bogota']);
    const lookDuration = Duration(milliseconds: 700 + 2 * 1250);

    late List<cartographer.CartographerAnswer> submitted;
    var nexts = 0;

    Future<void> pumpSequence(WidgetTester tester, cartographer.Sequence sequence, {RecordingSounds? sounds}) async {
      submitted = [];
      nexts = 0;
      usePixel(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SequenceView(
                  baseMap: map,
                  sequence: sequence,
                  header: 'Séquence de ${sequence.length}',
                  judge: (index, answer) => evaluate(map, sequence.questions[index], answer),
                  onSubmit: (answers) => submitted = answers,
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

    testWidgets('les Éléments sont surlignés et nommés un à un, dans l\'ordre, puis la main passe au joueur', (tester) async {
      await pumpSequence(tester, cities);
      expect(find.text('Regardez…'), findsOneWidget);
      expect(mapView(tester).labels, isEmpty);
      expect(mapView(tester).focus, isNull, reason: 'la carte garde ses tons tant que rien n\'est surligné');
      await tester.pump(const Duration(milliseconds: 750));
      expect(mapView(tester).labels, {'city:lima'});
      expect(mapView(tester).focus, {'city:lima'});
      await tester.pump(const Duration(milliseconds: 1000)); // fin du premier, silence entre deux
      expect(mapView(tester).labels, isEmpty);
      expect(mapView(tester).focus, isNull);
      await tester.pump(const Duration(milliseconds: 300));
      expect(mapView(tester).labels, {'city:bogota'});
      expect(mapView(tester).onTap, isNull, reason: 'pas touchable pendant le visionnage');
      await tester.pump(const Duration(milliseconds: 1400));
      expect(find.text('À vous : 1 sur 2'), findsOneWidget);
      expect(mapView(tester).onTap, isNotNull);
    });

    testWidgets('un même Élément peut revenir dans la séquence', (tester) async {
      await pumpSequence(tester, of(cityPool, ['city:lima', 'city:lima', 'city:bogota']));
      await tester.pump(const Duration(milliseconds: 750));
      expect(mapView(tester).labels, {'city:lima'});
      await tester.pump(const Duration(milliseconds: 1300));
      expect(mapView(tester).labels, {'city:lima'}, reason: 'le second Lima');
      await tester.pump(const Duration(milliseconds: 4000));
      await tapMapOn(tester, map, 'city:lima');
      await tapMapOn(tester, map, 'city:lima');
      await tapMapOn(tester, map, 'city:bogota');
      expect(submitted, hasLength(3));
      expect(find.text('Bravo !'), findsOneWidget);
    });

    testWidgets('les villes du jeu sont des ronds neutres, ni plus ni moins', (tester) async {
      await pumpSequence(tester, cities);
      await tester.pump(lookDuration);
      expect(mapView(tester).candidates, hasLength(4));
    });

    testWidgets('chaque Élément touché s\'allume en vert puis s\'éteint ; la manche réussie enchaîne seule', (tester) async {
      final sounds = RecordingSounds();
      await pumpSequence(tester, cities, sounds: sounds);
      await tester.pump(lookDuration);
      await tapMapOn(tester, map, 'city:lima');
      expect(submitted, isEmpty, reason: 'pas avant la fin de la manche');
      expect(mapView(tester).focus, {'city:lima'});
      expect(mapView(tester).fills, {'city:lima': green});
      expect(mapView(tester).labels, {'city:lima'}, reason: 'une ville touchée est nommée');
      await tester.pump(SequenceView.flash + const Duration(milliseconds: 50));
      expect(mapView(tester).focus, isNull);
      expect(mapView(tester).labels, {'city:lima'}, reason: 'le nom reste jusqu\'au toucher suivant');
      await tapMapOn(tester, map, 'city:bogota');
      expect(mapView(tester).labels, {'city:bogota'}, reason: 'puis il passe à la ville suivante');
      expect(submitted, hasLength(2));
      expect(find.text('Bravo !'), findsOneWidget);
      expect(sounds.events.last, 'success');
      expect(nexts, 0);
      await tester.pump(SequenceView.successPause + const Duration(milliseconds: 50));
      expect(nexts, 1);
    });

    testWidgets('le mauvais Élément s\'allume en rouge, le bon est nommé en vert, « Terminer »', (tester) async {
      final sounds = RecordingSounds();
      await pumpSequence(tester, cities, sounds: sounds);
      await tester.pump(lookDuration);
      await tapMapOn(tester, map, 'city:lima');
      await tapMapOn(tester, map, 'city:santiago'); // il fallait Bogotá
      expect(submitted, hasLength(2));
      expect(mapView(tester).fills, {'city:bogota': green, 'city:santiago': red});
      expect(mapView(tester).labels, {'city:bogota', 'city:santiago'}, reason: 'la bonne ville et celle touchée');
      expect(mapView(tester).onTap, isNull);
      expect(sounds.events.last, 'failure');
      await tester.pump(const Duration(seconds: 5));
      expect(mapView(tester).fills, hasLength(2), reason: 'la faute reste affichée');
      expect(nexts, 0, reason: 'on laisse le temps de voir la faute');
      await tester.tap(find.byKey(const Key('next')));
      expect(nexts, 1);
    });

    testWidgets('un toucher dans le vide ne compte pas', (tester) async {
      await pumpSequence(tester, cities);
      await tester.pump(lookDuration);
      await tapOcean(tester, map);
      expect(mapView(tester).fills, isEmpty);
      expect(submitted, isEmpty);
    });

    testWidgets('des pays : le fond reste pâle d\'un bout à l\'autre, seul le pays allumé reprend sa teinte', (tester) async {
      final countries = of(['BRA', 'ARG', 'CHL', 'PER'], ['BRA', 'ARG']);
      await pumpSequence(tester, countries);
      CartographerMapView view() => mapView(tester);
      expect(view().dimUnfocused, isTrue);
      expect(view().focus, isEmpty, reason: 'avant le visionnage : tous pâles, aucun ne change');
      await tester.pump(const Duration(milliseconds: 750));
      expect(view().focus, {'BRA'});
      await tester.pump(const Duration(milliseconds: 1100)); // entre deux Éléments
      expect(view().focus, isEmpty);
      await tester.pump(lookDuration);
      expect(view().focus, isEmpty, reason: 'à vous : rien n\'annonce le jeu');
      expect(view().candidates, isEmpty);
      await tapMapOn(tester, map, 'COL'); // hors du jeu : une faute
      expect(submitted, hasLength(1));
      expect(view().fills['COL'], red);
      expect(view().focus, {'COL', 'BRA'});
      expect(view().labels, {'BRA'}, reason: 'le bon Élément est nommé après la faute');
    });

    testWidgets('des villes : les pays ne sont jamais mis en retrait', (tester) async {
      await pumpSequence(tester, cities);
      expect(mapView(tester).dimUnfocused, isFalse);
    });

    testWidgets('des pays : les bons touchers réussissent la manche', (tester) async {
      await pumpSequence(tester, of(['BRA', 'ARG', 'CHL', 'PER'], ['BRA', 'ARG']));
      await tester.pump(lookDuration);
      await tapMapOn(tester, map, 'BRA');
      expect(mapView(tester).fills, {'BRA': green});
      await tapMapOn(tester, map, 'ARG');
      expect(submitted, hasLength(2));
      expect(find.text('Bravo !'), findsOneWidget);
    });

    testWidgets('l\'écart entre deux Éléments suit la vitesse', (tester) async {
      expect(SequenceView.gapFor(1200), const Duration(milliseconds: 300));
      expect(SequenceView.gapFor(400), const Duration(milliseconds: 100));
      expect(SequenceView.gapFor(200), const Duration(milliseconds: 100), reason: 'jamais sous 100 ms');
    });
  });

  group('la Partie à l\'écran', () {
    testWidgets('de l\'accueil au résultat : deux manches réussies, puis une faute', (tester) async {
      final services = newServices(profile: citiesProfile);
      await services.load();
      usePixel(tester);
      await tester.pumpWidget(
        MaterialApp(home: CartographerRunScreen(services: services, level: _level3, trial: cartographer.Trial.sequence)),
      );
      cartographer.Sequence round() => tester.widget<SequenceView>(find.byType(SequenceView)).sequence;

      expect(find.text('Séquence de 1'), findsOneWidget);
      var steps = round().steps;
      await tester.pump(const Duration(seconds: 4));
      await tapMapOn(tester, map, steps[0]);
      await tester.pump(SequenceView.successPause + const Duration(milliseconds: 50));

      expect(find.text('Séquence de 2'), findsOneWidget);
      steps = round().steps;
      await tester.pump(const Duration(seconds: 5));
      await tapMapOn(tester, map, steps[0]);
      await tapMapOn(tester, map, steps[1]);
      await tester.pump(SequenceView.successPause + const Duration(milliseconds: 50));

      expect(find.text('Séquence de 3'), findsOneWidget);
      final third = round();
      await tester.pump(const Duration(seconds: 7));
      await tapMapOn(tester, map, third.pool.firstWhere((id) => id != third.steps[0])); // faute dès le premier
      await tester.tap(find.byKey(const Key('next')));
      await tester.pump();

      expect(find.byKey(const Key('result-score')), findsOneWidget);
      expect(find.text('Score : ${2 * _level3.pointsPerQuestion}'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('éléments dans la plus longue séquence'), findsOneWidget);
    });
  });

  group('l\'accueil', () {
    testWidgets('choisir la Séquence change le résumé, sans option de présentation', (tester) async {
      final services = newServices(profile: citiesProfile);
      await services.load();
      usePixel(tester);
      await tester.pumpWidget(MaterialApp(home: CartographerHomeScreen(services: services)));
      await tester.pump();
      await tester.tap(find.text('Séquence'));
      await tester.pump();
      expect(find.textContaining('retoucher dans le même ordre'), findsOneWidget);
      expect(find.byKey(const Key('option-simultaneous')), findsNothing);
      expect(find.textContaining('jeu de 6 villes, 1,0 s par repère, objectif : 8'), findsOneWidget); // Niveau 3
      expect(tester.widget<FilledButton>(find.byKey(const Key('start'))).onPressed, isNotNull);
    });
  });
}
