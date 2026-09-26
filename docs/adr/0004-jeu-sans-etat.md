# Un jeu est un ensemble de fonctions sans état, la plateforme possède la partie

Le contrat entre plateforme et jeu se limite à trois fonctions : préparer les énigmes d'un niveau, évaluer une réponse à une énigme, calculer le score et le verdict « niveau franchi ». La plateforme possède la partie, ses énigmes (ADR 0002) et l'état de reprise, que le jeu décrit comme une donnée sérialisable et qu'elle stocke sans le lire. Les règles d'un jeu se testent alors comme de simples entrées et sorties, et la pause et la reprise ne demandent aucun mécanisme propre.

## Considered Options

- **Jeu avec état** : chaque jeu tient sa partie en mémoire et sait se sauvegarder et se recharger. Plus de liberté par jeu, mais autant de cycles de vie à tester et à garder cohérents.

## Consequences

- Chaque jeu doit décrire son état de reprise en données sérialisables.
- Ajouter un jeu revient à implémenter trois fonctions, sans toucher au cycle de vie de la partie.
