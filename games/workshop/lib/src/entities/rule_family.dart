/// Famille de règle : un regroupement de Règles qui partagent le même principe
/// (`games/workshop/CONTEXT.md`). Le Profil de génération active ou désactive des
/// Familles entières, pas des Règles individuelles (ADR 0008).
enum RuleFamily {
  mirror,
  rotation,
  transposition,
  cyclicShift,
  sliding,
  packing,
  colorCycle,
  shapeCycle,
  conditional,
}
