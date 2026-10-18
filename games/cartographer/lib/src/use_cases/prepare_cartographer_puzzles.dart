import '../domain_services/text_matcher.dart';
import '../entities/base_map.dart';
import '../entities/cartographer_answer.dart';
import '../entities/cartographer_level.dart';
import '../entities/cartographer_profile.dart';
import '../entities/cartographer_puzzle.dart';
import '../entities/item.dart';
import '../entities/knowledge.dart';
import '../entities/link.dart';
import '../entities/mastery.dart';
import '../entities/name_language.dart';
import '../entities/played_puzzle.dart';
import '../entities/recall_aid.dart';
import '../entities/recall_question.dart';
import 'ports/random_source.dart';

class PrepareCartographerRequest {
  final BaseMap baseMap;
  final CartographerLevel level;
  final CartographerProfile profile;
  final NameLanguage language;

  /// Ce que le joueur connaît déjà, d'après les Parties précédentes (ADR 0009).
  final Mastery mastery;

  PrepareCartographerRequest({
    required this.baseMap,
    required this.level,
    required this.profile,
    required this.language,
    Mastery? mastery,
  }) : mastery = mastery ?? Mastery.empty;
}

/// Cas d'usage « préparer les énigmes d'un niveau » du contrat jeu/plateforme (ADR 0004),
/// appelable plusieurs fois au fil de la Partie (ADR 0010). La plateforme le rappelle quand elle
/// n'a plus d'énigme à faire jouer, avec l'historique des énigmes jouées ; une liste vide
/// veut dire « Partie terminée ».
///
///  1. Historique vide : le **Repérage**, une question par Élément qui mérite d'être posé.
///  2. Repérage joué : les **Études-éclair** des Éléments ratés (au plus `maxStudyCycles` Lots),
///     suivies du **Bilan** qui les redemande. Rien si le joueur n'a rien raté.
///  3. Sinon : terminée.
class PrepareCartographerPuzzles {
  /// Au-delà, le Repérage prend un échantillon des Éléments les moins connus.
  static const screeningLimit = 20;

  /// Éléments déjà solides que le Repérage recontrôle quand même : un « connu » stocké vieillit.
  static const solidSpotChecks = 2;

  final RandomSource random;

  PrepareCartographerPuzzles({required this.random});

  List<CartographerPuzzle> call(PrepareCartographerRequest request, List<PlayedPuzzle> history) {
    if (history.isEmpty) return [_screening(request)];
    final first = history.first;
    if (first.puzzle is! Screening) {
      throw ArgumentError('Une Partie commence par le Repérage, pas par ${first.puzzle.runtimeType}.');
    }
    if (history.length > 1) return [];
    return _studiesAndDelayedRecall(request, first);
  }

  // --- Repérage ---

  Screening _screening(PrepareCartographerRequest request) {
    final mastery = request.mastery;
    final baseMapId = request.baseMap.id;
    final eligible = [
      for (final item in request.baseMap.items) if (_kindsFor(item, request.profile).isNotEmpty) item,
    ];
    if (eligible.isEmpty) {
      throw ArgumentError('Aucun Élément de ${request.baseMap.id} ne convient au Profil.');
    }

    int itemRank(Item item) => _kindsFor(item, request.profile)
        .map((k) => Knowledge.rank(mastery.of(baseMapId, item.id, k)))
        .reduce((a, b) => a < b ? a : b);

    // Du moins connu au mieux connu : le plus faible des Liens d'un Élément le classe. Les
    // Éléments solides ne sont recontrôlés que par quelques sondages.
    final unknown = _shuffled([for (final i in eligible) if (itemRank(i) == 0) i]);
    final shaky = _shuffled([for (final i in eligible) if (itemRank(i) == 1) i]);
    final solid = _shuffled([for (final i in eligible) if (itemRank(i) >= 2) i]).take(solidSpotChecks);
    final selected = _shuffled([...unknown, ...shaky, ...solid].take(screeningLimit));

    return Screening(
      language: request.language,
      questions: [
        for (final item in selected) _question(request, item, _kindToAsk(request, item)),
      ],
    );
  }

  /// Le genre de Lien à poser pour un Élément. Un joueur qui connaît déjà les positions se voit
  /// poser les capitales, sans que le Profil change. Mais s'il reste à la fois un genre nouveau
  /// et un genre fragile, on tire entre les deux à pile ou face : sinon un Lien fragile ne serait
  /// reposé qu'après avoir épuisé tous les autres genres, et ne pourrait presque jamais devenir
  /// solide (ni être rétrogradé s'il est oublié).
  LinkKind _kindToAsk(PrepareCartographerRequest request, Item item) {
    final kinds = _kindsFor(item, request.profile);
    int rank(LinkKind k) => Knowledge.rank(request.mastery.of(request.baseMap.id, item.id, k));
    final unknown = [for (final k in kinds) if (rank(k) == 0) k];
    final shaky = [for (final k in kinds) if (rank(k) == 1) k];
    if (unknown.isNotEmpty && shaky.isNotEmpty) {
      return _pick(random.nextInt(2) == 0 ? shaky : unknown);
    }
    if (unknown.isNotEmpty) return _pick(unknown);
    if (shaky.isNotEmpty) return _pick(shaky);
    return _pick(kinds);
  }

  // --- Études-éclair et Bilan ---

  List<CartographerPuzzle> _studiesAndDelayedRecall(PrepareCartographerRequest request, PlayedPuzzle screening) {
    final missed = _shuffled([
      for (var i = 0; i < screening.puzzle.questions.length; i++)
        if (screening.verdicts[i] != AnswerVerdict.exact) screening.puzzle.questions[i],
    ]);
    if (missed.isEmpty) return [];

    final level = request.level;
    final batches = <List<RecallQuestion>>[];
    for (var start = 0; start < missed.length && batches.length < level.maxStudyCycles; start += level.itemCount) {
      final end = start + level.itemCount < missed.length ? start + level.itemCount : missed.length;
      batches.add(missed.sublist(start, end));
    }

    final studies = [
      for (final batch in batches)
        FlashStudy(
          language: request.language,
          studySeconds: level.studySeconds,
          distractionSeconds: level.distractionSeconds,
          questions: [for (final q in batch) _question(request, request.baseMap.itemById(q.itemId), q.kind)],
        ),
    ];

    // Le Bilan redemande les mêmes Liens, en commençant par les plus anciennement étudiés.
    final studied = [for (final batch in batches) ..._shuffled(batch)];
    final count = level.delayedRecallCount < studied.length ? level.delayedRecallCount : studied.length;
    final delayed = DelayedRecall(
      language: request.language,
      questions: [
        for (final q in studied.take(count)) _question(request, request.baseMap.itemById(q.itemId), q.kind),
      ],
    );
    return [...studies, delayed];
  }

  // --- Questions ---

  List<LinkKind> _kindsFor(Item item, CartographerProfile profile) =>
      [for (final kind in LinkKind.supported) if (profile.linkKinds.contains(kind) && kind.appliesTo(item)) kind];

  RecallQuestion _question(PrepareCartographerRequest request, Item item, LinkKind kind) {
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
  List<String> _choices(PrepareCartographerRequest request, Item item, LinkKind kind) {
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
