import 'package:cognitiv_app/workshop/profile/workshop_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workshop/workshop.dart' as workshop;

void main() {
  late WorkshopProfileController controller;
  late InMemoryProfileStore store;

  setUp(() {
    store = InMemoryProfileStore();
    controller = WorkshopProfileController(store);
  });

  test('démarre sur le réglage par défaut', () {
    expect(controller.profile, workshop.GenerationProfile.intuitiveDefaults);
  });

  test('active une Famille avancée et persiste le choix', () async {
    await controller.setFamilyActive(workshop.RuleFamily.colorCycle, true);

    expect(controller.profile.isActive(workshop.RuleFamily.colorCycle), isTrue);
    expect((await store.load()).isActive(workshop.RuleFamily.colorCycle), isTrue);
  });

  test('désactive une Famille', () async {
    await controller.setFamilyActive(workshop.RuleFamily.packing, false);
    expect(controller.profile.isActive(workshop.RuleFamily.packing), isFalse);
  });

  test('refuse de désactiver la dernière Famille', () async {
    for (final family in workshop.RuleFamily.values) {
      await controller.setFamilyActive(family, false);
    }
    expect(controller.profile.activeFamilies, hasLength(1));
  });

  test('tout activer puis revenir au réglage par défaut', () async {
    await controller.activateAll();
    expect(controller.profile, workshop.GenerationProfile.allFamilies);
    await controller.resetToDefaults();
    expect(controller.profile, workshop.GenerationProfile.intuitiveDefaults);
  });

  test("ne prévient pas l'interface quand rien ne change", () async {
    var notified = 0;
    controller.addListener(() => notified++);
    await controller.resetToDefaults();
    expect(notified, 0);
  });

  group('SharedPreferencesProfileStore', () {
    test('sauve puis recharge', () async {
      SharedPreferences.setMockInitialValues({});
      final prefsStore = SharedPreferencesProfileStore();
      const profile = workshop.GenerationProfile({workshop.RuleFamily.mirror});
      await prefsStore.save(profile);
      expect((await prefsStore.load()).activeFamilies, {workshop.RuleFamily.mirror});
    });

    test('une donnée illisible ou vide redonne le réglage par défaut', () async {
      SharedPreferences.setMockInitialValues({'workshop.profile': 'pas du json'});
      expect(
        await SharedPreferencesProfileStore().load(),
        workshop.GenerationProfile.intuitiveDefaults,
      );

      SharedPreferences.setMockInitialValues({'workshop.profile': '{"activeFamilies":[]}'});
      expect(
        await SharedPreferencesProfileStore().load(),
        workshop.GenerationProfile.intuitiveDefaults,
      );
    });
  });
}
