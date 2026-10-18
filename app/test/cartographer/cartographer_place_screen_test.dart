import 'dart:convert';
import 'dart:io';

import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:cognitiv_app/audio/game_sounds.dart';
import 'package:cognitiv_app/cartographer/cartographer_place_screen.dart';
import 'package:cognitiv_app/cartographer/map_projection.dart';
import 'package:cognitiv_app/main_cartographer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Écran d'un Pixel 8a (412 × 915 dp) moins la barre d'état et la barre de navigation.
const _pixelSize = Size(412, 780);

class _RecordingSounds implements GameSounds {
  final events = <String>[];
  @override
  void tap() => events.add('tap');
  @override
  void success() => events.add('success');
  @override
  void failure() => events.add('failure');
}

cartographer.BaseMap _loadMap() => cartographer.BaseMapCodec.fromJson(
  jsonDecode(File('assets/maps/south_america.json').readAsStringSync()) as Map<String, dynamic>,
);

cartographer.RecallQuestion _where(String id) => cartographer.RecallQuestion(
  itemId: id,
  kind: const cartographer.LinkKind(cartographer.Facet.name, cartographer.Facet.position),
  aid: cartographer.RecallAid.free,
);

Future<void> _pump(WidgetTester tester, cartographer.BaseMap map, List<String> ids, {GameSounds? sounds}) async {
  tester.view.physicalSize = _pixelSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: CartographerPlaceScreen(
        baseMap: map,
        buildQuestions: () => [for (final id in ids) _where(id)],
        sounds: sounds ?? const SilentGameSounds(),
      ),
    ),
  );
}

/// Touche la carte à l'ancre de l'Élément [id] : le point, en pixels, que le joueur toucherait.
Future<void> _tapOn(WidgetTester tester, cartographer.BaseMap map, String id) async {
  final finder = find.byKey(const Key('cartographer-map'));
  final projection = MapProjection(map.frame, tester.getSize(finder));
  await tester.tapAt(tester.getTopLeft(finder) + projection.toCanvas(map.itemById(id).anchor));
  await tester.pump();
}

void main() {
  final map = _loadMap();

  test("l'asset de l'app est identique à la donnée générée du paquet", () {
    expect(
      File('assets/maps/south_america.json').readAsStringSync(),
      File('../games/cartographer/data/south_america.json').readAsStringSync(),
      reason: 'Recopier games/cartographer/data/south_america.json dans app/assets/maps/',
    );
  });

  testWidgets("toucher le bon pays : « Exact ! », la carte colore et nomme l'Élément, succès sonore", (tester) async {
    final sounds = _RecordingSounds();
    await _pump(tester, map, ['PRY', 'PER'], sounds: sounds);
    expect(find.text('Où se trouve : Paraguay ?'), findsOneWidget);
    expect(find.byKey(const Key('feedback')), findsNothing);

    await _tapOn(tester, map, 'PRY');

    expect(find.text('Exact !'), findsOneWidget);
    expect(sounds.events, ['success']);
  });

  testWidgets("toucher un pays éloigné : raté, échec doux, bouton Suivant", (tester) async {
    final sounds = _RecordingSounds();
    await _pump(tester, map, ['PRY', 'PER'], sounds: sounds);

    await _tapOn(tester, map, 'BOL');

    expect(find.textContaining('Raté'), findsOneWidget);
    expect(sounds.events, ['failure']);
    expect(find.byKey(const Key('next')), findsOneWidget);
  });

  testWidgets('toucher un voisin proche : « Presque »', (tester) async {
    await _pump(tester, map, ['SUR']);

    await _tapOn(tester, map, 'GUF');

    expect(find.textContaining('Presque'), findsOneWidget);
  });

  testWidgets("après la réponse, la carte ne prend plus de toucher", (tester) async {
    final sounds = _RecordingSounds();
    await _pump(tester, map, ['PRY', 'PER'], sounds: sounds);
    await _tapOn(tester, map, 'PRY');
    await _tapOn(tester, map, 'BOL');
    expect(sounds.events, ['success']);
    expect(find.text('Exact !'), findsOneWidget);
  });

  testWidgets('parcours complet : questions, résultat, recommencer', (tester) async {
    await _pump(tester, map, ['PRY', 'PER', 'URY']);
    expect(find.text('Question 1 sur 3'), findsOneWidget);

    await _tapOn(tester, map, 'PRY');
    await tester.tap(find.byKey(const Key('next')));
    await tester.pump();
    expect(find.text('Question 2 sur 3'), findsOneWidget);
    expect(find.text('Où se trouve : Pérou ?'), findsOneWidget);

    await _tapOn(tester, map, 'ARG'); // faux
    await tester.tap(find.byKey(const Key('next')));
    await tester.pump();

    await _tapOn(tester, map, 'URY');
    expect(find.text('Terminer'), findsOneWidget);
    await tester.tap(find.byKey(const Key('next')));
    await tester.pump();

    expect(find.text('2 sur 3'), findsOneWidget);
    expect(find.byKey(const Key('result-score')), findsOneWidget);

    await tester.tap(find.byKey(const Key('restart')));
    await tester.pump();
    expect(find.text('Question 1 sur 3'), findsOneWidget);
  });

  testWidgets("l'écran tient sans défilement ni débordement sur un Pixel", (tester) async {
    await _pump(tester, map, ['PRY']);
    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsNothing);
    final mapSize = tester.getSize(find.byKey(const Key('cartographer-map')));
    expect(mapSize.height, greaterThan(300));
  });

  test("les questions d'entraînement sont toutes des Placer, d'Éléments distincts par Étude", () {
    final level = cartographer.CartographerLevels.byNumber(3);
    for (var seed = 0; seed < 20; seed++) {
      final questions = placeQuestions(map, level, seed);
      expect(questions, hasLength(level.itemCount * level.studyCount));
      expect(questions.every((q) => q.kind.gesture == cartographer.Gesture.place), isTrue);
      for (var s = 0; s < level.studyCount; s++) {
        final ids = questions.skip(s * level.itemCount).take(level.itemCount).map((q) => q.itemId);
        expect(ids.toSet(), hasLength(level.itemCount));
      }
    }
  });
}
