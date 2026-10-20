import '../entities/cartographer_profile.dart';
import '../entities/category.dart';
import '../entities/facet.dart';
import '../entities/link.dart';

/// Traduit le Profil vers une donnée opaque que la plateforme stocke sans la lire
/// (patron de l'ADR 0008).
extension CartographerProfileJsonEncoding on CartographerProfile {
  Map<String, dynamic> toJson() => {
        'linkKinds': [
          for (final kind in LinkKind.supported)
            if (linkKinds.contains(kind)) {'cue': kind.cue.name, 'answer': kind.answer.name},
        ],
        'categories': [
          for (final category in Category.known)
            if (categories.contains(category)) category.id,
        ],
      };
}

class CartographerProfileCodec {
  /// Un Profil enregistré avant les Catégories n'a pas la clé `categories` : il active les pays.
  static CartographerProfile fromJson(Map<String, dynamic> json) => CartographerProfile(
        {
          for (final kind in json['linkKinds'] as List)
            LinkKind(
              Facet.values.byName((kind as Map)['cue'] as String),
              Facet.values.byName(kind['answer'] as String),
            ),
        },
        categories: json['categories'] == null
            ? null
            : {for (final id in json['categories'] as List) Category.byId(id as String)},
      );
}
