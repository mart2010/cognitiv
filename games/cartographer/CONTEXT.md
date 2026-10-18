# Le cartographe

Jeu de mémoire et d'apprentissage de connaissances : le joueur étudie des Éléments d'un Savoir sous contrainte de temps, est distrait, puis les rappelle. Le premier Savoir est la géographie. Nom retenu le 2026-10-18 (« The Cartographer » en anglais) : le joueur redessine le monde de mémoire, et le nom rappelle L'atelier. Nom de code : `cartographer` (ADR 0007). Utilise les termes énigme, partie, niveau et score de la plateforme, plus Savoir, Élément et Pack de contenu. Le jeu ne change jamais le Niveau : le joueur le choisit, comme dans L'atelier. Il retient en revanche ce que le joueur connaît (Maîtrise) pour choisir quoi faire étudier, et le dit à l'écran.

## Language

### Contenu

**Élément**:
Une unité à apprendre dans un Savoir (un pays, une ville, un fleuve). Il porte plusieurs Facettes.
_Code_: `Item`

**Facette**:
Une manière de connaître un Élément. Cinq types : Attribut (nom, capitale), Position (emplacement sur la carte), Forme (apparence visuelle : contour, drapeau), Grandeur (valeur approximative : population, altitude), Relation (voisinage avec d'autres Éléments). Savoir nommer un pays d'après sa forme n'est pas savoir sa capitale : chaque Facette s'apprend séparément.
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

**Capitale**:
Une Facette d'un pays. Principale (une Bolivie en a deux, La Paz et Sucre) ou alternative (Valparaíso pour le Chili). En Nommage, toutes sont acceptées comme réponse.
_Code_: `Capital`, `CapitalRole`

**Drapeau**:
La Facette visuelle d'un pays, ajoutée sur demande du joueur (2026-10-18) : posable comme Indice ou comme Réponse seulement pour les Éléments qui en ont un. Les données n'en portent pas encore ; le domaine les attend dans un champ optionnel de la Carte de base.
_Code_: `Facet.flag`

**Profil**:
Les genres de Lien que le joueur accepte qu'on lui pose (ex. placer les pays, nommer les capitales). Un seul par couple joueur/jeu, partagé par tous les Niveaux ; stocké par la plateforme comme donnée opaque (patron de l'ADR 0008). Le jeu ne l'évalue pas, c'est le joueur qui choisit ce qu'il travaille.
_Avoid_: Réglages, filtre
_Code_: `CartographerProfile`

**Verdict**:
Le résultat d'une réponse : exact (1 point), proche (la moitié, seulement pour Placer : le point est tout près de l'Élément sans être dedans) ou faux. Pas de bonus de vitesse.
_Avoid_: Note, réussite
_Code_: `AnswerVerdict`

**Tolérance de saisie**:
Ce que Nommer accepte comme correct : casse, accents et ponctuation ignorés, une faute de frappe pour un mot de 5 lettres ou plus, deux dès 9, aucune sous 5. Les noms des deux langues sont acceptés. Un texte qui est exactement le nom d'un autre Élément n'est jamais toléré comme faute (« Guyane » n'est pas « Guyana »).
_Code_: `TextMatcher`

**Repérage**:
La première manche d'une Partie : une question par Élément de la Région (ou un échantillon des moins connus), qui sert à choisir quoi étudier. Présentée comme une manche de jeu, pas comme un examen : elle rapporte des points comme les autres, sans commentaire sur ce que le joueur ne sait pas. Seul « exact » compte comme connu ; un placement « presque » est un raté.
_Avoid_: Test, diagnostic, évaluation
_Code_: `Screening`

**Lot d'étude**:
Les Éléments non connus d'une Étude-éclair, au plus `itemCount` du Niveau (4 au Niveau 3). S'il reste des ratés, une nouvelle Étude suit, jusqu'à 2 cycles par Partie ; le reste est laissé de côté.
_Code_: `StudyBatch`

**Maîtrise**:
Ce que le jeu sait d'un joueur, Lien par Lien, d'une Partie à l'autre. Sert à choisir quoi poser (repérage, Lot d'étude) et à suggérer un autre genre de Lien quand tout est connu, jamais à changer le Niveau ni à imposer. Trois états par Lien, sans dates ni compteurs : à apprendre (raté la dernière fois), fragile (réussi une fois), solide (réussi de nouveau à une Partie suivante). Un seul pas par Lien et par Partie, d'après le dernier verdict : une réussite fait monter d'un cran, tout autre verdict ramène à « à apprendre » (un pays raté au Repérage puis réussi au Bilan devient fragile, jamais solide le même jour). Un « connu » stocké vieillit : le Repérage recontrôle toujours quelques Liens solides, et tire entre un genre nouveau et un genre fragile pour confirmer ou rétrograder ce qui est fragile. Fragile et solide comptent comme connus pour suggérer d'autres genres de Lien. Le joueur peut réinitialiser sa Maîtrise, par Carte de base ou en entier. Stockée par la plateforme comme donnée opaque (ADR 0009).
_Avoid_: Score (un Score est celui d'une Partie), XP, niveau du joueur
_Code_: `Mastery`, `Knowledge`

**Région**:
L'ensemble des Éléments traversables et de leurs adjacences pour une Énigme de chemin (ex. terre seulement, terre et mers, métropole seulement). Annoncé au joueur : le même couple de points donne des réponses différentes selon le Réseau (France–Brésil : une frontière par la Guyane, ou plus si les territoires hors métropole sont exclus). La Réponse est le nombre d'Éléments traversés, départ et arrivée exclus.
_Code_: `CrossingNetwork`
