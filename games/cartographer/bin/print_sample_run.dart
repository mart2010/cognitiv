// Script de démo (Frameworks & Drivers, pas Interface Adapter) : génère une vraie Partie
// du Cartographe sur l'Amérique du Sud et l'affiche dans le terminal.
// Usage : dart run bin/print_sample_run.dart [niveau] [graine]
import 'dart:convert';
import 'dart:io';

import 'package:cartographer/cartographer.dart';

void main(List<String> args) {
  final levelNumber = args.isNotEmpty ? int.parse(args.first) : 4;
  final seed = args.length > 1 ? int.parse(args[1]) : DateTime.now().millisecondsSinceEpoch;
  final baseMap = BaseMapCodec.fromJson(
    jsonDecode(File('data/south_america.json').readAsStringSync()) as Map<String, dynamic>,
  );
  final level = CartographerLevels.byNumber(levelNumber);
  print('Niveau $levelNumber, graine $seed, aide : ${level.aid.name}\n');

  final puzzles = GenerateCartographerPuzzles(random: SystemRandomSource(seed)).call(GenerateCartographerRequest(
    baseMap: baseMap,
    level: level,
    profile: CartographerProfile.defaults(),
    language: NameLanguage.fr,
  ));

  for (var i = 0; i < puzzles.length; i++) {
    final puzzle = puzzles[i];
    switch (puzzle) {
      case FlashStudy(:final studySeconds, :final distractionSeconds):
        print('Étude-éclair ${i + 1} : ${studySeconds}s d\'étude, ${distractionSeconds}s de distraction');
      case DelayedRecall():
        print('Bilan (rappel différé)');
    }
    for (final q in puzzle.questions) {
      final item = baseMap.itemById(q.itemId);
      final cue = q.kind.cue.isText ? '« ${item.textFor(q.kind.cue, puzzle.language)} »' : q.kind.cue.name;
      final expected = q.kind.answer.isText ? item.textFor(q.kind.answer, puzzle.language) : 'position de ${item.names.fr}';
      final aid = q.choices.isNotEmpty
          ? '  choix : ${q.choices.join(' / ')}'
          : (q.aid == RecallAid.firstLetter && q.kind.answer.isText ? '  indice : ${HintBuilder.firstLetter(expected)}' : '');
      print('  ${q.kind.cue.name} -> ${q.kind.answer.name}  [$cue]  attendu : $expected$aid');
    }
    print('');
  }
}
