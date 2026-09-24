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
- Premier jeu à construire : la Vitrine (logique la plus simple, teste l'hypothèse « fun sans mécaniques addictives »).

## Décisions prises

- Trois axes de classification à distinguer : domaine cognitif, mode de séance (avec ou sans paliers), domaine de connaissance (hors v1).
- Mémoire à long terme et jeux de connaissances (ciel étoilé, atlas, corps humain…) : hors jalon v1, à revoir plus tard.
- Texte toléré quand le contenu l'exige. Jeux de mots ou lexicaux toujours exclus (non-goal).
- Contenu : approche hybride, généré pour le volume, écrit à la main avec Claude pour les énigmes soignées et les packs (unicité de solution vérifiée par solveur et tests).
- Ne jamais présenter le dual n-back ni aucun jeu comme améliorant le QI ou la santé cognitive.

## Prochaine étape

- [ ] **Session `/grill-domain`**, avec la Vitrine comme cas concret. À couvrir :
  - Vocabulaire (CONTEXT.md) : plateforme, app, jeu, bundle, séance, palier, session, domaine cognitif, mode de séance, domaine de connaissance, pack de contenu. Trancher « bundle » (ensemble de jeux) contre « pack de contenu » (contenu d'un jeu).
  - Définitions : score par jeu et par niveau, progression globale, temps passé.
  - Contrat commun entre plateforme et jeu (comment un jeu s'ajoute, comment il reçoit du contenu généré ou de pack).
  - Profil local et stockage sur l'appareil, sauvegarde externe possible.
  - Frontières Clean Architecture : domaine en Dart pur, sans import de Flutter. Ports et Fakes pour les dépendances (stockage, horloge, audio).
  - ADR : choix de Flutter (et éventuellement Flame). Préciser que le projet utilise `flutter_test` et non pytest.

## À décider avant le prototype

- [ ] Références et repoussoirs d'ambiance (jeux, design, univers sonore).
- [ ] Attention : suivi d'objets multiples ou Vigilance, et leur thème.
- [ ] Tablette Android disponible pour tester ? (le jalon vise téléphone et tablette).

## Plus tard

- [ ] Atelier (règles combinées, générateur, premiers packs écrits à la main).
- [ ] Jeu d'attention du jalon.
- [ ] Monétisation des bundles et packs payants.
- [ ] Sauvegarde sur Google Drive, puis iCloud.
- [ ] Livraison des packs sans serveur en v1 (embarqués ou via le store).
- [ ] Vérification juridique des formats inspirés de tests reconnus, licences des données astronomiques.
- [ ] Nom et pitch de l'app.
- [ ] iOS (Mac ou build cloud, iPhone de test).
