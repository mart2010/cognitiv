import 'package:cognitiv_app/workshop/profile/workshop_profile.dart';
import 'package:cognitiv_app/workshop/progress/workshop_progress.dart';
import 'package:cognitiv_app/workshop/workshop_home_screen.dart';
import 'package:cognitiv_app/workshop/workshop_rules_screen.dart';
import 'package:cognitiv_app/workshop/workshop_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop/workshop.dart' as workshop;

Future<WorkshopServices> _services({workshop.GenerationProfile? profile}) async {
  final services = WorkshopServices(
    generate: workshop.GenerateWorkshopPuzzle(
      catalog: const workshop.RuleCatalog(),
      random: workshop.SystemRandomSource(1),
    ),
    evaluate: workshop.EvaluateWorkshopAnswer(),
    progress: WorkshopProgressController(InMemoryProgressStore()),
    profileController: WorkshopProfileController(
      InMemoryProfileStore(profile ?? workshop.GenerationProfile.intuitiveDefaults),
    ),
  );
  await services.profileController.load();
  return services;
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: home));
  await tester.pump();
}

Switch _switch(WidgetTester tester, workshop.RuleFamily family) =>
    tester.widget<Switch>(find.byKey(Key('family-${family.name}')));

void main() {
  testWidgets('affiche un interrupteur par Famille, reflétant le Profil', (tester) async {
    final services = await _services();
    await _pump(tester, WorkshopRulesScreen(services: services));

    for (final family in workshop.RuleFamily.values) {
      expect(find.byKey(Key('family-${family.name}')), findsOneWidget);
      expect(
        _switch(tester, family).value,
        workshop.GenerationProfile.intuitiveDefaults.isActive(family),
      );
    }
    expect(find.byKey(const Key('availability-note')), findsOneWidget);
    expect(find.text('Tous les niveaux sont jouables.'), findsOneWidget);
  });

  testWidgets('activer une Famille avancée met à jour le Profil', (tester) async {
    final services = await _services();
    await _pump(tester, WorkshopRulesScreen(services: services));

    await tester.tap(find.byKey(const Key('family-colorCycle')));
    await tester.pump();

    expect(services.profile.isActive(workshop.RuleFamily.colorCycle), isTrue);
  });

  testWidgets('la dernière Famille active ne peut pas être désactivée', (tester) async {
    final services = await _services(
      profile: const workshop.GenerationProfile({workshop.RuleFamily.mirror}),
    );
    await _pump(tester, WorkshopRulesScreen(services: services));

    expect(_switch(tester, workshop.RuleFamily.mirror).onChanged, isNull);
    expect(find.text('Au moins une famille doit rester active.'), findsOneWidget);
  });

  testWidgets('prévient quand des Niveaux deviennent injouables', (tester) async {
    final services = await _services(
      profile: const workshop.GenerationProfile({workshop.RuleFamily.transposition}),
    );
    await _pump(tester, WorkshopRulesScreen(services: services));

    expect(find.textContaining('niveaux sur 10 jouables'), findsOneWidget);
  });

  testWidgets("« Tout activer » puis « Réglage par défaut »", (tester) async {
    final services = await _services();
    await _pump(tester, WorkshopRulesScreen(services: services));

    await tester.tap(find.byKey(const Key('activate-all')));
    await tester.pump();
    expect(services.profile, workshop.GenerationProfile.allFamilies);

    await tester.tap(find.byKey(const Key('reset-profile')));
    await tester.pump();
    expect(services.profile, workshop.GenerationProfile.intuitiveDefaults);
  });

  testWidgets("l'accueil ouvre les réglages et grise les Niveaux injouables", (tester) async {
    final services = await _services(
      profile: const workshop.GenerationProfile({workshop.RuleFamily.transposition}),
    );
    await _pump(tester, WorkshopHomeScreen(services: services));

    expect(find.text('Indisponible avec les règles actives'), findsWidgets);

    await tester.tap(find.byKey(const Key('open-rules')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkshopRulesScreen), findsOneWidget);
  });
}
