/// Port pour le hasard (ADR 0005) : le domaine l'injecte plutôt que d'appeler `dart:math`
/// directement, pour que la génération reste reproductible en test (doublure
/// déterministe, pas de mock — voir `games/cartographer/test/support`). Même contrat que
/// celui de L'atelier ; à partager quand le paquet `platform` existera.
abstract class RandomSource {
  /// Un entier dans `[0, exclusiveMax)`.
  int nextInt(int exclusiveMax);

  /// Un flottant dans `[0.0, 1.0)`.
  double nextDouble();
}
