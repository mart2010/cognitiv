import 'package:cognitiv_app/workshop/progress/workshop_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('WorkshopProgress', () {
    test('un Niveau franchi est mémorisé, avec son meilleur Score', () {
      final progress = const WorkshopProgress().afterRun(level: 2, score: 80, cleared: true);
      expect(progress.isCleared(2), isTrue);
      expect(progress.bestScore(2), 80);
    });

    test("un Niveau raté n'est pas marqué franchi, mais son Score est gardé", () {
      final progress = const WorkshopProgress().afterRun(level: 3, score: 30, cleared: false);
      expect(progress.isCleared(3), isFalse);
      expect(progress.bestScore(3), 30);
    });

    test("un moins bon Score n'écrase pas le meilleur, et un Niveau franchi le reste", () {
      final progress = const WorkshopProgress()
          .afterRun(level: 1, score: 50, cleared: true)
          .afterRun(level: 1, score: 20, cleared: false);
      expect(progress.bestScore(1), 50);
      expect(progress.isCleared(1), isTrue);
    });

    test('le Niveau suggéré suit le plus haut Niveau franchi, borné au dernier', () {
      expect(const WorkshopProgress().suggestedLevel(10), 1);
      expect(const WorkshopProgress(clearedLevels: {1, 4}).suggestedLevel(10), 5);
      expect(const WorkshopProgress(clearedLevels: {10}).suggestedLevel(10), 10);
    });

    test('aller-retour JSON', () {
      final progress = const WorkshopProgress().afterRun(level: 4, score: 120, cleared: true);
      final back = WorkshopProgress.fromJson(progress.toJson());
      expect(back.clearedLevels, {4});
      expect(back.bestScores, {4: 120});
    });
  });

  test('le contrôleur enregistre la Partie et la persiste', () async {
    final store = InMemoryProgressStore();
    final controller = WorkshopProgressController(store);
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.recordRun(level: 1, score: 40, cleared: true);

    expect(notified, 1);
    expect(controller.progress.isCleared(1), isTrue);
    expect((await store.load()).bestScore(1), 40);
  });

  group('SharedPreferencesProgressStore', () {
    test('sauve puis recharge', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesProgressStore();
      await store.save(const WorkshopProgress().afterRun(level: 5, score: 150, cleared: true));
      final loaded = await store.load();
      expect(loaded.isCleared(5), isTrue);
      expect(loaded.bestScore(5), 150);
    });

    test('une donnée illisible donne une progression vide', () async {
      SharedPreferences.setMockInitialValues({'workshop.progress': 'pas du json'});
      final loaded = await SharedPreferencesProgressStore().load();
      expect(loaded.clearedLevels, isEmpty);
    });
  });
}
