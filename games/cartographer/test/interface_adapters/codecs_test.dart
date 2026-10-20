import 'dart:convert';

import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

import '../support/real_base_map.dart';
import '../support/scripted_player.dart';

void main() {
  group('BaseMapCodec', () {
    final map = loadSouthAmerica();

    test('décode les 13 pays et les villes de la vraie Carte', () {
      expect(map.id, 'south_america');
      expect(map.itemsOf(Category.countries), hasLength(13));
      expect(map.itemsOf(Category.cities), hasLength(30));
      expect(map.categories, [Category.countries, Category.cities]);
      final guyane = map.itemById('GUF');
      expect(guyane.attributes.flag(AttributeKey.territory), isTrue);
      expect(guyane.attributes.text(AttributeKey.state), 'FRA');
      expect(guyane.neighbors, {'BRA', 'SUR'});
      expect(map.textFor(guyane, Facet.capital, NameLanguage.fr), 'Cayenne');
    });

    test('une ville est un Point contenu dans son pays, avec son rang de notoriété', () {
      final lima = map.itemById('city:lima');
      expect(lima.category, Category.cities);
      expect(lima.geometry, isA<PointGeometry>());
      expect(lima.containedIn, 'PER');
      expect(lima.isCapital, isTrue);
      expect(lima.population, greaterThan(5000000));
      expect(map.itemById('city:sao-paulo').attributes.integer(AttributeKey.rank), 1);
    });

    test('la capitale est la ville contenue marquée capitale ; la Bolivie en a deux, le Chili une alternative', () {
      expect({for (final c in map.capitalsOf(map.itemById('BOL'))) c.names.fr}, {'La Paz', 'Sucre'});
      final chile = map.itemById('CHL');
      expect(map.capitalsOf(chile).map((c) => c.names.fr), ['Santiago', 'Valparaíso']);
      expect(map.primaryCapitalsOf(chile).map((c) => c.names.fr), ['Santiago']);
      expect(map.textFor(chile, Facet.capital, NameLanguage.fr), 'Santiago');
      expect(map.acceptedTexts(chile, Facet.capital), containsAll(['Santiago', 'Valparaíso']));
    });

    test('toute ville est dans un pays de la Carte, et seules les capitales ont le rôle de capitale', () {
      final countryIds = map.itemsOf(Category.countries).map((c) => c.id).toSet();
      for (final city in map.itemsOf(Category.cities)) {
        expect(countryIds, contains(city.containedIn), reason: city.id);
        expect(city.attributes.has(AttributeKey.capitalRole), city.isCapital, reason: city.id);
      }
    });

    test("Facettes : le contour n'existe que pour un pays, la capitale que pour un pays qui en a une", () {
      final lima = map.itemById('city:lima');
      expect(map.hasFacet(lima, Facet.position), isTrue);
      expect(map.hasFacet(lima, Facet.shape), isFalse);
      expect(map.hasFacet(lima, Facet.capital), isFalse);
      expect(map.itemsOf(Category.countries).every((i) => map.hasFacet(i, Facet.capital) && map.hasFacet(i, Facet.shape)), isTrue);
      expect(map.items.any((i) => map.hasFacet(i, Facet.flag)), isFalse);
    });

    Map<String, dynamic> oneItem(Map<String, Object?> item) => jsonDecode(jsonEncode({
          'schemaVersion': 2,
          'baseMap': {'id': 't', 'frame': [0, 0, 1, 1]},
          'items': [item],
        })) as Map<String, dynamic>;

    test('lit un drapeau et une Ligne quand les données en portent', () {
      final country = BaseMapCodec.fromJson(oneItem({
        'id': 'AAA', 'category': 'countries', 'names': {'en': 'A', 'fr': 'A'},
        'geometry': {'type': 'area', 'anchor': [0.5, 0.5], 'polygons': <Object>[]},
        'attributes': {'flag': 'flags/aaa', 'languages': ['fr', 'en']},
      }));
      final item = country.items.single;
      expect(country.hasFacet(item, Facet.flag), isTrue);
      expect(item.flagAsset, 'flags/aaa');
      expect(item.attributes.list('languages'), ['fr', 'en']);
    });

    test('refuse une Géométrie qui ne correspond pas à la Catégorie', () {
      expect(
        () => BaseMapCodec.fromJson(oneItem({
          'id': 'x', 'category': 'cities', 'names': {'en': 'X', 'fr': 'X'},
          'geometry': {'type': 'area', 'anchor': [0, 0], 'polygons': <Object>[]},
          'attributes': <String, Object>{},
        })),
        throwsArgumentError,
      );
    });

    test('refuse une Catégorie inconnue, un schéma inconnu ou l\'ancien schéma', () {
      expect(
        () => BaseMapCodec.fromJson(oneItem({
          'id': 'x', 'category': 'volcanoes', 'names': {'en': 'X', 'fr': 'X'},
          'geometry': {'type': 'point', 'position': [0, 0]}, 'attributes': <String, Object>{},
        })),
        throwsFormatException,
      );
      expect(() => BaseMapCodec.fromJson({'schemaVersion': 99}), throwsFormatException);
      expect(() => BaseMapCodec.fromJson({'schemaVersion': 1}), throwsFormatException);
    });
  });

  group('CartographerPuzzleCodec', () {
    final map = loadSouthAmerica();

    test("aller-retour d'une Partie complète (Repérage, Études, Bilan), via JSON texte", () {
      final request = PrepareCartographerRequest(
        baseMap: map,
        level: CartographerLevels.byNumber(2),
        profile: CartographerProfile.defaults(),
        language: NameLanguage.fr,
      );
      final history = playWholeRun(PrepareCartographerPuzzles(random: SystemRandomSource(5)), request, (_, __) => knowsNothing);
      final puzzles = [for (final p in history) p.puzzle];
      final restored = [
        for (final p in puzzles) CartographerPuzzleCodec.fromJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>),
      ];
      expect([for (final p in restored) p.toJson()], [for (final p in puzzles) p.toJson()]);
      expect(restored.first, isA<Screening>());
      expect(restored.whereType<FlashStudy>(), isNotEmpty);
      expect(restored.last, isA<DelayedRecall>());
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
      expect(restored.categories, {Category.countries});
    });

    test('les Catégories activées font l\'aller-retour', () {
      final profile = CartographerProfile(CartographerProfile.defaults().linkKinds, categories: {Category.cities});
      final restored = CartographerProfileCodec.fromJson(jsonDecode(jsonEncode(profile.toJson())) as Map<String, dynamic>);
      expect(restored.categories, {Category.cities});
    });

    test('un Profil enregistré avant les Catégories active les pays', () {
      final old = {
        'linkKinds': [
          {'cue': 'position', 'answer': 'name'},
        ],
      };
      expect(CartographerProfileCodec.fromJson(old).categories, {Category.countries});
    });

    test('un Profil sans Catégorie est refusé', () {
      expect(() => CartographerProfile(CartographerProfile.defaults().linkKinds, categories: {}), throwsArgumentError);
    });

    test('un Profil vide ou non pris en charge est refusé', () {
      expect(() => CartographerProfile({}), throwsArgumentError);
      expect(() => CartographerProfile({const LinkKind(Facet.name, Facet.shape)}), throwsArgumentError);
    });
  });
}
