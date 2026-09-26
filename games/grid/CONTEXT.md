# Grille

Jeu de déduction sur grille à solution unique (famille Takuzu/Binairo), jeu de comparaison face à L'atelier. Utilise les termes énigme, partie, niveau et score de la plateforme.

## Language

**Grille**:
Le plateau de cases à remplir, de taille fixée par le niveau.
_Avoid_: Plateau, tableau
_Code_: `Grid`

**Case**:
Une cellule de la grille, vide ou portant un symbole. Certaines sont données au départ et non modifiables.
_Avoid_: Cellule, tuile
_Code_: `Cell`

**Symbole**:
L'une des deux valeurs qu'une case peut porter. L'habillage est propre à Cognitiv, sans reprendre celui des jeux commerciaux du genre.
_Avoid_: Pion, marque
_Code_: `Symbol`

**Contrainte**:
Une règle du genre que toute grille remplie doit respecter : pas trois symboles identiques d'affilée, autant de chaque symbole par ligne et par colonne.
_Avoid_: Règle (réservé à L'atelier)
_Code_: `Constraint`

**Énigme juste**:
Une grille de départ qui n'admet qu'une seule solution, garantie par le solveur. Plus strict que dans L'atelier, où seule la réponse doit être unique.
_Avoid_: Grille valide
_Code_: `FairPuzzle`
