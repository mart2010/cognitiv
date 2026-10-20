import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:flutter/painting.dart';

/// Les couleurs d'un verdict, les mêmes pour une question seule et pour un Plateau.
Color verdictColor(cartographer.AnswerVerdict verdict) => switch (verdict) {
  cartographer.AnswerVerdict.exact => const Color(0xFF4CAF7A),
  cartographer.AnswerVerdict.close => const Color(0xFFE8B84A),
  cartographer.AnswerVerdict.wrong => const Color(0xFFD9695F),
};

/// Comment nommer ce qu'on étudie : « pays », « ville », « lieu » (au pluriel : pays, villes,
/// lieux) selon les Catégories des Éléments.
({String one, String many}) placeNoun(cartographer.BaseMap baseMap, Iterable<String> itemIds) {
  final categories = {for (final id in itemIds) baseMap.itemById(id).category};
  if (categories.length == 1 && categories.single == cartographer.Category.countries) return (one: 'pays', many: 'pays');
  if (categories.length == 1 && categories.single == cartographer.Category.cities) return (one: 'ville', many: 'villes');
  return (one: 'lieu', many: 'lieux');
}
