# L'atelier

Jeu de raisonnement et logique à règle cachée : une machine transforme des créatures, le joueur déduit la règle d'après des exemples et l'applique à une nouvelle entrée. Utilise les termes énigme, partie, niveau et score de la plateforme.

## Language

**Règle**:
Une transformation que la machine applique à une entrée (change une couleur, ajoute un élément, inverse une position). Une règle peut en combiner plusieurs (jusqu'à trois).
_Avoid_: Loi, transformation
_Code_: `Rule`

**Catalogue de règles**:
L'ensemble fini des règles qu'un jeu connaît. Le solveur ne cherche que dans ce catalogue.
_Avoid_: Bibliothèque, moteur de règles
_Code_: `RuleCatalog`

**Énigme juste**:
Une énigme de règle cachée où toutes les règles du catalogue compatibles avec les exemples donnent la même sortie pour la question, et où chaque mauvaise réponse vient d'une règle plausible qui échoue sur au moins un exemple.
_Avoid_: Énigme valide, énigme à solution unique
_Code_: `FairPuzzle`
