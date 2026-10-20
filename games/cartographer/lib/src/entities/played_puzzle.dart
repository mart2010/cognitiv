import 'cartographer_answer.dart';
import 'cartographer_puzzle.dart';

/// Phase d'une Partie à laquelle appartient une question, pour le Score.
enum PuzzlePhase { screening, study, delayed, tray }

/// Le résultat d'une question, pour le calcul du Score et de la Maîtrise.
class QuestionOutcome {
  final AnswerVerdict verdict;
  final PuzzlePhase phase;
  const QuestionOutcome(this.verdict, {required this.phase});
}

/// Une Énigme jouée et le verdict de chacune de ses questions, dans l'ordre. L'historique de
/// la Partie, que la plateforme conserve et rend au jeu pour préparer la suite (ADR 0010).
class PlayedPuzzle {
  final CartographerPuzzle puzzle;
  final List<AnswerVerdict> verdicts;

  PlayedPuzzle(this.puzzle, this.verdicts) {
    if (verdicts.length != puzzle.questions.length) {
      throw ArgumentError('${verdicts.length} verdict(s) pour ${puzzle.questions.length} question(s).');
    }
  }

  PuzzlePhase get phase => switch (puzzle) {
        Screening() => PuzzlePhase.screening,
        FlashStudy() => PuzzlePhase.study,
        DelayedRecall() => PuzzlePhase.delayed,
        Tray() => PuzzlePhase.tray,
      };

  List<QuestionOutcome> get outcomes => [for (final v in verdicts) QuestionOutcome(v, phase: phase)];
}
