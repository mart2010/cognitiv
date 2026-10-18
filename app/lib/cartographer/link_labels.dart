import 'package:cartographer/cartographer.dart' show Facet, LinkKind;

/// Libellé français d'un genre de Lien, pour l'écran des réglages et les suggestions.
String linkKindLabel(LinkKind kind) {
  return switch ((kind.cue, kind.answer)) {
    (Facet.position, Facet.name) => 'Nommer un pays montré sur la carte',
    (Facet.shape, Facet.name) => 'Reconnaître un pays à sa forme',
    (Facet.flag, Facet.name) => 'Reconnaître un pays à son drapeau',
    (Facet.capital, Facet.name) => "Retrouver le pays d'une capitale",
    (Facet.name, Facet.capital) => "Retrouver la capitale d'un pays",
    (Facet.flag, Facet.capital) => "Retrouver la capitale d'un drapeau",
    (Facet.position, Facet.capital) => "Nommer la capitale d'un pays montré",
    (Facet.name, Facet.position) => 'Placer un pays sur la carte',
    (Facet.flag, Facet.position) => "Placer le pays d'un drapeau",
    (Facet.capital, Facet.position) => "Placer le pays d'une capitale",
    _ => '${kind.cue.name} → ${kind.answer.name}',
  };
}

/// Les genres de Lien que l'app sait poser aujourd'hui : ceux sans drapeau (les données n'en ont
/// pas encore, et aucune vue ne sait l'afficher).
List<LinkKind> get playableLinkKinds => [
  for (final kind in LinkKind.supported)
    if (kind.cue != Facet.flag && kind.answer != Facet.flag) kind,
];
