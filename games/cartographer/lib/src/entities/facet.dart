/// Facette d'un Élément : une manière de le connaître (`games/cartographer/CONTEXT.md`). Les
/// Facettes de la première tranche ; les autres Attributs (population, langues) et les Relations
/// viendront avec leurs Épreuves. Le Drapeau est une apparence visuelle comme le Contour : il
/// n'est proposé que pour les Éléments qui en ont un.
enum Facet {
  /// Le nom de l'Élément (Attribut).
  name,

  /// La capitale d'un pays : la ville qu'il contient et qui est marquée capitale (Relation).
  capital,

  /// L'emplacement sur la Scène (Position).
  position,

  /// Le contour, montré seul (Forme). Seulement pour une Géométrie en surface.
  shape,

  /// Le drapeau (Forme, apparence visuelle).
  flag;

  /// Une Facette textuelle se tape ; les autres se montrent ou se désignent.
  bool get isText => this == Facet.name || this == Facet.capital;
}
