import 'package:audioplayers/audioplayers.dart';

class AudioHelper {
  static final AudioPlayer _typingPlayer = AudioPlayer();
  static final AudioPlayer _msgPlayer = AudioPlayer();

  // Static player for typing to avoid garbage collection and lag
  static Future<void> playTyping() async {
    try {
      // Seek to beginning and play if already playing, or just play
      await _typingPlayer.stop();
      await _typingPlayer.setVolume(0.35);
      await _typingPlayer.play(AssetSource('audio/typing.wav'));
    } catch (_) {}
  }

  static Future<void> playMessageReceived() async {
    try {
      await _msgPlayer.stop();
      await _msgPlayer.setVolume(0.8);
      await _msgPlayer.play(AssetSource('audio/message.wav'));
    } catch (_) {}
  }

  static Future<void> startLooping(AudioPlayer player, String assetPath) async {
    try {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0.7);
      await player.play(AssetSource(assetPath));
    } catch (_) {}
  }

  static Future<void> stopPlayer(AudioPlayer player) async {
    try {
      await player.stop();
    } catch (_) {}
  }
}
