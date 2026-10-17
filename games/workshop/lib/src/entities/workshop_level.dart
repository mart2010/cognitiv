/// Niveau de L'atelier : un réglage de difficulté fixé par le jeu (`platform/CONTEXT.md`).
/// Il règle la taille de la Matrice, le nombre de Règles combinées et le nombre
/// d'Exemples (moins d'Exemples = plus difficile). Le joueur choisit librement son
/// Niveau, il n'y a pas de verrou ; la difficulté ne s'adapte jamais en secret.
class WorkshopLevel {
  /// De 1 (le plus facile) à `WorkshopLevels.all.length`.
  final int number;
  final int rowCount;
  final int columnCount;
  final int ruleCount;
  final int exampleCount;

  /// Nombre d'Énigmes d'une Partie à ce Niveau.
  final int puzzleCount;

  const WorkshopLevel({
    required this.number,
    required this.rowCount,
    required this.columnCount,
    required this.ruleCount,
    required this.exampleCount,
    this.puzzleCount = 5,
  });

  /// Les points croissent avec le Niveau : une bonne réponse vaut plus quand le Niveau
  /// est plus difficile, ce qui rend les Scores de Niveaux différents comparables.
  int get pointsPerCorrectAnswer => 10 * number;

  /// Score maximal d'une Partie à ce Niveau.
  int get maxScore => pointsPerCorrectAnswer * puzzleCount;
}

/// Échelle des Niveaux de L'atelier, du plus facile au plus difficile. Chaque palier
/// durcit un seul axe à la fois (taille, nombre de Règles, nombre d'Exemples).
abstract final class WorkshopLevels {
  static const all = [
    WorkshopLevel(number: 1, rowCount: 3, columnCount: 3, ruleCount: 1, exampleCount: 3),
    WorkshopLevel(number: 2, rowCount: 3, columnCount: 3, ruleCount: 1, exampleCount: 2),
    WorkshopLevel(number: 3, rowCount: 3, columnCount: 4, ruleCount: 1, exampleCount: 2),
    WorkshopLevel(number: 4, rowCount: 4, columnCount: 4, ruleCount: 1, exampleCount: 2),
    WorkshopLevel(number: 5, rowCount: 3, columnCount: 3, ruleCount: 2, exampleCount: 3),
    WorkshopLevel(number: 6, rowCount: 4, columnCount: 4, ruleCount: 2, exampleCount: 3),
    WorkshopLevel(number: 7, rowCount: 4, columnCount: 4, ruleCount: 2, exampleCount: 2),
    WorkshopLevel(number: 8, rowCount: 4, columnCount: 4, ruleCount: 3, exampleCount: 3),
    WorkshopLevel(number: 9, rowCount: 4, columnCount: 5, ruleCount: 3, exampleCount: 3),
    WorkshopLevel(number: 10, rowCount: 4, columnCount: 5, ruleCount: 3, exampleCount: 2),
  ];

  static WorkshopLevel get first => all.first;
  static WorkshopLevel get last => all.last;

  static WorkshopLevel byNumber(int number) => all.firstWhere(
        (level) => level.number == number,
        orElse: () => throw ArgumentError('Niveau inconnu : $number'),
      );

  static bool hasNext(WorkshopLevel level) => level.number < last.number;
  static bool hasPrevious(WorkshopLevel level) => level.number > first.number;
  static WorkshopLevel next(WorkshopLevel level) => byNumber(level.number + 1);
  static WorkshopLevel previous(WorkshopLevel level) => byNumber(level.number - 1);
}
