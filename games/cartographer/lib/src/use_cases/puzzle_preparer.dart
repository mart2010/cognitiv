import '../entities/base_map.dart';
import '../entities/cartographer_level.dart';
import '../entities/cartographer_profile.dart';
import '../entities/cartographer_puzzle.dart';
import '../entities/mastery.dart';
import '../entities/name_language.dart';
import '../entities/played_puzzle.dart';

class PrepareCartographerRequest {
  final BaseMap baseMap;
  final CartographerLevel level;
  final CartographerProfile profile;
  final NameLanguage language;

  /// Ce que le joueur connaît déjà, d'après les Parties précédentes (ADR 0009).
  final Mastery mastery;

  PrepareCartographerRequest({
    required this.baseMap,
    required this.level,
    required this.profile,
    required this.language,
    Mastery? mastery,
  }) : mastery = mastery ?? Mastery.empty;
}

/// Le contrat de la préparation des énigmes (ADR 0004, 0010), commun à toutes les Épreuves : de
/// l'historique de la Partie, les énigmes suivantes, ou une liste vide quand la Partie est finie.
abstract interface class PuzzlePreparer {
  List<CartographerPuzzle> call(PrepareCartographerRequest request, List<PlayedPuzzle> history);
}
