import 'name_language.dart';
import 'recall_question.dart';

/// Énigme du Cartographe (`platform/CONTEXT.md`) : le Repérage, une Étude-éclair, un Plateau, ou le Bilan
/// de fin de Partie. Une Énigme reste valide par rapport à la Carte de base qui l'a produite
/// (ADR 0001, 0002) : elle ne référence les Éléments que par leur identifiant.
sealed class CartographerPuzzle {
  final NameLanguage language;
  final List<RecallQuestion> questions;
  const CartographerPuzzle({required this.language, required this.questions});
}

/// Repérage : la première manche d'une Partie, une question par Élément de la Région (ou un
/// échantillon des moins connus). Sert à choisir quoi étudier ; rapporte des points comme les
/// autres manches.
final class Screening extends CartographerPuzzle {
  const Screening({required super.language, required super.questions});
}

/// Une Énigme où l'on étudie des Éléments montrés ensemble pendant `studySeconds`, puis une
/// Distraction de `distractionSeconds` (suspendue : l'app montre pour l'instant une page
/// d'attente), puis le Rappel. Une question par Élément étudié.
sealed class StudyPuzzle extends CartographerPuzzle {
  final int studySeconds;
  final int distractionSeconds;

  const StudyPuzzle({
    required super.language,
    required super.questions,
    required this.studySeconds,
    required this.distractionSeconds,
  });

  List<String> get studiedItemIds => [for (final q in questions) q.itemId];
}

/// Étude-éclair : on étudie les Liens des questions (Indice et Réponse montrés ensemble), puis le
/// Rappel se fait une question à la fois, avec son verdict tout de suite. Une question par Élément
/// du Lot d'étude.
final class FlashStudy extends StudyPuzzle {
  const FlashStudy({
    required super.language,
    required super.questions,
    required super.studySeconds,
    required super.distractionSeconds,
  });
}

/// Plateau (`games/cartographer/CONTEXT.md`) : N Éléments d'une même Catégorie sont montrés
/// ensemble, nommés, puis le joueur les replace tous sur la Scène, dans l'ordre qu'il veut, et ne
/// voit les verdicts qu'après les avoir tous placés. Chaque question est un Lien « nom → position ».
final class Tray extends StudyPuzzle {
  const Tray({
    required super.language,
    required super.questions,
    required super.studySeconds,
    required super.distractionSeconds,
  });
}

/// Bilan : le Rappel différé de Liens étudiés plus tôt dans la Partie, sans les remontrer.
final class DelayedRecall extends CartographerPuzzle {
  const DelayedRecall({required super.language, required super.questions});
}
