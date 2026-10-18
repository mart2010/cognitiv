# Rappel

Jeu de mémoire et d'apprentissage de connaissances : le joueur étudie des Éléments d'un Savoir sous contrainte de temps, est distrait, puis les rappelle. Le premier Savoir est la géographie. Nom de travail (jeu nommé d'après sa mécanique, ADR 0003) ; le nom définitif reste à trancher. Utilise les termes énigme, partie, niveau et score de la plateforme, plus Savoir, Élément et Pack de contenu.

## Language

### Contenu

**Élément**:
Une unité à apprendre dans un Savoir (un pays, une ville, un fleuve). Il porte plusieurs Facettes.
_Code_: `Item`

**Facette**:
Une manière de connaître un Élément. Cinq types : Attribut (nom, capitale), Position (emplacement sur la carte), Forme (contour), Grandeur (valeur approximative : population, altitude), Relation (voisinage avec d'autres Éléments). Savoir nommer un pays d'après sa forme n'est pas savoir sa capitale : chaque Facette s'apprend séparément.
_Avoid_: Propriété, champ
_Code_: `Facet`

**Région**:
Un sous-ensemble d'Éléments d'un Savoir qui sert d'unité à une Partie (ex. l'Afrique de l'Ouest). Jamais tout le Savoir d'un bloc.
_Avoid_: Zone, continent (une Région peut être plus petite)
_Code_: `Region`

### Énigmes

**Indice**:
La Facette donnée au joueur dans une Énigme.
_Code_: `Cue`

**Réponse**:
La Facette que le joueur doit produire.
_Code_: `Answer`

**Lien**:
Le couple (Élément, Indice → Réponse), par exemple « Kenya : forme → nom ». L'unité que la Maîtrise suit.
_Avoid_: Fait, carte
_Code_: `Link`

**Geste**:
L'action du joueur pour répondre : placer, nommer, ordonner, repérer l'erreur, tracer un chemin. Première tranche : placer, nommer, repérer l'erreur.
_Avoid_: Mode, type de question
_Code_: `Gesture`

**Étude-éclair**:
La séquence d'une Énigme : l'Étude (N Éléments montrés quelques secondes), la Distraction (courte tâche qui coupe l'encodage), puis le Rappel. Hérite du rythme de La vitrine sans sa question « qu'est-ce qui a changé ? ».
_Code_: `FlashStudy`

**Aide au rappel**:
La force de l'Indice au moment du Rappel, du plus faible au plus fort : saisie libre, première lettre et longueur, choix parmi des propositions. Un réglage de Niveau, pas un mode.
_Code_: `RecallAid`

### Progression

**Maîtrise**:
Ce que le jeu sait d'un joueur, Lien par Lien. Sert à choisir quels Liens poser et à suggérer une montée entre deux Parties, jamais à changer le Niveau en cours de Partie. Stockée par la plateforme comme donnée opaque (ADR 0009).
_Avoid_: Score (un Score est celui d'une Partie), XP
_Code_: `Mastery`
