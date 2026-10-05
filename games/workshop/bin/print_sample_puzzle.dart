// Script de démo (Frameworks & Drivers, pas Interface Adapter) : génère une vraie
// Énigme avec le générateur réel et `SystemRandomSource`, et l'affiche dans le terminal.
// Usage : dart run bin/print_sample_puzzle.dart [graine]
import 'package:workshop/workshop.dart';

void main(List<String> args) {
  final seed = args.isNotEmpty ? int.parse(args.first) : DateTime.now().millisecondsSinceEpoch;
  print('Graine : $seed\n');

  final generator = GenerateWorkshopPuzzle(
    catalog: const RuleCatalog(),
    random: SystemRandomSource(seed),
  );

  GenerationResult result = const GenerationFailed('pas encore essayé');
  var attempt = 0;
  while (result is! GenerationSucceeded && attempt < 20) {
    result = generator(GenerateWorkshopPuzzleRequest(
      rowCount: 3,
      columnCount: 3,
      ruleCount: 1,
      exampleCount: 2,
      profile: GenerationProfile.intuitiveDefaults,
    ));
    attempt++;
  }

  switch (result) {
    case GenerationFailed(reason: final reason):
      print('Échec après $attempt tentative(s) : $reason');
    case GenerationSucceeded(puzzle: final puzzle):
      print('Énigme générée ($attempt tentative(s)) :\n');
      for (var i = 0; i < puzzle.examples.length; i++) {
        print('Exemple ${i + 1} :');
        _printSideBySide(puzzle.examples[i].input, puzzle.examples[i].output);
        print('');
      }
      print('Question :');
      print(_render(puzzle.question));
      print('');
      for (var i = 0; i < puzzle.answerChoices.length; i++) {
        final marker = i == puzzle.correctAnswerIndex ? ' <- bonne réponse' : '';
        print('Choix ${i + 1}$marker :');
        print(_render(puzzle.answerChoices[i]));
        print('');
      }
      print('Règle(s) appliquée(s) (indice) : ${puzzle.appliedRules.map((r) => r.family.name).join(', ')}');
  }
}

void _printSideBySide(Matrix input, Matrix output) {
  final left = _render(input).split('\n');
  final right = _render(output).split('\n');
  for (var i = 0; i < left.length; i++) {
    final arrow = i == left.length ~/ 2 ? ' -> ' : '    ';
    print('${left[i]}$arrow${right[i]}');
  }
}

String _render(Matrix matrix) {
  final lines = <String>[];
  for (var r = 0; r < matrix.rowCount; r++) {
    final cells = [for (var c = 0; c < matrix.columnCount; c++) _renderCell(matrix.cellAt(r, c))];
    lines.add(cells.join(' '));
  }
  return lines.join('\n');
}

String _renderCell(Cell cell) {
  if (cell.isEmpty) {
    return cell.emptyRole == EmptyCellRole.active ? '..' : '··';
  }
  final shapeLetter = switch (cell.shape) {
    Shape.round => 'O',
    Shape.square => 'S',
    Shape.cross => 'X',
    Shape.empty => '?',
  };
  final colorLetter = cell.color!.name[0].toUpperCase();
  return '$shapeLetter$colorLetter';
}
