/// Un point en degrés (longitude, latitude).
class GeoPoint {
  final double lon;
  final double lat;
  const GeoPoint(this.lon, this.lat);

  @override
  bool operator ==(Object other) => other is GeoPoint && other.lon == lon && other.lat == lat;

  @override
  int get hashCode => Object.hash(lon, lat);

  @override
  String toString() => 'GeoPoint($lon, $lat)';
}

/// Cadre d'une Carte de base, en degrés.
class GeoFrame {
  final double west;
  final double south;
  final double east;
  final double north;
  const GeoFrame({required this.west, required this.south, required this.east, required this.north});

  double get width => east - west;
  double get height => north - south;
}

/// Un anneau fermé de points (premier point = dernier point).
typedef Ring = List<GeoPoint>;

/// Un polygone : l'anneau extérieur, puis les trous éventuels.
typedef Polygon = List<Ring>;
