import '../entities/base_map.dart';
import '../entities/geo_point.dart';
import '../entities/item.dart';
import '../entities/name_language.dart';

/// Lit le JSON d'une Carte de base produit par `tool/build_base_map.dart` (schéma 1).
/// L'app lit le fichier (asset) et passe la donnée décodée ; le domaine ne touche à aucun
/// fichier (ADR 0005).
class BaseMapCodec {
  static const supportedSchemaVersion = 1;

  static BaseMap fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version != supportedSchemaVersion) {
      throw FormatException('Schéma de Carte de base non pris en charge : $version');
    }
    final base = json['baseMap'] as Map<String, dynamic>;
    final frame = (base['frame'] as List).cast<num>();
    return BaseMap(
      id: base['id'] as String,
      frame: GeoFrame(
        west: frame[0].toDouble(),
        south: frame[1].toDouble(),
        east: frame[2].toDouble(),
        north: frame[3].toDouble(),
      ),
      items: [for (final item in json['items'] as List) _item(item as Map<String, dynamic>)],
    );
  }

  static Item _item(Map<String, dynamic> json) => Item(
        id: json['id'] as String,
        kind: ItemKind.values.byName(json['kind'] as String),
        belongsTo: json['belongsTo'] as String,
        names: _names(json['names'] as Map<String, dynamic>),
        capitals: [for (final c in json['capitals'] as List) _capital(c as Map<String, dynamic>)],
        anchor: _point(json['anchor'] as List),
        outline: [
          for (final polygon in json['outline'] as List)
            [
              for (final ring in polygon as List) [for (final p in ring as List) _point(p as List)],
            ],
        ],
        neighbors: {for (final id in json['neighbors'] as List) id as String},
        population: json['population'] as int?,
        flagAsset: json['flag'] as String?,
      );

  static Capital _capital(Map<String, dynamic> json) => Capital(
        names: _names(json['names'] as Map<String, dynamic>),
        position: _point(json['position'] as List),
        role: CapitalRole.values.byName(json['role'] as String),
        population: json['population'] as int?,
      );

  static LocalizedText _names(Map<String, dynamic> json) =>
      LocalizedText(en: json['en'] as String, fr: json['fr'] as String);

  static GeoPoint _point(List coordinates) => GeoPoint((coordinates[0] as num).toDouble(), (coordinates[1] as num).toDouble());
}
