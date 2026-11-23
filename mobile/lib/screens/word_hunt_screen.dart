import 'package:flutter/material.dart';
import '../core/brand.dart';
import '../core/strings.dart';
import '../data/app_store.dart';
import '../games/word_hunt.dart';
import '../services/ads_service.dart';
import '../widgets/game_3d_art.dart';

class WordHuntScreen extends StatefulWidget {
  const WordHuntScreen({super.key, required this.store});
  final AppStore store;
  @override State<WordHuntScreen> createState() => _WordHuntScreenState();
}

class _WordHuntScreenState extends State<WordHuntScreen> {
  late final WordHuntGame game =
      WordHuntGame(level: widget.store.settings.level);

  @override Widget build(BuildContext context) {
    final s = S(widget.store.settings.english);
    return Directionality(
      textDirection: widget.store.settings.english
        ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('Word Hunt')),
        body: SafeArea(child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          children: [
            Row(children: [
              const Game3DArt(kind: GameArtKind.words, size: 82),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.t('صيد الكلمات', 'Word Hunt'),
                    style: const TextStyle(fontSize: 22,
                      color: Brand.navy, fontWeight: FontWeight.w900)),
                  Text(s.t('اضغط أول حرف وآخر حرف للكلمة المخفية.',
                      'Tap the first and last letters of a hidden word.'),
                    style: const TextStyle(color: Brand.muted)),
                ])),
            ]),
            const SizedBox(height: 17),
            Text(s.t('الكلمات: ', 'Words: ') + game.progress.toString() +
                 '/' + game.targets.length.toString(),
              style: const TextStyle(color: Brand.blue,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Directionality(textDirection: TextDirection.ltr,
              child: Center(child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 365),
                child: AspectRatio(aspectRatio: 1,
                  child: GridView.builder(
                    itemCount: game.letters.length,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: WordHuntGame.size,
                      mainAxisSpacing: 4, crossAxisSpacing: 4),
                    itemBuilder: (context, index) {
                      final found = game.foundCells.contains(index);
                      final active = game.start == index;
                      return Material(
                        color: found ? const Color(0xFF50D9AC) :
                          active ? const Color(0xFFFFD578) : Colors.white,
                        elevation: active ? 3 : 1,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          key: Key('word-cell-' + index.toString()),
                          borderRadius: BorderRadius.circular(8),
                          onTap: game.finished ? null :
                            () => setState(() => game.tap(index)),
                          child: Center(child: Text(game.letters[index],
                            style: TextStyle(fontSize: 19,
                              color: found ? const Color(0xFF065C43) : Brand.navy,
                              fontWeight: FontWeight.w900))),
                        ),
                      );
                    },
                  ),
                ),
              ))),
            const SizedBox(height: 17),
            Text(s.t('الكلمات المطلوبة', 'Find these words'),
              style: const TextStyle(color: Brand.navy,
                fontWeight: FontWeight.w900)),
            const SizedBox(height: 9),
            Wrap(spacing: 8, runSpacing: 8,
              children: [for (final word in game.targets) Chip(
                key: Key('word-target-' + word),
                avatar: game.found.contains(word)
                  ? const Icon(Icons.check_circle, size: 17,
                      color: Color(0xFF098A61)) : null,
                label: Text(word, style: TextStyle(
                  fontWeight: FontWeight.w800,
                  decoration: game.found.contains(word)
                    ? TextDecoration.lineThrough : null)),
                backgroundColor: game.found.contains(word)
                  ? const Color(0xFFDAF9E9) : const Color(0xFFE7EEFF),
              )]),
            const SizedBox(height: 14),
            if (game.finished || game.lastFound != null || game.lastMiss)
              Text(game.finished
                ? s.t('شاطر! لقيت كل الكلمات 🎉',
                    'Amazing! You found every word! 🎉')
                : game.lastFound != null
                  ? s.t('لقيت كلمة ', 'Found ') + game.lastFound!
                  : s.t('جرب حرف البداية والنهاية لنفس الكلمة.',
                      'Try the first and last letters of one word.'),
                key: const Key('word-feedback'),
                style: const TextStyle(color: Brand.navy,
                  fontWeight: FontWeight.w800)),
          ],
        )),
        bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
          SchoolBanner(store: widget.store),
          SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: FilledButton.icon(
              key: const Key('word-reset'),
              onPressed: () => setState(game.reset),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(s.t('لعبة جديدة', 'New puzzle'))))),
        ]),
      ),
    );
  }
}
