/// Les clés d'Attribut que le jeu connaît.
abstract final class AttributeKey {
  /// Nombre : habitants (d'un pays, ou d'une ville dans son agglomération).
  static const population = 'population';

  /// Booléen : territoire distinct de l'État dont il dépend (la Guyane).
  static const territory = 'territory';

  /// Texte : code de l'État auquel l'Élément appartient (FRA pour la Guyane).
  static const state = 'state';

  /// Texte : clé de l'image du drapeau, absente tant que les données n'en portent pas.
  static const flag = 'flag';

  /// Booléen : la ville est une capitale d'État.
  static const capital = 'capital';

  /// Texte : `primary` ou `alt` (la Bolivie a deux capitales principales ; Valparaíso est
  /// une capitale alternative du Chili).
  static const capitalRole = 'capitalRole';

  /// Nombre : rang de notoriété dans la Carte de base (1 = la plus connue).
  static const rank = 'rank';
}

/// Les données typées attachées à un Élément (`games/cartographer/CONTEXT.md`). Une valeur est
/// un texte, un nombre, un booléen ou une liste de textes. Le nom n'en fait pas partie : il
/// est bilingue et porté par l'Élément.
class Attributes {
  final Map<String, Object> values;

  Attributes([Map<String, Object> values = const {}]) : values = Map.unmodifiable(values) {
    for (final entry in values.entries) {
      final value = entry.value;
      final valid = value is String ||
          value is num ||
          value is bool ||
          (value is List && value.every((v) => v is String));
      if (!valid) throw ArgumentError('Attribut ${entry.key} : type non pris en charge (${value.runtimeType}).');
    }
  }

  static final empty = Attributes();

  bool has(String key) => values.containsKey(key);

  String? text(String key) => _typed<String>(key);

  int? integer(String key) => _typed<num>(key)?.round();

  bool flag(String key) => _typed<bool>(key) ?? false;

  List<String> list(String key) => _typed<List>(key)?.cast<String>() ?? const [];

  T? _typed<T>(String key) {
    final value = values[key];
    if (value == null) return null;
    if (value is! T) throw StateError('Attribut $key : ${value.runtimeType}, attendu $T.');
    return value as T;
  }
}
