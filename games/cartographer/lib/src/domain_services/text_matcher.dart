/// Compare un texte saisi à des réponses attendues, en tolérant la casse, les accents, la
/// ponctuation et de petites fautes de frappe (`games/cartographer/CONTEXT.md`, Nommer).
abstract final class TextMatcher {
  static const _folding = {
    'àáâãäåā': 'a', 'çćč': 'c', 'èéêëēě': 'e', 'ìíîïī': 'i', 'ñń': 'n',
    'òóôõöøō': 'o', 'ùúûüū': 'u', 'ýÿ': 'y', 'š': 's', 'ž': 'z', 'ß': 'ss',
    'œ': 'oe', 'æ': 'ae',
  };

  /// Minuscules, sans accents, réduit aux lettres et chiffres : « São Tomé » = « sao tome ».
  static String normalize(String text) {
    final buffer = StringBuffer();
    for (final char in text.toLowerCase().split('')) {
      final folded = _folding.entries.where((e) => e.key.contains(char)).map((e) => e.value).firstOrNull;
      buffer.write(folded ?? char);
    }
    return buffer.toString().replaceAll(RegExp('[^a-z0-9]'), '');
  }

  static int editDistance(String a, String b) {
    var previous = List<int>.generate(b.length + 1, (j) => j);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        current[j] = [previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost].reduce((x, y) => x < y ? x : y);
      }
      previous = current;
    }
    return previous[b.length];
  }

  /// Fautes tolérées selon la longueur du mot attendu : aucune pour un mot court, une à
  /// partir de 5 lettres, deux à partir de 9.
  static int tolerance(String normalizedExpected) =>
      normalizedExpected.length >= 9 ? 2 : (normalizedExpected.length >= 5 ? 1 : 0);

  /// `true` si [input] correspond à l'une des réponses [expected]. Un texte qui est
  /// exactement une autre réponse plausible ([confusable], ex. le nom d'un autre pays)
  /// n'est jamais toléré comme faute de frappe : « Guyane » n'est pas « Guyana ».
  static bool matches(String input, Set<String> expected, {Set<String> confusable = const {}}) {
    final typed = normalize(input);
    if (typed.isEmpty) return false;
    final accepted = expected.map(normalize).toSet();
    if (accepted.contains(typed)) return true;
    if (confusable.map(normalize).contains(typed)) return false;
    return accepted.any((e) => editDistance(typed, e) <= tolerance(e));
  }
}
