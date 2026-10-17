/// Rôle de case vide : valide seulement quand la Forme d'une Cellule est `Shape.empty`
/// (`games/workshop/CONTEXT.md`). Le rendu des deux rôles est identique pour le joueur ;
/// seule une Règle ciblée (taquin, tassement) distingue une case Active d'une case Fixe.
enum EmptyCellRole { active, fixed }
