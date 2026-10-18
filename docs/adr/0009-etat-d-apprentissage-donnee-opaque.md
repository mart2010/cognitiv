# Le jeu retient ce que le joueur connaît dans un état d'apprentissage stocké par la plateforme

Les jeux de connaissances (Le cartographe) choisissent quoi faire étudier d'après ce que le joueur connaît déjà ; sans mémoire entre les séances, chaque Partie referait le même repérage et un expert repartirait toujours du même point. Suivant le patron du Profil de génération (ADR 0008), le jeu décrit cet état comme une donnée sérialisable que la plateforme stocke par joueur et par jeu, dans le Profil local, sans la lire. Le contrat de l'ADR 0004 gagne une fonction pure : **mettre à jour l'état** à partir des résultats d'une Partie ; la préparation reçoit l'état en entrée. Le jeu reste sans état : il reçoit un état, il en rend un nouveau.

Cette décision a été prise, écartée (2026-10-18, « restons simple, pas d'évaluation du joueur »), puis rétablie le même jour pour la raison ci-dessus. L'état reste minimal : ce que le joueur a su ou non, jamais de dates d'échéance, de séries ni de rappels (brief : pas de répétition espacée intrusive).

## Considered Options

- **Pas d'état, repérage refait à chaque Partie** : le plus simple, mais le joueur revérifie sans fin ce qu'il connaît et le jeu ne peut proposer aucune progression.
- **Jeu avec état** : écarté pour les mêmes raisons que dans l'ADR 0004.
- **Plateforme qui lit l'état** : briserait la règle « la plateforme ne connaît jamais les règles internes d'un jeu ».

## Consequences

- La fonction est optionnelle dans le contrat : L'atelier ne l'implémente pas.
- L'état est identifié par Carte de base, Élément et genre de Lien, donc il dépend de la version des identifiants d'une Carte de base (ADR 0001) ; un changement d'identifiants demande une migration ou une remise à zéro.
- L'état fait partie du Profil local, donc de son export et de son import, et le joueur doit pouvoir le réinitialiser.
- Un « connu » stocké vieillit : il sert à prioriser les questions, jamais à établir un fait. Le jeu contrôle quelques Éléments connus à chaque Partie et peut les rétrograder.
- Le Niveau ne s'adapte jamais en secret : seul le choix du contenu s'adapte, de façon visible (voir le glossaire de la plateforme).
