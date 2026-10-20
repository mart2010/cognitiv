import '../entities/attributes.dart';
import '../entities/base_map.dart';
import '../entities/category.dart';
import '../entities/geo_point.dart';
import '../entities/geometry.dart';
import '../entities/item.dart';
import '../entities/name_language.dart';

/// Lit le JSON d'une Carte de base produit par `tool/build_base_map.dart` (schéma 2). L'app
/// lit le fichier (asset) et passe la donnée décodée ; le domaine ne touche à aucun fichier
/// (ADR 0005).
class BaseMapCodec {
  static const supportedSchemaVersion = 2;

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
        category: Category.byId(json['category'] as String),
        names: _names(json['names'] as Map<String, dynamic>),
        geometry: _geometry(json['geometry'] as Map<String, dynamic>),
        attributes: Attributes({
          for (final entry in (json['attributes'] as Map<String, dynamic>).entries)
            entry.key: entry.value is List ? (entry.value as List).cast<String>() : entry.value as Object,
        }),
        neighbors: {for (final id in (json['neighbors'] as List? ?? const [])) id as String},
        containedIn: json['containedIn'] as String?,
      );

  static Geometry _geometry(Map<String, dynamic> json) => switch (json['type']) {
        'area' => AreaGeometry(
            labelAnchor: _point(json['anchor'] as List),
            polygons: [
              for (final polygon in json['polygons'] as List)
                [
                  for (final ring in polygon as List) [for (final p in ring as List) _point(p as List)],
                ],
            ],
          ),
        'point' => PointGeometry(_point(json['position'] as List)),
        'line' => LineGeometry([
            for (final line in json['lines'] as List) [for (final p in line as List) _point(p as List)],
          ]),
        final other => throw FormatException('Géométrie inconnue : $other'),
      };

  static LocalizedText _names(Map<String, dynamic> json) =>
      LocalizedText(en: json['en'] as String, fr: json['fr'] as String);

  static GeoPoint _point(List coordinates) => GeoPoint((coordinates[0] as num).toDouble(), (coordinates[1] as num).toDouble());
}
