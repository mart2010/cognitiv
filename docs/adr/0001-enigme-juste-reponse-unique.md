# Une énigme de règle cachée est juste si la réponse est unique, pas la règle

Dans L'atelier, plusieurs règles peuvent expliquer les mêmes exemples. Exiger une règle unique rejetterait des énigmes correctes, alors qu'exiger une réponse unique garantit que le joueur ne peut pas se tromper « avec raison ». Une énigme est donc juste quand toutes les règles d'un **catalogue fini** compatibles avec les exemples donnent la même sortie pour la question, et que chaque mauvaise réponse vient d'une règle plausible qui échoue sur au moins un exemple.

## Considered Options

- **Règle unique** : trop restrictif, rejette de bonnes énigmes.
- **Réponse unique sans catalogue fini** : invérifiable par un programme, l'espace des règles possibles est ouvert.

## Consequences

- Le catalogue de règles devient le cœur du jeu : ajouter une règle change ce que le solveur peut prouver.
- Une énigme est valide seulement par rapport à une version du catalogue. Un pack de contenu doit indiquer laquelle.
- La difficulté se mesure par le nombre de règles combinées et le nombre d'exemples.
