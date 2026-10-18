import 'geo_point.dart';

/// Réponse du joueur à une question de Rappel, selon le Geste.
sealed class CartographerAnswer {
  const CartographerAnswer();
}

/// Placer : le point touché sur la Scène.
final class PlacedAnswer extends CartographerAnswer {
  final GeoPoint point;
  const PlacedAnswer(this.point);
}

/// Nommer : le texte saisi (ou le choix touché, quand l'aide propose des choix).
final class TypedAnswer extends CartographerAnswer {
  final String text;
  const TypedAnswer(this.text);
}

/// Verdict d'une réponse. `close` ne concerne que Placer : le point est tout près de
/// l'Élément sans être dedans.
enum AnswerVerdict {
  exact(1.0),
  close(0.5),
  wrong(0.0);

  /// Part des points accordée.
  final double credit;
  const AnswerVerdict(this.credit);
}
