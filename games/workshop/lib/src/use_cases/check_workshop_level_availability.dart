import '../entities/generation_profile.dart';
import '../entities/rule_catalog.dart';
import '../entities/workshop_level.dart';
import 'generate_workshop_puzzle.dart';
import 'ports/random_source.dart';

/// Dit si un Niveau reste jouable avec un Profil de génération : le Profil limite les
/// Familles de règles, et un Niveau avancé (3 Règles distinctes) peut devenir impossible
/// à générer avec trop peu de Familles (ADR 0008). Essaie de générer quelques Énigmes
/// avec un hasard propre à la vérification (`randomFactory`), donc le verdict ne dépend
/// ni du hasard de la Partie ni de l'ordre des appels.
class CheckWorkshopLevelAvailability {
  static const int _attempts = 10;

  final RuleCatalog catalog;
  final RandomSource Function() randomFactory;

  CheckWorkshopLevelAvailability({required this.catalog, required this.randomFactory});

  bool call(WorkshopLevel level, GenerationProfile profile) {
    final generate = GenerateWorkshopPuzzle(catalog: catalog, random: randomFactory());
    final request = GenerateWorkshopPuzzleRequest.forLevel(level, profile: profile);
    for (var attempt = 0; attempt < _attempts; attempt++) {
      if (generate(request) is GenerationSucceeded) return true;
    }
    return false;
  }

  /// Numéros des Niveaux jouables avec ce Profil.
  Set<int> availableLevels(GenerationProfile profile) => {
        for (final level in WorkshopLevels.all)
          if (call(level, profile)) level.number,
      };
}
