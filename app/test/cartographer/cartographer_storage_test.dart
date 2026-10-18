import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:cognitiv_app/cartographer/storage/cartographer_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _positionOfName = cartographer.LinkKind(cartographer.Facet.name, cartographer.Facet.position);
const _capitalOfName = cartographer.LinkKind(cartographer.Facet.name, cartographer.Facet.capital);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Maîtrise', () {
    final mastery = cartographer.Mastery({
      const cartographer.MasteryKey('south_america', 'PRY', _positionOfName): cartographer.Knowledge.shaky,
      const cartographer.MasteryKey('africa', 'KEN', _capitalOfName): cartographer.Knowledge.solid,
    });

    test('aller-retour par SharedPreferences', () async {
      await SharedPreferencesMasteryStore().save(mastery);
      expect((await SharedPreferencesMasteryStore().load()).states, mastery.states);
    });

    test('rien de stocké : Maîtrise vide', () async {
      expect((await SharedPreferencesMasteryStore().load()).isEmpty, isTrue);
    });

    test('une donnée illisible ou d\'une version inconnue ne plante pas : on repart à vide', () async {
      SharedPreferences.setMockInitialValues({'cartographer.mastery': 'pas du json'});
      expect((await SharedPreferencesMasteryStore().load()).isEmpty, isTrue);
      SharedPreferences.setMockInitialValues({'cartographer.mastery': '{"version":99,"links":[]}'});
      expect((await SharedPreferencesMasteryStore().load()).isEmpty, isTrue);
    });

    test('le contrôleur charge, remplace et persiste', () async {
      final store = InMemoryMasteryStore(mastery);
      final controller = CartographerMasteryController(store);
      var notified = 0;
      controller.addListener(() => notified++);

      await controller.load();
      expect(controller.mastery.states, mastery.states);

      await controller.replace(cartographer.Mastery.empty);
      expect((await store.load()).isEmpty, isTrue);
      expect(notified, 2);
    });

    test("réinitialiser une Carte de base n'efface pas les autres", () async {
      final controller = CartographerMasteryController(InMemoryMasteryStore(mastery));
      await controller.load();
      await controller.resetBaseMap('south_america');
      expect(controller.mastery.of('south_america', 'PRY', _positionOfName), isNull);
      expect(controller.mastery.of('africa', 'KEN', _capitalOfName), cartographer.Knowledge.solid);
    });
  });

  group('Profil', () {
    test('démarre sur le Profil par défaut', () {
      expect(
        CartographerProfileController(InMemoryCartographerProfileStore()).profile.linkKinds,
        cartographer.CartographerProfile.defaults().linkKinds,
      );
    });

    test('active un genre de Lien et persiste le choix', () async {
      final store = InMemoryCartographerProfileStore();
      final controller = CartographerProfileController(store);
      const extra = cartographer.LinkKind(cartographer.Facet.position, cartographer.Facet.capital);
      await controller.setKindActive(extra, true);
      expect(controller.profile.linkKinds, contains(extra));
      expect((await store.load()).linkKinds, contains(extra));
    });

    test('refuse de désactiver le dernier genre de Lien', () async {
      final controller = CartographerProfileController(InMemoryCartographerProfileStore());
      for (final kind in cartographer.CartographerProfile.defaults().linkKinds) {
        await controller.setKindActive(kind, false);
      }
      expect(controller.profile.linkKinds, hasLength(1));
    });

    test('aller-retour par SharedPreferences, puis repli sur le défaut si illisible', () async {
      final profile = cartographer.CartographerProfile({_capitalOfName});
      await SharedPreferencesCartographerProfileStore().save(profile);
      expect((await SharedPreferencesCartographerProfileStore().load()).linkKinds, {_capitalOfName});

      SharedPreferences.setMockInitialValues({'cartographer.profile': '{"linkKinds":[]}'});
      expect(
        (await SharedPreferencesCartographerProfileStore().load()).linkKinds,
        cartographer.CartographerProfile.defaults().linkKinds,
      );
    });
  });
}
