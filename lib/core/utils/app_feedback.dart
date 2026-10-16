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
      _tocarSom('sounds/lancamento.wav', volume: 0.85),
    ]);
  }

  /// Mesmo clique, mais alto e com vibração mais cheia. Corrida acima da média.
  static Future<void> lancamentoPesado() async {
    await Future.wait([
      _vibrar(duration: 220),
      _tocarSom('sounds/lancamento_pesado.wav', volume: 1),
    ]);
  }

  /// Som e vibração mais longos, só quando o bruto do dia cruza a meta.
  static Future<void> metaBatida() async {
    await Future.wait([
      _vibrarMeta(),
      _tocarSom(
        'sounds/meta_batida.wav',
        volume: 1,
        fallback: SystemSoundType.alert,
      ),
    ]);
  }

  static Future<void> _vibrar({int duration = 140}) async {
    if (!kIsWeb) {
      try {
        final temAmplitude = await Vibration.hasAmplitudeControl();
        if (temAmplitude) {
          await Vibration.vibrate(duration: duration, amplitude: 255);
        } else {
          await Vibration.vibrate(duration: duration);
        }
        return;
      } catch (_) {
        try {
          await Vibration.vibrate(duration: duration);
          return;
        } catch (_) {}
      }
    }

    try {
      await HapticFeedback.heavyImpact();
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  static Future<void> _vibrarMeta() async {
    const padrao = [0, 80, 50, 80, 50, 260];
    if (!kIsWeb) {
      try {
        final temAmplitude = await Vibration.hasAmplitudeControl();
        if (temAmplitude) {
          await Vibration.vibrate(
            pattern: padrao,
            intensities: const [0, 180, 0, 255, 0, 255],
          );
        } else {
          await Vibration.vibrate(pattern: padrao);
        }
        return;
      } catch (_) {
        try {
          await Vibration.vibrate(duration: 420);
          return;
        } catch (_) {}
      }
    }

    try {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 90));
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 90));
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  static Future<void> _tocarSom(
    String asset, {
    required double volume,
    SystemSoundType fallback = SystemSoundType.click,
  }) async {
    try {
      if (!_ready) {
        await _player.setReleaseMode(ReleaseMode.stop);
        _ready = true;
      }
      await _player.setVolume(volume);
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {
      try {
        await SystemSound.play(fallback);
      } catch (_) {}
    }
  }
}
