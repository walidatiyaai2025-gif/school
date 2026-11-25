import 'package:flutter/material.dart';
import '../core/brand.dart';
import '../core/strings.dart';
import '../data/app_store.dart';
import '../games/tic_tac_toe.dart';
import '../widgets/game_3d_art.dart';
import '../widgets/motion_fx.dart';
import '../widgets/clean_3d_dialog.dart';
import '../widgets/game_achievements_panel.dart';
import 'tic_tac_toe_screen.dart';
import 'math_match_screen.dart';
import 'word_hunt_screen.dart';
import 'sudoku_screen.dart';

/// Four glossy games in a compact two-column grid, with one unified cabinet.
class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key, required this.store, this.onGameVisibilityChanged});
  final AppStore store;
  final ValueChanged<bool>? onGameVisibilityChanged;

  Future<void> _open(BuildContext context, Widget page) async {
    onGameVisibilityChanged?.call(true);
    try {
      final reduced = MediaQuery.disableAnimationsOf(context);
      await Navigator.of(context).push(PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: reduced
            ? Duration.zero : const Duration(milliseconds: 320),
        reverseTransitionDuration: reduced
            ? Duration.zero : const Duration(milliseconds: 240),
        transitionsBuilder: (_, animation, __, child) {
          if (reduced) return child;
          final eased = CurvedAnimation(
            parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: eased,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .07), end: Offset.zero).animate(eased),
              child: child,
            ),
          );
        },
      ));
    } finally {
      onGameVisibilityChanged?.call(false);
    }
  }

  Future<void> _chooseOpponent(BuildContext context) async {
    final s = S(store.settings.english);
    final mode = await showClean3DDialog<GameMode>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(s.t('اختار طريقة اللعب', 'Choose how to play')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.people_alt_outlined, color: Brand.blue),
            title: Text(s.t('مع صديق', 'Play with a friend')),
            subtitle: Text(s.t('لاعبان على نفس الجهاز',
                'Two players on one device')),
            onTap: () => Navigator.of(d).pop(GameMode.friend)),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined, color: Brand.blue),
            title: Text(s.t('ضد الكمبيوتر', 'Play against computer')),
            subtitle: Text(s.t('أنت X والكمبيوتر O',
                'You are X; computer is O')),
            onTap: () => Navigator.of(d).pop(GameMode.computer)),
        ]),
        actions: [TextButton(
          onPressed: () => Navigator.of(d).pop(),
          child: Text(s.cancel))],
      ),
    );
    if (mode == null || !context.mounted) return;
    await _open(context, TicTacToeScreen(
      mode: mode, english: store.settings.english, store: store));
  }

  @override Widget build(BuildContext context) =>
      AnimatedBuilder(animation: store, builder: (context, _) {
        final s = S(store.settings.english);
        return LayoutBuilder(
          builder: (context, bounds) => Center(
            child: FittedBox(
              key: const Key('play-fit-canvas'),
              fit: BoxFit.contain,
              child: SizedBox(
                width: 390,
                height: 650,
                child: Padding(
                  key: const Key('play-game-list'),
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
                  child: Column(children: [
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.t('العب واتعلم', 'Play & Learn'),
                    style: const TextStyle(color: Brand.navy,
                      fontSize: 26, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(s.t('٤ تحديات مجانية • ألف مرحلة في كل لعبة',
                      '4 free challenges • 1,000 levels each'),
                    style: const TextStyle(
                      color: Brand.muted, fontSize: 12)),
                ],
              )),
              const MotionReveal(order: 0, child: _SchoolArt()),
            ]),
            const SizedBox(height: 11),
            GameAchievementsPanel(
              store: store, english: store.settings.english,
              compact: true),
            const SizedBox(height: 15),
            Expanded(child: LayoutBuilder(
              builder: (context, space) {
                final cellWidth = (space.maxWidth - 11) / 2;
                final cellHeight = (space.maxHeight - 11) / 2;
                return GridView.count(
                  key: const Key('play-2x2-grid'),
                  padding: EdgeInsets.zero,
                  crossAxisCount: 2,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 11,
                  mainAxisSpacing: 11,
                  childAspectRatio: cellWidth / cellHeight,
                  children: [
                MotionReveal(order: 1, child: _GameCard(
                  cardKey: const Key('xo-game-card'),
                  kind: GameArtKind.xo,
                  title: 'XO',
                  subtitle: s.t('تحدي الذكاء', 'Tic Tac Toe'),
                  stage: store.unlockedGameStage('xo'),
                  bestStars: store.bestStarsFor('xo',
                    store.unlockedGameStage('xo') == 1 ? 1 :
                      store.unlockedGameStage('xo') - 1),
                  colors: const [Color(0xFF35C8FF), Color(0xFF0C62DC)],
                  dark: true, onTap: () => _chooseOpponent(context),
                )),
                MotionReveal(order: 2, child: _GameCard(
                  cardKey: const Key('math-match-card'),
                  kind: GameArtKind.math,
                  title: 'Math Match',
                  subtitle: s.t('ألغاز الحساب', 'Math puzzles'),
                  stage: store.unlockedGameStage('math'),
                  bestStars: store.bestStarsFor('math',
                    store.unlockedGameStage('math') == 1 ? 1 :
                      store.unlockedGameStage('math') - 1),
                  colors: const [Color(0xFFEBE8FF), Color(0xFFB6ABF4)],
                  onTap: () => _open(context, MathMatchScreen(store: store)),
                )),
                MotionReveal(order: 3, child: _GameCard(
                  cardKey: const Key('word-hunt-card'),
                  kind: GameArtKind.words,
                  title: 'Word Hunt',
                  subtitle: s.t('صيد الكلمات', 'Find words'),
                  stage: store.unlockedGameStage('words'),
                  bestStars: store.bestStarsFor('words',
                    store.unlockedGameStage('words') == 1 ? 1 :
                      store.unlockedGameStage('words') - 1),
                  colors: const [Color(0xFFE0FFFA), Color(0xFF9CE7CF)],
                  onTap: () => _open(context, WordHuntScreen(store: store)),
                )),
                MotionReveal(order: 4, child: _GameCard(
                  cardKey: const Key('sudoku-game-card'),
                  kind: GameArtKind.sudoku,
                  title: 'Sudoku',
                  subtitle: s.t('مغامرة الأرقام', 'Number quest'),
                  stage: store.unlockedGameStage('sudoku'),
                  bestStars: store.bestStarsFor('sudoku',
                    store.unlockedGameStage('sudoku') == 1 ? 1 :
                      store.unlockedGameStage('sudoku') - 1),
                  colors: const [Color(0xFFFFF2D8), Color(0xFFFFCD89)],
                  onTap: () => _open(context, SudokuScreen(store: store)),
                )),
                  ],
                );
              },
            )),
            const SizedBox(height: 9),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.shield_moon_rounded,
                size: 15, color: Brand.blue),
              const SizedBox(width: 5),
              Flexible(child: Text(s.t(
                'الألعاب مجانية، ومكافآتك حسب أفضل إنجاز',
                'Always free • Rewards based on your best result'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Brand.muted, fontSize: 11))),
            ]),
                  ]),
                ),
              ),
            ),
          ),
        );
      });
}

class _SchoolArt extends StatelessWidget {
  const _SchoolArt();
  @override Widget build(BuildContext context) => SizedBox(
    width: 61, height: 61,
    child: Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF48D0FF), Color(0xFF0A58DB)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(
          color: Color(0x55084FB9), blurRadius: 9, offset: Offset(2, 6))]),
      child: const Icon(Icons.school_rounded,
        color: Colors.white, size: 35),
    ),
  );
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.cardKey, required this.kind, required this.title,
    required this.subtitle, required this.stage, required this.bestStars,
    required this.colors, required this.onTap, this.dark = false});
  final Key cardKey;
  final GameArtKind kind;
  final String title, subtitle;
  final int stage, bestStars;
  final List<Color> colors;
  final VoidCallback onTap;
  final bool dark;

  @override Widget build(BuildContext context) {
    final ink = dark ? Colors.white : Brand.navy;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: colors),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xAAFFFFFF), width: 1.3),
        boxShadow: const [BoxShadow(
          color: Color(0x330B4BA6), offset: Offset(0, 7), blurRadius: 13)]),
      child: MotionPress(
        key: cardKey, radius: 23, onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Stack(children: [
            Positioned(bottom: -26, right: -30,
              child: Container(width: 110, height: 90,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .19)))),
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 5, 7, 5),
              child: Column(children: [
                Expanded(child: Center(
                  child: Game3DArt(kind: kind, size: 75))),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ink, fontSize: 15,
                    fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle, maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ink.withValues(alpha: .8),
                    fontSize: 10.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => Icon(
                    Icons.star_rounded, size: 17,
                    color: i < bestStars
                      ? const Color(0xFFFFBC2D)
                      : (dark ? const Color(0x88FFFFFF)
                              : const Color(0xFFBEC7D8))))),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: dark ? .22 : .62),
                    borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    (Directionality.of(context) == TextDirection.rtl
                      ? 'المرحلة ' : 'Level ') + stage.toString() + '/1000',
                    maxLines: 1,
                    style: TextStyle(color: ink,
                      fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
