# Le cartographe

Jeu de mémoire et d'apprentissage de connaissances : le joueur étudie des Éléments d'un Savoir sous contrainte de temps, est distrait, puis les rappelle. Le premier Savoir est la géographie. Nom retenu le 2026-10-18 (« The Cartographer » en anglais) : le joueur redessine le monde de mémoire, et le nom rappelle L'atelier. Le nom de code reste `recall` (ADR 0007). Utilise les termes énigme, partie, niveau et score de la plateforme, plus Savoir, Élément et Pack de contenu. Le jeu n'évalue pas le joueur : c'est lui qui choisit son Niveau, comme dans L'atelier.

## Language

### Contenu

**Élément**:
Une unité à apprendre dans un Savoir (un pays, une ville, un fleuve). Il porte plusieurs Facettes.
_Code_: `Item`

**Facette**:
Une manière de connaître un Élément. Cinq types : Attribut (nom, capitale), Position (emplacement sur la carte), Forme (contour), Grandeur (valeur approximative : population, altitude), Relation (voisinage avec d'autres Éléments). Savoir nommer un pays d'après sa forme n'est pas savoir sa capitale : chaque Facette s'apprend séparément.
_Avoid_: Propriété, champ
_Code_: `Facet`

**Carte de base**:
Une Scène géographique cadrée que le joueur choisit, à n'importe quelle échelle (Europe de l'Ouest, Espagne, Afrique australe, Asie du Sud-Est, Chine, Sichuan…). C'est le moyen de généraliser le Savoir géographique sans changer le moteur.
_Avoid_: Fond de carte, niveau
_Code_: `BaseMap`

**Région**:
Les Éléments d'une Carte de base à un niveau donné (pays, provinces, villes, mers), qui servent d'unité à une Partie. Jamais tout le Savoir d'un bloc.
_Avoid_: Zone, continent
_Code_: `Region`

### Énigmes

**Indice**:
La Facette donnée au joueur dans une Énigme.
_Code_: `Cue`

**Réponse**:
La Facette que le joueur doit produire.
_Code_: `Answer`

**Lien**:
Le couple (Élément, Indice → Réponse), par exemple « Kenya : forme → nom ». L'unité de base d'une Énigme : ce qu'on demande, indépendamment du Niveau.
_Avoid_: Fait, carte
_Code_: `Link`

**Geste**:
L'action du joueur pour répondre : placer, nommer, ordonner, repérer l'erreur, tracer un chemin. Première tranche : placer, nommer, repérer l'erreur.
_Avoid_: Mode, type de question
_Code_: `Gesture`

**Étude-éclair**:
La séquence d'une Énigme : l'Étude (N Éléments montrés quelques secondes), la Distraction (courte tâche qui coupe l'encodage), puis le Rappel. Hérite du rythme de La vitrine sans sa question « qu'est-ce qui a changé ? ».
_Code_: `FlashStudy`

**Distraction**:
La courte tâche entre l'Étude et le Rappel (compter, trier, toucher des cibles), indépendante du Savoir, qui coupe le maintien actif en mémoire de travail. Sa durée et sa nature sont des réglages de Niveau.
_Avoid_: Pause, brouillage
_Code_: `Distraction`

**Bilan**:
Les questions de fin de Partie qui redemandent des Éléments étudiés plus tôt, sans les remontrer : le Rappel différé, qui sollicite la mémoire à plus long terme sans rien stocker entre les Parties. Pèse davantage dans le Score que les Énigmes ordinaires.
_Avoid_: Test, examen
_Code_: `DelayedRecall`

**Aide au rappel**:
La force de l'Indice au moment du Rappel, du plus faible au plus fort : saisie libre, première lettre et longueur, choix parmi des propositions. Un réglage de Niveau, pas un mode.
_Code_: `RecallAid`
 
**Scène**:
Le fond sur lequel des Éléments sont positionnés : une carte, un schéma du corps (avec couches et vues), une voûte céleste. Le moteur manipule une Scène sans savoir de quel Savoir elle vient.
_Avoid_: Carte (réservé à la géographie), décor
_Code_: `Scene`

**Relation**:
Une Facette qui lie des Éléments entre eux, de trois natures : voisinage (symétrique), inclusion (hiérarchique : continent ⊃ pays), flux (orienté : circulation du sang, cours d'un fleuve).
_Code_: `Relation`

**Réseau de traversée**:
L'ensemble des Éléments traversables et de leurs adjacences pour une Énigme de chemin (ex. terre seulement, terre et mers, métropole seulement). Annoncé au joueur : le même couple de points donne des réponses différentes selon le Réseau (France–Brésil : une frontière par la Guyane, ou plus si les territoires hors métropole sont exclus). La Réponse est le nombre d'Éléments traversés, départ et arrivée exclus.
_Code_: `CrossingNetwork`
