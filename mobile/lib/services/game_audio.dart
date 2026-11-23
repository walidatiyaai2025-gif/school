import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum GameSound { tap, correct, incorrect, hint, win, lose, draw }

/// Locally synthesized chimes. No copyrighted recordings or network calls.
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
      await player.play(BytesSource(makeWav(sound)), volume: .5);
    } catch (_) {
      try { await SystemSound.play(SystemSoundType.click); } catch (_) {}
    }
  }

  static Uint8List makeWav(GameSound effect) {
    const rate = 22050;
    final notes = switch (effect) {
      GameSound.tap => <int>[560],
      GameSound.correct => <int>[580, 760],
      GameSound.incorrect => <int>[360, 280],
      GameSound.hint => <int>[680, 840],
      GameSound.win => <int>[523, 659, 784, 1046],
      GameSound.lose => <int>[460, 380, 310],
      GameSound.draw => <int>[480, 590, 480],
    };
    final noteDuration = effect == GameSound.win ? .115 : .09;
    final framesPerNote = (rate * noteDuration).round();
    final total = framesPerNote * notes.length;
    final bytes = Uint8List(44 + total * 2);
    final d = ByteData.view(bytes.buffer);
    void word(int o, int v) => d.setUint16(o, v, Endian.little);
    void dword(int o, int v) => d.setUint32(o, v, Endian.little);
    void ascii(int start, String v) {
      for (var i = 0; i < v.length; i++) { bytes[start+i] = v.codeUnitAt(i); }
    }
    ascii(0,'RIFF'); dword(4,bytes.length-8);
    ascii(8,'WAVE'); ascii(12,'fmt '); dword(16,16);
    word(20,1);word(22,1);dword(24,rate);
    dword(28,rate*2);word(32,2);word(34,16);
    ascii(36,'data');dword(40,total*2);
    for (var i = 0; i < total; i++) {
      final n = i ~/ framesPerNote;
      final x = (i % framesPerNote) / framesPerNote;
      final envelope = math.min(1.0,x*24)*math.min(1.0,(1-x)*15);
      final t = (i % framesPerNote) / rate;
      final wave = math.sin(2*math.pi*notes[n]*t);
      d.setInt16(44+i*2,(wave*envelope*9000).round(),Endian.little);
    }
    return bytes;
  }
  static Future<void> close() async {
    final p = _player;
    _player = null;
    await p?.dispose();
  }
}
