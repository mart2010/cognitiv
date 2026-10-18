import '../entities/facet.dart';
import '../entities/knowledge.dart';
import '../entities/link.dart';
import '../entities/mastery.dart';

/// Traduit la Maîtrise vers une donnée opaque que la plateforme stocke dans le Profil local
/// sans la lire (ADR 0009). Triée, donc la même Maîtrise donne toujours le même JSON.
extension MasteryJsonEncoding on Mastery {
  Map<String, dynamic> toJson() {
    final entries = states.entries.toList()
      ..sort((a, b) => _sortKey(a.key).compareTo(_sortKey(b.key)));
    return {
      'version': MasteryCodec.version,
      'links': [
        for (final e in entries)
          {
            'baseMap': e.key.baseMapId,
            'item': e.key.itemId,
            'cue': e.key.kind.cue.name,
            'answer': e.key.kind.answer.name,
            'knowledge': e.value.name,
          },
      ],
    };
  }

  static String _sortKey(MasteryKey k) => '${k.baseMapId}|${k.itemId}|${k.kind.cue.name}|${k.kind.answer.name}';
}

class MasteryCodec {
  static const version = 1;

  static Mastery fromJson(Map<String, dynamic> json) {
    if (json['version'] != version) {
      throw FormatException('Version de Maîtrise non prise en charge : ${json['version']}');
    }
    return Mastery({
      for (final link in json['links'] as List)
        MasteryKey(
          (link as Map)['baseMap'] as String,
          link['item'] as String,
          LinkKind(Facet.values.byName(link['cue'] as String), Facet.values.byName(link['answer'] as String)),
        ): Knowledge.values.byName(link['knowledge'] as String),
    });
  }
}
