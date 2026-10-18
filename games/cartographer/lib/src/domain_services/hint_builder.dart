/// Construit l'aide « première lettre et longueur » : « A______ » pour « Asunción ». Les
/// espaces, tirets et apostrophes sont conservés pour que la forme du mot se lise.
abstract final class HintBuilder {
  static String firstLetter(String expected) {
    final chars = expected.split('');
    final first = chars.indexWhere((c) => RegExp(r'\p{L}|\p{N}', unicode: true).hasMatch(c));
    return [
      for (var i = 0; i < chars.length; i++)
        if (i <= first || !RegExp(r'\p{L}|\p{N}', unicode: true).hasMatch(chars[i])) chars[i] else '_',
    ].join();
  }
}
