import '../domain_services/text_matcher.dart';
import '../entities/cartographer_answer.dart';
import '../entities/cartographer_puzzle.dart';
import '../entities/item.dart';
import '../entities/knowledge.dart';
import '../entities/link.dart';
import '../entities/played_puzzle.dart';
import '../entities/recall_aid.dart';
import '../entities/recall_question.dart';
import 'ports/random_source.dart';
import 'puzzle_preparer.dart';

/// Cas d'usage « préparer les énigmes d'un niveau » du contrat jeu/plateforme (ADR 0004),
/// appelable plusieurs fois au fil de la Partie (ADR 0010). La plateforme le rappelle quand elle
/// n'a plus d'énigme à faire jouer, avec l'historique des énigmes jouées ; une liste vide
/// veut dire « Partie terminée ».
///
///  1. Historique vide : le **Repérage**, une question par Élément qui mérite d'être posé.
///  2. Repérage joué : les **Études-éclair** des Éléments ratés (au plus `maxStudyCycles` Lots),
///     suivies du **Bilan** qui les redemande. Rien si le joueur n'a rien raté.
///  3. Sinon : terminée.
class PrepareCartographerPuzzles implements PuzzlePreparer {
  /// Au-delà, le Repérage prend un échantillon des Éléments les moins connus.
  static const screeningLimit = 20;

  /// Éléments déjà solides que le Repérage recontrôle quand même : un « connu » stocké vieillit.
  static const solidSpotChecks = 2;

  final RandomSource random;

  PrepareCartographerPuzzles({required this.random});

  @override
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
      for (final item in _pool(request)) if (_kindsFor(request, item).isNotEmpty) item,
    ];
    if (eligible.isEmpty) {
      throw ArgumentError('Aucun Élément de ${request.baseMap.id} ne convient au Profil.');
    }

    int itemRank(Item item) => _kindsFor(request, item)
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
    final kinds = _kindsFor(request, item);
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

  /// Les Éléments des Catégories que le joueur a activées.
  List<Item> _pool(PrepareCartographerRequest request) =>
      [for (final item in request.baseMap.items) if (request.profile.categories.contains(item.category)) item];

  List<LinkKind> _kindsFor(PrepareCartographerRequest request, Item item) => [
        for (final kind in LinkKind.supported)
          if (request.profile.linkKinds.contains(kind) && kind.appliesTo(request.baseMap, item)) kind,
      ];

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
  /// Catégorie, sans jamais proposer un texte que la bonne réponse accepte aussi.
  List<String> _choices(PrepareCartographerRequest request, Item item, LinkKind kind) {
    final facet = kind.answer;
    final language = request.language;
    final baseMap = request.baseMap;
    final correct = baseMap.textFor(item, facet, language);
    final forbidden = baseMap.acceptedTexts(item, facet).map(TextMatcher.normalize).toSet();
    final distractors = <String>{};
    for (final other in _shuffled([
      for (final i in baseMap.itemsOf(item.category)) if (i.id != item.id && baseMap.hasFacet(i, facet)) i,
    ])) {
      final text = baseMap.textFor(other, facet, language);
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
