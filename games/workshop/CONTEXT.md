# L'atelier

Jeu de raisonnement et logique à règle cachée : une machine transforme des créatures, le joueur déduit la règle d'après des exemples et l'applique à une nouvelle entrée. Utilise les termes énigme, partie, niveau et score de la plateforme.

## Language

### Modèle

**Matrice**:
La grille de Cellules que la machine transforme, de dimensions m×n fixées par le niveau, pas nécessairement carrée. Transposer ou pivoter une Matrice rectangulaire change ses dimensions.
_Avoid_: Grille (réservé au contexte Grille), plateau
_Code_: `Matrix`

**Cellule**:
Une case de la Matrice, portant une Forme et une Couleur.
_Avoid_: Case, tuile
_Code_: `Cell`

**Forme**:
L'apparence géométrique d'une Cellule : Rond, Carré, Triangle, ou Vide.
_Code_: `Shape`

**Couleur**:
L'une des couleurs d'une palette fixe qu'une Cellule non vide peut porter.
_Code_: `Color`

**Rôle de case vide**:
Un attribut de Cellule, valide seulement quand sa Forme est Vide : Active (une Règle peut la cibler précisément — vider une cellule, taquin, gravité) ou Fixe (jamais ciblée, sert seulement à alléger les grandes Matrices). Rendu identique pour les deux (pointillé), pour ne jamais trahir la règle par un motif toujours vide dans les exemples.
_Avoid_: Type de case vide
_Code_: `EmptyCellRole`

### Règles

**Règle**:
Une transformation précise que la machine applique à la Matrice (ex. Miroir horizontal, Rotation 180°) : l'élément atomique et fini du Catalogue de règles. Une énigme combine jusqu'à trois Règles distinctes — pas nécessairement de Familles différentes.
_Avoid_: Loi, transformation
_Code_: `Rule`

**Famille de règle**:
Un regroupement de Règles qui partagent le même principe (ex. Miroir regroupe Miroir horizontal et Miroir vertical). Le Profil de génération active ou désactive des Familles entières.
_Avoid_: Type de règle, catégorie
_Code_: `RuleFamily`

**Catalogue de règles**:
L'ensemble fini des Règles qu'un jeu connaît, groupées en Familles. Le solveur ne cherche que dans ce catalogue.
_Avoid_: Bibliothèque, moteur de règles
_Code_: `RuleCatalog`

**Miroir**:
Famille de règle qui inverse la Matrice selon son axe horizontal ou vertical.
_Code_: `Mirror`

**Rotation**:
Famille de règle qui tourne la Matrice de 90° ou 180°. La rotation 180° est nommée explicitement plutôt que laissée comme composition implicite de deux Miroirs, moins lisible pour le joueur qui la perçoit comme un seul geste.
_Code_: `Rotation`

**Transposition**:
Famille de règle qui reflète la Matrice selon sa diagonale principale ou sa diagonale secondaire (anti-diagonale). Change les dimensions d'une Matrice rectangulaire.
_Code_: `Transposition`

**Décalage cyclique**:
Famille de règle qui décale les lignes ou colonnes de la Matrice en boucle (façon tore), sans dépendre de cases vides. Distincte de la Gravité (qui en dépend) et du Taquin (qui ne déplace que la case vide).
_Avoid_: Rotation de ligne, wrap
_Code_: `CyclicShift`

**Taquin**:
Famille de règle où seule une case vide Active se déplace d'une position dans la Matrice, à la manière du jeu de taquin.
_Avoid_: Glissement
_Code_: `Sliding`

**Gravité**:
Famille de règle où les Cellules non vides tombent vers un bord de la Matrice, comblant les cases vides Actives sur leur passage.
_Code_: `Gravity`

**Cycle de couleur**:
Famille de règle qui avance la Couleur d'une ou plusieurs Cellules d'un cran dans un ordre fixe, globalement ou limitée à une ligne ou une colonne. Repérée en playtest comme peu intuitive.
_Code_: `ColorCycle`

**Cycle de forme**:
Famille de règle qui avance la Forme d'une ou plusieurs Cellules d'un cran dans un ordre fixe, globalement ou limitée à une ligne ou une colonne. Repérée en playtest comme peu intuitive.
_Code_: `ShapeCycle`

**Conditionnelle**:
Famille de règle qui transforme une Cellule selon un critère portant sur une autre de ses propriétés (ex. toute Cellule d'une Couleur donnée devient une Forme donnée). Repérée en playtest comme peu intuitive.
_Avoid_: Règle if/then
_Code_: `Conditional`

**Profil de génération**:
La préférence d'un joueur pour L'atelier : quelles Familles de règles le générateur et le solveur peuvent utiliser. Un seul par couple joueur/jeu, partagé par tous les niveaux — pas un réglage par niveau. Stocké par la plateforme comme l'état de reprise : une donnée opaque que le jeu décrit, sans être lue ni interprétée par la plateforme (voir ADR 0008).
_Avoid_: Filtre de règles, réglages
_Code_: `GenerationProfile`

### Énigmes

**Énigme juste**:
Une énigme de règle cachée où toutes les Règles du catalogue compatibles avec les exemples donnent la même sortie pour la question, et où chaque mauvaise réponse vient d'une Règle plausible qui échoue sur au moins un exemple.
_Avoid_: Énigme valide, énigme à solution unique
_Code_: `FairPuzzle`
