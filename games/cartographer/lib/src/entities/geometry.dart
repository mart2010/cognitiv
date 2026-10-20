import 'geo_point.dart';

/// Le type de Géométrie d'un Élément : un Polygone (pays, mers, parcs), un Point (villes) ou
/// une Ligne (fleuves) (`games/cartographer/CONTEXT.md`).
enum GeometryKind { area, point, line }

/// La forme spatiale d'un Élément sur la Scène. Value Object immuable ; la Catégorie de
/// l'Élément impose son type.
sealed class Geometry {
  const Geometry();

  GeometryKind get kind;

  /// Où ancrer l'étiquette de l'Élément sur la Scène.
  GeoPoint get anchor;
}

/// Un ou plusieurs polygones (un pays et ses îles), chacun avec ses trous éventuels.
final class AreaGeometry extends Geometry {
  final List<Polygon> polygons;
  final GeoPoint labelAnchor;

  AreaGeometry({required List<Polygon> polygons, required this.labelAnchor}) : polygons = List.unmodifiable(polygons);

  @override
  GeometryKind get kind => GeometryKind.area;

  @override
  GeoPoint get anchor => labelAnchor;
}

final class PointGeometry extends Geometry {
  final GeoPoint position;
  const PointGeometry(this.position);

  @override
  GeometryKind get kind => GeometryKind.point;

  @override
  GeoPoint get anchor => position;
}

/// Une ou plusieurs lignes ouvertes (un fleuve et ses bras).
final class LineGeometry extends Geometry {
  final List<List<GeoPoint>> lines;

  LineGeometry(List<List<GeoPoint>> lines) : lines = List.unmodifiable(lines) {
    if (lines.isEmpty || lines.any((l) => l.length < 2)) {
      throw ArgumentError('Une Ligne a au moins un tracé de deux points.');
    }
  }

  @override
  GeometryKind get kind => GeometryKind.line;

  /// Le point du milieu du tracé le plus long (en nombre de points).
  @override
  GeoPoint get anchor {
    final longest = lines.reduce((a, b) => b.length > a.length ? b : a);
    return longest[longest.length ~/ 2];
  }
}
