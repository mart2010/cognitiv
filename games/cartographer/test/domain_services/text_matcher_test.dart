import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

void main() {
  group('normalize', () {
    test('ignore casse, accents et ponctuation', () {
      expect(TextMatcher.normalize('  Asunción '), 'asuncion');
      expect(TextMatcher.normalize('São Tomé-et-Príncipe'), 'saotomeetprincipe');
      expect(TextMatcher.normalize("Côte d'Ivoire"), 'cotedivoire');
    });
  });

  group('matches', () {
    final expected = {'Colombia', 'Colombie'};

    test('accepte la réponse exacte dans les deux langues, sans accent ni casse', () {
      expect(TextMatcher.matches('colombie', expected), isTrue);
      expect(TextMatcher.matches('COLOMBIA', expected), isTrue);
    });

    test('tolère une faute de frappe sur un mot assez long', () {
      expect(TextMatcher.matches('Colombai', expected), isFalse); // transposition = 2 fautes
      expect(TextMatcher.matches('Colomia', expected), isTrue);
    });

    test('ne tolère aucune faute sur un mot court', () {
      expect(TextMatcher.matches('Per', {'Peru'}), isFalse);
      expect(TextMatcher.matches('Pero', {'Peru'}), isFalse);
    });

    test('refuse un texte vide', () {
      expect(TextMatcher.matches('  ', expected), isFalse);
    });

    test("n'accepte jamais comme faute le nom exact d'une autre réponse plausible", () {
      expect(TextMatcher.matches('Guyane', {'Guyana'}), isTrue); // sans contexte, c'est une faute
      expect(TextMatcher.matches('Guyane', {'Guyana'}, confusable: {'Guyane', 'French Guiana'}), isFalse);
    });
  });

  test('tolerance : 0 sous 5 lettres, 1 dès 5, 2 dès 9', () {
    expect(TextMatcher.tolerance('peru'), 0);
    expect(TextMatcher.tolerance('chile'), 1);
    expect(TextMatcher.tolerance('venezuela'), 2);
  });
}
