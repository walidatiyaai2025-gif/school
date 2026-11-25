import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum GameSound { tap, correct, incorrect, hint, win, lose, draw }

/// Short non-melodic UI/game effects. No soundtrack, chord sequences,
/// looping audio or downloaded assets. All samples are synthesized offline.
class GameAudio {
  static bool enabled = true;
  static AudioPlayer? _player;

  static void play(GameSound sound) {
    if (!enabled) return;
    unawaited(_play(sound));
  }

  static Future<void> _play(GameSound sound) async {
    try {
      final player = _player ??= AudioPlayer();
      await player.stop();
      await player.play(BytesSource(makeWav(sound)), volume: .36);
    } catch (_) {
      // A missing native audio channel must not interrupt a timed game.
      try { await SystemSound.play(SystemSoundType.click); } catch (_) {}
    }
  }

  /// One brief, percussive frequency sweep + filtered texture per event.
  /// Unlike a melody there are no ordered musical notes or rhythmic phrases.
  static Uint8List makeWav(GameSound effect) {
    const sampleRate = 22050;
    final (duration, startHz, endHz, texture) = switch (effect) {
      GameSound.tap => (.048, 820.0, 540.0, .18),
      GameSound.correct => (.115, 950.0, 1320.0, .10),
      GameSound.incorrect => (.135, 490.0, 220.0, .24),
      GameSound.hint => (.135, 1200.0, 1570.0, .15),
      GameSound.win => (.210, 1230.0, 1780.0, .24),
      GameSound.lose => (.190, 480.0, 190.0, .30),
      GameSound.draw => (.140, 740.0, 650.0, .18),
    };
    final samples = (sampleRate * duration).round();
    final bytes = Uint8List(44 + samples * 2);
    final data = ByteData.view(bytes.buffer);
    void u16(int offset, int value) =>
        data.setUint16(offset, value, Endian.little);
    void u32(int offset, int value) =>
        data.setUint32(offset, value, Endian.little);
    void tag(int offset, String text) {
      for (var i = 0; i < text.length; i++) {
        bytes[offset + i] = text.codeUnitAt(i);
      }
    }

    tag(0, 'RIFF');
    u32(4, bytes.length - 8);
    tag(8, 'WAVE');
    tag(12, 'fmt ');
    u32(16, 16);
    u16(20, 1);
    u16(22, 1);
    u32(24, sampleRate);
    u32(28, sampleRate * 2);
    u16(32, 2);
    u16(34, 16);
    tag(36, 'data');
    u32(40, samples * 2);
    var phase = 0.0;
    var noiseState = 7241;
    for (var i = 0; i < samples; i++) {
      final progress = i / samples;
      final frequency = startHz + (endHz - startHz) * progress;
      phase += 2 * math.pi * frequency / sampleRate;
      // Deterministic texture: stable tests and no external sound library.
      noiseState = (noiseState * 1103515245 + 12345) & 0x7fffffff;
      final noise = (noiseState / 0x3fffffff) - 1;
      final attack = math.min(1.0, progress * 65);
      final release = math.pow(1 - progress, 3).toDouble();
      final envelope = attack * release;
      final sample = math.sin(phase) * (1 - texture) + noise * texture;
      data.setInt16(44 + i * 2,
          (sample * envelope * 8500).round().clamp(-32768, 32767).toInt(),
          Endian.little);
    }
    return bytes;
  }

  static Future<void> close() async {
    final player = _player;
    _player = null;
    await player?.dispose();
  }
}
