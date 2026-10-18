import 'facet.dart';
import 'link.dart';

/// Préférence du joueur pour Le cartographe : quels genres de Lien peuvent lui être posés.
/// Un seul par couple joueur/jeu, partagé par tous les Niveaux ; stocké par la plateforme
/// comme donnée opaque (patron de l'ADR 0008). Le joueur choisit ce qu'il veut travailler,
/// le jeu ne l'évalue pas.
class CartographerProfile {
  final Set<LinkKind> linkKinds;

  CartographerProfile(Set<LinkKind> linkKinds) : linkKinds = Set.unmodifiable(linkKinds) {
    if (linkKinds.isEmpty) throw ArgumentError('Un Profil doit autoriser au moins un genre de Lien.');
    final unsupported = linkKinds.where((k) => !LinkKind.supported.contains(k));
    if (unsupported.isNotEmpty) throw ArgumentError('Genre de Lien non pris en charge : $unsupported');
  }

  /// Placer et nommer les pays, nommer les capitales.
  factory CartographerProfile.defaults() => CartographerProfile({
        const LinkKind(Facet.position, Facet.name),
        const LinkKind(Facet.shape, Facet.name),
        const LinkKind(Facet.name, Facet.position),
        const LinkKind(Facet.name, Facet.capital),
        const LinkKind(Facet.capital, Facet.name),
      });
}
