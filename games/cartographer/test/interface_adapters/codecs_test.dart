import 'dart:convert';

import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

import '../support/real_base_map.dart';

void main() {
  group('BaseMapCodec', () {
    final map = loadSouthAmerica();

    test('décode les 13 Éléments de la vraie Carte', () {
      expect(map.id, 'south_america');
      expect(map.items, hasLength(13));
      final guyane = map.itemById('GUF');
      expect(guyane.kind, ItemKind.territory);
      expect(guyane.belongsTo, 'FRA');
      expect(guyane.neighbors, {'BRA', 'SUR'});
      expect(guyane.textFor(Facet.capital, NameLanguage.fr), 'Cayenne');
    });

    test('Facettes disponibles : pas de drapeau tant que les données n\'en ont pas', () {
      expect(map.items.every((i) => i.hasFacet(Facet.name) && i.hasFacet(Facet.capital) && i.hasFacet(Facet.position)), isTrue);
      expect(map.items.any((i) => i.hasFacet(Facet.flag)), isFalse);
    });

    test('lit un drapeau quand les données en portent un', () {
      final json = jsonDecode(jsonEncode({
        'schemaVersion': 1,
        'baseMap': {'id': 't', 'frame': [0, 0, 1, 1]},
        'items': [
          {
            'id': 'AAA', 'kind': 'country', 'belongsTo': 'AAA', 'flag': 'flags/aaa',
            'names': {'en': 'A', 'fr': 'A'}, 'population': null, 'anchor': [0.5, 0.5],
            'capitals': <Object>[], 'neighbors': <Object>[], 'outline': <Object>[],
          },
        ],
      })) as Map<String, dynamic>;
      final item = BaseMapCodec.fromJson(json).items.single;
      expect(item.hasFacet(Facet.flag), isTrue);
      expect(item.flagAsset, 'flags/aaa');
    });

    test('refuse un schéma inconnu', () {
      expect(() => BaseMapCodec.fromJson({'schemaVersion': 99}), throwsFormatException);
    });
  });

  group('CartographerPuzzleCodec', () {
    final map = loadSouthAmerica();

    test("aller-retour d'une Partie complète, via JSON texte", () {
      final puzzles = GenerateCartographerPuzzles(random: SystemRandomSource(5)).call(GenerateCartographerRequest(
        baseMap: map,
        level: CartographerLevels.byNumber(2),
        profile: CartographerProfile.defaults(),
        language: NameLanguage.fr,
      ));
      final restored = [
        for (final p in puzzles) CartographerPuzzleCodec.fromJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>),
      ];
      expect([for (final p in restored) p.toJson()], [for (final p in puzzles) p.toJson()]);
      expect(restored.last, isA<DelayedRecall>());
      expect(restored.first, isA<FlashStudy>());
    });

    test('refuse un type inconnu', () {
      expect(() => CartographerPuzzleCodec.fromJson({'type': 'x', 'language': 'fr', 'questions': <Object>[]}), throwsFormatException);
    });
  });

  group('CartographerProfileCodec', () {
    test('aller-retour du Profil par défaut', () {
      final profile = CartographerProfile.defaults();
      final restored = CartographerProfileCodec.fromJson(jsonDecode(jsonEncode(profile.toJson())) as Map<String, dynamic>);
      expect(restored.linkKinds, profile.linkKinds);
    });

    test('un Profil vide ou non pris en charge est refusé', () {
      expect(() => CartographerProfile({}), throwsArgumentError);
      expect(() => CartographerProfile({const LinkKind(Facet.name, Facet.shape)}), throwsArgumentError);
    });
  });
}
