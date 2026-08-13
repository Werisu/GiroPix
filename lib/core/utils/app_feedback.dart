import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Feedback ao confirmar um lançamento (som + vibração).
class AppFeedback {
  AppFeedback._();

  static final AudioPlayer _player = AudioPlayer();
  static bool _ready = false;

  static Future<void> lancamentoSalvo() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}

    try {
      if (!_ready) {
        await _player.setReleaseMode(ReleaseMode.stop);
        await _player.setVolume(0.85);
        _ready = true;
      }
      await _player.stop();
      await _player.play(AssetSource('sounds/lancamento.wav'));
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }
}
