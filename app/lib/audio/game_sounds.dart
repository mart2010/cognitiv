import 'package:audioplayers/audioplayers.dart';

/// Port audio de l'app (ADR 0005 : l'audio reste côté app, le domaine n'émet que des
/// faits que l'interface traduit en sons). Les tests utilisent `SilentGameSounds`.
abstract class GameSounds {
  /// Geste discret : poser une forme, choisir une réponse.
  void tap();

  /// Réussite d'une Énigme, célébrée fortement.
  void success();

  /// Mauvaise réponse, volontairement douce.
  void failure();
}

class SilentGameSounds implements GameSounds {
  const SilentGameSounds();

  @override
  void tap() {}

  @override
  void success() {}

  @override
  void failure() {}
}

/// Sons synthétisés par `tool/generate_sounds.py`, joués avec `audioplayers`. Un lecteur
/// par son pour qu'un clic ne coupe pas la fanfare. Une erreur audio (pas de sortie,
/// plugin absent) ne doit jamais casser le jeu.
class AudioPlayersGameSounds implements GameSounds {
  final _tap = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
  final _success = AudioPlayer();
  final _failure = AudioPlayer();

  Future<void> _play(AudioPlayer player, String asset, double volume) async {
    try {
      await player.stop();
      await player.setVolume(volume);
      await player.play(AssetSource('sounds/$asset'));
    } catch (_) {}
  }

  @override
  void tap() => _play(_tap, 'tap.wav', 0.5);

  @override
  void success() => _play(_success, 'success.wav', 1.0);

  @override
  void failure() => _play(_failure, 'wrong.wav', 0.6);
}
