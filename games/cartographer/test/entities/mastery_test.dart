import 'dart:convert';

import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

const _kind = LinkKind(Facet.name, Facet.position);
const _other = LinkKind(Facet.name, Facet.capital);

void main() {
  test('Knowledge : rang, cran suivant, connu', () {
    expect(Knowledge.rank(null), 0);
    expect(Knowledge.rank(Knowledge.toLearn), 0);
    expect(Knowledge.rank(Knowledge.solid), 2);
    expect(Knowledge.toLearn.promoted, Knowledge.shaky);
    expect(Knowledge.shaky.promoted, Knowledge.solid);
    expect(Knowledge.solid.promoted, Knowledge.solid);
    expect(Knowledge.toLearn.isKnown, isFalse);
    expect(Knowledge.shaky.isKnown, isTrue);
  });

  test('Mastery est immuable : set rend une nouvelle valeur', () {
    final a = Mastery.empty;
    final b = a.set(const MasteryKey('m', 'PRY', _kind), Knowledge.shaky);
    expect(a.isEmpty, isTrue);
    expect(b.of('m', 'PRY', _kind), Knowledge.shaky);
    expect(b.of('m', 'PRY', _other), isNull);
    expect(() => (b.states as Map).clear(), throwsUnsupportedError);
  });

  test("réinitialiser une Carte de base n'efface pas les autres", () {
    final m = Mastery({
      const MasteryKey('a', 'X', _kind): Knowledge.solid,
      const MasteryKey('b', 'X', _kind): Knowledge.shaky,
    }).withoutBaseMap('a');
    expect(m.of('a', 'X', _kind), isNull);
    expect(m.of('b', 'X', _kind), Knowledge.shaky);
  });

  group('MasteryCodec', () {
    final mastery = Mastery({
      const MasteryKey('south_america', 'PRY', _kind): Knowledge.shaky,
      const MasteryKey('south_america', 'ARG', _other): Knowledge.solid,
      const MasteryKey('africa', 'KEN', _kind): Knowledge.toLearn,
    });

    test("aller-retour via JSON texte", () {
      final restored = MasteryCodec.fromJson(jsonDecode(jsonEncode(mastery.toJson())) as Map<String, dynamic>);
      expect(restored.states, mastery.states);
    });

    test("le JSON est trié : le même état donne toujours le même texte", () {
      final reversed = Mastery({for (final e in mastery.states.entries.toList().reversed) e.key: e.value});
      expect(jsonEncode(reversed.toJson()), jsonEncode(mastery.toJson()));
    });

    test('une version inconnue est refusée', () {
      expect(() => MasteryCodec.fromJson({'version': 99, 'links': <Object>[]}), throwsFormatException);
    });

    test("la Maîtrise vide s'encode et se relit", () {
      expect(MasteryCodec.fromJson(Mastery.empty.toJson()).isEmpty, isTrue);
    });
  });
}
