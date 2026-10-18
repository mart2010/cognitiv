# Context Map

## Contexts

- [Plateforme](./platform/CONTEXT.md): catalogue, profil local, progression, parties et scores stockés
- [L'atelier (`workshop`)](./games/workshop/CONTEXT.md): jeu de règle cachée (règles, catalogue, énigmes justes)
- [Rappel (`recall`, nom de travail)](./games/recall/CONTEXT.md): jeu de mémoire et d'apprentissage de connaissances (Savoirs, Éléments, Scènes)
- [Grille (`grid`)](./games/grid/CONTEXT.md): jeu de déduction sur grille à solution unique (Tango-like), jeu de comparaison

Un contexte est ajouté par jeu, quand ses premiers termes sont réglés.

## Relationships

- **Plateforme → Jeu**: la plateforme demande une partie pour un niveau donné, en transmettant les préférences du jeu si elle en stocke (ex. Profil de génération de L'atelier), puis relaie les réponses du joueur au jeu, qui les évalue.
- **Jeu → Plateforme**: le jeu fournit ses énigmes, le score, l'état de reprise, ses éventuelles préférences de joueur et si le niveau est franchi. Il ne connaît ni le profil ni les autres jeux.
- **Plateforme ↔ Jeux**: vocabulaire partagé (Énigme, Partie, Niveau, Score), défini côté plateforme et respecté à l'identique par chaque jeu.
