import 'package:flutter/material.dart';

import '../core/brand.dart';
import '../core/strings.dart';
import '../data/app_store.dart';
import '../games/tic_tac_toe.dart';
import 'tic_tac_toe_screen.dart';

/// Free, offline game catalogue. New games can be added here later.
class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key, required this.store});
  final AppStore store;

  Future<void> _chooseOpponent(BuildContext context) async {
    final s = S(store.settings.english);
    final mode = await showDialog<GameMode>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.t('اختار طريقة اللعب', 'Choose how to play')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.people_alt_outlined, color: Brand.blue),
            title: Text(s.t('مع صديق', 'Play with a friend')),
            subtitle: Text(s.t('لاعبان على نفس الجهاز', 'Two players on one device')),
            onTap: () => Navigator.of(dialogContext).pop(GameMode.friend),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined, color: Brand.blue),
            title: Text(s.t('ضد الكمبيوتر', 'Play against computer')),
            subtitle: Text(s.t('أنت X والكمبيوتر O', 'You are X; computer is O')),
            onTap: () => Navigator.of(dialogContext).pop(GameMode.computer),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(s.cancel),
          ),
        ],
      ),
    );
    if (mode == null || !context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TicTacToeScreen(mode: mode, english: store.settings.english),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = S(store.settings.english);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 32), children: [
      Row(children: [
        const Icon(Icons.sports_esports_rounded, color: Brand.blue, size: 34),
        const SizedBox(width: 10),
        Expanded(child: Text(s.t('العب واتعلم', 'Play & Learn'),
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900,
                color: Brand.navy))),
      ]),
      const SizedBox(height: 8),
      Text(s.t('ألعاب مجانية من غير اشتراك وتشتغل بدون إنترنت.',
          'Free games, no subscriptions, and playable offline.'),
          style: const TextStyle(color: Brand.muted)),
      const SizedBox(height: 26),
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          key: const Key('xo-game-card'),
          borderRadius: BorderRadius.circular(24),
          onTap: () => _chooseOpponent(context),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 76, height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5EFFF),
                  borderRadius: BorderRadius.circular(20)),
                child: const Text('X O', style: TextStyle(fontSize: 29,
                    fontWeight: FontWeight.w900, color: Brand.blue)),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('XO • Tic Tac Toe',
                      style: TextStyle(color: Brand.navy, fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(s.t('تحدي X و O ضد صديق أو الكمبيوتر',
                      'Challenge a friend or the computer'),
                      style: const TextStyle(color: Brand.muted)),
                  const SizedBox(height: 8),
                  Text(s.t('ابدأ اللعب', 'Start playing'),
                      style: const TextStyle(color: Brand.blue,
                          fontWeight: FontWeight.w800)),
                ],
              )),
              const Icon(Icons.chevron_right_rounded, color: Brand.blue),
            ]),
          ),
        ),
      ),
    ]);
  }
}
