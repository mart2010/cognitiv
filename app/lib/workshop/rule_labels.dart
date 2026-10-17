import 'package:workshop/workshop.dart' as workshop;

/// Textes affichés pour les Familles de règles (traduction FR/EN à venir).
class RuleFamilyLabel {
  final String name;
  final String description;

  /// Familles repérées en test comme peu intuitives : désactivées par défaut.
  final bool advanced;

  const RuleFamilyLabel(this.name, this.description, {this.advanced = false});
}

RuleFamilyLabel labelOf(workshop.RuleFamily family) => switch (family) {
  workshop.RuleFamily.mirror => const RuleFamilyLabel(
    'Miroir',
    'La grille est retournée, de gauche à droite ou de haut en bas.',
  ),
  workshop.RuleFamily.rotation => const RuleFamilyLabel(
    'Rotation',
    'La grille tourne d’un quart de tour ou d’un demi-tour.',
  ),
  workshop.RuleFamily.transposition => const RuleFamilyLabel(
    'Transposition',
    'La grille est reflétée selon une diagonale ; lignes et colonnes sont échangées.',
  ),
  workshop.RuleFamily.cyclicShift => const RuleFamilyLabel(
    'Décalage cyclique',
    'Les lignes ou les colonnes glissent d’un cran, en boucle.',
  ),
  workshop.RuleFamily.sliding => const RuleFamilyLabel(
    'Taquin',
    'Les cases vides avancent d’un cran dans une même direction, en échangeant leur place avec leur voisine.',
  ),
  workshop.RuleFamily.packing => const RuleFamilyLabel(
    'Tassement',
    'Toutes les formes se tassent contre un côté et comblent les cases vides.',
  ),
  workshop.RuleFamily.colorCycle => const RuleFamilyLabel(
    'Cycle de couleur',
    'Les couleurs avancent d’un cran dans un ordre fixe.',
    advanced: true,
  ),
  workshop.RuleFamily.shapeCycle => const RuleFamilyLabel(
    'Cycle de forme',
    'Les formes avancent d’un cran dans un ordre fixe.',
    advanced: true,
  ),
  workshop.RuleFamily.conditional => const RuleFamilyLabel(
    'Conditionnelle',
    'Toutes les cases d’une même couleur prennent la même forme.',
    advanced: true,
  ),
};
