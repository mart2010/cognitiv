import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:flutter/painting.dart';

/// Affecte à chaque Élément l'indice d'une teinte, de sorte que deux voisins n'en aient
/// jamais la même : coloriage glouton du graphe de voisinage, en commençant par les Éléments
/// les plus connectés (le Brésil d'abord). Déterministe. Avec les voisinages réels d'un
/// continent, 5 teintes suffisent largement (le théorème des quatre couleurs en promet 4
/// pour une carte plane ; le glouton n'atteint pas toujours ce minimum).
Map<String, int> tintIndices(cartographer.BaseMap baseMap, {int tintCount = 5}) {
  final items = [...baseMap.items]
    ..sort((a, b) {
      final byDegree = b.neighbors.length.compareTo(a.neighbors.length);
      return byDegree != 0 ? byDegree : a.id.compareTo(b.id);
    });
  final result = <String, int>{};
  for (final item in items) {
    final used = {for (final id in item.neighbors) if (result.containsKey(id)) result[id]!};
    final free = List.generate(tintCount, (i) => i).where((i) => !used.contains(i));
    if (free.isEmpty) {
      throw StateError('Plus de teinte libre pour ${item.id} (${item.neighbors.length} voisins) : augmenter tintCount.');
    }
    result[item.id] = free.first;
  }
  return result;
}

/// Teintes très douces à partir du gris neutre du thème : on en garde la luminosité et on
/// ne fait varier que la teinte, avec une saturation faible, pour distinguer les frontières
/// sans que la carte devienne un coloriage. Marche en thème clair comme sombre.
List<Color> softTints(Color neutral, {int count = 5}) {
  const hues = [210.0, 140.0, 40.0, 330.0, 270.0];
  final base = HSLColor.fromColor(neutral);
  return [
    for (var i = 0; i < count; i++) base.withHue(hues[i % hues.length]).withSaturation(0.22).toColor(),
  ];
}
