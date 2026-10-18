import 'dart:ui';

import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:cognitiv_app/cartographer/label_layout.dart';
import 'package:cognitiv_app/cartographer/map_projection.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cartographer_test_support.dart';

LabelRequest _req(double x, double y, {double boundsW = 200, double boundsH = 200, double w = 80, double h = 32}) =>
    LabelRequest(
      anchor: Offset(x, y),
      bounds: Rect.fromCenter(center: Offset(x, y), width: boundsW, height: boundsH),
      size: Size(w, h),
    );

bool _noOverlap(List<PlacedLabel> labels) {
  for (var i = 0; i < labels.length; i++) {
    for (var j = i + 1; j < labels.length; j++) {
      if (labels[i].rect.overlaps(labels[j].rect)) return false;
    }
  }
  return true;
}

void main() {
  const canvas = Size(400, 700);

  test('un grand pays garde son libellé au centre', () {
    final placed = placeLabels(canvas, [_req(200, 300)]).single;
    expect(placed.rect.center, const Offset(200, 300));
    expect(placed.displaced, isFalse);
  });

  test('un pays plus petit que son texte reçoit le libellé à côté, sans le recouvrir', () {
    final request = _req(200, 300, boundsW: 20, boundsH: 20);
    final placed = placeLabels(canvas, [request]).single;
    expect(placed.displaced, isTrue);
    expect(placed.rect.overlaps(request.bounds), isFalse, reason: 'la forme du pays reste visible');
    expect(placed.rect.contains(request.anchor), isFalse);
  });

  test('deux petits pays voisins ne se recouvrent pas', () {
    final placed = placeLabels(canvas, [
      _req(200, 300, boundsW: 20, boundsH: 20),
      _req(215, 310, boundsW: 20, boundsH: 20),
    ]);
    expect(_noOverlap(placed), isTrue);
  });

  test("beaucoup de libellés serrés : aucun chevauchement, tous dans le cadre", () {
    final requests = [
      for (var i = 0; i < 8; i++) _req(180 + (i % 3) * 14, 300 + (i ~/ 3) * 12, boundsW: 18, boundsH: 18),
    ];
    final placed = placeLabels(canvas, requests);
    expect(_noOverlap(placed), isTrue);
    for (final p in placed) {
      expect(p.rect.left, greaterThanOrEqualTo(0));
      expect(p.rect.top, greaterThanOrEqualTo(0));
      expect(p.rect.right, lessThanOrEqualTo(canvas.width));
      expect(p.rect.bottom, lessThanOrEqualTo(canvas.height));
    }
  });

  test('un libellé près du bord reste dans le cadre', () {
    for (final anchor in [const Offset(5, 5), const Offset(395, 695), const Offset(5, 695), const Offset(395, 5)]) {
      final placed = placeLabels(canvas, [_req(anchor.dx, anchor.dy, boundsW: 10, boundsH: 10)]).single;
      expect(placed.rect.left, greaterThanOrEqualTo(0));
      expect(placed.rect.top, greaterThanOrEqualTo(0));
      expect(placed.rect.right, lessThanOrEqualTo(canvas.width));
      expect(placed.rect.bottom, lessThanOrEqualTo(canvas.height));
    }
  });

  test('le résultat suit l’ordre des demandes, quel que soit l’ordre de traitement', () {
    final small = _req(100, 100, boundsW: 10, boundsH: 10);
    final large = _req(300, 400);
    final placed = placeLabels(canvas, [small, large]);
    expect(placed[1].rect.center, const Offset(300, 400), reason: 'le grand pays est en seconde position de la liste');
    expect(placed[0].rect.overlaps(small.bounds), isFalse);
  });

  test('déterministe, et sans place il ne plante pas', () {
    final requests = [for (var i = 0; i < 30; i++) _req(200, 300, boundsW: 5, boundsH: 5, w: 90, h: 34)];
    final a = placeLabels(const Size(120, 120), requests);
    final b = placeLabels(const Size(120, 120), requests);
    expect([for (final p in a) p.rect], [for (final p in b) p.rect]);
    expect(a, hasLength(30));
  });

  test("sans demande, rien", () {
    expect(placeLabels(canvas, const []), isEmpty);
  });

  group('sur la vraie carte, à la taille d’un Pixel', () {
    final map = loadMap();
    final projection = MapProjection(map.frame, const Size(380, 560));

    LabelRequest request(cartographer.Item item, {double w = 70, double h = 30}) {
      final points = [for (final polygon in item.outline) for (final p in polygon.first) projection.toCanvas(p)];
      final left = points.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
      final right = points.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
      final top = points.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
      final bottom = points.map((p) => p.dy).reduce((a, b) => a > b ? a : b);
      return LabelRequest(anchor: projection.toCanvas(item.anchor), bounds: Rect.fromLTRB(left, top, right, bottom), size: Size(w, h));
    }

    test('les quatre pays de l’étude : aucun libellé ne chevauche un autre', () {
      for (final ids in [
        ['PRY', 'URY', 'ECU', 'GUY'],
        ['SUR', 'GUF', 'GUY', 'VEN'],
        ['ECU', 'COL', 'PER', 'BOL'],
      ]) {
        final placed = placeLabels(const Size(380, 560), [for (final id in ids) request(map.itemById(id))]);
        expect(_noOverlap(placed), isTrue, reason: ids.join(','));
      }
    });

    test('même les treize libellés à la fois restent sans chevauchement', () {
      final placed = placeLabels(const Size(380, 560), [for (final item in map.items) request(item, w: 60, h: 18)]);
      expect(_noOverlap(placed), isTrue);
    });

    test('le Suriname, la Guyane et le Guyana (très petits, voisins) sont tous lisibles', () {
      final requests = [for (final id in ['SUR', 'GUF', 'GUY']) request(map.itemById(id), w: 80, h: 32)];
      // Sans placement (tous centrés sur leur pays), ils se chevaucheraient : c'est le défaut corrigé.
      final naive = [for (final r in requests) Rect.fromCenter(center: r.anchor, width: r.size.width, height: r.size.height)];
      expect(naive[0].overlaps(naive[1]) || naive[1].overlaps(naive[2]) || naive[0].overlaps(naive[2]), isTrue);

      final placed = placeLabels(const Size(380, 560), requests);
      expect(_noOverlap(placed), isTrue);
      for (var i = 0; i < 3; i++) {
        expect(placed[i].rect.overlaps(requests[i].bounds), isFalse, reason: 'le libellé ne cache pas le pays $i');
      }
    });
  });
}
