import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:flutter/material.dart';

import 'cartographer_result_view.dart';
import 'cartographer_run.dart';
import 'cartographer_services.dart';
import 'question_view.dart';
import 'study_views.dart';
import 'tray_views.dart';
import 'verdict_colors.dart';

/// Une Partie du Cartographe de bout en bout : Repérage, puis Étude chronométrée, Distraction et
/// Rappel des pays ratés, puis Bilan, puis résultat. Quitter en cours demande confirmation et ne
/// compte pas (aucun point, rien de retenu).
class CartographerRunScreen extends StatefulWidget {
  final CartographerServices services;
  final cartographer.CartographerLevel level;
  final cartographer.Trial trial;

  const CartographerRunScreen({super.key, required this.services, required this.level, this.trial = cartographer.Trial.flashStudy});

  @override
  State<CartographerRunScreen> createState() => _CartographerRunScreenState();
}

class _CartographerRunScreenState extends State<CartographerRunScreen> {
  late CartographerRun _run = widget.services.newRun(widget.level, widget.trial);

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  void _replay() {
    final old = _run;
    setState(() => _run = widget.services.newRun(widget.level, widget.trial));
    old.dispose();
  }

  Future<void> _confirmQuit() async {
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter la Partie ?'),
        content: const Text("Elle ne comptera pas et le jeu ne retiendra rien de ce que vous avez fait."),
        actions: [
          TextButton(key: const Key('stay'), onPressed: () => Navigator.of(context).pop(false), child: const Text('Rester')),
          TextButton(key: const Key('quit'), onPressed: () => Navigator.of(context).pop(true), child: const Text('Quitter')),
        ],
      ),
    );
    if (quit == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _run,
      builder: (context, _) => PopScope(
        canPop: _run.stage == RunStage.finished,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmQuit();
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Le cartographe')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _body(),
            ),
          ),
        ),
      ),
    );
  }

  bool get _isTray => _run.current is cartographer.Tray;

  String get _studyHeader => _isTray
      ? 'Plateau ${_run.studyNumber} sur ${_run.studyTotal}'
      : 'Étude ${_run.studyNumber} sur ${_run.studyTotal}';

  String get _questionHeader {
    final index = _run.questionIndex + 1;
    final total = _run.current!.questions.length;
    return switch (_run.current!) {
      cartographer.Screening() => 'Première manche · $index sur $total',
      cartographer.FlashStudy() => '$_studyHeader · Rappel $index sur $total',
      cartographer.Tray() => '$_studyHeader · Rappel',
      cartographer.DelayedRecall() => 'Bilan · $index sur $total',
    };
  }

  /// « Retenez ces 4 villes », « Retenez ce pays » : le nom suit la Catégorie des Éléments à étudier.
  String get _studyTitle {
    final study = _run.study;
    final noun = placeNoun(_run.baseMap, study.studiedItemIds);
    final count = study.questions.length;
    if (count == 1) return 'Retenez ${noun.one == 'ville' ? 'cette' : 'ce'} ${noun.one}';
    return 'Retenez ces $count ${noun.many}';
  }

  Widget _body() {
    switch (_run.stage) {
      case RunStage.studyIntro:
        return StudyIntroView(
          key: ValueKey('intro-${_run.history.length}'),
          study: _run.study,
          header: _studyHeader,
          title: _studyTitle,
          note: _isTray ? 'Il faudra ensuite toutes les replacer.' : null,
          onStart: _run.beginStudy,
        );
      case RunStage.study:
        return StudyView(
          key: ValueKey('study-${_run.history.length}'),
          baseMap: _run.baseMap,
          study: _run.study,
          header: _studyHeader,
          language: _run.language,
          onDone: _run.endStudy,
        );
      case RunStage.distraction:
        return _isTray
            ? WaitView(
                key: ValueKey('wait-${_run.history.length}'),
                seconds: _run.study.distractionSeconds,
                header: _studyHeader,
                onDone: _run.endDistraction,
              )
            : DistractionView(
                key: ValueKey('distraction-${_run.history.length}'),
                seconds: _run.study.distractionSeconds,
                onDone: _run.endDistraction,
              );
      case RunStage.trayRecall:
        return TrayRecallView(
          key: ValueKey('tray-${_run.history.length}'),
          baseMap: _run.baseMap,
          tray: _run.current! as cartographer.Tray,
          language: _run.language,
          header: _questionHeader,
          onSubmit: _run.answerTray,
          onNext: _run.next,
          nextLabel: _run.studyNumber == _run.studyTotal ? 'Terminer' : 'Suivant',
          sounds: widget.services.sounds,
        );
      case RunStage.questions:
        final last = _run.questionIndex == _run.current!.questions.length - 1;
        return QuestionView(
          key: ValueKey('question-${_run.history.length}-${_run.questionIndex}'),
          baseMap: _run.baseMap,
          question: _run.question,
          language: _run.language,
          header: _questionHeader,
          onAnswer: _run.answer,
          onNext: _run.next,
          nextLabel: last && _run.current is cartographer.DelayedRecall ? 'Terminer' : 'Suivant',
          sounds: widget.services.sounds,
        );
      case RunStage.finished:
        return CartographerResultView(
          run: _run,
          onReplay: _replay,
          onHome: () => Navigator.of(context).pop(),
          onAcceptKind: (kind) => widget.services.profile.setKindActive(kind, true),
        );
    }
  }
}
