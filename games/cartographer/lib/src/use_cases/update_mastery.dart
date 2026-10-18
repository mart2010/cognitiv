import '../entities/cartographer_answer.dart';
import '../entities/knowledge.dart';
import '../entities/mastery.dart';
import '../entities/played_puzzle.dart';

/// Cas d'usage « mettre à jour l'état » du contrat (ADR 0009) : de la Maîtrise d'avant la
/// Partie et de l'historique de la Partie, la Maîtrise d'après. Fonction pure.
///
/// Par Lien, un seul pas par Partie, d'après le **dernier** verdict : exact fait monter d'un
/// cran à partir de l'état stocké (pas d'état → fragile, fragile → solide), tout autre verdict
/// ramène à « à apprendre ». Un pays raté au Repérage puis réussi au Bilan devient donc fragile
/// et ne peut devenir solide qu'à une Partie suivante.
class UpdateMastery {
  Mastery call(Mastery before, String baseMapId, List<PlayedPuzzle> history) {
    final lastVerdict = <MasteryKey, AnswerVerdict>{};
    for (final played in history) {
      for (var i = 0; i < played.puzzle.questions.length; i++) {
        final q = played.puzzle.questions[i];
        lastVerdict[MasteryKey(baseMapId, q.itemId, q.kind)] = played.verdicts[i];
      }
    }
    var after = before;
    for (final entry in lastVerdict.entries) {
      final previous = before.states[entry.key];
      after = after.set(
        entry.key,
        entry.value == AnswerVerdict.exact ? (previous ?? Knowledge.toLearn).promoted : Knowledge.toLearn,
      );
    }
    return after;
  }
}
