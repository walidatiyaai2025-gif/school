import 'package:flutter/material.dart';
import '../core/brand.dart';
import '../games/game_stages.dart';
import 'clean_3d_dialog.dart';

/// Virtual stage navigation: never create 1000 widgets at once.
class GameStageStrip extends StatelessWidget {
  const GameStageStrip({super.key, required this.current,
    required this.unlocked, required this.english, required this.onSelect});
  final int current;
  final int unlocked;
  final bool english;
  final ValueChanged<int> onSelect;

  @override Widget build(BuildContext context) {
    final stages = <int>[
      if (current > 1) current - 1,
      current,
      if (current < GameStages.count) current + 1,
    ];
    return Row(children: [
      for (final stage in stages) ...[
        if (stage != stages.first) const SizedBox(width: 7),
        Expanded(child: SizedBox(height: 45, child: OutlinedButton(
          key: Key('game-stage-$stage'),
          onPressed: stage <= unlocked ? () => onSelect(stage) : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: stage == current ? Brand.blue
                : const Color(0xFFF2F5FB),
            foregroundColor: stage == current ? Colors.white : Brand.navy,
            disabledForegroundColor: const Color(0xFF9BA9C0),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            side: BorderSide(color: stage == current ? Brand.blue
                : const Color(0xFFD6E1F0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (stage > unlocked) const Icon(Icons.lock_outline, size: 13),
            Flexible(child: Text(
              english ? 'Level $stage' : 'مرحلة $stage',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5,
                fontWeight: FontWeight.w800))),
          ]),
        ))),
      ],
      const SizedBox(width: 5),
      IconButton(
        key: const Key('game-stage-jump'),
        tooltip: english ? 'Choose an unlocked level' : 'اختار مرحلة مفتوحة',
        icon: const Icon(Icons.grid_view_rounded, color: Brand.blue),
        onPressed: () => _jumpToStage(context),
      ),
    ]);
  }

  Future<void> _jumpToStage(BuildContext context) async {
    final controller = TextEditingController(text: current.toString());
    final choice = await showClean3DDialog<int>(context: context,
      builder: (ctx) => AlertDialog(
        title: Text(english ? 'Jump to a level' : 'انتقل إلى مرحلة'),
        content: TextField(
          key: const Key('game-stage-input'),
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            helperText: english
                ? 'Unlocked: 1–$unlocked of 1000'
                : 'المفتوح: 1–$unlocked من 1000'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text(english ? 'Cancel' : 'إلغاء')),
          FilledButton(onPressed: () {
            final value = int.tryParse(controller.text.trim());
            if (value != null && value >= 1 && value <= unlocked) {
              Navigator.pop(ctx, value);
            }
          }, child: Text(english ? 'Go' : 'اذهب')),
        ],
      ),
    );
    controller.dispose();
    if (choice != null) onSelect(choice);
  }
}
