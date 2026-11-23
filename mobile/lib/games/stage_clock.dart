import 'dart:async';
import 'package:flutter/foundation.dart';

/// A finite, pauseable countdown used by each individual game.
class StageClock {
  final ValueNotifier<int> seconds = ValueNotifier<int>(0);
  Timer? _ticker;
  VoidCallback? _expired;
  bool _done = false;

  void start(int totalSeconds, VoidCallback onExpired) {
    stop();
    _done = false;
    _expired = onExpired;
    seconds.value = totalSeconds.clamp(1, 3600).toInt();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (seconds.value <= 0 || _done) return;
      seconds.value--;
      if (seconds.value == 0) {
        _done = true;
        stop();
        _expired?.call();
      }
    });
  }

  /// Small word-find bonus; timer remains finite and capped.
  void addSeconds(int bonus) {
    if (bonus <= 0 || seconds.value <= 0 || _done) return;
    seconds.value = (seconds.value + bonus).clamp(1, 300).toInt();
  }

  void pause() { _ticker?.cancel(); _ticker = null; }
  void resume() {
    if (seconds.value == 0 || _ticker != null || _expired == null) return;
    final remaining = seconds.value;
    final callback = _expired!;
    start(remaining, callback);
  }
  void stop() { _ticker?.cancel(); _ticker = null; }
  void dispose() { stop(); seconds.dispose(); }
}
