import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:flutter/foundation.dart' show listEquals, mapEquals, setEquals;
import 'package:flutter/material.dart';

import 'country_tints.dart';
import 'label_layout.dart';
import 'map_projection.dart';

/// Un repère posé par le joueur sur la carte : un rond numéroté (ou lettré) de la couleur voulue,
/// par exemple l'endroit où il croit qu'est la quatrième ville d'un Plateau.
class MapMarker {
  final cartographer.GeoPoint point;
  final String text;
  final Color color;

  const MapMarker({required this.point, required this.text, required this.color});

  @override
  bool operator ==(Object other) =>
      other is MapMarker && other.point == point && other.text == text && other.color == color;

  @override
  int get hashCode => Object.hash(point, text, color);
}

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

  /// Si renseigné, ces Éléments gardent leur teinte et reçoivent un contour net, tous les autres
  /// sont mis en retrait : pour concentrer le regard sur ceux à retenir sans changer leurs couleurs.
  final Set<String>? focus;

  /// Point à marquer (le toucher du joueur).
  final cartographer.GeoPoint? marker;

  /// Repères numérotés posés par le joueur (les villes d'un Plateau qu'il a placées).
  final List<MapMarker> markers;

  final cartographer.NameLanguage language;
  final ValueChanged<cartographer.GeoPoint>? onTap;

  const CartographerMapView({
    super.key,
    required this.baseMap,
    this.fills = const {},
    this.labels = const {},
    this.labelTexts = const {},
    this.focus,
    this.marker,
    this.markers = const [],
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
                  focus: widget.focus,
                  marker: widget.marker,
                  markers: widget.markers,
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
  final Set<String>? focus;
  final cartographer.GeoPoint? marker;
  final List<MapMarker> markers;
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
    required this.focus,
    required this.marker,
    required this.markers,
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
    // Ceux hors de la mise en avant d'abord, en retrait ; les autres par-dessus, avec leur contour net.
    final focused = focus;
    final areas = [for (final item in baseMap.items) if (item.geometry is cartographer.AreaGeometry) item];
    // Si la mise en avant ne vise aucun pays (on étudie des villes), les pays restent tous nets :
    // ils servent de repères.
    final dimOthers = focused != null && areas.any((item) => focused.contains(item.id));
    for (final item in areas) {
      final path = paths[item.id]!;
      final base = fills[item.id] ?? tints[item.id]!;
      final inFocus = !dimOthers || focused.contains(item.id);
      if (inFocus) continue;
      canvas.drawPath(path, Paint()..color = base.withValues(alpha: 0.28));
      canvas.drawPath(path, stroke..color = border.withValues(alpha: 0.35));
    }
    stroke.color = border;
    for (final item in areas) {
      final path = paths[item.id]!;
      final base = fills[item.id] ?? tints[item.id]!;
      if (dimOthers && !focused.contains(item.id)) continue;
      canvas.drawPath(path, Paint()..color = base);
      canvas.drawPath(path, stroke);
      if (dimOthers) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeJoin = StrokeJoin.round
            ..color = markerColor.withValues(alpha: 0.85),
        );
      }
    }
    _paintPoints(canvas);
    _paintLabels(canvas, size);
    _paintMarkers(canvas);
    if (marker != null) {
      final center = projection.toCanvas(marker!);
      canvas.drawCircle(center, 7, Paint()..color = markerColor.withValues(alpha: 0.25));
      canvas.drawCircle(center, 3.5, Paint()..color = markerColor);
    }
  }

  static const _markerRadius = 11.0;

  void _paintMarkers(Canvas canvas) {
    for (final marker in markers) {
      final center = projection.toCanvas(marker.point);
      canvas.drawCircle(center, _markerRadius + 1.5, Paint()..color = sea);
      canvas.drawCircle(center, _markerRadius, Paint()..color = marker.color);
      final text = TextPainter(
        text: TextSpan(
          text: marker.text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: ThemeData.estimateBrightnessForColor(marker.color) == Brightness.dark ? Colors.white : Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
    }
  }

  static const _dotRadius = 5.0;

  /// Les villes (Points) ne se montrent que si on les vise : colorées, mises en avant ou nommées.
  /// Sinon la carte ne révélerait pas ce qu'on demande de placer.
  bool _isShown(cartographer.Item item) =>
      fills.containsKey(item.id) || labels.contains(item.id) || (focus?.contains(item.id) ?? false);

  void _paintPoints(Canvas canvas) {
    for (final item in baseMap.items) {
      if (item.geometry is! cartographer.PointGeometry || !_isShown(item)) continue;
      final center = projection.toCanvas(item.anchor);
      canvas.drawCircle(center, _dotRadius + 1.5, Paint()..color = sea);
      canvas.drawCircle(center, _dotRadius, Paint()..color = fills[item.id] ?? markerColor);
    }
  }

  /// Là où un libellé ne doit pas se poser : le contour d'un pays, ou le point d'une ville.
  Rect _boundsOf(cartographer.Item item) => item.geometry is cartographer.PointGeometry
      ? Rect.fromCircle(center: projection.toCanvas(item.anchor), radius: _dotRadius + 1.5)
      : paths[item.id]!.getBounds();

  /// Pose les libellés sans chevauchement (`placeLabels`) : au centre du pays quand il y tient, sinon
  /// à côté, relié par un trait, avec un point sur le pays.
  void _paintLabels(Canvas canvas, Size size) {
    const base = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.15);
    final items = [for (final item in baseMap.items) if (labels.contains(item.id)) item];
    final inks = <TextPainter>[];
    final halos = <TextPainter>[];
    for (final item in items) {
      final text = labelTexts[item.id] ?? item.names.of(language);
      TextPainter styled(TextStyle style) => TextPainter(
        text: TextSpan(text: text, style: style),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      // Un contour de la couleur de la mer sous le texte le garde lisible sur n'importe quel pays.
      halos.add(styled(base.copyWith(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round
          ..color = sea,
      )));
      inks.add(styled(base.copyWith(color: markerColor)));
    }
    final placed = placeLabels(size, [
      for (var i = 0; i < items.length; i++)
        LabelRequest(
          anchor: projection.toCanvas(items[i].anchor),
          bounds: _boundsOf(items[i]),
          size: Size(inks[i].width, inks[i].height),
        ),
    ]);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = markerColor.withValues(alpha: 0.7);
    for (var i = 0; i < items.length; i++) {
      final rect = placed[i].rect;
      if (placed[i].displaced) {
        final anchor = projection.toCanvas(items[i].anchor);
        final target = Offset(anchor.dx.clamp(rect.left, rect.right), anchor.dy.clamp(rect.top, rect.bottom));
        canvas.drawLine(anchor, target, line);
        canvas.drawCircle(anchor, 2.5, Paint()..color = markerColor);
      }
      halos[i].paint(canvas, rect.topLeft);
      inks[i].paint(canvas, rect.topLeft);
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.paths != paths ||
      !mapEquals(old.labelTexts, labelTexts) ||
      !setEquals(old.focus, focus) ||
      old.labels != labels ||
      old.marker != marker ||
      !listEquals(old.markers, markers) ||
      !mapEquals(old.tints, tints) ||
      !mapEquals(old.fills, fills) ||
      old.border != border ||
      old.sea != sea;
}
