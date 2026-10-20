import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

import '../support/real_base_map.dart';

void main() {
  final map = loadSouthAmerica();
  const positionOfName = LinkKind(Facet.position, Facet.name);
  const nameOfPosition = LinkKind(Facet.name, Facet.position);
  const capitalOfName = LinkKind(Facet.name, Facet.capital);

  test('le Profil par défaut peut poser des questions sur les pays', () {
    expect(CartographerProfile.defaults().canAsk(map), isTrue);
  });

  test('les villes se posent avec placer et nommer, pas avec contour ni capitale', () {
    final profile = CartographerProfile.defaults().copyWith(categories: {Category.cities});
    expect(profile.usableKinds(map), {positionOfName, nameOfPosition});
  });

  test("des villes avec seulement des capitales : rien à poser, le Profil le dit", () {
    final profile = CartographerProfile({capitalOfName}, categories: {Category.cities});
    expect(profile.canAsk(map), isFalse);
    expect(profile.copyWith(categories: {Category.countries}).canAsk(map), isTrue);
  });

  test('copyWith garde ce qu\'on ne change pas', () {
    final profile = CartographerProfile.defaults().copyWith(categories: {Category.countries, Category.cities});
    expect(profile.linkKinds, CartographerProfile.defaults().linkKinds);
    expect(profile.copyWith(linkKinds: {positionOfName}).categories, {Category.countries, Category.cities});
  });
}
