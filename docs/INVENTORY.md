# Cognitiv — Inventaire des jeux

Document de travail issu de la session d'exploration. Complète `BRIEF.md`. Mécaniques génériques (principes connus), sans items ni marques protégés.

**Mode de séance** : P = avec paliers, S = sans paliers.

## Critères de short-list

1. Texte toléré quand le contenu l'exige (jeux de connaissances). Pour les autres jeux, on privilégie peu de texte, ce qui simplifie la traduction FR/EN.
2. Fun en partie courte : la boucle se comprend en 10 secondes.
3. Jouable au toucher sur téléphone et tablette.
4. Score clair, sans notion de réussite médicale ou de QI.
5. Potentiel d'originalité de traitement (univers, sons, ton).
6. Simple à construire et à tester (logique de jeu isolable).

## Candidats pour le jalon des 3 jeux

| Domaine | Candidat | Statut |
|---|---|---|
| Raisonnement et logique (S) | **L'atelier** (règle cachée) | Retenu |
| Mémoire de travail (S) | **La vitrine** (« qu'est-ce qui a changé ? ») | Retenu |
| Attention et concentration (P) | Suivi d'objets multiples (thème à revoir, voir ci-dessous) ou **Vigilance** | À trancher |

### L'atelier (règle cachée)
Une machine transforme des créatures (change une couleur, ajoute un élément, inverse une position). On voit 2 ou 3 exemples « entrée → sortie », puis une nouvelle entrée, et on choisit la bonne sortie parmi 4.
- Difficulté : règles combinées (une, deux, trois), exemples de plus en plus rares.
- Score : règles trouvées, bonus si moins d'exemples ont été nécessaires.

### Comparaison : déduction sur grille à solution unique (Tango-like ou Queens-like)
Jeu témoin, pas un candidat du jalon. Sert à séparer « la mécanique est-elle fun ? » de « notre traitement est-il fun ? » face à L'atelier.
- Tango-like (famille Takuzu/Binairo) : remplir une grille de deux symboles sans jamais en aligner trois identiques, avec autant de chaque par ligne et colonne. Règles minimales, solveur très simple.
- Queens-like : une reine par ligne, colonne et région colorée, sans contact en diagonale. Plus visuel.
- Générateur + solveur vérifiant l'unicité : même travail que pour L'atelier. Format quotidien possible, à arbitrer plus tard.
- Propriété intellectuelle : les mécaniques sont des genres anciens. Ne pas reprendre les noms ni l'habillage des jeux commerciaux.

### La vitrine (« qu'est-ce qui a changé ? »)
Une étagère de 6 à 9 objets s'affiche 5 s, l'écran se brouille 1 s, puis un objet a bougé, changé ou disparu. On le touche.
- Difficulté : plus d'objets, affichage plus court, changement plus discret.
- Score : justesse et temps de réponse.
- Décors variables (atelier, cuisine, jardin) : porte l'originalité visuelle.

### Suivi d'objets multiples (thème provisoire : lucioles)
Une mare, la nuit. 3 à 5 lucioles cibles s'allument un instant, mélangées à des leurres présents dès le début. Toutes deviennent identiques et dérivent de façon indépendante, se croisent. À l'arrêt, on touche celles qu'on a suivies. Thème à confirmer (lucioles, poissons, bulles…).
- Difficulté : nombre d'objets, vitesse, durée, croisements.
- Score : justesse par manche.
- Contrainte : les objets doivent bouger indépendamment et rester identiques entre cibles et leurres. Sinon le jeu devient de la mémoire de forme (autre domaine).
- Séance à paliers : enchaînement de manches de 10 à 15 s sur 8, 10, 12 min…
- Réserve : relève de l'attention sélective, soutenue seulement si la séance est longue.

## Pistes notées

### Ciel étoilé : mémoire à long terme et acquisition de connaissances
Décision : le ciel étoilé est réservé à un futur jeu de **mémoire à long terme** (localiser et identifier des étoiles ou constellations dans une portion du ciel, apprendre leurs noms). Il n'est pas le thème des jeux d'attention.
- Idée plus large : ajouter à l'aspect ludique et cognitif l'acquisition de connaissances (culture), généralisable à d'autres **domaines de connaissance** : astronomie, atlas et cartes géographiques, corps humain, etc. Livrés en packs de contenu.
- Rendre ces jeux fun demandera de l'imagination : à revoir plus tard.
- Mécaniques génériques possibles, indépendantes du contenu : identifier sur une carte, associer un nom à une image, localiser un élément, retrouver après un délai.
- Hors jalon v1. Points à arbitrer : texte et traduction FR/EN, ambiance « salle de classe », répétition espacée sans rappels ni streaks, état de maîtrise stocké sur l'appareil, licences des catalogues d'étoiles et tracés de constellations.

### Vigilance (attention soutenue)
Attention soutenue : rester disponible longtemps face à un flux monotone et réagir juste à la cible rare. Idée de jeu, thème à trouver (hors ciel étoilé) : un flux calme où l'on touche l'événement rare (ex. un poisson doré dans un banc) en ignorant les faux positifs (go/no-go). Correspond le mieux à « attention soutenue avec paliers » du brief, mais c'est le plus difficile à rendre fun, ce qui teste directement l'hypothèse centrale. À garder en concurrence avec le suivi d'objets multiples.

### Dual N-back (mémoire de travail)
Deux flux simultanés (ex. position visuelle + son), on signale indépendamment quand chacun répète celui d'il y a N pas.
- Domaine principal : mémoire de travail. Sollicite aussi attention partagée et fonctions exécutives.
- Bon candidat de **second jeu de mémoire** : plus exigeant que la vitrine, public plus motivé.
- Conditions : montée en charge douce (1-back mono-flux d'abord, puis second flux), habillage qui donne du sens aux flux (ex. deux instruments, une créature et un son), retour sensoriel immédiat. Le son devient un élément central du design.
- Réserve : le transfert vers l'intelligence, revendiqué en 2008, est peu confirmé par les réplications. Ne jamais le présenter comme améliorant le QI ou la santé cognitive.

## Inventaire large

### Attention et concentration (P)
| Mécanique | Principe |
|---|---|
| Vigilance | Flux calme, cible rare. |
| Suivi d'objets multiples | Suivre 3 à 5 objets mobiles parmi des leurres. |
| Recherche visuelle | Repérer l'intrus dans une scène dense. |
| Rythme et rupture | Tenir une cadence, détecter le moment où elle change. |

### Raisonnement et logique (S)
| Mécanique | Principe |
|---|---|
| Complétion de motifs | Trouver la pièce manquante dans une grille visuelle. |
| Règle cachée | Déduire la règle d'après des exemples, puis l'appliquer. |
| Déduction sur grille | Placer des éléments selon des contraintes (familles Sudoku, nonogramme, grilles de déduction en icônes). |
| Intrus et analogies | Trouver l'élément qui ne suit pas la logique du groupe. |
| Circuits et chemins | Faire circuler un signal ou un objet par un réseau de règles. |

### Mémoire de travail (S)
| Mécanique | Principe |
|---|---|
| Séquence à reproduire | Rejouer une suite de positions, sons ou couleurs. |
| N-back habillé | Signaler la répétition d'il y a N pas. |
| « Qu'est-ce qui a changé ? » | Mémoriser une scène, repérer la différence. |
| Paires et positions | Mémoire de cartes revisitée. |
| Double tâche | Retenir quelque chose pendant une petite tâche de calcul ou de tri. |

### Domaines en réserve (S)
| Domaine | Mécanique |
|---|---|
| Vitesse de traitement | Go/no-go, tri rapide selon une règle qui change. |
| Fonctions exécutives | Conflit de type Stroop visuel, changement de règle en cours de jeu, planification (blocs à déplacer en un minimum de coups). |
| Visuo-spatial | Rotation mentale, pliage, assemblage de formes. |
| Numérique | Comparer des quantités, estimer sans compter, compléter une suite numérique. |

## Notes de conception

### Sources d'inspiration : tests de type QI (ex. Mensa)
- Les tests de dépistage (matrices visuelles) sont exactement ce que le brief exclut : pas de score de QI, pas de copie d'items, pas de nom de marque.
- Réutilisables : les **principes** (matrices, suites, intrus, analogies, déductions sur grille), surtout pour le domaine raisonnement.
- Risques : ambiance « examen » à éviter (univers et ton), difficulté délicate à calibrer sans données de joueurs, vérification juridique de la frontière « inspiré de ».

### Contenu généré et contenu écrit à la main
Un contenu uniquement généré finit par répéter des motifs trop proches, avec un manque d'originalité à la longue. Approche **hybride** à retenir :
- **Généré** : volume de base, rejouabilité, contenu hors ligne sans limite.
- **Écrit à la main (co-créé avec Claude)** : énigmes fixes soignées, à unicité de solution vérifiée par un solveur et des tests, pour les « moments » marquants et les packs.
- Les énigmes écrites à la main peuvent être livrées en **packs de contenu**, gratuits ou payants (voir questions ouvertes).

## Questions ouvertes

- Références et repoussoirs (ambiance, design) : à traiter avant de figer les 3 jeux.
- Attention : suivi d'objets multiples ou Vigilance pour le prototype ? Thème à trouver pour l'un et l'autre. (fun vs fidélité à « attention soutenue »).
- Ordre de construction : décidé, l'Atelier d'abord (jeu de raisonnement, le plus risqué pour le concept), puis la Vitrine.
- Appareil de test : Pixel 8a (Android). Mac et iPhone : plus tard.
- Vocabulaire : « bundle » désigne aujourd'hui un ensemble de jeux. Un ensemble d'énigmes pour un jeu donné est autre chose (proposition : **pack de contenu**). À trancher dans CONTEXT.md.
- Livraison des packs de contenu sans serveur en v1 : embarqués dans l'app, ou téléchargeables via le store (ex. livraison de ressources Google Play) ? Impact sur la monétisation et le hors-ligne.
- Contrat commun jeu / plateforme : un jeu doit pouvoir consommer du contenu généré et du contenu de pack.
