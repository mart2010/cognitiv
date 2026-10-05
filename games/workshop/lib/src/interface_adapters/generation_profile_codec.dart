import '../entities/generation_profile.dart';
import '../entities/rule_family.dart';

/// Traduit le Profil de génération vers une donnée sérialisable : stocké par la
/// plateforme comme donnée opaque du joueur, au même titre que l'État de reprise
/// (ADR 0008, ADR 0004).
extension GenerationProfileJsonEncoding on GenerationProfile {
  Map<String, dynamic> toJson() => {
        'activeFamilies': [for (final family in activeFamilies) family.name],
      };
}

class GenerationProfileCodec {
  static GenerationProfile fromJson(Map<String, dynamic> json) => GenerationProfile({
        for (final name in json['activeFamilies'] as List) RuleFamily.values.byName(name as String),
      });
}
