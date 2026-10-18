import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

import '../support/real_base_map.dart';

void main() {
  final map = loadSouthAmerica();
  final evaluate = EvaluateCartographerAnswer();

  RecallQuestion ask(String id, Facet cue, Facet answer) =>
      RecallQuestion(itemId: id, kind: LinkKind(cue, answer), aid: RecallAid.free);

  group('Nommer', () {
    test("la capitale s'accepte sans accent, dans les deux langues", () {
      final q = ask('PRY', Facet.name, Facet.capital);
      expect(evaluate(map, q, const TypedAnswer('Asuncion')).verdict, AnswerVerdict.exact);
      expect(evaluate(map, q, const TypedAnswer('asunción')).verdict, AnswerVerdict.exact);
      expect(evaluate(map, q, const TypedAnswer('Montevideo')).verdict, AnswerVerdict.wrong);
    });

    test('la Bolivie accepte ses deux capitales', () {
      final q = ask('BOL', Facet.name, Facet.capital);
      expect(evaluate(map, q, const TypedAnswer('La Paz')).isCorrect, isTrue);
      expect(evaluate(map, q, const TypedAnswer('Sucre')).isCorrect, isTrue);
    });

    test('le Chili accepte aussi sa capitale alternative', () {
      final q = ask('CHL', Facet.name, Facet.capital);
      expect(evaluate(map, q, const TypedAnswer('Santiago')).isCorrect, isTrue);
      expect(evaluate(map, q, const TypedAnswer('Valparaiso')).isCorrect, isTrue);
    });

    test('une faute de frappe est tolérée, un autre pays ne l\'est jamais', () {
      final q = ask('GUY', Facet.position, Facet.name);
      expect(evaluate(map, q, const TypedAnswer('Guyna')).isCorrect, isTrue);
      // « Guyane » est une faute à une lettre de « Guyana », mais c'est le nom d'un autre Élément.
      expect(evaluate(map, q, const TypedAnswer('Guyane')).verdict, AnswerVerdict.wrong);
      expect(evaluate(map, q, const TypedAnswer('Guyana')).isCorrect, isTrue);
    });

    test('la Guyane se nomme aussi Guyane française', () {
      final q = ask('GUF', Facet.shape, Facet.name);
      expect(evaluate(map, q, const TypedAnswer('Guyane')).isCorrect, isTrue);
      expect(evaluate(map, q, const TypedAnswer('French Guiana')).isCorrect, isTrue);
    });
  });

  group('Placer', () {
    final q = ask('PRY', Facet.name, Facet.position);

    test("toucher l'Élément est exact", () {
      expect(evaluate(map, q, PlacedAnswer(map.itemById('PRY').anchor)).verdict, AnswerVerdict.exact);
    });

    test('toucher un autre Élément éloigné est faux', () {
      expect(evaluate(map, q, PlacedAnswer(map.itemById('PER').anchor)).verdict, AnswerVerdict.wrong);
    });
  });

  test('une réponse du mauvais Geste est une erreur de l\'app', () {
    expect(() => evaluate(map, ask('PRY', Facet.name, Facet.position), const TypedAnswer('Paraguay')), throwsArgumentError);
    expect(() => evaluate(map, ask('PRY', Facet.name, Facet.capital), const PlacedAnswer(GeoPoint(0, 0))), throwsArgumentError);
  });
}
