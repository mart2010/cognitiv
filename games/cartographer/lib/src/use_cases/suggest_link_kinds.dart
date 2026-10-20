import '../entities/base_map.dart';
import '../entities/cartographer_profile.dart';
import '../entities/link.dart';
import '../entities/mastery.dart';

/// Quand tous les Liens du Profil sont connus (fragiles ou solides), propose d'autres genres
/// de Lien (capitales, drapeaux…). Une suggestion, jamais imposée : le joueur reste libre de
/// garder son Profil malgré ses réussites. Liste vide tant qu'il reste des Liens à apprendre.
class SuggestLinkKinds {
  List<LinkKind> call(BaseMap baseMap, CartographerProfile profile, Mastery mastery) {
    var anyLink = false;
    final pool = [for (final item in baseMap.items) if (profile.categories.contains(item.category)) item];
    for (final item in pool) {
      for (final kind in profile.linkKinds.where((k) => k.appliesTo(baseMap, item))) {
        anyLink = true;
        final knowledge = mastery.of(baseMap.id, item.id, kind);
        if (knowledge == null || !knowledge.isKnown) return const [];
      }
    }
    if (!anyLink) return const [];
    return [
      for (final kind in LinkKind.supported)
        if (!profile.linkKinds.contains(kind) && pool.any((item) => kind.appliesTo(baseMap, item))) kind,
    ];
  }
}
