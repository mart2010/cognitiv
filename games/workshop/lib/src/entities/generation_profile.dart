import 'rule_family.dart';

/// Profil de génération : la préférence d'un joueur pour L'atelier, quelles Familles de
/// règles le générateur et le solveur peuvent utiliser (`games/workshop/CONTEXT.md`,
/// ADR 0008). Un seul par couple joueur/jeu, partagé par tous les niveaux. La plateforme
/// le stocke comme une donnée opaque, au même titre que l'État de reprise (ADR 0004) :
/// la (dé)sérialisation appartient aux Interface Adapters, pas à cette Entité.
class GenerationProfile {
  final Set<RuleFamily> activeFamilies;
  const GenerationProfile(this.activeFamilies);

  bool isActive(RuleFamily family) => activeFamilies.contains(family);

  /// Catalogue complet actif, pour les tests et le jeu de comparaison.
  static const GenerationProfile allFamilies = GenerationProfile({
    RuleFamily.mirror,
    RuleFamily.rotation,
    RuleFamily.transposition,
    RuleFamily.cyclicShift,
    RuleFamily.sliding,
    RuleFamily.gravity,
    RuleFamily.colorCycle,
    RuleFamily.shapeCycle,
    RuleFamily.conditional,
  });

  /// Réglage par défaut retenu suite au test externe du 2026-09-28 (`docs/PLAN.md`) :
  /// seules les Familles géométriques, lues d'un coup d'œil, sont actives par défaut.
  static const GenerationProfile intuitiveDefaults = GenerationProfile({
    RuleFamily.mirror,
    RuleFamily.rotation,
    RuleFamily.transposition,
    RuleFamily.cyclicShift,
    RuleFamily.sliding,
    RuleFamily.gravity,
  });
}
