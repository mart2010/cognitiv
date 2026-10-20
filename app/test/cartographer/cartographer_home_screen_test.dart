import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:cognitiv_app/cartographer/cartographer_home_screen.dart';
import 'package:cognitiv_app/cartographer/link_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cartographer_test_support.dart';

void main() {
  const positionOfName = cartographer.LinkKind(cartographer.Facet.name, cartographer.Facet.position);

  Future<void> pump(WidgetTester tester, services) async {
    usePixel(tester);
    await tester.pumpWidget(MaterialApp(home: CartographerHomeScreen(services: services)));
    await tester.pump();
  }

  testWidgets('niveau 3 par défaut, résumé du Niveau en français', (tester) async {
    await pump(tester, newServices());
    expect(find.text('Niveau 3'), findsOneWidget);
    expect(find.text('4 pays par étude, 10 s pour les retenir, avec propositions'), findsOneWidget);
  });

  testWidgets('déplacer le curseur change le Niveau affiché et son résumé', (tester) async {
    await pump(tester, newServices());
    await tester.drag(find.byKey(const Key('level-slider')), const Offset(400, 0));
    await tester.pump();
    expect(find.text('Niveau 10'), findsOneWidget);
    expect(find.text('8 pays par étude, 4 s pour les retenir, sans aide'), findsOneWidget);
  });

  testWidgets('chaque genre de Lien jouable a son interrupteur, ceux du Profil sont allumés', (tester) async {
    final services = newServices();
    await pump(tester, services);
    for (final kind in playableLinkKinds) {
      final finder = find.byKey(Key('kind-${kind.cue.name}-${kind.answer.name}'));
      await tester.scrollUntilVisible(finder, 100, scrollable: find.byType(Scrollable).first);
      final tile = tester.widget<SwitchListTile>(finder);
      expect(tile.value, services.profile.profile.linkKinds.contains(kind), reason: '$kind');
    }
  });

  testWidgets('aucun genre avec drapeau tant que les données n’en ont pas', (tester) async {
    await pump(tester, newServices());
    expect(find.byKey(const Key('kind-flag-name')), findsNothing);
    expect(playableLinkKinds.where((k) => k.cue == cartographer.Facet.flag || k.answer == cartographer.Facet.flag), isEmpty);
  });

  testWidgets('allumer un genre l’ajoute au Profil', (tester) async {
    final services = newServices();
    await pump(tester, services);
    const extra = cartographer.LinkKind(cartographer.Facet.position, cartographer.Facet.capital);
    await tester.scrollUntilVisible(find.byKey(const Key('kind-position-capital')), 100, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(ListView), const Offset(0, -200)); // hors de la zone du bouton épinglé
    await tester.pump();
    await tester.tap(find.byKey(const Key('kind-position-capital')));
    await tester.pump();
    expect(services.profile.profile.linkKinds, contains(extra));
  });

  testWidgets('éteindre le dernier genre est refusé', (tester) async {
    final services = newServices(profile: cartographer.CartographerProfile({positionOfName}));
    await pump(tester, services);
    await tester.scrollUntilVisible(find.byKey(const Key('kind-name-position')), 100, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('kind-name-position')));
    await tester.pump();
    expect(services.profile.profile.linkKinds, {positionOfName});
  });

  testWidgets('« Repartir de zéro » demande confirmation puis efface la Maîtrise de la carte', (tester) async {
    final services = newServices(
      mastery: cartographer.Mastery({
        const cartographer.MasteryKey('south_america', 'PRY', positionOfName): cartographer.Knowledge.shaky,
        const cartographer.MasteryKey('autre', 'X', positionOfName): cartographer.Knowledge.solid,
      }),
    );
    await pump(tester, services);

    await tester.tap(find.byKey(const Key('reset-progress')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset-cancel')));
    await tester.pumpAndSettle();
    expect(services.mastery.mastery.length, 2, reason: 'annuler ne touche à rien');

    await tester.tap(find.byKey(const Key('reset-progress')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset-confirm')));
    await tester.pumpAndSettle();
    expect(services.mastery.mastery.of('south_america', 'PRY', positionOfName), isNull);
    expect(services.mastery.mastery.of('autre', 'X', positionOfName), cartographer.Knowledge.solid);
  });

  testWidgets('« Jouer » ouvre la Partie, par le Repérage', (tester) async {
    await pump(tester, newServices());
    await tester.tap(find.byKey(const Key('start')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Première manche · 1 sur'), findsOneWidget);
  });

  testWidgets('l’accueil tient sur un Pixel sans débordement, et « Jouer » reste visible sans défiler', (tester) async {
    await pump(tester, newServices());
    expect(tester.takeException(), isNull);
    final play = tester.getRect(find.byKey(const Key('start')));
    expect(play.bottom, lessThanOrEqualTo(pixelSize.height));
    expect(play.top, greaterThan(0));
  });
}
