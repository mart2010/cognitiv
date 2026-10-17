import 'package:test/test.dart';
import 'package:workshop/workshop.dart';

void main() {
  final check = CheckWorkshopLevelAvailability(
    catalog: const RuleCatalog(),
    randomFactory: () => SystemRandomSource(11),
  );

  test('avec le Profil par défaut, tous les Niveaux sont jouables', () {
    expect(
      check.availableLevels(GenerationProfile.intuitiveDefaults),
      {for (final l in WorkshopLevels.all) l.number},
    );
  });

  test('avec toutes les Familles, tous les Niveaux sont jouables', () {
    expect(
      check.availableLevels(GenerationProfile.allFamilies),
      {for (final l in WorkshopLevels.all) l.number},
    );
  });

  test('avec une seule Famille pauvre en Règles, les Niveaux à 3 Règles disparaissent', () {
    // Transposition n'offre que 2 Règles : impossible d'en combiner 3 distinctes.
    final available = check.availableLevels(const GenerationProfile({RuleFamily.transposition}));
    expect(available, isNot(contains(8)));
    expect(available, isNot(contains(10)));
  });

  test('le verdict est le même à chaque appel', () {
    const profile = GenerationProfile({RuleFamily.mirror, RuleFamily.rotation});
    expect(check.availableLevels(profile), check.availableLevels(profile));
  });
}
