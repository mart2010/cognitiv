import 'base_map.dart';
import 'facet.dart';
import 'item.dart';

/// L'action du joueur pour répondre (`games/recall/CONTEXT.md`). Première tranche :
/// placer sur la Scène, ou nommer (saisir un texte).
enum Gesture { place, naming }

/// Le genre d'un Lien : de quelle Facette (Indice) à quelle Facette (Réponse). Le Geste en
/// découle : une Réponse en Position se place, une Réponse textuelle se nomme.
class LinkKind {
  final Facet cue;
  final Facet answer;
  const LinkKind(this.cue, this.answer);

  Gesture get gesture => answer == Facet.position ? Gesture.place : Gesture.naming;

  bool appliesTo(BaseMap baseMap, Item item) => baseMap.hasFacet(item, cue) && baseMap.hasFacet(item, answer);

  /// Les genres de Lien de la première tranche.
  static const supported = [
    LinkKind(Facet.position, Facet.name),
    LinkKind(Facet.shape, Facet.name),
    LinkKind(Facet.flag, Facet.name),
    LinkKind(Facet.capital, Facet.name),
    LinkKind(Facet.name, Facet.capital),
    LinkKind(Facet.flag, Facet.capital),
    LinkKind(Facet.position, Facet.capital),
    LinkKind(Facet.name, Facet.position),
    LinkKind(Facet.flag, Facet.position),
    LinkKind(Facet.capital, Facet.position),
  ];

  @override
  bool operator ==(Object other) => other is LinkKind && other.cue == cue && other.answer == answer;

  @override
  int get hashCode => Object.hash(cue, answer);

  @override
  String toString() => 'LinkKind(${cue.name} -> ${answer.name})';
}
