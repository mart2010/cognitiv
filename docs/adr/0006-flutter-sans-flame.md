# Flutter pour l'app, Android d'abord, sans Flame pour l'instant

L'app est écrite en Flutter (Dart), cible Android d'abord puis iOS. Les deux jeux de départ (L'atelier, un jeu de grille) sont des interfaces à toucher, sans physique ni mouvement continu : les widgets et le dessin personnalisé suffisent. Flame est à réévaluer quand un jeu d'objets mobiles (suivi de lucioles) deviendra un vrai candidat. Les tests utilisent `dart test` pour les paquets purs et `flutter_test` pour l'app.

## Considered Options

- **Flame dès le départ** : utile pour des objets qui bougent, superflu pour deux jeux à interface tactile.
