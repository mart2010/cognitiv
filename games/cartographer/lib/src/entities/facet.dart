/// Facette d'un Élément : une manière de le connaître (`games/recall/CONTEXT.md`). Les
/// Facettes de la première tranche ; les Grandeurs et les Relations viendront avec leurs
/// Gestes. Le Drapeau est une apparence visuelle comme le Contour : il n'est proposé que
/// pour les Éléments qui en ont un.
enum Facet {
  /// Le nom de l'Élément (Attribut).
  name,

  /// La capitale (Attribut).
  capital,

  /// L'emplacement sur la Scène (Position).
  position,

  /// Le contour, montré seul (Forme).
  shape,

  /// Le drapeau (Forme, apparence visuelle).
  flag;

  /// Une Facette textuelle se tape ; les autres se montrent ou se désignent.
  bool get isText => this == Facet.name || this == Facet.capital;
}
