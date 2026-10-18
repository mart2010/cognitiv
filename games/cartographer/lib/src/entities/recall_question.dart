import 'link.dart';
import 'recall_aid.dart';

/// Une question de Rappel : un Lien (Élément, Indice → Réponse) posé avec une Aide. Pour une
/// Réponse textuelle avec l'aide `choices`, `choices` porte les propositions (dont la bonne),
/// dans la langue de l'Énigme ; vide sinon.
class RecallQuestion {
  final String itemId;
  final LinkKind kind;
  final RecallAid aid;
  final List<String> choices;

  const RecallQuestion({
    required this.itemId,
    required this.kind,
    required this.aid,
    this.choices = const [],
  });
}
