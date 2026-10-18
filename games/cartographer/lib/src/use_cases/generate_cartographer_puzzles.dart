import '../domain_services/text_matcher.dart';
import '../entities/base_map.dart';
import '../entities/cartographer_level.dart';
import '../entities/cartographer_profile.dart';
import '../entities/cartographer_puzzle.dart';
import '../entities/item.dart';
import '../entities/link.dart';
import '../entities/name_language.dart';
import '../entities/recall_aid.dart';
import '../entities/recall_question.dart';
import 'ports/random_source.dart';

class GenerateCartographerRequest {
  final BaseMap baseMap;
  final CartographerLevel level;
  final CartographerProfile profile;
  final NameLanguage language;

  const GenerateCartographerRequest({
    required this.baseMap,
    required this.level,
    required this.profile,
    required this.language,
  });
}

/// Cas d'usage « préparer les énigmes d'un niveau » du contrat jeu/plateforme (ADR 0004).
/// Prépare toute la Partie d'un coup : les Études-éclair, puis le Bilan, qui redemande
/// des Liens étudiés plus tôt. La plateforme stocke ces Énigmes dès le début (ADR 0002),
/// donc le Bilan peut être décidé d'avance sans état entre les Parties.
///
/// Lance une `ArgumentError` si la Carte de base n'a pas assez d'Éléments compatibles avec
/// le Profil : l'écran de réglages l'empêche en amont, la garantie reste ici.
class GenerateCartographerPuzzles {
  final RandomSource random;

  GenerateCartographerPuzzles({required this.random});

  List<CartographerPuzzle> call(GenerateCartographerRequest request) {
    final level = request.level;
    final eligible = [for (final item in request.baseMap.items) if (_kindsFor(item, request.profile).isNotEmpty) item];
    if (eligible.length < level.itemCount) {
      throw ArgumentError(
        'La Carte de base ${request.baseMap.id} n\'a que ${eligible.length} Élément(s) compatible(s) '
        'avec le Profil, le Niveau ${level.number} en demande ${level.itemCount}.',
      );
    }

    final studies = <FlashStudy>[];
    var queue = _shuffled(eligible);
    for (var s = 0; s < level.studyCount; s++) {
      final batch = <Item>[];
      while (batch.length < level.itemCount) {
        if (queue.isEmpty) {
          final inBatch = batch.map((i) => i.id).toSet();
          queue = _shuffled([for (final item in eligible) if (!inBatch.contains(item.id)) item]);
        }
        batch.add(queue.removeLast());
      }
      studies.add(FlashStudy(
        language: request.language,
        studySeconds: level.studySeconds,
        distractionSeconds: level.distractionSeconds,
        questions: [
          for (final item in batch) _question(request, item, _pick(_kindsFor(item, request.profile))),
        ],
      ));
    }

    return [...studies, _delayedRecall(request, studies)];
  }

  /// Le Bilan redemande les mêmes Liens que ceux étudiés (ce que le joueur a vu associé),
  /// en privilégiant les Éléments des premières Études, donc les plus anciens.
  DelayedRecall _delayedRecall(GenerateCartographerRequest request, List<FlashStudy> studies) {
    final latestKind = <String, LinkKind>{};
    for (final study in studies) {
      for (final q in study.questions) {
        latestKind[q.itemId] = q.kind;
      }
    }
    final lastIds = studies.last.studiedItemIds.toSet();
    final earlier = [for (final id in latestKind.keys) if (!lastIds.contains(id)) id];
    final ordered = [..._shuffled(earlier), ..._shuffled(lastIds.toList())];
    final count = request.level.delayedRecallCount < ordered.length ? request.level.delayedRecallCount : ordered.length;
    return DelayedRecall(
      language: request.language,
      questions: [
        for (final id in ordered.take(count)) _question(request, request.baseMap.itemById(id), latestKind[id]!),
      ],
    );
  }

  List<LinkKind> _kindsFor(Item item, CartographerProfile profile) =>
      [for (final kind in LinkKind.supported) if (profile.linkKinds.contains(kind) && kind.appliesTo(item)) kind];

  RecallQuestion _question(GenerateCartographerRequest request, Item item, LinkKind kind) {
    final naming = kind.gesture == Gesture.naming;
    final aid = naming ? request.level.aid : RecallAid.free;
    return RecallQuestion(
      itemId: item.id,
      kind: kind,
      aid: aid,
      choices: aid == RecallAid.choices ? _choices(request, item, kind) : const [],
    );
  }

  /// Quatre propositions au plus : la bonne et jusqu'à trois autres Éléments de la même
  /// Carte, sans jamais proposer un texte que la bonne réponse accepte aussi.
  List<String> _choices(GenerateCartographerRequest request, Item item, LinkKind kind) {
    final facet = kind.answer;
    final language = request.language;
    final correct = item.textFor(facet, language);
    final forbidden = item.acceptedTexts(facet).map(TextMatcher.normalize).toSet();
    final distractors = <String>{};
    for (final other in _shuffled([for (final i in request.baseMap.items) if (i.id != item.id && i.hasFacet(facet)) i])) {
      final text = other.textFor(facet, language);
      final normalized = TextMatcher.normalize(text);
      if (!forbidden.contains(normalized)) {
        forbidden.add(normalized);
        distractors.add(text);
      }
      if (distractors.length == 3) break;
    }
    return _shuffled([correct, ...distractors]);
  }

  T _pick<T>(List<T> list) => list[random.nextInt(list.length)];

  /// Mélange de Fisher-Yates avec le hasard injecté.
  List<T> _shuffled<T>(Iterable<T> source) {
    final list = source.toList();
    for (var i = list.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return list;
  }
}
