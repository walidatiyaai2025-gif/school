import 'package:flutter/material.dart';
import '../core/brand.dart';
import '../data/app_store.dart';
import '../games/achievement_rules.dart';
import 'clean_3d_dialog.dart';

/// Progress cabinet: real offline achievements, never paid tokens.
class GameAchievementsPanel extends StatelessWidget {
  const GameAchievementsPanel({
    super.key, required this.store, required this.english,
    this.compact = false});
  final AppStore store;
  final bool english;
  final bool compact;

  static const badgeTitles = <String, (String, String)>{
    'first-win': ('أول انتصار', 'First Victory'),
    'five-perfect': ('خمس مراحل كاملة', 'Five Perfect'),
    'ten-clears': ('مستكشف الألعاب', 'Game Explorer'),
    'word-explorer': ('صياد الكلمات', 'Word Hunter'),
    'sudoku-solver': ('عبقري سودوكو', 'Sudoku Solver'),
    'twenty-five': ('بطل المدرسة', 'School Champion'),
    'hundred-clears': ('أسطورة المراحل', 'Stage Legend'),
  };

  String tr(String ar, String en) => english ? en : ar;

  Future<void> _showCabinet(BuildContext context) async {
    final unlocked = store.gameBadgeIds.toSet();
    await showClean3DDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('خزانة الإنجازات 🏆', 'Achievement Cabinet 🏆')),
        content: SizedBox(
          width: 330,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(tr('اجمع الكؤوس بإكمال مراحل جديدة',
                    'Earn trophies by clearing new stages'),
                  style: const TextStyle(color: Brand.muted)),
                const SizedBox(height: 12),
                Wrap(spacing: 7, runSpacing: 7, children: [
                  for (final target in AchievementRules.trophyMilestones)
                    Chip(
                      avatar: Icon(
                        store.clearedGameStages >= target
                            ? Icons.emoji_events_rounded
                            : Icons.lock_outline_rounded,
                        size: 18, color: store.clearedGameStages >= target
                            ? const Color(0xFFB87904) : Brand.muted),
                      label: Text(target.toString() + ' ' +
                          tr('مرحلة', 'levels'),
                        style: const TextStyle(fontSize: 11)),
                      backgroundColor: store.clearedGameStages >= target
                          ? const Color(0xFFFFF0BC)
                          : const Color(0xFFECEFF5)),
                ]),
                const SizedBox(height: 12),
                Text(tr('البادجز', 'Badges'),
                  style: const TextStyle(fontWeight: FontWeight.w900)),
                for (final badge in AchievementRules.badgeIds)
                  ListTile(
                    key: Key('badge-' + badge),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      unlocked.contains(badge)
                          ? Icons.workspace_premium_rounded
                          : Icons.lock_outline_rounded,
                      color: unlocked.contains(badge)
                          ? const Color(0xFFF3AA2D) : Brand.muted),
                    title: Text(
                      tr(badgeTitles[badge]!.$1, badgeTitles[badge]!.$2),
                      style: TextStyle(
                        color: unlocked.contains(badge)
                            ? Brand.navy : Brand.muted,
                        fontWeight: FontWeight.w800)),
                    trailing: unlocked.contains(badge)
                        ? const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF12A47D)) : null,
                  ),
              ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr('تمام', 'Done'))),
        ],
      ),
    );
  }

  @override Widget build(BuildContext context) {
    final badges = store.gameBadgeIds;
    if (compact) {
      return Container(
        key: const Key('play-progress-summary'),
        padding: const EdgeInsets.fromLTRB(8, 3, 8, 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1447AB), Color(0xFF063078)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xAAFFFFFF)),
          boxShadow: const [BoxShadow(color: Color(0x44375C9E),
            blurRadius: 8, offset: Offset(0, 4))]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded,
              size: 17, color: Color(0xFFFFE593)),
            const SizedBox(width: 4),
            Expanded(child: Text(tr('جوائزك', 'Your rewards'),
              maxLines: 1,
              style: const TextStyle(color: Colors.white,
                fontSize: 13, fontWeight: FontWeight.w900))),
            TextButton.icon(
              key: const Key('play-achievements-button'),
              onPressed: () => _showCabinet(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 7)),
              icon: const Icon(Icons.workspace_premium_rounded, size: 17),
              label: Text(tr('الجوائز', 'Awards'),
                style: const TextStyle(fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 3),
          Row(children: [
            _stat('⭐', store.totalGameStars.toString(),
                tr('نجوم', 'Stars')),
            const SizedBox(width: 5),
            _stat('✨', store.totalGamePoints.toString(),
                tr('نقاط', 'Points')),
            const SizedBox(width: 5),
            _stat('🏆', store.gameTrophies.toString(),
                tr('كؤوس', 'Trophies')),
            const SizedBox(width: 5),
            _stat('🏅', badges.length.toString(),
                tr('بادجز', 'Badges')),
          ]),
        ]),
      );
    }
    return Container(
      key: const Key('play-progress-summary'),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1447AB), Color(0xFF063078)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xAAFFFFFF)),
        boxShadow: const [BoxShadow(
          color: Color(0x55375C9E), blurRadius: 13,
          offset: Offset(0, 7))]),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.auto_awesome_rounded,
            size: 18, color: Color(0xFFFFE593)),
          const SizedBox(width: 6),
          Expanded(child: Text(tr('رحلتك كبطل التعلم',
              'Your learning adventure'),
            style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900))),
          TextButton.icon(
            key: const Key('play-achievements-button'),
            onPressed: () => _showCabinet(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4)),
            icon: const Icon(Icons.workspace_premium_rounded, size: 17),
            label: Text(tr('الجوائز', 'Awards'),
              style: const TextStyle(fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 9),
        Row(children: [
          _stat('⭐', store.totalGameStars.toString(),
            tr('نجوم', 'Stars')),
          const SizedBox(width: 7),
          _stat('✨', store.totalGamePoints.toString(),
            tr('نقاط', 'Points')),
          const SizedBox(width: 7),
          _stat('🏆', store.gameTrophies.toString(),
            tr('كؤوس', 'Trophies')),
          const SizedBox(width: 7),
          _stat('🏅', badges.length.toString(),
            tr('بادجز', 'Badges')),
        ]),
        const SizedBox(height: 7),
        Align(alignment: AlignmentDirectional.centerStart,
          child: Text(tr('اكسب نجوم وافتح جوائز في كل لعبة',
              'Collect stage stars to unlock awards'),
            style: const TextStyle(
              color: Color(0xFFD7E5FF), fontSize: 10.5))),
      ]),
    );
  }

  Widget _stat(String emoji, String count, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
      decoration: BoxDecoration(
        color: const Color(0x1EFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x44FFFFFF))),
      child: Column(children: [
        Text(emoji + ' ' + count, maxLines: 1,
          style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w900, fontSize: 15)),
        Text(label, style: const TextStyle(
          color: Color(0xFFD8E6FF), fontSize: 10)),
      ]),
    ),
  );
}
