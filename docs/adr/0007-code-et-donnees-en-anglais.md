# Le code et les données stockées utilisent des noms anglais, la documentation reste en français

Chaque terme du glossaire a un nom de code anglais (`_Code_` dans les `CONTEXT.md`) utilisé pour les types, les paquets, les dossiers (`games/workshop`) et les clés de données stockées dans le profil local. La documentation et le glossaire restent en français, langue de travail. Les noms stockés sont difficiles à changer après publication (migration des données du joueur), et l'app est bilingue : figer des identifiants dans une seule langue d'affichage aurait un coût.

## Consequences

- Toute création de terme dans un `CONTEXT.md` doit fournir son `_Code_`.
- Le texte affiché au joueur ne vient jamais des identifiants, mais de la traduction FR/EN.
