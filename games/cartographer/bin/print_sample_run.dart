// Script de démo (Frameworks & Drivers, pas Interface Adapter) : joue deux Parties du
// Cartographe sur l'Amérique du Sud avec un joueur simulé, et affiche chaque phase et la
// Maîtrise qui en résulte. Le joueur connaît d'abord 5 pays, puis retient ce qu'il étudie.
// Usage : dart run bin/print_sample_run.dart [niveau] [graine]
import 'dart:convert';
import 'dart:io';

import 'package:cartographer/cartographer.dart';

void main(List<String> args) {
  final levelNumber = args.isNotEmpty ? int.parse(args.first) : 3;
  final seed = args.length > 1 ? int.parse(args[1]) : DateTime.now().millisecondsSinceEpoch;
  final baseMap = BaseMapCodec.fromJson(
    jsonDecode(File('data/south_america.json').readAsStringSync()) as Map<String, dynamic>,
  );
  final level = CartographerLevels.byNumber(levelNumber);
  final profile = CartographerProfile.defaults();
  final prepare = PrepareCartographerPuzzles(random: SystemRandomSource(seed));
  final update = UpdateMastery();
  final score = ComputeCartographerScore();

  // Ce que le joueur simulé connaît avant de jouer ; il apprend ensuite ce qu'il étudie.
  final known = {'BRA', 'ARG', 'CHL', 'PER', 'COL'};
  var mastery = Mastery.empty;

  for (var run = 1; run <= 2; run++) {
    print('════ Partie $run (niveau $levelNumber, graine $seed) ════');
    final history = <PlayedPuzzle>[];
    while (true) {
      final next = prepare(
        PrepareCartographerRequest(baseMap: baseMap, level: level, profile: profile, language: NameLanguage.fr, mastery: mastery),
        history,
      );
      if (next.isEmpty) break;
      for (final puzzle in next) {
        // Il retient ce qu'il étudie : il le saura au Rappel qui suit l'Étude.
        if (puzzle is FlashStudy) known.addAll(puzzle.studiedItemIds);
        final verdicts = [for (final q in puzzle.questions) known.contains(q.itemId) ? AnswerVerdict.exact : AnswerVerdict.wrong];
        history.add(PlayedPuzzle(puzzle, verdicts));
        _print(baseMap, puzzle, verdicts);
      }
    }
    final result = score(history.expand((p) => p.outcomes).toList(), level: level);
    print('Score ${result.score}, niveau franchi : ${result.levelCleared}, suggestion : ${result.suggestion.name}');
    mastery = update(mastery, baseMap.id, history);
    final counts = <Knowledge, int>{};
    for (final k in mastery.states.values) {
      counts[k] = (counts[k] ?? 0) + 1;
    }
    print('Maîtrise : ${[for (final k in Knowledge.values) '${k.name} ${counts[k] ?? 0}'].join(', ')}\n');
  }
}

void _print(BaseMap baseMap, CartographerPuzzle puzzle, List<AnswerVerdict> verdicts) {
  switch (puzzle) {
    case Screening():
      print('Repérage (${puzzle.questions.length} questions)');
    case FlashStudy(:final studySeconds, :final distractionSeconds):
      print('Étude-éclair : ${studySeconds}s d\'étude, ${distractionSeconds}s de distraction');
    case Tray(:final studySeconds):
      print('Plateau : ${puzzle.questions.length} à replacer, ${studySeconds}s d\'étude');
    case Sequence(:final length):
      print('Séquence de $length Éléments');
    case DelayedRecall():
      print('Bilan (rappel différé)');
  }
  for (var i = 0; i < puzzle.questions.length; i++) {
    final q = puzzle.questions[i];
    final item = baseMap.itemById(q.itemId);
    final mark = verdicts[i] == AnswerVerdict.exact ? '✓' : '✗';
    print('  $mark ${item.names.fr.padRight(10)} ${q.kind.cue.name} -> ${q.kind.answer.name}');
  }
  print('');
}
