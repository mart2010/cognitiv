import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Progression locale du joueur dans L'atelier : Niveaux franchis et meilleur Score par
/// Niveau. Aucun verrou n'en découle (`platform/CONTEXT.md`) : elle ne sert qu'à
/// l'affichage et à suggérer un Niveau. Provisoire : la plateforme prendra ce rôle plus
/// tard (Profil local), l'app la porte en attendant.
@immutable
class WorkshopProgress {
  final Set<int> clearedLevels;
  final Map<int, int> bestScores;

  const WorkshopProgress({this.clearedLevels = const {}, this.bestScores = const {}});

  bool isCleared(int level) => clearedLevels.contains(level);
  int? bestScore(int level) => bestScores[level];

  /// Niveau à mettre en avant : celui qui suit le plus haut Niveau franchi.
  int suggestedLevel(int lastLevel) {
    if (clearedLevels.isEmpty) return 1;
    final highest = clearedLevels.reduce((a, b) => a > b ? a : b);
    return highest >= lastLevel ? lastLevel : highest + 1;
  }

  WorkshopProgress afterRun({required int level, required int score, required bool cleared}) {
    final best = bestScores[level];
    return WorkshopProgress(
      clearedLevels: cleared ? {...clearedLevels, level} : clearedLevels,
      bestScores: best != null && best >= score ? bestScores : {...bestScores, level: score},
    );
  }

  Map<String, dynamic> toJson() => {
    'cleared': clearedLevels.toList()..sort(),
    'best': {for (final e in bestScores.entries) '${e.key}': e.value},
  };

  factory WorkshopProgress.fromJson(Map<String, dynamic> json) => WorkshopProgress(
    clearedLevels: {for (final n in json['cleared'] as List) n as int},
    bestScores: {
      for (final e in (json['best'] as Map).entries) int.parse(e.key as String): e.value as int,
    },
  );
}

/// Port de stockage de la progression (ADR 0005).
abstract class ProgressStore {
  Future<WorkshopProgress> load();
  Future<void> save(WorkshopProgress progress);
}

class InMemoryProgressStore implements ProgressStore {
  WorkshopProgress _progress;
  InMemoryProgressStore([this._progress = const WorkshopProgress()]);

  @override
  Future<WorkshopProgress> load() async => _progress;

  @override
  Future<void> save(WorkshopProgress progress) async => _progress = progress;
}

class SharedPreferencesProgressStore implements ProgressStore {
  static const _key = 'workshop.progress';

  @override
  Future<WorkshopProgress> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return const WorkshopProgress();
      return WorkshopProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Donnée absente ou illisible : on repart de zéro plutôt que de planter.
      return const WorkshopProgress();
    }
  }

  @override
  Future<void> save(WorkshopProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(progress.toJson()));
    } catch (_) {}
  }
}

/// Garde la progression en mémoire, la persiste et prévient l'interface à chaque Partie.
class WorkshopProgressController extends ChangeNotifier {
  final ProgressStore store;
  WorkshopProgress _progress = const WorkshopProgress();

  WorkshopProgressController(this.store);

  WorkshopProgress get progress => _progress;

  Future<void> load() async {
    _progress = await store.load();
    notifyListeners();
  }

  Future<void> recordRun({required int level, required int score, required bool cleared}) async {
    _progress = _progress.afterRun(level: level, score: score, cleared: cleared);
    notifyListeners();
    await store.save(_progress);
  }
}
