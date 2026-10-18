import 'knowledge.dart';
import 'link.dart';

/// Identifie un Lien dans la Maîtrise : une Carte de base, un Élément, un genre de Lien.
class MasteryKey {
  final String baseMapId;
  final String itemId;
  final LinkKind kind;
  const MasteryKey(this.baseMapId, this.itemId, this.kind);

  @override
  bool operator ==(Object other) =>
      other is MasteryKey && other.baseMapId == baseMapId && other.itemId == itemId && other.kind == kind;

  @override
  int get hashCode => Object.hash(baseMapId, itemId, kind);

  @override
  String toString() => 'MasteryKey($baseMapId, $itemId, $kind)';
}

/// Ce que le jeu sait d'un joueur, Lien par Lien, d'une Partie à l'autre (`games/cartographer/CONTEXT.md`,
/// ADR 0009). Valeur immuable : chaque mise à jour en rend une nouvelle. Donnée opaque pour
/// la plateforme, qui la stocke et la rend sans la lire.
class Mastery {
  final Map<MasteryKey, Knowledge> _states;

  Mastery._(Map<MasteryKey, Knowledge> states) : _states = Map.unmodifiable(states);

  factory Mastery(Map<MasteryKey, Knowledge> states) => Mastery._(states);

  static final empty = Mastery._(const {});

  Knowledge? of(String baseMapId, String itemId, LinkKind kind) => _states[MasteryKey(baseMapId, itemId, kind)];

  Mastery set(MasteryKey key, Knowledge knowledge) => Mastery._({..._states, key: knowledge});

  /// Efface la Maîtrise d'une seule Carte de base (le joueur repart de zéro sur celle-là).
  Mastery withoutBaseMap(String baseMapId) =>
      Mastery._({for (final e in _states.entries) if (e.key.baseMapId != baseMapId) e.key: e.value});

  Map<MasteryKey, Knowledge> get states => _states;

  int get length => _states.length;
  bool get isEmpty => _states.isEmpty;
}
