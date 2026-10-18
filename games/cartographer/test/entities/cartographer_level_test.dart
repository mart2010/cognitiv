import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

void main() {
  test('10 Niveaux numérotés de 1 à 10, la difficulté ne diminue jamais', () {
    final levels = CartographerLevels.all;
    expect(levels.map((l) => l.number), List.generate(10, (i) => i + 1));
    for (var i = 1; i < levels.length; i++) {
      expect(levels[i].itemCount, greaterThanOrEqualTo(levels[i - 1].itemCount));
      expect(levels[i].studySeconds, lessThanOrEqualTo(levels[i - 1].studySeconds));
      expect(levels[i].distractionSeconds, greaterThanOrEqualTo(levels[i - 1].distractionSeconds));
    }
  });

  test("l'aide s'allège avec le Niveau : choix, puis première lettre, puis saisie libre", () {
    final aids = CartographerLevels.all.map((l) => l.aid).toList();
    final order = [RecallAid.choices, RecallAid.firstLetter, RecallAid.free];
    var rank = 0;
    for (final aid in aids) {
      final r = order.indexOf(aid);
      expect(r, greaterThanOrEqualTo(rank));
      rank = r;
    }
  });

  test('un Niveau plus difficile rapporte plus de points par question', () {
    expect(CartographerLevels.byNumber(5).pointsPerQuestion, 50);
  });

  test('Niveau inconnu : erreur', () {
    expect(() => CartographerLevels.byNumber(11), throwsArgumentError);
  });
}
