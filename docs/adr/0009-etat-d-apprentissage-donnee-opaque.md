# La Maîtrise est un état d'apprentissage stocké par la plateforme, mis à jour par une quatrième fonction du jeu

Les jeux de mémoire doivent savoir, d'une Partie à l'autre, quels Liens le joueur maîtrise (adaptation du contenu, révision espacée). Suivant le patron du Profil de génération (ADR 0008), le jeu décrit cet état comme une donnée sérialisable que la plateforme stocke par joueur et par jeu sans la lire. Le contrat de l'ADR 0004 passe de trois à quatre fonctions pures : préparer les énigmes (qui reçoit désormais l'état en entrée), évaluer une réponse, calculer le score et le verdict, et mettre à jour l'état à partir des résultats d'une Partie. Le jeu reste sans état : il reçoit un état et en rend un nouveau.

## Considered Options

- **Jeu avec état** : écarté pour les mêmes raisons que dans l'ADR 0004.
- **Plateforme qui lit la Maîtrise** : briserait la règle « la plateforme ne connaît jamais les règles internes d'un jeu ».

## Consequences

- Un jeu sans apprentissage (L'atelier) n'implémente pas la quatrième fonction ; elle est optionnelle dans le contrat.
- La révision espacée a besoin du temps : l'horloge reste un port (ADR 0005), le jeu reçoit une date en entrée et n'appelle jamais l'horloge lui-même.
- L'adaptation porte sur le choix des Liens et sur une suggestion entre deux Parties, pas sur le Niveau en cours de Partie (voir le glossaire de la plateforme).
