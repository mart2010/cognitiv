import 'recall_aid.dart';

/// Niveau du Cartographe : un réglage de difficulté fixé par le jeu (`platform/CONTEXT.md`).
/// Il règle la taille du Lot d'étude, la durée d'étude, la durée de Distraction et
/// l'Aide au rappel. Le joueur choisit librement son Niveau, il n'y a pas de verrou ; la
/// difficulté ne s'adapte jamais en secret.
class CartographerLevel {
  /// De 1 (le plus facile) à `CartographerLevels.all.length`.
  final int number;
  /// Taille du Lot d'étude : les Éléments non connus étudiés ensemble.
  final int itemCount;
  final int studySeconds;
  final int distractionSeconds;
  final RecallAid aid;

  /// Points bidon posés avec les vrais sur un Plateau de Points (villes) : le joueur choisit parmi
  /// des points candidats plutôt que de viser librement.
  final int trayDecoys;

  /// Nombre maximal d'Études-éclair d'une Partie ; les ratés du Repérage au-delà restent de
  /// côté, une Partie ne devient jamais interminable.
  final int maxStudyCycles;

  /// Nombre de questions du Bilan de fin de Partie.
  final int delayedRecallCount;

  const CartographerLevel({
    required this.number,
    required this.itemCount,
    required this.studySeconds,
    required this.distractionSeconds,
    required this.aid,
    this.trayDecoys = 4,
    this.maxStudyCycles = 2,
    this.delayedRecallCount = 5,
  });

  /// Les points croissent avec le Niveau, comme dans L'atelier.
  int get pointsPerQuestion => 10 * number;
}

/// Échelle des Niveaux, du plus facile au plus difficile. Provisoire : les chiffres se
/// règlent au playtest.
abstract final class CartographerLevels {
  static const all = [
    CartographerLevel(number: 1, itemCount: 3, studySeconds: 12, distractionSeconds: 3, aid: RecallAid.choices, trayDecoys: 3),
    CartographerLevel(number: 2, itemCount: 4, studySeconds: 12, distractionSeconds: 3, aid: RecallAid.choices, trayDecoys: 4),
    CartographerLevel(number: 3, itemCount: 4, studySeconds: 10, distractionSeconds: 5, aid: RecallAid.choices, trayDecoys: 5),
    CartographerLevel(number: 4, itemCount: 5, studySeconds: 10, distractionSeconds: 5, aid: RecallAid.firstLetter, trayDecoys: 6),
    CartographerLevel(number: 5, itemCount: 5, studySeconds: 8, distractionSeconds: 6, aid: RecallAid.firstLetter, trayDecoys: 8),
    CartographerLevel(number: 6, itemCount: 6, studySeconds: 8, distractionSeconds: 6, aid: RecallAid.firstLetter, trayDecoys: 10),
    CartographerLevel(number: 7, itemCount: 6, studySeconds: 6, distractionSeconds: 8, aid: RecallAid.free, trayDecoys: 12),
    CartographerLevel(number: 8, itemCount: 7, studySeconds: 6, distractionSeconds: 8, aid: RecallAid.free, trayDecoys: 14),
    CartographerLevel(number: 9, itemCount: 8, studySeconds: 5, distractionSeconds: 10, aid: RecallAid.free, trayDecoys: 17),
    CartographerLevel(number: 10, itemCount: 8, studySeconds: 4, distractionSeconds: 10, aid: RecallAid.free, trayDecoys: 20),
  ];

  static CartographerLevel get first => all.first;
  static CartographerLevel get last => all.last;

  static CartographerLevel byNumber(int number) => all.firstWhere(
        (level) => level.number == number,
        orElse: () => throw ArgumentError('Niveau inconnu : $number'),
      );

  static bool hasNext(CartographerLevel level) => level.number < last.number;
  static bool hasPrevious(CartographerLevel level) => level.number > first.number;
}
