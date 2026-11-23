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
    // The route can remain mounted after Navigator.pop resolves.
    // Let the dialog State own its text controller until final disposal.
    final choice = await showClean3DDialog<int>(
      context: context,
      builder: (_) => _StageJumpDialog(
        current: current, unlocked: unlocked, english: english),
    );
    if (!context.mounted || choice == null) return;
    if (choice >= 1 && choice <= unlocked &&
        choice <= GameStages.count) {
      onSelect(choice);
    }
  }
}

class _StageJumpDialog extends StatefulWidget {
  const _StageJumpDialog({
    required this.current, required this.unlocked, required this.english});
  final int current, unlocked;
  final bool english;

  @override State<_StageJumpDialog> createState() => _StageJumpDialogState();
}

class _StageJumpDialogState extends State<_StageJumpDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.current.toString());

  @override void dispose() {
    // Disposed with the dialog route, not when Navigator.pop completes.
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 1 ||
        value > widget.unlocked || value > GameStages.count) return;
    Navigator.of(context).pop(value);
  }

  @override Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.english ? 'Jump to a level' : 'انتقل إلى مرحلة'),
    content: TextField(
      key: const Key('game-stage-input'),
      controller: _controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        helperText: widget.english
            ? 'Unlocked: 1–' + widget.unlocked.toString() + ' of 1000'
            : 'المفتوح: 1–' + widget.unlocked.toString() + ' من 1000'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(widget.english ? 'Cancel' : 'إلغاء')),
      FilledButton(
        key: const Key('game-stage-submit'),
        onPressed: _submit,
        child: Text(widget.english ? 'Go' : 'اذهب')),
    ],
  );
}
