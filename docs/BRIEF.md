# Cognitiv — Brief

## Context

Les apps et réseaux sociaux ont érodé l'attention et la concentration de chacun. Les apps de brain training existantes (Lumosity, Elevate, Peak, BrainHQ…) et les jeux de logique classiques sont souvent perçus comme « salle de classe » ou comme des exercices plus que comme du jeu.

Le projet naît d'une envie de créer, en tant qu'utilisateur, quelque chose d'original et fun : se divertir sans s'abrutir. L'originalité vient du traitement (design, ton, identité visuelle et sonore soignée), de jeux originaux et de la réinterprétation de formats existants (tests de type QI, exercices cognitifs), en s'inspirant des principes sans copier d'items ni de marques protégés.

## Goals

- Une **plateforme d'accueil** mobile (une seule app sur les stores) qui accueille une multitude de jeux et d'exercices cognitifs, répartis par **domaine cognitif** (un jeu a un domaine principal, même s'il en touche plusieurs) :
  - **Domaines du jalon v1** : attention et concentration, raisonnement et logique, mémoire de travail (court terme).
  - **Domaines en réserve** (à considérer dans l'inventaire des jeux) : vitesse de traitement / réactivité, fonctions exécutives (inhibition, flexibilité mentale, planification), visuo-spatial, numérique.
  - **Mémoire à long terme** : hors v1. Elle demande de la répétition espacée (rappels, retours sur plusieurs jours), en tension avec les non-goals et le format de partie courte. Une variante intra-partie (apprendre, distraction, rappeler) reste envisageable.
- Public : **grand public adulte**, sans mineurs. Aucun trouble cognitif reconnu n'est visé.
- Parties courtes par défaut. Pour les seuls jeux d'attention et de concentration, des **sessions à paliers progressifs** (ex. 8, 10, 12, 14 min) : l'app propose le palier suivant, l'utilisateur reste libre de choisir, un abandon n'est jamais pénalisé.
- La plateforme mesure un score par jeu et par niveau, une progression globale (niveaux, régularité) et le temps passé (information neutre) pour entretenir la motivation.
- Bundles de jeux gratuits, et éventuellement payants (monétisation à décider plus tard).
- Promesse : divertissement d'abord, progression légère, sans promesse santé affichée. La concentration est une intention de conception, pas un argument de vente. Le pitch « se divertir sans s'abrutir » est provisoire.

## Non-goals

- Pas de publicité.
- Pas de culpabilisation de l'utilisateur (streaks punitifs, notifications insistantes). Le jeu lui-même n'est pas bridé : un jeu très accrocheur est un bon jeu.
- Pas de score de QI ni d'évaluation cognitive, pas de diagnostic, pas de ciblage TDAH.
- Pas de multijoueur (solo uniquement).
- Pas de compte utilisateur ni de serveur en v1.
- Pas de création de jeux par les utilisateurs en v1 (évolution possible, pas un objectif).
- Pas de jeux de mots ou lexicaux au départ. Le texte n'est pas interdit : les jeux de connaissances (hors v1) en ont besoin. Les jeux du jalon v1 restent légers en texte.

## Constraints

- Développeur solo assisté par Claude, sans date butoir, sur Windows ou Linux.
- Pile envisagée : Flutter (Dart), comme wordlai. À confirmer par un ADR au moment de la conception du domaine.
- **Android d'abord** (téléphone et tablette), Apple ensuite. Compiler et publier pour iOS exige un Mac ou un service de build cloud, plus un appareil de test.
- Fonctionnement 100 % hors ligne, données stockées sur l'appareil. Une politique de confidentialité reste obligatoire pour les stores.
- Interface en français et en anglais.
- Publication à terme sur les stores : classification d'âge adulte, déclarations des stores, comptes développeur (Apple 99 $/an, Google 25 $ une fois).
- Propriété intellectuelle : s'inspirer des principes des tests reconnus, sans copier d'items ni de marques, sans se présenter comme un « test de QI ».

## Success criteria

- **Jalon technique** : 3 jeux jouables sur téléphone et tablette Android, un par domaine cognitif (attention soutenue avec paliers, raisonnement/logique, mémoire de travail), reliés par un écran d'accueil commun.
- **Signal de valeur** : le créateur y joue de lui-même après 2 semaines, et au moins 3 proches adultes sur 5 rejouent sans qu'on le leur demande.
- **Hypothèse à valider en premier** : des jeux qui sollicitent réflexion et attention peuvent être vraiment fun, au point qu'on veuille rejouer. Elle se teste avec un prototype jouable avant de construire le reste de la plateforme. Le prototype est un jeu de raisonnement et logique (L'atelier), le type de jeu le plus difficile à concevoir et essentiel au concept : s'il échoue, le concept est à revoir.

## Open questions

- Références et repoussoirs (ambiance, design) : à traiter avec l'inventaire large des jeux, avant de choisir les 3 premiers. À décider avant le prototype.
- Short-list des premiers jeux à partir d'un inventaire plus large, à faire ensemble. L'inventaire couvre les domaines du jalon v1 et les domaines en réserve (vitesse de traitement et fonctions exécutives semblent les plus prometteuses pour des jeux fun).
- Mémoire à long terme : la traiter un jour ou non, et sous quelle forme, sans répétition espacée intrusive. À réévaluer après la v1.
- Acquisition de connaissances (culture) : ajouter à la dimension cognitive et ludique un apprentissage de contenu (ex. noms et emplacement des étoiles et constellations), qui donnerait un rôle à la mémoire à long terme et se généraliserait à d'autres domaines de connaissance. Hors jalon v1. Tensions à arbitrer : texte dans un produit « presque sans texte », ambiance « salle de classe », répétition espacée sans notifications ni streaks, licences des données astronomiques, état de maîtrise stocké sur l'appareil.
- Appareils de test : un Pixel 8a (téléphone Android) est disponible. Tablette Android : à préciser (le jalon vise téléphone et tablette). Mac et iPhone : plus tard, à préciser avant de fixer l'ordre de livraison iOS.
- Monétisation des bundles payants : avant la publication.
- Sauvegarde optionnelle sur le Google Drive de l'utilisateur (reprise sur une autre appareil, ex. tablette) et équivalent iCloud plus tard : avant la publication.
- Nom et pitch de l'app.
- Pauses intégrées aux paliers d'attention : à décider lors de la conception du premier jeu d'attention.
- Ouverture de la création de jeux aux utilisateurs : évolution éventuelle, à réévaluer après la v1.
- Vérification juridique des formats inspirés de tests reconnus, quand on s'en approchera.

## Handoff to domain design

- Vocabulaire à fixer : plateforme, app, jeu, bundle, séance, palier, session, domaine cognitif, mode de séance, domaine de connaissance, pack de contenu.
- Trois axes possibles de classification d'un jeu (le troisième, hors v1, n'existe que si l'acquisition de connaissances est retenue) :
  - **domaine cognitif** (attention, raisonnement, mémoire de travail…) ;
  - **mode de séance** : avec paliers (attention/concentration) ou sans paliers ;
  - **domaine de connaissance** (astronomie, géographie…) : le contenu appris, porté par des packs de contenu, indépendant de la mécanique du jeu.
- Score par jeu, par niveau, progression globale, temps passé : définition de chacun.
- Profil local et stockage des données sur l'appareil, possible sauvegarde externe.
- Catalogue de jeux et bundles (gratuits / payants).
- Comment un nouveau jeu s'ajoute à la plateforme (contrat commun entre plateforme et jeu).
