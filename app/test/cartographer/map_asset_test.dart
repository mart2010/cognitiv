import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test("l'asset de l'app est identique à la donnée générée du paquet", () {
    expect(
      File('assets/maps/south_america.json').readAsStringSync(),
      File('../games/cartographer/data/south_america.json').readAsStringSync(),
      reason: 'Recopier games/cartographer/data/south_america.json dans app/assets/maps/',
    );
  });
}
