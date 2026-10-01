/// Port pour le hasard (ADR 0005) : le domaine l'injecte plutôt que d'appeler `dart:math`
/// directement, pour que les Cas d'usage de génération restent reproductibles en test
/// (doublure déterministe, pas de mock — voir `games/workshop/test/support`).
abstract class RandomSource {
  /// Un entier dans `[0, exclusiveMax)`.
  int nextInt(int exclusiveMax);

  /// Un flottant dans `[0.0, 1.0)`.
  double nextDouble();
}
