import 'dart:ui';

/// Un libellé à poser sur la carte : où est l'Élément, la place qu'il occupe à l'écran et la taille
/// du texte.
class LabelRequest {
  final Offset anchor;
  final Rect bounds;
  final Size size;
  const LabelRequest({required this.anchor, required this.bounds, required this.size});
}

/// Le résultat pour un libellé : son rectangle, et s'il a dû quitter son pays (alors on trace un
/// trait entre le point d'ancrage et le texte).
class PlacedLabel {
  final Rect rect;
  final bool displaced;
  const PlacedLabel(this.rect, {required this.displaced});
}

/// Place des libellés pour qu'ils ne se chevauchent pas et restent dans le cadre. Les grands pays
/// gardent le leur au centre quand il y tient ; un pays trop petit pour son texte le reçoit à côté
/// (au-dessus, en dessous, à droite, à gauche, puis en diagonale, de plus en plus loin) pour que sa
/// forme reste visible. Le résultat est dans l'ordre des demandes. S'il n'y a vraiment plus de
/// place, un libellé est posé à l'endroit le moins mauvais : on ne plante jamais.
List<PlacedLabel> placeLabels(Size canvas, List<LabelRequest> requests, {double gap = 6, double margin = 2}) {
  final order = [for (var i = 0; i < requests.length; i++) i]
    ..sort((a, b) {
      final byArea = _area(requests[b].bounds).compareTo(_area(requests[a].bounds));
      return byArea != 0 ? byArea : a.compareTo(b);
    });
  final placed = <Rect>[];
  final result = List<PlacedLabel?>.filled(requests.length, null);

  for (final index in order) {
    final request = requests[index];
    final size = request.size;
    final fitsInside = size.width <= request.bounds.width && size.height <= request.bounds.height;
    final candidates = <Rect>[
      if (fitsInside) _clamp(Rect.fromCenter(center: request.anchor, width: size.width, height: size.height), canvas),
      for (var ring = 0; ring < 8; ring++) ..._ring(request, gap + ring * (size.height * 0.9), canvas),
    ];
    Rect? chosen;
    for (final candidate in candidates) {
      if (!placed.any((r) => r.inflate(margin).overlaps(candidate))) {
        chosen = candidate;
        break;
      }
    }
    chosen ??= _leastOverlapping(candidates, placed);
    placed.add(chosen);
    final centered = fitsInside && (chosen.center - request.anchor).distance < 1.0;
    result[index] = PlacedLabel(chosen, displaced: !centered && !request.bounds.contains(chosen.center));
  }
  return [for (final r in result) r!];
}

double _area(Rect r) => r.width * r.height;

/// Huit positions autour du pays, à `distance` de son rectangle englobant.
Iterable<Rect> _ring(LabelRequest request, double distance, Size canvas) sync* {
  final b = request.bounds;
  final a = request.anchor;
  final w = request.size.width;
  final h = request.size.height;
  final centers = [
    Offset(a.dx, b.top - distance - h / 2), // au-dessus
    Offset(a.dx, b.bottom + distance + h / 2), // en dessous
    Offset(b.right + distance + w / 2, a.dy), // à droite
    Offset(b.left - distance - w / 2, a.dy), // à gauche
    Offset(b.right + distance + w / 2, b.top - distance - h / 2), // en haut à droite
    Offset(b.left - distance - w / 2, b.top - distance - h / 2), // en haut à gauche
    Offset(b.right + distance + w / 2, b.bottom + distance + h / 2), // en bas à droite
    Offset(b.left - distance - w / 2, b.bottom + distance + h / 2), // en bas à gauche
  ];
  for (final c in centers) {
    yield _clamp(Rect.fromCenter(center: c, width: w, height: h), canvas);
  }
}

/// Ramène le rectangle dans le cadre sans le déformer (ou le plus près possible s'il est plus
/// grand que le cadre).
Rect _clamp(Rect r, Size canvas) {
  final dx = r.left < 0 ? -r.left : (r.right > canvas.width ? canvas.width - r.right : 0.0);
  final dy = r.top < 0 ? -r.top : (r.bottom > canvas.height ? canvas.height - r.bottom : 0.0);
  return r.shift(Offset(dx, dy));
}

Rect _leastOverlapping(List<Rect> candidates, List<Rect> placed) {
  double overlapArea(Rect c) => placed.fold(0.0, (sum, r) {
    final i = r.intersect(c);
    return sum + (i.width > 0 && i.height > 0 ? i.width * i.height : 0);
  });
  return candidates.reduce((best, c) => overlapArea(c) < overlapArea(best) ? c : best);
}
