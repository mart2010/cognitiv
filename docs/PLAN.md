# Cognitiv — Plan

Marqueurs : `[ ]` à faire, `[~]` en cours, `[x]` fait. À mettre à jour en place.

Documents de référence : `BRIEF.md` (problème, périmètre, contraintes), `INVENTORY.md` (jeux candidats, notes de conception).

## État actuel

- Brief rédigé et enrichi (domaines cognitifs, mode de séance, piste « acquisition de connaissances », règle de texte assouplie).
- Inventaire des jeux amorcé. Jalon des 3 jeux :
  - Raisonnement/logique : **L'atelier** (règle cachée), retenu.
  - Mémoire de travail : **La vitrine** (« qu'est-ce qui a changé ? »), retenu.
  - Attention : suivi d'objets multiples ou Vigilance, à trancher. Thème à trouver pour l'un et l'autre (pas le ciel étoilé, réservé aux jeux de connaissances).
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

## Prochaine étape

- [x] **Session `/grill-domain`** (faite : voir `CONTEXT-MAP.md`, les `CONTEXT.md` par contexte et `docs/adr/0001` à `0006`). Restait à couvrir, gardé pour mémoire, avec L'atelier comme cas concret et le Tango-like comme second cas (pour vérifier que le contrat jeu/plateforme tient pour deux jeux de nature différente). À couvrir :
  - Vocabulaire (CONTEXT.md) : plateforme, app, jeu, bundle, séance, palier, session, domaine cognitif, mode de séance, domaine de connaissance, pack de contenu. Trancher « bundle » (ensemble de jeux) contre « pack de contenu » (contenu d'un jeu).
  - Définitions : score par jeu et par niveau, progression globale, temps passé.
  - Contrat commun entre plateforme et jeu (comment un jeu s'ajoute, comment il reçoit du contenu généré ou de pack).
  - Profil local et stockage sur l'appareil, sauvegarde externe possible.
  - Frontières Clean Architecture : domaine en Dart pur, sans import de Flutter. Ports et Fakes pour les dépendances (stockage, horloge, audio).
  - ADR : choix de Flutter (et éventuellement Flame). Préciser que le projet utilise `flutter_test` et non pytest.

## À décider avant le prototype

- [x] Choix du jeu de comparaison : **Tango-like** (Takuzu/Binairo), retenu. Utiliser les noms génériques du genre dans nos documents, pas les marques.
- [x] Jouer à Samewise (fait en session). Retour : format à règle cachée sur grille carrée, mais limité aux transformations 2D simples (couleur de case) ; a motivé l'exploration du modèle de L'atelier ci-dessus.
- [x] Écrire des énigmes de L'atelier à la main — remplacé par un générateur (10 énigmes, chacune vérifiée automatiquement contre un catalogue de règles avant d'être présentée, dans l'esprit de l'ADR 0001). Plus robuste qu'écrire à la main, et permet de rejouer une énigme avec une instance neuve à chaque fois.
- [ ] **Prochaine étape concrète : faire jouer 2 ou 3 proches** au prototype (lien ci-dessus, en exemples fixes seulement). Ne pas les aider ; noter où ils bloquent, où ils s'ennuient, où ils devinent sans comprendre la règle (le prototype recueille leurs remarques écrites, à copier et ramener en session). Une fois ces retours en main : trancher le nom (« The Matrix » vs « L'atelier »), reporter le vocabulaire stabilisé dans `games/workshop/CONTEXT.md`, et passer un coup d'habillage visuel/sonore avant de conclure que le concept plaît (le prototype reste volontairement neutre pour isoler la mécanique).
- [ ] Mode de réponse plus difficile, à explorer une fois le format à choix multiples validé : au lieu de proposer 4 grilles à choisir, laisser construire la solution soi-même sur une grille vide (choisir la forme et la couleur de chaque cellule). Retire l'indice des dimensions et l'élimination par distracteurs implausibles ; probablement réservé aux niveaux avancés.

- [ ] Références et repoussoirs d'ambiance (jeux, design, univers sonore).
- [ ] Attention : suivi d'objets multiples ou Vigilance, et leur thème.
- [ ] Tablette Android disponible pour tester ? (le jalon vise téléphone et tablette).

## Plus tard

- [ ] La vitrine (deuxième jeu, mémoire de travail).
- [ ] Jeu d'attention du jalon.
- [ ] Monétisation des bundles et packs payants.
- [ ] Sauvegarde sur Google Drive, puis iCloud.
- [ ] Livraison des packs sans serveur en v1 (embarqués ou via le store).
- [ ] Vérification juridique des formats inspirés de tests reconnus, licences des données astronomiques.
- [ ] Nom et pitch de l'app.
- [ ] iOS (Mac ou build cloud, iPhone de test).
