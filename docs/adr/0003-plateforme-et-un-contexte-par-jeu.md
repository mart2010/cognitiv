# Un contexte Plateforme et un contexte par jeu, reliés par un contrat étroit

Les jeux parlent des langages différents (règles et catalogue pour L'atelier, cases et contraintes pour un jeu de grille). On sépare donc la plateforme (catalogue, profil, progression, parties, scores) de chaque jeu (règles, générateur, solveur, calcul de score), qui communiquent par un contrat étroit. Cela permet d'ajouter un jeu sans toucher aux autres et empêche les règles d'un jeu de fuir dans la plateforme.

## Considered Options

- **Un seul contexte** : moins de cérémonie, mais le vocabulaire des jeux se mélange et chaque nouveau jeu touche au reste.

## Consequences

- Énigme, Partie, Niveau et Score forment un vocabulaire partagé à garder identique des deux côtés.
- Le contrat doit rester très petit, sinon chaque jeu devra s'adapter à la plateforme.
