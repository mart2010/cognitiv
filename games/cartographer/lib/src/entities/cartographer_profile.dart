import 'base_map.dart';
import 'category.dart';
import 'facet.dart';
import 'link.dart';

/// Préférence du joueur pour Le cartographe : quelles Catégories il active (elles décident des
/// Éléments posés) et quels genres de Lien peuvent lui être posés. Un seul par couple
/// joueur/jeu, partagé par tous les Niveaux ; stocké par la plateforme comme donnée opaque
/// (patron de l'ADR 0008). Le joueur choisit ce qu'il veut travailler, le jeu ne l'évalue pas.
///
/// Transitoire : les genres de Lien disparaîtront du Profil quand les Épreuves les décideront
/// (`docs/PLAN.md`, « Refonte Épreuves et Catégories »).
class CartographerProfile {
  final Set<LinkKind> linkKinds;
  final Set<Category> categories;

  CartographerProfile(Set<LinkKind> linkKinds, {Set<Category>? categories})
      : linkKinds = Set.unmodifiable(linkKinds),
        categories = Set.unmodifiable(categories ?? {Category.countries}) {
    if (linkKinds.isEmpty) throw ArgumentError('Un Profil doit autoriser au moins un genre de Lien.');
    final unsupported = linkKinds.where((k) => !LinkKind.supported.contains(k));
    if (unsupported.isNotEmpty) throw ArgumentError('Genre de Lien non pris en charge : $unsupported');
    if (this.categories.isEmpty) throw ArgumentError('Un Profil doit activer au moins une Catégorie.');
  }

  CartographerProfile copyWith({Set<LinkKind>? linkKinds, Set<Category>? categories}) =>
      CartographerProfile(linkKinds ?? this.linkKinds, categories: categories ?? this.categories);

  /// Les genres de Lien du Profil qui s'appliquent à au moins un Élément des Catégories activées.
  Set<LinkKind> usableKinds(BaseMap baseMap) => {
        for (final kind in linkKinds)
          if (baseMap.items.any((item) => categories.contains(item.category) && kind.appliesTo(baseMap, item))) kind,
      };

  /// Y a-t-il de quoi poser au moins une question ? Faux si les genres de Lien choisis ne
  /// conviennent à aucune Catégorie activée (ex. les villes avec seulement des capitales).
  bool canAsk(BaseMap baseMap) => usableKinds(baseMap).isNotEmpty;

  /// Placer et nommer les pays, nommer les capitales.
  factory CartographerProfile.defaults() => CartographerProfile({
        const LinkKind(Facet.position, Facet.name),
        const LinkKind(Facet.shape, Facet.name),
        const LinkKind(Facet.name, Facet.position),
        const LinkKind(Facet.name, Facet.capital),
        const LinkKind(Facet.capital, Facet.name),
      });
}
