import 'package:flutter/material.dart';

import '../core/brand.dart';
import '../games/game_stages.dart';

/// Compact, accessible, unlocked-by-completion stage picker.
class GameStageStrip extends StatelessWidget {
  const GameStageStrip({
    super.key, required this.current, required this.unlocked,
    required this.english, required this.onSelect,
  });

  final int current;
  final int unlocked;
  final bool english;
  final ValueChanged<int> onSelect;

  @override Widget build(BuildContext context) {
    return Row(children: [
      for (var stage = 1; stage <= GameStages.count; stage++) ...[
        if (stage > 1) const SizedBox(width: 7),
        Expanded(child: SizedBox(height: 45,
          child: OutlinedButton(
            key: Key('game-stage-$stage'),
            onPressed: stage <= unlocked ? () => onSelect(stage) : null,
            style: OutlinedButton.styleFrom(
              backgroundColor: stage == current
                  ? Brand.blue : const Color(0xFFF2F5FB),
              foregroundColor: stage == current ? Colors.white : Brand.navy,
              disabledForegroundColor: const Color(0xFF9BA9C0),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              side: BorderSide(color: stage == current
                  ? Brand.blue : const Color(0xFFD6E1F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center, children: [
                if (stage > unlocked) ...[
                  const Icon(Icons.lock_outline, size: 13),
                  const SizedBox(width: 3),
                ] else if (stage < unlocked) ...[
                  const Icon(Icons.check_circle_outline, size: 13),
                  const SizedBox(width: 3),
                ],
                Flexible(child: Text(
                  english ? 'Level $stage' : 'مرحلة $stage',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5,
                    fontWeight: FontWeight.w800),
                )),
              ]),
          ),
        )),
      ],
    ]);
  }
}
