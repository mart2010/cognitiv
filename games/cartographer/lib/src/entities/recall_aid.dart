/// Aide au rappel : la force de l'Indice au moment du Rappel (`games/recall/CONTEXT.md`).
/// Elle ne s'applique qu'aux Réponses textuelles ; placer sur la Scène n'a pas d'aide.
enum RecallAid {
  /// Saisie libre, sans rien.
  free,

  /// Première lettre et longueur du mot.
  firstLetter,

  /// Choix parmi quelques propositions.
  choices,
}
