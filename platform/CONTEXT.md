# Plateforme

Le socle de l'app : catalogue, profil local, progression, parties et scores stockés. Elle ne connaît jamais les règles internes d'un jeu. Son vocabulaire (énigme, partie, niveau, score) est partagé avec chaque jeu par le contrat.

## Language

Chaque terme porte un nom de code anglais (`_Code_`), utilisé dans le code, les noms de paquets et les clés de données stockées. Les textes affichés au joueur passent par la traduction FR/EN. Attention : la `Session` du code est la **séance** ; l'ancien mot français « session » reste écarté.

**Noms de code des jeux** : L'atelier = `workshop`, La vitrine = `showcase`, Grille = `grid`, Lucioles = `fireflies`.

**Plateforme**:
Le socle commun qui accueille les jeux : écran d'accueil, catalogue, progression et données du joueur.
_Avoid_: Hub, launcher
_Code_: `Platform`

**Jeu**:
Une mécanique jouable complète, avec ses règles et son score, rattachée à un domaine cognitif principal (ex. L'atelier, La vitrine).
_Avoid_: Mini-jeu, exercice
_Code_: `Game`

**Énigme**:
Un problème unique à résoudre dans un jeu (L'atelier : les exemples et la question ; jeu de grille : une grille).
_Avoid_: Niveau, manche, puzzle
_Code_: `Puzzle`
Une manche de séance est une énigme courte, sans terme à part.

**Partie**:
Un enchaînement d'énigmes propre à un jeu et à un niveau, qui produit un score. Elle se termine après un nombre fixe d'énigmes, ou, pour une séance, à la durée cible. Elle peut être mise en pause à tout moment (app en arrière-plan ou fermée) et reprise ensuite. Elle est en cours, en pause, terminée ou abandonnée. Un jeu n'a qu'une partie en cours ou en pause à la fois. Ses énigmes sont générées et stockées dès son début. À la reprise, une énigme sensible au temps repart de son début, et le temps de pause ne compte jamais.
_Avoid_: Session, round
_Code_: `Run`

**Abandon**:
Le fait de quitter volontairement une partie avant sa fin. Elle ne rapporte aucun point et n'est jamais pénalisée autrement.
_Avoid_: Échec, forfait
_Code_: `Abandon`

**Niveau**:
Un réglage de difficulté défini par un jeu (ex. nombre de règles combinées et d'exemples). Aucun niveau n'est verrouillé : le joueur choisit librement de monter ou de descendre, et le jeu peut seulement lui suggérer le niveau suivant après une partie (verdict « niveau franchi »). La difficulté ne s'adapte pas en secret pendant la partie. Le score d'un jeu peut tenir compte du niveau (une bonne réponse vaut plus à un niveau difficile).
_Avoid_: Palier, étape, difficulté adaptative
_Code_: `Level`

**État de reprise**:
Les données qu'un jeu fournit pour décrire où en est une énigme en cours (ex. exemples déjà révélés). La plateforme les stocke sans les lire et les rend au jeu à la reprise.
_Avoid_: Sauvegarde, snapshot
_Code_: `ResumeState`

**Niveau franchi**:
Verdict renvoyé par le jeu à la fin d'une partie, selon ses propres seuils. La plateforme s'en sert pour débloquer le niveau suivant, sans interpréter le score.
_Avoid_: Réussite, validation
_Code_: `LevelCleared`

**Score**:
Le résultat d'une partie, calculé par le jeu selon ses propres règles. La plateforme le stocke sans l'interpréter et ne compare que des scores du même jeu et du même niveau.
_Avoid_: Points globaux, note
_Code_: `Score`

**Séance**:
Un type de partie propre aux jeux d'attention, dont la fin est une durée cible (le palier) et non un nombre d'énigmes. Elle a la même vie qu'une partie (pause, reprise, abandon).
_Avoid_: Session
_Code_: `Session`

**Terminer maintenant**:
Sortie d'une séance avant le palier : le score des manches déjà jouées est conservé, sans pénalité. À distinguer de l'abandon, qui ne rapporte aucun point.
_Avoid_: Abandon, arrêt
_Code_: `finishEarly`

**Palier**:
Une durée cible d'une séance (8, 10, 12, 14 min…), proposée par la plateforme. Le joueur reste libre de choisir.
_Avoid_: Étape, niveau
_Code_: `Tier`

**Bundle**:
Un ensemble de jeux proposé ensemble au catalogue, gratuit ou payant.
_Avoid_: Pack, collection
_Code_: `Bundle`

**Pack de contenu**:
Un ensemble d'énigmes écrites à la main pour un jeu donné, consommé par ce jeu.
_Avoid_: Bundle, DLC
_Code_: `ContentPack`

**Joueur**:
La personne qui utilise l'app. Un seul par installation, sans compte.
_Avoid_: Utilisateur, compte
_Code_: `Player`

**Profil local**:
L'ensemble des scores, de la progression et des préférences du joueur, stocké sur l'appareil. Il peut être exporté et importé (sauvegarde externe).
_Avoid_: Compte, profil en ligne
_Code_: `LocalProfile`

## Progression et mesures

**Progression**:
Les niveaux franchis par jeu et les parties terminées, dérivés de faits que la plateforme connaît sans lire les scores.
_Avoid_: Rang, XP
_Code_: `Progress`

**Régularité**:
Le nombre de jours joués sur les 7 ou 30 derniers jours, affiché comme un simple constat. Jamais une série à ne pas casser.
_Avoid_: Streak, série
_Code_: `ActiveDays`

**Temps passé**:
La durée de jeu actif mesurée par la plateforme, pause exclue, par jeu et au total. Information neutre.
_Avoid_: Temps d'écran
_Code_: `PlayTime`
