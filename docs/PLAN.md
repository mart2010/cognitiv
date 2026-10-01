# Cognitiv — Plan

Marqueurs : `[ ]` à faire, `[~]` en cours, `[x]` fait. À mettre à jour en place.

Documents de référence : `BRIEF.md` (problème, périmètre, contraintes), `INVENTORY.md` (jeux candidats, notes de conception).

## État actuel

- Brief rédigé et enrichi (domaines cognitifs, mode de séance, piste « acquisition de connaissances », règle de texte assouplie).
- Inventaire des jeux amorcé. Jalon des 3 jeux :
  - Raisonnement/logique : **L'atelier** (règle cachée), retenu.
  - Mémoire de travail : **La vitrine** (« qu'est-ce qui a changé ? »), retenu.
  - Attention : suivi d'objets multiples ou Vigilance, à trancher plus tard (après L'atelier). Thème à trouver pour l'un et l'autre (pas le ciel étoilé, réservé aux jeux de connaissances).
- Pile envisagée : Flutter (Dart), à confirmer par ADR. Appareil de test : Pixel 8a. Développement sous Windows ou Linux.
- Premier jeu à construire : **L'atelier**. Les jeux de raisonnement et logique sont les plus difficiles à rendre fun et à concevoir (règles, générateur, unicité de solution), mais ils sont essentiels au concept. Si on n'y arrive pas, le concept ne tient pas : on le teste donc en premier. La Vitrine passe en deuxième.
- Jeu de comparaison : une déduction sur grille à solution unique, du genre de Tango (famille Takuzu/Binairo) ou Queens (reines par régions colorées). Il partage avec L'atelier le couple générateur + solveur, avec un fun déjà éprouvé. Il sert de point de repère : si les deux se construisent bien mais que seul l'un est fun, on saura où est le problème (la mécanique ou le traitement). Retenu : Tango-like.
- Revue de jeux existants faite en session : Samewise (Android) reprend déjà le format « règle cachée » sur grille. L'originalité de L'atelier devra venir du traitement (créatures, univers, sons) et de la qualité des énigmes.
- Exploration du modèle de L'atelier par prototypes jetables (hors dépôt, non Flutter), sur plusieurs séances : ligne à 4 emplacements, puis figurine à plusieurs parties, puis forme unique évolutive, puis **matrice m×n de cellules** (forme + couleur), retenue pour l'instant. Nom de travail du prototype : « The Matrix », distinct du nom « L'atelier » gardé dans les documents — à trancher une fois le concept validé. Prototype interactif : <https://claude.ai/artifact/VWaA8fxuFgfJvL25JNUN4w> (lien privé, le partager depuis le menu de partage de la page avant de le faire jouer à quelqu'un).

## Décisions prises

- Trois axes de classification à distinguer : domaine cognitif, mode de séance (avec ou sans paliers), domaine de connaissance (hors v1).
- Mémoire à long terme et jeux de connaissances (ciel étoilé, atlas, corps humain…) : hors jalon v1, à revoir plus tard.
- Texte toléré quand le contenu l'exige. Jeux de mots ou lexicaux toujours exclus (non-goal).
- Contenu : approche hybride, généré pour le volume, écrit à la main avec Claude pour les énigmes soignées et les packs (unicité de solution vérifiée par solveur et tests).
- Ne jamais présenter le dual n-back ni aucun jeu comme améliorant le QI ou la santé cognitive.
- Modèle retenu pour L'atelier (à date, avant test externe) : une matrice m×n de cellules, chacune une forme (rond, carré, triangle) et une couleur, pas nécessairement carrée. Transposer ou pivoter une grille rectangulaire change ses dimensions, un effet qu'une grille carrée ne montre pas.
- Deux types de case vide, un seul rendu (pointillé, car la répétition dans les exemples suffit à distinguer) : **active** (rôle dans la règle : vider une cellule ciblée, case vide façon taquin, gravité) et **fixe** (aucun rôle, sert seulement à alléger les grandes grilles ; exclue du catalogue de règles ciblées pour ne jamais produire un mauvais choix qui casse un motif toujours vide dans les exemples).
- Essai actif (interroger soi-même la machine) mis de côté pour l'instant : on avance avec le format exemples fixes seul.
- Titre et famille de règle d'une énigme cachés par défaut (ils trahissaient la réponse) ; révélés seulement à la demande, via un bouton d'indice.
- Piège de conception identifié et corrigé en session : pour toute règle qui change les dimensions de la grille, les mauvaises réponses doivent impérativement garder les mêmes dimensions que la bonne — sinon la réponse se devine à sa seule forme, sans comprendre la règle. À vérifier pour toute future règle du même genre.
- Retour de test externe (2026-09-28, prototype fait jouer à des proches) : les règles de cycle de couleur ou de forme (globales et localisées à une ligne/colonne) et les règles conditionnelles (« toute cellule d'une couleur devient telle forme ») ne sont pas intuitives dans ce genre de jeu — contrairement aux règles géométriques (miroir, rotation), qui se lisent d'un coup d'œil. Décision : elles restent dans le catalogue de règles (qui reste unique et complet), mais désactivées par défaut. Ce qui varie par jeu/pack, c'est un **filtre de règles à inclure/exclure**, choisi à la création du jeu, qui contrôle quelles règles le générateur (et donc le solveur) peut utiliser pour ce jeu. Effet secondaire utile : l'écran de création listant toutes les règles à cocher sert aussi de rappel visuel de ce que permet le catalogue. Concept de modèle encore sans nom stable (candidat : « filtre de règles » ou « profil de génération »), distinct du Catalogue de règles lui-même — à trancher en session `/grill-domain`.
- Catalogue de règles à enrichir (pistes retenues à explorer, suite à la vérification du calcul matriciel) :
  - Rotation 180° comme règle explicite et nommée, plutôt que laissée comme composition implicite de deux miroirs (moins lisible pour le joueur, qui perçoit une rotation 180° comme un seul geste).
  - Décalage cyclique (façon tore) de lignes ou colonnes de la grille entière — distinct de la gravité (qui dépend des cases vides) et du taquin (qui ne déplace que la case vide seule) ; fonctionne même sur une grille pleine.
  - Transposition selon la diagonale secondaire (anti-diagonale), retenue aux côtés de la transposition actuelle (diagonale principale) : aucune raison de l'exclure.
- Pas d'étape séparée d'habillage visuel/sonore sur le prototype jetable : l'habillage se fera directement pendant l'implémentation Flutter, avec pour consigne de viser un design soigné, attrayant et moderne (pas l'apparence neutre du prototype).
- Ambiance visuelle et sonore : repoussoir identifié, référence retenue. Éviter une ambiance trop lourde, colorée et saturée en images et en sons (le quotidien du jeu doit rester propre et épuré). Référence positive : Samewise. Exception volontaire : la réussite d'une énigme doit être célébrée fortement, à la fois visuellement et auditivement — contraste recherché entre un quotidien sobre et un moment de succès marqué.
- Les deux modes de réponse seront implémentés pour L'atelier, pas l'un après l'autre à valider : choix multiple (4 grilles) et construction libre de la solution (choisir forme et couleur de chaque cellule sur une grille vide).
- Session `/grill-domain` du 2026-09-28 (L'atelier) : vocabulaire stabilisé et reporté dans `games/workshop/CONTEXT.md` (Matrice, Cellule, Forme, Rôle de case vide, Règle, Famille de règle, Catalogue de règles enrichi, Profil de génération). Nom du jeu tranché : on garde **L'atelier** (« The Matrix » écarté, marque tierce). Le Profil de génération est une préférence du joueur par jeu (pas par niveau), stockée comme donnée opaque au même titre que l'état de reprise ; une Règle est un couple (Famille, paramètres), ce qui permet de combiner plusieurs Règles d'une même Famille quand le joueur restreint ses Familles actives. Voir ADR 0008.

## Prochaine étape

- [x] **Session `/grill-domain`** (faite : voir `CONTEXT-MAP.md`, les `CONTEXT.md` par contexte et `docs/adr/0001` à `0006`). Restait à couvrir, gardé pour mémoire, avec L'atelier comme cas concret et le Tango-like comme second cas (pour vérifier que le contrat jeu/plateforme tient pour deux jeux de nature différente). À couvrir :
  - Vocabulaire (CONTEXT.md) : plateforme, app, jeu, bundle, séance, palier, session, domaine cognitif, mode de séance, domaine de connaissance, pack de contenu. Trancher « bundle » (ensemble de jeux) contre « pack de contenu » (contenu d'un jeu).
  - Définitions : score par jeu et par niveau, progression globale, temps passé.
  - Contrat commun entre plateforme et jeu (comment un jeu s'ajoute, comment il reçoit du contenu généré ou de pack).
  - Profil local et stockage sur l'appareil, sauvegarde externe possible.
  - Frontières Clean Architecture : domaine en Dart pur, sans import de Flutter. Ports et Fakes pour les dépendances (stockage, horloge, audio).
  - ADR : choix de Flutter (et éventuellement Flame). Préciser que le projet utilise `flutter_test` et non pytest.
- [~] **Implémentation Flutter de L'atelier** : on avance avec ce seul jeu de raisonnement (pas de jeu d'attention à trancher pour l'instant).
  - [x] Paquet Dart pur `games/workshop/` (ADR 0005) : Entités et Value Objects (Shape, Color, EmptyCellRole, Cell, Matrix, RuleFamily, Rule — une sous-classe par Famille avec son `apply()` —, RuleCatalog, GenerationProfile, WorkshopPuzzle, WorkshopAnswer), Service de domaine (WorkshopPuzzleSolver) et Cas d'usage (GenerateWorkshopPuzzle, EvaluateWorkshopAnswer, ComputeWorkshopScore) avec port `RandomSource`. Tests `dart test` avec `FakeRandomSource`, `dart analyze` propres. Décisions prises en cours de route, à relire :
    - `RuleCatalog.rulesFor(rows, columns)` énumère les Règles pour des dimensions précises plutôt qu'une liste statique : les Règles localisées (cycle sur une ligne/colonne) dépendent des dimensions, donc « catalogue fini » (ADR 0001) ne peut pas être une liste indépendante des dimensions.
    - L'ADR 0001 (équité par réponse unique) est vérifiée contre le sous-catalogue filtré par le Profil de génération actif, pas contre le catalogue complet — interprétation à confirmer, l'ADR 0008 (qui introduit le Profil) ne tranchait pas ce point explicitement.
    - Palette de Couleurs (5 valeurs) et sémantique précise de Décalage cyclique, Taquin, Gravité, Cycle de couleur/forme, Conditionnelle : premier jet documenté dans le code (`rule.dart`), à valider une fois le générateur réel en main.
    - Formule de score (`ComputeWorkshopScore`) : provisoire (nombre de bonnes réponses, seuil de ratio), aucune vraie décision de jeu encore prise.
    - Note Interface Adapters à venir : le nom de code `Color` (ADR 0007) entrera en collision avec `dart:ui`/Flutter `Color` dans l'app — à résoudre par un alias d'import (`as workshop`), pas par un renommage du terme de domaine.
  - [ ] Interface Adapters et UI Flutter (modes de réponse à choix et construction libre, habillage visuel/sonore sobre avec célébration du succès).

## À décider avant le prototype

- [x] Choix du jeu de comparaison : **Tango-like** (Takuzu/Binairo), retenu. Utiliser les noms génériques du genre dans nos documents, pas les marques.
- [x] Jouer à Samewise (fait en session). Retour : format à règle cachée sur grille carrée, mais limité aux transformations 2D simples (couleur de case) ; a motivé l'exploration du modèle de L'atelier ci-dessus.
- [x] Écrire des énigmes de L'atelier à la main — remplacé par un générateur (10 énigmes, chacune vérifiée automatiquement contre un catalogue de règles avant d'être présentée, dans l'esprit de l'ADR 0001). Plus robuste qu'écrire à la main, et permet de rejouer une énigme avec une instance neuve à chaque fois.
- [x] **Faire jouer 2 ou 3 proches** au prototype (fait ; retours en main — voir les décisions du 2026-09-28 ci-dessus : règles couleur/forme et conditionnelles pas intuitives, filtre de règles à ajouter, pistes de géométrie à explorer).
- [x] Trancher le nom : on garde **L'atelier** (« The Matrix » était un nom de travail, écarté car marque tierce).
- [x] Reporter le vocabulaire stabilisé dans `games/workshop/CONTEXT.md` : catalogue de règles enrichi (rotation 180°, décalage cyclique, anti-diagonale), et concept de filtre de règles nommé **Profil de génération** (voir `games/workshop/CONTEXT.md` et ADR 0008).
- [x] Mode(s) de réponse : les deux modes seront implémentés (choix multiple et construction libre) — voir décision ci-dessus.

- [ ] Références et repoussoirs d'ambiance (jeux, design, univers sonore) — Samewise retenu comme référence positive (voir décision ci-dessus) ; compléter avec d'autres références au besoin.
- [ ] Tablette Android disponible pour tester ? (le jalon vise téléphone et tablette).

## Plus tard

- [ ] La vitrine (deuxième jeu, mémoire de travail).
- [ ] Jeu d'attention du jalon : suivi d'objets multiples ou Vigilance, et leur thème, à trancher une fois L'atelier avancé.
- [ ] Monétisation des bundles et packs payants.
- [ ] Sauvegarde sur Google Drive, puis iCloud.
- [ ] Livraison des packs sans serveur en v1 (embarqués ou via le store).
- [ ] Vérification juridique des formats inspirés de tests reconnus, licences des données astronomiques.
- [ ] Nom et pitch de l'app.
- [ ] iOS (Mac ou build cloud, iPhone de test).
