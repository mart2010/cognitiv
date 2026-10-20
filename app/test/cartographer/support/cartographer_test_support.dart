import 'dart:convert';
import 'dart:io';

import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:cognitiv_app/audio/game_sounds.dart';
import 'package:cognitiv_app/cartographer/cartographer_services.dart';
import 'package:cognitiv_app/cartographer/map_projection.dart';
import 'package:cognitiv_app/cartographer/question_view.dart';
import 'package:cognitiv_app/cartographer/storage/cartographer_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Écran d'un Pixel 8a (412 × 915 dp) moins la barre d'état et la barre de navigation.
const pixelSize = Size(412, 780);

cartographer.BaseMap loadMap() => cartographer.BaseMapCodec.fromJson(
  jsonDecode(File('assets/maps/south_america.json').readAsStringSync()) as Map<String, dynamic>,
);

class RecordingSounds implements GameSounds {
  final events = <String>[];
  @override
  void tap() => events.add('tap');
  @override
  void success() => events.add('success');
  @override
  void failure() => events.add('failure');
}

CartographerServices newServices({
  RecordingSounds? sounds,
  int seed = 1,
  cartographer.Mastery? mastery,
  cartographer.CartographerProfile? profile,
}) => CartographerServices(
  baseMap: loadMap(),
  mastery: CartographerMasteryController(InMemoryMasteryStore(mastery)),
  profile: CartographerProfileController(InMemoryCartographerProfileStore(profile)),
  sounds: sounds ?? RecordingSounds(),
  randomFactory: () => cartographer.SystemRandomSource(seed),
);

void usePixel(WidgetTester tester) {
  tester.view.physicalSize = pixelSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Touche la carte à l'ancre de l'Élément [id], ou en plein océan.
Future<void> tapMapOn(WidgetTester tester, cartographer.BaseMap map, String id) async {
  final finder = find.byKey(const Key('cartographer-map'));
  final projection = MapProjection(map.frame, tester.getSize(finder));
  await tester.tapAt(tester.getTopLeft(finder) + projection.toCanvas(map.itemById(id).anchor));
  await tester.pump();
}

Future<void> tapOcean(WidgetTester tester, cartographer.BaseMap map) async {
  final finder = find.byKey(const Key('cartographer-map'));
  final projection = MapProjection(map.frame, tester.getSize(finder));
  await tester.tapAt(tester.getTopLeft(finder) + projection.toCanvas(const cartographer.GeoPoint(-30, -40)));
  await tester.pump();
}

/// Répond à la question affichée, juste ou faux, selon son genre et son aide, puis attend le verdict.
Future<void> answerCurrent(WidgetTester tester, cartographer.BaseMap map, {required bool correct}) async {
  final question = tester.widget<QuestionView>(find.byType(QuestionView)).question;
  final item = map.itemById(question.itemId);
  if (question.kind.gesture == cartographer.Gesture.place) {
    correct ? await tapMapOn(tester, map, item.id) : await tapOcean(tester, map);
    return;
  }
  final right = map.textFor(item, question.kind.answer, cartographer.NameLanguage.fr);
  if (question.aid == cartographer.RecallAid.choices) {
    final index = correct
        ? question.choices.indexOf(right)
        : question.choices.indexWhere((c) => c != right && !map.acceptedTexts(item, question.kind.answer).contains(c));
    await tester.tap(find.byKey(Key('choice-$index')));
  } else {
    await tester.enterText(find.byKey(const Key('answer-field')), correct ? right : 'zzzzzz');
    await tester.tap(find.byKey(const Key('submit')));
  }
  await tester.pump();
}
