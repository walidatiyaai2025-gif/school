import 'package:flutter/material.dart';
import '../core/brand.dart';
import '../core/strings.dart';
import '../data/app_store.dart';
import '../games/tic_tac_toe.dart';
import '../widgets/game_3d_art.dart';
import 'tic_tac_toe_screen.dart';
import 'math_match_screen.dart';
import 'word_hunt_screen.dart';

/// Offline games with glossy, locally-rendered 3D cards.
class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key, required this.store, this.onGameVisibilityChanged});
  final AppStore store;
  final ValueChanged<bool>? onGameVisibilityChanged;

  Future<void> _open(BuildContext context, Widget page) async {
    onGameVisibilityChanged?.call(true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page));
    } finally {
      onGameVisibilityChanged?.call(false);
    }
  }

  Future<void> _chooseOpponent(BuildContext context) async {
    final s = S(store.settings.english);
    final mode = await showDialog<GameMode>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(s.t('اختار طريقة اللعب', 'Choose how to play')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.people_alt_outlined, color: Brand.blue),
            title: Text(s.t('مع صديق', 'Play with a friend')),
            subtitle: Text(s.t('لاعبان على نفس الجهاز', 'Two players on one device')),
            onTap: () => Navigator.of(d).pop(GameMode.friend)),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined, color: Brand.blue),
            title: Text(s.t('ضد الكمبيوتر', 'Play against computer')),
            subtitle: Text(s.t('أنت X والكمبيوتر O', 'You are X; computer is O')),
            onTap: () => Navigator.of(d).pop(GameMode.computer)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.of(d).pop(),
            child: Text(s.cancel))],
      ),
    );
    if (mode == null || !context.mounted) return;
    await _open(context, TicTacToeScreen(
      mode: mode, english: store.settings.english, store: store));
  }

  @override
  Widget build(BuildContext context) {
    final s = S(store.settings.english);
    return ListView(
      key: const Key('play-game-list'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.t('العب واتعلم', 'Play & Learn'),
                style: const TextStyle(color: Brand.navy, fontSize: 28,
                  fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              Text(s.t('3 ألعاب تعليمية مجانية وممتعة، بدون إنترنت.',
                'Three free educational games, even offline.'),
                style: const TextStyle(color: Brand.muted, height: 1.35)),
            ])),
          const SizedBox(width: 8),
          const _SchoolArt(),
        ]),
        const SizedBox(height: 22),
        _GameCard(cardKey: const Key('xo-game-card'),
          kind: GameArtKind.xo, hero: true,
          title: 'XO • Tic Tac Toe',
          stageLabel: s.t('المرحلة ', 'Level ') +
            store.unlockedGameStage('xo').toString() + ' / 3',
          description: s.t('تحدى صديقك أو العب ضد الكمبيوتر.',
            'Challenge a friend or the computer.'),
          button: s.t('ابدأ اللعب', 'Start playing'),
          colors: const [Color(0xFF16B4FF), Color(0xFF064BDA)],
          onTap: () => _chooseOpponent(context)),
        const SizedBox(height: 15),
        _GameCard(cardKey: const Key('math-match-card'),
          kind: GameArtKind.math, title: 'Math Match',
          stageLabel: s.t('المرحلة ', 'Level ') +
            store.unlockedGameStage('math').toString() + ' / 3',
          description: s.t('طابق الأرقام وحل ألغاز الحساب.',
            'Match numbers and solve quick math puzzles.'),
          button: s.t('العب الآن', 'Play now'),
          colors: const [Color(0xFFF4F0FF), Color(0xFFD0C7FF)],
          onTap: () => _open(context, MathMatchScreen(store: store))),
        const SizedBox(height: 15),
        _GameCard(cardKey: const Key('word-hunt-card'),
          kind: GameArtKind.words, title: 'Word Hunt',
          stageLabel: s.t('المرحلة ', 'Level ') +
            store.unlockedGameStage('words').toString() + ' / 3',
          description: s.t('اكتشف الكلمات المخفية وطوّر مفرداتك.',
            'Find hidden words and grow your vocabulary.'),
          button: s.t('العب الآن', 'Play now'),
          colors: const [Color(0xFFE8FAFF), Color(0xFFB0F0DD)],
          onTap: () => _open(context, WordHuntScreen(store: store))),
      ],
    );
  }
}

class _SchoolArt extends StatelessWidget {
  const _SchoolArt();
  @override Widget build(BuildContext context) => SizedBox(
    width: 78, height: 82,
    child: Stack(children: [
      Positioned(bottom: 4, left: 10, right: 7,
        child: Container(height: 16, decoration: BoxDecoration(
          color: const Color(0xFF9B7EE9), borderRadius: BorderRadius.circular(5)))),
      Positioned(bottom: 18, left: 2, right: 11,
        child: Container(height: 16, decoration: BoxDecoration(
          color: const Color(0xFF65B8FF), borderRadius: BorderRadius.circular(5)))),
      Positioned(top: 2, left: 4,
        child: Container(width: 68, height: 51,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [
              Color(0xFF43CFFF), Color(0xFF1851DC)]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0x440B56C4),
              blurRadius: 10, offset: Offset(0, 7))]),
          child: const Icon(Icons.school_rounded,
            color: Colors.white, size: 38))),
    ]),
  );
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.cardKey, required this.kind,
    required this.title, required this.stageLabel, required this.description, required this.button,
    required this.colors, required this.onTap, this.hero = false});

  final Key cardKey;
  final GameArtKind kind;
  final String title, stageLabel, description, button;
  final List<Color> colors;
  final VoidCallback onTap;
  final bool hero;

  @override Widget build(BuildContext context) {
    final ink = hero ? Colors.white : Brand.navy;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft,
          end: Alignment.bottomRight, colors: colors),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xAAFFFFFF), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x330B4BA6),
          offset: Offset(0, 8), blurRadius: 17)]),
      child: Material(color: Colors.transparent,
        child: InkWell(key: cardKey,
          borderRadius: BorderRadius.circular(26), onTap: onTap,
          child: ClipRRect(borderRadius: BorderRadius.circular(26),
            child: Stack(children: [
              Positioned(bottom: -70, right: -32,
                child: Container(width: 162, height: 130,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: hero ? .12 : .26)))),
              Positioned(bottom: -77, left: -37,
                child: Container(width: 145, height: 115,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: hero ? .17 : .3)))),
              Padding(padding: EdgeInsets.fromLTRB(17, hero ? 21 : 14, 8,
                  hero ? 21 : 14),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: ink,
                          fontSize: hero ? 20 : 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text(stageLabel, style: TextStyle(
                        color: ink.withValues(alpha: .9),
                        fontWeight: FontWeight.w800, fontSize: 11)),
                      const SizedBox(height: 7),
                      Text(description, maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: ink.withValues(alpha: .86),
                          fontSize: 12, height: 1.4)),
                      const SizedBox(height: 14),
                      DecoratedBox(decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Colors.white, Color(0xFFE4EDFF)]),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [BoxShadow(color: Color(0x400B3D8A),
                          blurRadius: 8, offset: Offset(0, 3))]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.play_arrow_rounded,
                              color: Brand.blue, size: 19),
                            const SizedBox(width: 2),
                            Flexible(child: Text(button,
                              style: const TextStyle(color: Brand.blue,
                                fontSize: 12, fontWeight: FontWeight.w800))),
                          ]),
                        )),
                    ],
                  )),
                  const SizedBox(width: 2),
                  Game3DArt(kind: kind, size: hero ? 120 : 107),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
