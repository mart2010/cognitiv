/// Langue d'affichage des noms (texte du joueur, ADR 0007 : les textes passent par la
/// traduction FR/EN, les noms de code restent en anglais).
enum NameLanguage { en, fr }

/// Un nom dans chaque langue prise en charge.
class LocalizedText {
  final String en;
  final String fr;
  const LocalizedText({required this.en, required this.fr});

  String of(NameLanguage language) => switch (language) {
        NameLanguage.en => en,
        NameLanguage.fr => fr,
      };

  Set<String> get all => {en, fr};
}
