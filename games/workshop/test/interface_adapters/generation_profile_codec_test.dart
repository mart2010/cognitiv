import 'dart:convert';

import 'package:test/test.dart';
import 'package:workshop/workshop.dart';

void main() {
  test('aller-retour JSON préserve les Familles actives', () {
    const profile = GenerationProfile({RuleFamily.mirror, RuleFamily.gravity});
    final roundTripped = jsonDecode(jsonEncode(profile.toJson())) as Map<String, dynamic>;
    final decoded = GenerationProfileCodec.fromJson(roundTripped);
    expect(decoded.activeFamilies, profile.activeFamilies);
  });
}
