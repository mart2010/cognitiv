import '../entities/cartographer_puzzle.dart';
import '../entities/facet.dart';
import '../entities/link.dart';
import '../entities/name_language.dart';
import '../entities/recall_aid.dart';
import '../entities/recall_question.dart';

/// Traduit une Énigme vers une donnée sérialisable : une Partie stocke ses énigmes
/// générées telles quelles, pas une graine (ADR 0002). Les Éléments ne sont référencés que
/// par identifiant : relire une Énigme demande la même Carte de base (ADR 0001).
extension RecallQuestionJsonEncoding on RecallQuestion {
  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'cue': kind.cue.name,
        'answer': kind.answer.name,
        'aid': aid.name,
        'choices': choices,
      };
}

extension CartographerPuzzleJsonEncoding on CartographerPuzzle {
  Map<String, dynamic> toJson() => switch (this) {
        FlashStudy(:final language, :final questions, :final studySeconds, :final distractionSeconds) => {
            'type': 'flashStudy',
            'language': language.name,
            'studySeconds': studySeconds,
            'distractionSeconds': distractionSeconds,
            'questions': [for (final q in questions) q.toJson()],
          },
        DelayedRecall(:final language, :final questions) => {
            'type': 'delayedRecall',
            'language': language.name,
            'questions': [for (final q in questions) q.toJson()],
          },
      };
}

class CartographerPuzzleCodec {
  static RecallQuestion questionFromJson(Map<String, dynamic> json) => RecallQuestion(
        itemId: json['itemId'] as String,
        kind: LinkKind(Facet.values.byName(json['cue'] as String), Facet.values.byName(json['answer'] as String)),
        aid: RecallAid.values.byName(json['aid'] as String),
        choices: [for (final c in json['choices'] as List) c as String],
      );

  static CartographerPuzzle fromJson(Map<String, dynamic> json) {
    final language = NameLanguage.values.byName(json['language'] as String);
    final questions = [
      for (final q in json['questions'] as List) questionFromJson(q as Map<String, dynamic>),
    ];
    return switch (json['type']) {
      'flashStudy' => FlashStudy(
          language: language,
          questions: questions,
          studySeconds: json['studySeconds'] as int,
          distractionSeconds: json['distractionSeconds'] as int,
        ),
      'delayedRecall' => DelayedRecall(language: language, questions: questions),
      final other => throw FormatException('Type d\'Énigme inconnu : $other'),
    };
  }
}
