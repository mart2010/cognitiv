import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

import '../support/real_base_map.dart';

const _positionOfName = LinkKind(Facet.name, Facet.position);
const _capitalOfName = LinkKind(Facet.name, Facet.capital);

void main() {
  final map = loadSouthAmerica();
  final suggest = SuggestLinkKinds();

  Mastery everything(Knowledge k, LinkKind kind) => Mastery({
    for (final item in map.items) MasteryKey(map.id, item.id, kind): k,
  });

  test('rien de connu : aucune suggestion', () {
    expect(suggest(map, CartographerProfile({_positionOfName}), Mastery.empty), isEmpty);
  });

  test('un seul Lien à apprendre suffit à ne rien proposer', () {
    final m = everything(Knowledge.solid, _positionOfName).set(
      MasteryKey(map.id, 'PRY', _positionOfName),
      Knowledge.toLearn,
    );
    expect(suggest(map, CartographerProfile({_positionOfName}), m), isEmpty);
  });

  test('tout connu (fragile ou solide) : propose les autres genres de Lien posables', () {
    final m = everything(Knowledge.shaky, _positionOfName);
    final suggestions = suggest(map, CartographerProfile({_positionOfName}), m);
    expect(suggestions, isNot(contains(_positionOfName)));
    expect(suggestions, contains(_capitalOfName));
    // Aucun drapeau dans les données : un genre de Lien avec drapeau n'est pas proposé.
    expect(suggestions.where((k) => k.cue == Facet.flag || k.answer == Facet.flag), isEmpty);
  });

  test("ne propose pas ce qui est déjà dans le Profil", () {
    final profile = CartographerProfile({_positionOfName, _capitalOfName});
    final m = Mastery({
      ...everything(Knowledge.solid, _positionOfName).states,
      ...everything(Knowledge.solid, _capitalOfName).states,
    });
    final suggestions = suggest(map, profile, m);
    expect(suggestions, isNot(contains(_positionOfName)));
    expect(suggestions, isNot(contains(_capitalOfName)));
  });
}
