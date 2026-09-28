# Le Profil de génération restreint par Famille de règle, stocké comme donnée opaque du joueur

Le joueur choisit, par jeu, quelles Familles de règles (miroir, rotation, décalage cyclique…) le générateur et le solveur de L'atelier peuvent utiliser — un playtest a montré que certaines familles (cycle de couleur/forme, conditionnelles) sont moins intuitives que d'autres (miroir, rotation). Le Profil de génération porte ce choix, un par couple joueur/jeu et non par niveau, et suit le même patron que l'état de reprise (ADR 0004) : une donnée opaque décrite par L'atelier, stockée par la plateforme dans le Profil local sans être lue ni interprétée.

Pour rester jouable même avec peu de Familles actives, une Règle est le couple (Famille, paramètres) — ex. Miroir horizontal et Miroir vertical sont deux Règles distinctes de la même Famille — et un combo de règles exige des Règles distinctes, pas des Familles distinctes. Le Niveau continue de fixer une cible de complexité (nombre de règles combinées, nombre d'exemples) indépendante du joueur ; c'est au générateur de choisir comment l'atteindre selon le Profil actif, quitte à combiner plusieurs Règles d'une même Famille.

## Considered Options

- **Profil de génération porté par le Niveau ou le Pack de contenu** : empêcherait une préférence stable du joueur, à refaire à chaque niveau ou pack.
- **Concept de plateforme dédié aux préférences de jeu** : dupliquerait le patron déjà validé de l'état de reprise pour un besoin identique (donnée opaque définie par le jeu).
- **Combo exigeant des Familles distinctes** : plus simple à énoncer, mais rend un Niveau avancé impossible à générer dès que le joueur limite le nombre de Familles actives.

## Consequences

- Le générateur reste la garantie ultime de jouabilité : si la combinaison Niveau × Profil est insuffisante pour la complexité visée, il échoue proprement plutôt que de produire une énigme injuste. L'écran de réglages empêche déjà les cas absurdes en amont, mais ne remplace pas cette garantie.
- L'écran de réglages de L'atelier coche des Familles entières, pas des Règles individuelles.
- Une Famille avec un seul paramétrage possible ne peut jamais, seule, atteindre une complexité de plus d'une Règle — à surveiller à l'ajout de nouvelles Familles.
