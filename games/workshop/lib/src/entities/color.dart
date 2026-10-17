/// Couleur : l'une des couleurs qu'une Cellule non vide peut porter
/// (`games/workshop/CONTEXT.md`). L'énumération contient toutes les Couleurs connues ;
/// la palette réellement utilisée par un jeu en est un sous-ensemble ordonné (par défaut
/// `defaultPalette`, via `RuleCatalog.colorOrder`). Augmenter le nombre de Couleurs plus
/// tard = passer une palette plus large au Catalogue, sans toucher au domaine.
enum Color {
  blue,
  yellow,
  red,
  green,
  purple;

  /// Trois Couleurs bien distinctes, y compris en cas de daltonisme : bleu et jaune
  /// s'opposent sur l'axe bleu-jaune, et le rouge se distingue du jaune par sa clarté.
  static const defaultPalette = [Color.blue, Color.yellow, Color.red];
}
