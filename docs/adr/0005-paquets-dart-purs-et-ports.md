# Paquets Dart purs pour la plateforme et chaque jeu, ports pour l'extérieur

La plateforme (`platform/`) et chaque jeu (`games/<game>/`) sont des paquets Dart sans aucun import de Flutter, testés avec `dart test`. Une app Flutter (`app/`) les assemble et porte l'interface. Les dépendances pointent vers l'intérieur uniquement, et la frontière est vérifiée par les dépendances des paquets elles-mêmes. Le domaine définit des ports pour le stockage du profil local, l'horloge et le hasard ; l'app fournit les implémentations, les tests des doublures. L'audio reste côté app : le domaine émet des faits (bonne réponse, niveau franchi) que l'app traduit en sons.

## Considered Options

- **Un seul paquet Flutter avec des dossiers** : moins de configuration, mais rien n'empêche un jeu d'importer Flutter ou la plateforme par erreur.

## Consequences

- Il faut un espace de travail Dart avec plusieurs paquets dès le départ.
- Le hasard injecté rend les générateurs d'énigmes reproductibles en test.
