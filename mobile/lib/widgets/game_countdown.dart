import 'package:flutter/material.dart';
import '../core/brand.dart';
import '../games/stage_clock.dart';

class GameCountdown extends StatelessWidget {
  const GameCountdown({super.key, required this.clock});
  final StageClock clock;

  @override Widget build(BuildContext context) =>
      ValueListenableBuilder<int>(valueListenable: clock.seconds,
        builder: (context, secs, _) {
          final warning = secs <= 15;
          final time = (secs ~/ 60).toString().padLeft(2, '0') + ':' +
              (secs % 60).toString().padLeft(2, '0');
          return AnimatedContainer(
            key: const Key('game-timer'),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero : const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 11),
            decoration: BoxDecoration(
              color: warning ? const Color(0xFFFFE6E6)
                : const Color(0xFFE2EDFF),
              borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.timer_rounded, size: 19,
                color: warning ? const Color(0xFFC62828) : Brand.blue),
              const SizedBox(width: 4),
              Text(time, style: TextStyle(
                fontWeight: FontWeight.w900,
                color: warning ? const Color(0xFFC62828) : Brand.navy)),
            ]),
          );
        });
}
