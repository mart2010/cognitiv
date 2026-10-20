/// L'Épreuve d'une Partie : sa structure complète, de l'encodage au Rappel
/// (`games/cartographer/CONTEXT.md`). Le joueur la choisit à l'accueil, comme son Niveau.
enum Trial {
  /// Le Repérage, les Études-éclair des Éléments ratés, puis le Bilan. Héritée de la première
  /// tranche ; ADR 0011 retire le Repérage, elle sera reprise ou remplacée.
  flashStudy,

  /// Plateau : des Éléments montrés ensemble, puis tous replacés.
  tray,

  /// Séquence : des Éléments surlignés un à un, à retoucher dans le même ordre ; elle s'allonge
  /// à chaque réussite.
  sequence,
}

/// Comment un Plateau montre ses Éléments pendant l'étude : un réglage de l'Épreuve, pas une
/// Épreuve à part. Le Rappel est le même dans les deux cas.
enum TrayPresentation {
  /// Tous les Éléments à la fois, pendant la durée d'étude du Niveau.
  together,

  /// Un Élément à la fois, chacun un temps fixe (`PrepareTrayPuzzles.secondsPerItem`), puis il
  /// disparaît quand le suivant arrive. Le joueur ne choisit pas son temps.
  oneByOne,
}
