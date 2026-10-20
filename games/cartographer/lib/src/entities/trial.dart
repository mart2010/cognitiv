/// L'Épreuve d'une Partie : sa structure complète, de l'encodage au Rappel
/// (`games/cartographer/CONTEXT.md`). Le joueur la choisit à l'accueil, comme son Niveau.
enum Trial {
  /// Le Repérage, les Études-éclair des Éléments ratés, puis le Bilan. Héritée de la première
  /// tranche ; ADR 0011 retire le Repérage, elle sera reprise ou remplacée.
  flashStudy,

  /// Plateau : des Éléments montrés ensemble, puis tous replacés.
  tray,
}
