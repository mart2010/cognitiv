import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';

import 'country_tints.dart';
import 'map_projection.dart';

/// La Scène du Cartographe : les contours des Éléments d'une Carte de base, où l'on touche
/// pour placer. Se pince pour zoomer (les petits pays, Guyane ou Suriname, se touchent mal
/// à l'échelle du continent). Ne connaît ni les questions ni le score : l'écran qui
/// l'utilise colore les Éléments (`fills`), pose les étiquettes (`labels`) et reçoit le
/// point touché en degrés.
class CartographerMapView extends StatefulWidget {
  final cartographer.BaseMap baseMap;

  /// Couleur de remplissage par identifiant d'Élément ; les autres restent neutres.
  final Map<String, Color> fills;

  /// Identifiants des Éléments dont on écrit le nom sur la carte.
  final Set<String> labels;

  /// Texte à écrire à la place du nom, par identifiant (ex. le nom et la capitale, sur deux lignes).
  final Map<String, String> labelTexts;

  /// Met en retrait tous les Éléments qui n'ont pas de couleur dans `fills`, pour concentrer le
  /// regard sur ceux à retenir.
  final bool dimOthers;

  /// Point à marquer (le toucher du joueur).
  final cartographer.GeoPoint? marker;

  final cartographer.NameLanguage language;
  final ValueChanged<cartographer.GeoPoint>? onTap;

  const CartographerMapView({
    super.key,
    required this.baseMap,
    this.fills = const {},
    this.labels = const {},
    this.labelTexts = const {},
    this.dimOthers = false,
    this.marker,
    this.language = cartographer.NameLanguage.fr,
    this.onTap,
  });

  @override
  State<CartographerMapView> createState() => _CartographerMapViewState();
}

class _CartographerMapViewState extends State<CartographerMapView> {
  Size? _pathsSize;
  Map<String, Path> _paths = const {};
  late final Map<String, int> _tints = tintIndices(widget.baseMap);

  /// Les chemins ne dépendent que de la taille : on les refait seulement si elle change.
  Map<String, Path> _pathsFor(MapProjection projection, Size size) {
    if (_pathsSize != size) {
      _pathsSize = size;
      _paths = {
        for (final item in widget.baseMap.items) item.id: _pathOf(item, projection),
      };
    }
    return _paths;
  }

  /// Tous les anneaux dans un même chemin, règle pair-impair : les trous (enclaves) restent vides.
  Path _pathOf(cartographer.Item item, MapProjection projection) {
    final path = Path()..fillType = PathFillType.evenOdd;
    for (final polygon in item.outline) {
      for (final ring in polygon) {
        path.addPolygon([for (final p in ring) projection.toCanvas(p)], true);
      }
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = softTints(scheme.surfaceContainerHighest);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final projection = MapProjection(widget.baseMap.frame, size);
        final paths = _pathsFor(projection, size);
        return ClipRect(
          child: InteractiveViewer(
            maxScale: 8,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: widget.onTap == null ? null : (details) => widget.onTap!(projection.toGeo(details.localPosition)),
              child: CustomPaint(
                key: const Key('cartographer-map'),
                size: size,
                painter: _MapPainter(
                  baseMap: widget.baseMap,
                  paths: paths,
                  projection: projection,
                  fills: widget.fills,
                  labels: widget.labels,
                  labelTexts: widget.labelTexts,
                  dimOthers: widget.dimOthers,
                  marker: widget.marker,
                  language: widget.language,
                  tints: {for (final entry in _tints.entries) entry.key: palette[entry.value]},
                  border: scheme.outline,
                  sea: scheme.surfaceContainerLow,
                  markerColor: scheme.onSurface,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MapPainter extends CustomPainter {
  final cartographer.BaseMap baseMap;
  final Map<String, Path> paths;
  final MapProjection projection;
  final Map<String, Color> fills;
  final Set<String> labels;
  final Map<String, String> labelTexts;
  final bool dimOthers;
  final cartographer.GeoPoint? marker;
  final cartographer.NameLanguage language;
  final Map<String, Color> tints;
  final Color border;
  final Color sea;
  final Color markerColor;

  _MapPainter({
    required this.baseMap,
    required this.paths,
    required this.projection,
    required this.fills,
    required this.labels,
    required this.labelTexts,
    required this.dimOthers,
    required this.marker,
    required this.language,
    required this.tints,
    required this.border,
    required this.sea,
    required this.markerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = sea);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeJoin = StrokeJoin.round
      ..color = border;
    for (final item in baseMap.items) {
      final path = paths[item.id]!;
      final base = fills[item.id] ?? tints[item.id]!;
      canvas.drawPath(path, Paint()..color = dimOthers && !fills.containsKey(item.id) ? base.withValues(alpha: 0.3) : base);
      canvas.drawPath(path, stroke);
    }
    for (final item in baseMap.items) {
      if (!labels.contains(item.id)) continue;
      final text = labelTexts[item.id] ?? item.names.of(language);
      TextPainter styled(TextStyle style) => TextPainter(
        text: TextSpan(text: text, style: style),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      const base = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.15);
      // Un contour de la couleur de la mer sous le texte le garde lisible sur n'importe quel pays.
      final halo = styled(base.copyWith(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round
          ..color = sea,
      ));
      final fill = styled(base.copyWith(color: markerColor));
      final origin = projection.toCanvas(item.anchor) - Offset(fill.width / 2, fill.height / 2);
      halo.paint(canvas, origin);
      fill.paint(canvas, origin);
    }
    if (marker != null) {
      final center = projection.toCanvas(marker!);
      canvas.drawCircle(center, 7, Paint()..color = markerColor.withValues(alpha: 0.25));
      canvas.drawCircle(center, 3.5, Paint()..color = markerColor);
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.paths != paths ||
      !mapEquals(old.labelTexts, labelTexts) ||
      old.dimOthers != dimOthers ||
      old.labels != labels ||
      old.marker != marker ||
      !mapEquals(old.tints, tints) ||
      !mapEquals(old.fills, fills) ||
      old.border != border ||
      old.sea != sea;
}
