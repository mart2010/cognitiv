/// Forme : l'apparence géométrique d'une Cellule (`games/workshop/CONTEXT.md`).
/// Les trois formes non vides ont une symétrie de rotation à 90° : une Règle de
/// Rotation ne change que la position des Cellules, jamais l'orientation du glyphe
/// lui-même, donc aucune forme ne doit paraître « tournée » dans le mauvais sens.
enum Shape { round, square, cross, empty }
