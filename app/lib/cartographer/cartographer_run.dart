import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:flutter/foundation.dart';

/// Où en est le joueur dans l'Énigme courante.
enum RunStage {
  /// Avant une Étude : « retenez ces pays », bouton Commencer.
  studyIntro,

  /// L'Étude chronométrée.
  study,

  /// La Distraction entre l'Étude et le Rappel.
  distraction,

  /// Une question à la fois : Repérage, Rappel après Étude, ou Bilan.
  questions,

  /// Le Rappel d'un Plateau : tous les Éléments à replacer, puis les verdicts d'un coup.
  trayRecall,

  /// Plus d'Énigme : résultat.
  finished,
}

/// Une Partie du Cartographe : la machine à états entre le domaine (préparation progressive,
/// évaluation, score, Maîtrise, ADR 0010) et les écrans. Ne connaît ni widget ni minuterie : les
/// écrans mesurent le temps et appellent `endStudy` / `endDistraction`. Une Partie quittée avant la
/// fin n'appelle jamais `onFinished` : un abandon ne touche pas la Maîtrise.
class CartographerRun extends ChangeNotifier {
  final cartographer.BaseMap baseMap;
  final cartographer.CartographerLevel level;
  final cartographer.CartographerProfile profile;
  final cartographer.NameLanguage language;
  final cartographer.Mastery masteryBefore;

  final cartographer.PuzzlePreparer prepare;
  final cartographer.EvaluateCartographerAnswer evaluate;
  final cartographer.ComputeCartographerScore computeScore;
  final cartographer.UpdateMastery updateMastery;
  final cartographer.SuggestLinkKinds suggestKinds;

  /// Appelée une fois, à la fin, avec la Maîtrise mise à jour.
  final void Function(cartographer.Mastery updated)? onFinished;

  final List<cartographer.PlayedPuzzle> history = [];
  final List<cartographer.CartographerPuzzle> _queue = [];
  final List<cartographer.AnswerVerdict> _verdicts = [];

  cartographer.CartographerPuzzle? _current;
  RunStage _stage = RunStage.questions;
  int _questionIndex = 0;
  bool _answered = false;

  cartographer.CartographerScoreResult? _result;
  cartographer.Mastery? _masteryAfter;
  List<cartographer.LinkKind> _suggestedKinds = const [];

  CartographerRun({
    required this.baseMap,
    required this.level,
    required this.profile,
    required this.language,
    required this.masteryBefore,
    required this.prepare,
    cartographer.EvaluateCartographerAnswer? evaluate,
    cartographer.ComputeCartographerScore? computeScore,
    cartographer.UpdateMastery? updateMastery,
    cartographer.SuggestLinkKinds? suggestKinds,
    this.onFinished,
  }) : evaluate = evaluate ?? cartographer.EvaluateCartographerAnswer(),
       computeScore = computeScore ?? cartographer.ComputeCartographerScore(),
       updateMastery = updateMastery ?? cartographer.UpdateMastery(),
       suggestKinds = suggestKinds ?? cartographer.SuggestLinkKinds() {
    _advancePuzzle();
  }

  RunStage get stage => _stage;
  cartographer.CartographerPuzzle? get current => _current;
  bool get answered => _answered;
  int get questionIndex => _questionIndex;

  cartographer.RecallQuestion get question => _current!.questions[_questionIndex];
  cartographer.Item get questionItem => baseMap.itemById(question.itemId);

  /// L'Étude courante : un Lot d'étude (Étude-éclair) ou un Plateau.
  cartographer.StudyPuzzle get study => _current! as cartographer.StudyPuzzle;

  /// Étude courante (à partir de 1) et nombre total d'Études, connu dès que le Repérage est joué
  /// (pour un Plateau, connu dès le début : toute la Partie est préparée d'un coup).
  int get studyNumber => history.where((p) => p.puzzle is cartographer.StudyPuzzle).length + 1;
  int get studyTotal =>
      history.where((p) => p.puzzle is cartographer.StudyPuzzle).length +
      (_current is cartographer.StudyPuzzle ? 1 : 0) +
      _queue.whereType<cartographer.StudyPuzzle>().length;

  /// Une Partie de Plateaux ?
  bool get isTrayRun => (_current ?? history.last.puzzle) is cartographer.Tray;

  /// Le résultat de chaque Plateau joué : combien replacés exactement, sur combien.
  List<({int exact, int total})> get trayResults => [
    for (final played in history)
      if (played.puzzle is cartographer.Tray)
        (exact: played.verdicts.where((v) => v == cartographer.AnswerVerdict.exact).length, total: played.verdicts.length),
  ];

  // Résultat, disponible quand la Partie est finie.
  cartographer.CartographerScoreResult get result => _result!;
  cartographer.Mastery get masteryAfter => _masteryAfter!;
  List<cartographer.LinkKind> get suggestedKinds => _suggestedKinds;

  List<cartographer.QuestionOutcome> get outcomes => [for (final p in history) ...p.outcomes];
  int get exactCount => outcomes.where((o) => o.verdict == cartographer.AnswerVerdict.exact).length;

  /// Combien d'Éléments le Repérage a montrés non connus (0 : le joueur connaissait tout).
  int get missedAtScreening {
    final first = history.isEmpty ? null : history.first;
    if (first == null) return 0;
    return first.verdicts.where((v) => v != cartographer.AnswerVerdict.exact).length;
  }

  void beginStudy() {
    _require(_stage == RunStage.studyIntro, 'beginStudy hors de l\'introduction d\'une Étude');
    _stage = RunStage.study;
    notifyListeners();
  }

  void endStudy() {
    _require(_stage == RunStage.study, 'endStudy hors de l\'Étude');
    _stage = RunStage.distraction;
    notifyListeners();
  }

  void endDistraction() {
    _require(_stage == RunStage.distraction, 'endDistraction hors de la Distraction');
    _stage = _current is cartographer.Tray ? RunStage.trayRecall : RunStage.questions;
    notifyListeners();
  }

  /// Évalue la réponse à la question courante. Une seule réponse par question.
  cartographer.AnswerEvaluation answer(cartographer.CartographerAnswer answer) {
    _require(_stage == RunStage.questions && !_answered, 'réponse hors question ou déjà donnée');
    final evaluation = evaluate(baseMap, question, answer);
    _verdicts.add(evaluation.verdict);
    _answered = true;
    notifyListeners();
    return evaluation;
  }

  /// Évalue d'un coup les réponses d'un Plateau, une par question et dans l'ordre des questions.
  /// Aucun verdict n'est connu avant : le joueur les a tous placés avant de les voir.
  List<cartographer.AnswerEvaluation> answerTray(List<cartographer.CartographerAnswer> answers) {
    _require(_stage == RunStage.trayRecall && !_answered, 'réponse hors Rappel de Plateau ou déjà donnée');
    final questions = _current!.questions;
    if (answers.length != questions.length) {
      throw ArgumentError('${answers.length} réponse(s) pour ${questions.length} question(s).');
    }
    final evaluations = [for (var i = 0; i < questions.length; i++) evaluate(baseMap, questions[i], answers[i])];
    _verdicts.addAll(evaluations.map((e) => e.verdict));
    _answered = true;
    notifyListeners();
    return evaluations;
  }

  /// Passe à la question suivante, ou à l'Énigme suivante après la dernière (après les verdicts,
  /// pour un Plateau).
  void next() {
    _require((_stage == RunStage.questions || _stage == RunStage.trayRecall) && _answered, 'next avant une réponse');
    _questionIndex = _stage == RunStage.trayRecall ? _current!.questions.length : _questionIndex + 1;
    _answered = false;
    if (_questionIndex >= _current!.questions.length) {
      history.add(cartographer.PlayedPuzzle(_current!, List.of(_verdicts)));
      _verdicts.clear();
      _advancePuzzle();
    }
    notifyListeners();
  }

  void _advancePuzzle() {
    if (_queue.isEmpty) {
      _queue.addAll(
        prepare(
          cartographer.PrepareCartographerRequest(
            baseMap: baseMap,
            level: level,
            profile: profile,
            language: language,
            mastery: masteryBefore,
          ),
          history,
        ),
      );
    }
    if (_queue.isEmpty) {
      _finish();
      return;
    }
    _current = _queue.removeAt(0);
    _questionIndex = 0;
    _stage = _current is cartographer.StudyPuzzle ? RunStage.studyIntro : RunStage.questions;
  }

  void _finish() {
    _current = null;
    _stage = RunStage.finished;
    _result = computeScore(outcomes, level: level);
    _masteryAfter = updateMastery(masteryBefore, baseMap.id, history);
    // Un Plateau ignore les genres de Lien du Profil : rien à suggérer.
    _suggestedKinds = history.any((p) => p.puzzle is cartographer.Tray) ? const [] : suggestKinds(baseMap, profile, _masteryAfter!);
    onFinished?.call(_masteryAfter!);
  }

  void _require(bool condition, String message) {
    if (!condition) throw StateError(message);
  }
}
