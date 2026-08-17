import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Feedback ao confirmar um lançamento (som + vibração).
class AppFeedback {
  AppFeedback._();

  static final AudioPlayer _player = AudioPlayer();
  static bool _ready = false;

  static Future<void> lancamentoSalvo() async {
    await Future.wait([
      _vibrar(),
      _tocarSom(),
    ]);
  }

  static Future<void> _vibrar() async {
    if (!kIsWeb) {
      try {
        final temAmplitude = await Vibration.hasAmplitudeControl();
        if (temAmplitude) {
          await Vibration.vibrate(duration: 140, amplitude: 255);
        } else {
          await Vibration.vibrate(duration: 140);
        }
        return;
      } catch (_) {
        try {
          await Vibration.vibrate(duration: 140);
          return;
        } catch (_) {}
      }
    }

    try {
      await HapticFeedback.heavyImpact();
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  static Future<void> _tocarSom() async {
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
