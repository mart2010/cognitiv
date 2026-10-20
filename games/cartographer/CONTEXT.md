# Le cartographe

Jeu de mémoire et d'apprentissage de connaissances : le joueur étudie des Éléments d'un Savoir sous contrainte de temps, est distrait, puis les rappelle. Le premier Savoir est la géographie. Nom retenu le 2026-10-18 (« The Cartographer » en anglais) : le joueur redessine le monde de mémoire, et le nom rappelle L'atelier. Nom de code : `cartographer` (ADR 0007). Utilise les termes énigme, partie, niveau et score de la plateforme, plus Savoir, Élément et Pack de contenu. Le jeu ne change jamais le Niveau : le joueur le choisit, comme dans L'atelier. Il retient en revanche ce que le joueur connaît (Maîtrise) pour choisir quoi faire étudier, et le dit à l'écran.

## Language

### Contenu

**Élément**:
Une unité à apprendre dans un Savoir (un pays, une ville, un fleuve). Il appartient à une Catégorie, a une Géométrie et porte des Attributs.
_Code_: `Item`

**Catégorie**:
Le genre d'un Élément (pays, villes, fleuves, mers, parcs…). Elle impose le type de Géométrie de ses Éléments : on ne mélange pas des points et des polygones dans une même Catégorie. Le joueur active une ou plusieurs Catégories : c'est ce qui décide des Éléments sur lesquels il s'exerce.
_Avoid_: Type, couche (la couche est un rôle dans la Scène)
_Code_: `Category`

**Géométrie**:
La forme spatiale d'un Élément sur la Scène : Polygone (pays, mers, parcs), Point (villes) ou Ligne (fleuves). La Position et la Forme d'un Élément en découlent.
_Avoid_: Type de forme (« Forme » désigne une Facette)
_Code_: `Geometry`

**Attribut**:
Une donnée typée attachée à un Élément : texte (nom), nombre (population), booléen (`capitale`), liste (langues). Le nom est un Attribut comme les autres. Un Attribut sert à choisir des Éléments, à les filtrer et, une fois interrogé, de matière à une Facette.
_Avoid_: Propriété, champ
_Code_: `Attribute`

**Facette**:
Une manière de connaître un Élément, donc ce qu'une Énigme peut interroger. Quatre types : Attribut (nom, capitale, population, langues), Position (emplacement sur la Scène), Forme (apparence visuelle : contour), Relation (lien avec d'autres Éléments). Savoir nommer un pays d'après sa forme n'est pas savoir sa capitale : chaque Facette s'apprend séparément. La population, jadis une Grandeur, est un Attribut numérique.
_Avoid_: Propriété, champ
_Code_: `Facet`

**Épreuve**:
La structure complète d'une Partie : comment le joueur encode les Éléments, puis comment il les rappelle. Inspirée des jeux de mémoire classiques. Une Épreuve combine un mode d'encodage et un Geste de Rappel. Distincte du Geste (l'action de répondre) et du jeu (un produit de la plateforme).
_Avoid_: Mode, type de jeu
_Code_: `Trial`

**Plateau**:
Une Épreuve inspirée du jeu de Kim : N Éléments d'une même Catégorie sont montrés ensemble, nommés, pendant la durée d'étude du Niveau ; puis, après une page d'attente (la Distraction est suspendue), le joueur les replace tous sur la Scène, dans l'ordre qu'il veut, et ne voit les verdicts qu'après les avoir tous placés (un verdict immédiat donnerait un repère exact pour placer les suivants). Une Partie compte trois Plateaux, sans Repérage : la Maîtrise choisit les Éléments, les moins connus d'abord, sans en reprendre dans la Partie tant que la Catégorie en a d'autres. Chaque question est un Lien « nom → position ». La présentation est un réglage de l'Épreuve : simultanée (faite), successive (un Élément à la fois, à faire). L'ordre n'est pas évalué.
_Code_: `Tray`

**Séquence**:
Une Épreuve inspirée de Simon et des blocs de Corsi : les Éléments sont surlignés un à un (leur nom s'affiche brièvement) et le joueur les touche dans le même ordre. La séquence s'allonge à chaque réussite ; le Score est la longueur atteinte. L'ordre est évalué.
_Code_: `Sequence`

**Exploration**:
Une Épreuve où le joueur découvre les Éléments en touchant des formes sans nom : le nom se révèle au toucher, avec un budget de touches plutôt qu'un chronomètre. Le Rappel demande ensuite où se trouve tel Élément.
_Code_: `Exploration`

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
La séquence d'une Énigme : l'Étude (N Éléments montrés quelques secondes), la Distraction (courte tâche qui coupe l'encodage, suspendue pour l'instant), puis le Rappel. Hérite du rythme de La vitrine sans sa question « qu'est-ce qui a changé ? ».
_Code_: `FlashStudy`

**Distraction**:
La courte tâche entre l'Étude et le Rappel (compter, trier, toucher des cibles), indépendante du Savoir, qui coupe le maintien actif en mémoire de travail. **Suspendue (2026-10-20)** : sa forme actuelle est trop basique et la reprendre demande de l'expérimenter (un simple écran blanc avec un texte pour commencer). En attendant, rien ne sépare l'Étude du Rappel. Un Simon abstrait est une piste, mais il interfère avec la mémoire visuo-spatiale de la carte et ressemble à la Séquence.
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
Une ville (Élément de Catégorie Villes, Point) dont l'Attribut `capitale` est vrai, liée à son pays par une Relation d'inclusion. « La capitale du Brésil » est donc le Lien entre Brasília et le Brésil. Principale (la Bolivie en a deux, La Paz et Sucre) ou alternative (Valparaíso pour le Chili). En Nommage, toutes sont acceptées comme réponse.
_Code_: `Capital`, `CapitalRole`

**Drapeau**:
La Facette visuelle d'un pays, ajoutée sur demande du joueur (2026-10-18) : posable comme Indice ou comme Réponse seulement pour les Éléments qui en ont un. Les données n'en portent pas encore ; le domaine les attend dans un champ optionnel de la Carte de base.
_Code_: `Facet.flag`

**Profil**:
Les Catégories que le joueur active (ex. pays, villes, fleuves) ; elles décident des Éléments sur lesquels il s'exerce. Un seul par couple joueur/jeu, partagé par tous les Niveaux ; stocké par la plateforme comme donnée opaque (patron de l'ADR 0008). Le jeu ne l'évalue pas, c'est le joueur qui choisit ce qu'il travaille. Remplace la liste de genres de Lien (« Nommer un pays », « Reconnaître un pays ») : le genre de Lien découle désormais de l'Épreuve et de la Catégorie.
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
**Abandonné (2026-10-20, ADR 0011).** C'était la première manche d'une Partie, une question par Élément pour choisir quoi étudier. Le choix des Éléments passe désormais par la seule Maîtrise ; un joueur neuf a une Maîtrise vide, donc tout lui est « à apprendre ».
_Avoid_: Test, diagnostic, évaluation
_Code_: `Screening` (à retirer)

**Lot d'étude**:
Les Éléments choisis pour une Étude, au plus `itemCount` du Niveau (4 au Niveau 3), pris dans les Catégories actives en privilégiant ceux « à apprendre » puis « fragiles » d'après la Maîtrise. (Avant l'ADR 0011 : les ratés du Repérage, avec 2 cycles maximum par Partie.)
_Code_: `StudyBatch`

**Maîtrise**:
Ce que le jeu sait d'un joueur, Lien par Lien, d'une Partie à l'autre. Sert à choisir quoi poser (repérage, Lot d'étude) et à suggérer un autre genre de Lien quand tout est connu, jamais à changer le Niveau ni à imposer. Trois états par Lien, sans dates ni compteurs : à apprendre (raté la dernière fois), fragile (réussi une fois), solide (réussi de nouveau à une Partie suivante). Un seul pas par Lien et par Partie, d'après le dernier verdict : une réussite fait monter d'un cran, tout autre verdict ramène à « à apprendre » (un pays raté au Repérage puis réussi au Bilan devient fragile, jamais solide le même jour). Un « connu » stocké vieillit : la sélection des Éléments y remet toujours quelques Liens solides, et tire entre un genre nouveau et un genre fragile pour confirmer ou rétrograder ce qui est fragile. Fragile et solide comptent comme connus pour suggérer d'autres genres de Lien. Le joueur peut réinitialiser sa Maîtrise, par Carte de base ou en entier. Stockée par la plateforme comme donnée opaque (ADR 0009).
_Avoid_: Score (un Score est celui d'une Partie), XP, niveau du joueur
_Code_: `Mastery`, `Knowledge`

**Réseau de traversée**:
L'ensemble des Éléments traversables et de leurs adjacences pour une Énigme de chemin (ex. terre seulement, terre et mers, métropole seulement). Annoncé au joueur : le même couple de points donne des réponses différentes selon le Réseau (France–Brésil : une frontière par la Guyane, ou plus si les territoires hors métropole sont exclus). La Réponse est le nombre d'Éléments traversés, départ et arrivée exclus.
_Code_: `CrossingNetwork`
