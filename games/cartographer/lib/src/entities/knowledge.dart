/// Ce que le jeu sait d'un Lien (`games/cartographer/CONTEXT.md`, Maîtrise). Trois états, sans
/// dates : un Lien jamais vu n'a pas d'état et se traite comme `toLearn`.
enum Knowledge {
  /// Raté la dernière fois qu'il a été posé.
  toLearn,

  /// Réussi une fois.
  shaky,

  /// Réussi de nouveau à une Partie suivante.
  solid;

  /// Rang pour classer du moins connu au mieux connu ; un Lien sans état vaut 0.
  static int rank(Knowledge? knowledge) => knowledge?.index ?? 0;

  /// Après une réussite : un cran de plus, jamais au-delà de `solid`.
  Knowledge get promoted => switch (this) {
        Knowledge.toLearn => Knowledge.shaky,
        Knowledge.shaky || Knowledge.solid => Knowledge.solid,
      };

  /// Compte comme connu pour proposer un autre genre de Lien.
  bool get isKnown => this != Knowledge.toLearn;
}
