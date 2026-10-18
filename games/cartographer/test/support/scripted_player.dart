import 'package:cartographer/cartographer.dart';

/// Un joueur scripté pour les tests : répond exact ou faux selon l'Élément de la question.
typedef Verdicts = AnswerVerdict Function(RecallQuestion question);

Verdicts knowsOnly(Set<String> itemIds) =>
    (q) => itemIds.contains(q.itemId) ? AnswerVerdict.exact : AnswerVerdict.wrong;

AnswerVerdict knowsNothing(RecallQuestion q) => AnswerVerdict.wrong;
AnswerVerdict knowsEverything(RecallQuestion q) => AnswerVerdict.exact;

PlayedPuzzle play(CartographerPuzzle puzzle, Verdicts verdicts) =>
    PlayedPuzzle(puzzle, [for (final q in puzzle.questions) verdicts(q)]);

/// Joue une Partie entière : prépare, fait jouer, rappelle la préparation jusqu'à « terminée ».
/// `verdictsFor` peut changer au fil des Énigmes (le joueur apprend entre le Repérage et le Bilan).
List<PlayedPuzzle> playWholeRun(
  PrepareCartographerPuzzles prepare,
  PrepareCartographerRequest request,
  Verdicts Function(CartographerPuzzle puzzle, List<PlayedPuzzle> history) verdictsFor,
) {
  final history = <PlayedPuzzle>[];
  for (var guard = 0; guard < 10; guard++) {
    final next = prepare(request, history);
    if (next.isEmpty) return history;
    for (final puzzle in next) {
      history.add(play(puzzle, verdictsFor(puzzle, history)));
    }
  }
  throw StateError('La Partie ne se termine pas.');
}
