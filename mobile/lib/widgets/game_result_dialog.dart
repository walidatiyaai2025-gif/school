import 'package:flutter/material.dart';
import '../core/brand.dart';
import '../services/game_audio.dart';

enum GameOutcome { win, loss, draw, timeout }
enum GameResultAction { next, retry, list }

/// Clean 3D animated result sheet for all three games.
class GameResultDialog extends StatefulWidget {
  const GameResultDialog({super.key, required this.game,
    required this.outcome, required this.english, required this.result,
    required this.stage, required this.stars, required this.remaining,
    required this.hasNext, this.pointsEarned = 0, this.badgeEarned,
    this.trophyUnlocked});
  final String game, result;
  final GameOutcome outcome;
  final bool english;
  final int stage, stars, remaining;
  final bool hasNext;
  final int pointsEarned;
  final String? badgeEarned;
  final int? trophyUnlocked;

  static Future<GameResultAction> show(BuildContext context, {
    required String game, required GameOutcome outcome,
    required bool english, required String result,
    required int stage, required int stars,
    required int remaining, required bool hasNext,
    int pointsEarned = 0, String? badgeEarned,
    int? trophyUnlocked,
  }) async {
    GameAudio.play(switch(outcome) {
      GameOutcome.win => GameSound.win,
      GameOutcome.draw => GameSound.draw,
      _ => GameSound.lose,
    });
    return await showGeneralDialog<GameResultAction>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xAA152A55),
      transitionDuration: const Duration(milliseconds: 370),
      pageBuilder: (_, __, ___) => GameResultDialog(
        game: game, outcome: outcome, english: english, result: result,
        stage: stage, stars: stars.clamp(0,3).toInt(),
        remaining: remaining, hasNext: hasNext,
        pointsEarned: pointsEarned, badgeEarned: badgeEarned,
        trophyUnlocked: trophyUnlocked),
      transitionBuilder: (dialogContext, animation, _, child) =>
        MediaQuery.disableAnimationsOf(dialogContext)
          ? child : FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: .86, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
              child: child)),
    ) ?? GameResultAction.retry;
  }

  @override State<GameResultDialog> createState() => _GameResultDialogState();
}

class _GameResultDialogState extends State<GameResultDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 760));

  @override void initState() { super.initState(); _animation.forward(); }
  @override void dispose() { _animation.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final win = widget.outcome == GameOutcome.win;
    final draw = widget.outcome == GameOutcome.draw;
    final icon = win ? Icons.emoji_events_rounded :
      draw ? Icons.handshake_rounded : Icons.favorite_rounded;
    final color = win ? const Color(0xFFFFB634) :
      draw ? const Color(0xFF62B8FF) : const Color(0xFFA782F8);
    final title = switch(widget.outcome) {
      GameOutcome.win => widget.english ? 'Great Job!' : 'أحسنت! 🎉',
      GameOutcome.loss => widget.english ? 'Good Try!' : 'محاولة جميلة!',
      GameOutcome.draw => widget.english ? "It's a Draw!" : 'تعادل!',
      GameOutcome.timeout => widget.english ? "Time's Up!" : 'انتهى الوقت!',
    };
    final allowNext = widget.hasNext && win;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Directionality(
      textDirection: widget.english ? TextDirection.ltr : TextDirection.rtl,
      child: Dialog(
        key: const Key('game-result-popup'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            padding: const EdgeInsets.fromLTRB(19, 13, 19, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFE4EDFF)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(
                color: Color(0x665065AA), blurRadius: 26,
                offset: Offset(0, 13))]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Align(alignment: AlignmentDirectional.topEnd, child: IconButton(
                tooltip: widget.english ? 'Game list' : 'قائمة الألعاب',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(
                  context, GameResultAction.list))),
              AnimatedBuilder(
                animation: _animation,
                builder: (context, _) {
                  final progress = Curves.easeOutBack.transform(
                    (_animation.value / .7).clamp(0.0, 1.0));
                  return Transform.translate(
                    offset: Offset(0, reduced ? 0 : 12 * (1 - progress)),
                    child: Transform.scale(
                      scale: reduced ? 1 : .83 + .17 * progress,
                      child: Container(
                        width: 77, height: 77,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(color, Colors.white, .65)!,
                              color.withValues(alpha: .26),
                            ]),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: const [BoxShadow(
                            color: Color(0x330C43A0),
                            blurRadius: 12, offset: Offset(2, 7))]),
                        child: Icon(icon, color: color, size: 46),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 9),
              Text(title, key: const Key('game-result-title'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 25,
                  fontWeight: FontWeight.w900, color: Brand.navy)),
              const SizedBox(height: 5),
              Text(widget.game + ' • ' +
                (widget.english ? 'Level ' : 'مرحلة ') +
                widget.stage.toString(),
                style: const TextStyle(color: Brand.muted,
                  fontWeight: FontWeight.w700)),
              const SizedBox(height: 13),
              AnimatedBuilder(animation: _animation,
                builder: (_, __) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final progress = ((_animation.value - i*.18)/.55)
                        .clamp(0.0,1.0).toDouble();
                    return Transform.scale(
                      scale: reduced ? 1 : .82 +
                        .18*Curves.easeOutBack.transform(progress),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.star_rounded, size: 36,
                          color: i < widget.stars
                            ? const Color(0xFFFFB31A)
                            : const Color(0xFFC3CDE7))));
                  }),
                )),
              const SizedBox(height: 13),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF3FF),
                  borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Text(widget.result,
                    key: const Key('game-result-score'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Brand.navy,
                      fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text((widget.english ? 'Time left: ' : 'الوقت المتبقي: ') +
                      widget.remaining.toString() +
                      (widget.english ? 's' : ' ثانية'),
                    style: const TextStyle(
                      color: Brand.muted, fontSize: 12)),
                ]),
              ),
              if (widget.pointsEarned > 0) ...[
                const SizedBox(height: 9),
                Container(
                  key: const Key('result-reward-points'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1CA),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [BoxShadow(
                      color: Color(0x44C18A32), blurRadius: 8,
                      offset: Offset(1, 3))]),
                  child: Text(
                    '+${widget.pointsEarned} XP  ⭐',
                    style: const TextStyle(
                      color: Color(0xFF7E540C),
                      fontWeight: FontWeight.w900),
                  ),
                ),
              ],
              if (widget.trophyUnlocked != null) ...[
                const SizedBox(height: 6),
                Text((widget.english ? 'Trophy unlocked: ' :
                    'كأس جديد: ') + widget.trophyUnlocked.toString() + ' 🏆',
                  key: const Key('result-new-trophy'),
                  style: const TextStyle(
                    color: Color(0xFFB87811),
                    fontWeight: FontWeight.w900)),
              ],
              if (widget.badgeEarned != null) ...[
                const SizedBox(height: 6),
                Text((widget.english ? 'New badge unlocked! ' :
                    'بادج جديد! ') + '🏅',
                  key: const Key('result-new-badge'),
                  style: const TextStyle(
                    color: Brand.blue, fontWeight: FontWeight.w900)),
              ],
              const SizedBox(height: 18),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Color(0x550B5CEB),
                    blurRadius: 11, offset: Offset(0, 5))]),
                child: SizedBox(width: double.infinity, child: FilledButton(
                  key: const Key('game-result-primary'),
                  onPressed: () => Navigator.pop(context,
                    allowNext ? GameResultAction.next : GameResultAction.retry),
                  child: Text(allowNext
                    ? (widget.english ? 'Next Stage' : 'المرحلة التالية')
                    : (widget.english ? 'Play Again' : 'العب من جديد')))),
              ),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: OutlinedButton(
                key: const Key('game-result-list'),
                onPressed: () => Navigator.pop(
                  context, GameResultAction.list),
                child: Text(widget.english ? 'Game List' : 'قائمة الألعاب'))),
            ]),
          ),
        )),
      ),
    );
  }
}
