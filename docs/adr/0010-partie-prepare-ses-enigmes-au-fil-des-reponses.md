# Une Partie prépare ses énigmes suivantes à partir des réponses précédentes

Dans Le cartographe, les Études portent sur les Éléments que le repérage de la même Partie a montrés non connus : les énigmes ne peuvent donc pas toutes être générées au début. La préparation des énigmes devient appelable plusieurs fois, avec l'historique des réponses déjà données, et rend soit les énigmes suivantes, soit « terminée ». Comme pour une séance (ADR 0002), la plateforme stocke chaque énigme dès sa génération, donc la reprise après pause ne change pas : les énigmes déjà vues et leurs réponses sont conservées, et la préparation reste une fonction pure (ADR 0004).

## Considered Options

- **Tout préparer au début, avec le repérage comme seule Énigme adaptative** : garde le contrat actuel, mais l'étude porterait sur des Éléments choisis sans connaître les réponses.
- **Jeu avec état qui pilote sa Partie** : écarté (ADR 0004).

## Consequences

- Une Partie peut se terminer parce que le jeu la déclare terminée, en plus du nombre fixe d'énigmes et de la durée d'une séance.
- Sa longueur varie : le score et le verdict « niveau franchi » ne doivent pas supposer un nombre fixe d'énigmes.
- L'atelier garde son comportement : il prépare tout d'un coup et déclare « terminée » à l'appel suivant.
