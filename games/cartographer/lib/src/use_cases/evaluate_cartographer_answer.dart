import '../domain_services/placement_judge.dart';
import '../domain_services/text_matcher.dart';
import '../entities/base_map.dart';
import '../entities/cartographer_answer.dart';
import '../entities/facet.dart';
import '../entities/link.dart';
import '../entities/recall_question.dart';

/// Verdict de `EvaluateCartographerAnswer`.
class AnswerEvaluation {
  final AnswerVerdict verdict;
  const AnswerEvaluation(this.verdict);

  bool get isCorrect => verdict == AnswerVerdict.exact;
}

/// Cas d'usage « évaluer une réponse à une énigme » du contrat jeu/plateforme (ADR 0004).
/// Fonction pure et sans état. Lance une `ArgumentError` si la réponse n'est pas du Geste
/// de la question (un texte pour un Placer, ou l'inverse) : c'est une erreur de l'app.
class EvaluateCartographerAnswer {
  AnswerEvaluation call(BaseMap baseMap, RecallQuestion question, CartographerAnswer answer) {
    final item = baseMap.itemById(question.itemId);
    switch ((question.kind.gesture, answer)) {
      case (Gesture.place, PlacedAnswer(point: final point)):
        return AnswerEvaluation(PlacementJudge(baseMap.frame).judge(item, point));
      case (Gesture.naming, TypedAnswer(text: final text)):
        final Facet facet = question.kind.answer;
        final confusable = {
          for (final other in baseMap.items)
            if (other.id != item.id && baseMap.hasFacet(other, facet)) ...baseMap.acceptedTexts(other, facet),
        };
        final matches = TextMatcher.matches(text, baseMap.acceptedTexts(item, facet), confusable: confusable);
        return AnswerEvaluation(matches ? AnswerVerdict.exact : AnswerVerdict.wrong);
      default:
        throw ArgumentError('La réponse ${answer.runtimeType} ne convient pas au Geste ${question.kind.gesture.name}.');
    }
  }
}
