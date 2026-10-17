import 'package:workshop/workshop.dart' as workshop;

import '../audio/game_sounds.dart';
import 'profile/workshop_profile.dart';
import 'progress/workshop_progress.dart';

/// Ce que les écrans de L'atelier utilisent : les cas d'usage du domaine, le son et la
/// progression. Regroupé ici plutôt que passé écran par écran. Provisoire : le contrat
/// plateforme/jeu (ADR 0004) le remplacera quand le second jeu existera.
class WorkshopServices {
  final workshop.GenerateWorkshopPuzzle generate;
  final workshop.EvaluateWorkshopAnswer evaluate;
  final workshop.ComputeWorkshopScore computeScore;
  final WorkshopProfileController profileController;
  final workshop.CheckWorkshopLevelAvailability levelAvailability;
  final GameSounds sounds;
  final WorkshopProgressController progress;

  WorkshopServices({
    required this.generate,
    required this.evaluate,
    required this.progress,
    workshop.ComputeWorkshopScore? computeScore,
    WorkshopProfileController? profileController,
    this.sounds = const SilentGameSounds(),
  }) : computeScore = computeScore ?? workshop.ComputeWorkshopScore(),
       profileController = profileController ?? WorkshopProfileController(InMemoryProfileStore()),
       levelAvailability = workshop.CheckWorkshopLevelAvailability(
         catalog: const workshop.RuleCatalog(),
         randomFactory: () => workshop.SystemRandomSource(2026),
       );

  /// Profil de génération courant du joueur.
  workshop.GenerationProfile get profile => profileController.profile;
}
