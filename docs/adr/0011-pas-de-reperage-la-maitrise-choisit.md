# Pas de Repérage : la Maîtrise seule choisit les Éléments à étudier

Le Repérage posait une question par Élément au début de chaque Partie pour trouver les ratés. On le retire (2026-10-20) : la Maîtrise (ADR 0009), alimentée par les Rappels, choisit les Éléments des Catégories actives, en privilégiant « à apprendre » puis « fragile ». Un joueur neuf a une Maîtrise vide, donc tout lui est à apprendre ; un expert verra des Éléments connus, que le Rappel confirmera en « solide ». Le Repérage devenait de toute façon inadapté aux Catégories nombreuses et aux Épreuves de mémoire (Plateau, Séquence, Exploration), où l'on ne peut pas tout interroger d'abord.

## Considered Options

- **Garder le Repérage comme préambule facultatif** : écarté, il coûte une manche entière à chaque Partie pour un gain que la Maîtrise donne déjà avec le temps.

## Consequences

- L'ADR 0010 reste valable pour son mécanisme (la préparation des énigmes est appelable plusieurs fois, la Partie peut se terminer d'elle-même, utile à la Séquence qui s'allonge), mais son motif (étudier les ratés du Repérage) ne tient plus.
- `PrepareCartographerPuzzles` et le Score par phase (Repérage ×1) sont à reprendre ; « niveau franchi » se juge sur le Bilan seul, ou sur le Rappel.
- La Distraction est suspendue en parallèle : à réintroduire après expérimentation.
