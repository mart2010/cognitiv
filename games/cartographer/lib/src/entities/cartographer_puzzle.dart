import 'name_language.dart';
import 'recall_question.dart';

/// Énigme du Cartographe (`platform/CONTEXT.md`) : le Repérage, une Étude-éclair, ou le Bilan
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

/// Étude-éclair : on étudie les Liens des questions (Indice et Réponse montrés ensemble) en
/// `studySeconds`, puis une Distraction de `distractionSeconds`, puis le Rappel. Une
/// question par Élément du Lot d'étude.
final class FlashStudy extends CartographerPuzzle {
  final int studySeconds;
  final int distractionSeconds;

  const FlashStudy({
    required super.language,
    required super.questions,
    required this.studySeconds,
    required this.distractionSeconds,
  });

  List<String> get studiedItemIds => [for (final q in questions) q.itemId];
}

/// Bilan : le Rappel différé de Liens étudiés plus tôt dans la Partie, sans les remontrer.
final class DelayedRecall extends CartographerPuzzle {
  const DelayedRecall({required super.language, required super.questions});
}
