import 'dart:async';
import 'package:flutter/material.dart';
import '../core/brand.dart';
import '../core/strings.dart';
import '../data/app_store.dart';
import '../games/word_hunt.dart';
import '../games/game_stages.dart';
import '../games/stage_clock.dart';
import '../widgets/game_countdown.dart';
import '../widgets/game_result_dialog.dart';
import '../services/game_audio.dart';
import '../widgets/game_stage_strip.dart';
import '../widgets/game_3d_tile.dart';
import '../services/ads_service.dart';
import '../widgets/game_3d_art.dart';

class WordHuntScreen extends StatefulWidget {
  const WordHuntScreen({super.key, required this.store});
  final AppStore store;
  @override State<WordHuntScreen> createState() => _WordHuntScreenState();
}

class _WordHuntScreenState extends State<WordHuntScreen>
    with WidgetsBindingObserver {
  final StageClock _clock = StageClock();
  Timer? _hintTimer;
  int? _hintCell;
  bool _resultOpen = false;
  int _attempt = 0;
  void _startClock() {
    _clock.start(GameStages.secondsFor('words', _stage),
        () => _finish(timedOut: true));
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_resultOpen) {
      _clock.resume();
    } else { _clock.pause(); }
  }
  @override void dispose() {
    _hintTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    super.dispose();
  }
  Future<void> _hint() async {
    if (_resultOpen || game.finished ||
        widget.store.hasUsedWordHint(_stage)) return;
    final cell = game.hintCell;
    if (cell == null || !await widget.store.useWordHint(_stage) || !mounted) {
      return;
    }
    GameAudio.play(GameSound.hint);
    _hintTimer?.cancel();
    setState(() => _hintCell = cell);
    _hintTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _hintCell = null);
    });
  }
  Future<void> _finish({bool timedOut = false}) async {
    if (_resultOpen || !mounted) return;
    _resultOpen = true;
    _clock.stop();
    final won = !timedOut && game.finished;
    final stars = won
        ? (widget.store.hasUsedWordHint(_stage) || game.misses > 4
            ? 1 : game.misses > 1 ? 2 : 3)
        : 0;
    final award = won
        ? await widget.store.earnGameStars('words', _stage, stars)
        : null;
    if (!mounted) return;
    final action = await GameResultDialog.show(context,
      game: 'Word Hunt',
      outcome: won ? GameOutcome.win : GameOutcome.timeout,
      english: widget.store.settings.english,
      result: game.progress.toString() + ' / ' +
        game.targets.length.toString() +
        (widget.store.settings.english ? ' words • ' : ' كلمات • ') +
        game.score.toString() +
        (widget.store.settings.english ? ' points' : ' نقطة'),
      stage: _stage,
      stars: stars,
      remaining: _clock.seconds.value,
      hasNext: won && _stage < GameStages.count,
      pointsEarned: award?.earnedPoints ?? 0,
      badgeEarned: award?.newBadges.isNotEmpty == true
          ? award!.newBadges.first : null);
    if (!mounted) return;
    if (action == GameResultAction.list) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        if (action == GameResultAction.next &&
            won && _stage < GameStages.count) {
          _stage++;
          _attempt = 0;
        } else {
          _attempt++;
        }
        _hintTimer?.cancel();
        _hintCell = null;
        game = _newGame(_stage);
        _resultOpen = false;
      });
      _startClock();
    }
  }

  late WordHuntGame game;
  int _stage = 1;
  @override void initState() {
    super.initState();
    _stage = widget.store.unlockedGameStage('words');
    game = _newGame(_stage);
    WidgetsBinding.instance.addObserver(this);
    _startClock();
  }
  WordHuntGame _newGame(int stage) => WordHuntGame(
    level: widget.store.settings.level, stage: stage,
    seed: 2026 + stage + _attempt * 4099);
  void _selectStage(int stage) {
    if (_resultOpen || stage > widget.store.unlockedGameStage('words')) return;
    setState(() {
      _stage = stage;
      _attempt = 0;
      game = _newGame(_stage);
      _hintTimer?.cancel();
      _hintCell = null;
    });
    _startClock();
  }
  void _chooseLetter(int index) {
    if (_resultOpen || !game.tap(index)) return;
    if (game.lastFound != null) {
      _clock.addSeconds(2);
      GameAudio.play(GameSound.correct);
    } else if (game.lastMiss) {
      GameAudio.play(GameSound.incorrect);
    } else {
      GameAudio.play(GameSound.tap);
    }
    setState(() {});
    if (game.finished) unawaited(_finish());
  }
  void _replay() {
    if (_resultOpen) return;
    _hintTimer?.cancel();
    setState(() {
      if (game.finished && _stage < GameStages.count) {
        _stage++;
        _attempt = 0;
      } else {
        _attempt++;
      }
      _hintCell = null;
      game = _newGame(_stage);
    });
    _startClock();
  }

  @override Widget build(BuildContext context) {
    final s = S(widget.store.settings.english);
    final english = widget.store.settings.english;
    return Directionality(
      textDirection: english ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('Word Hunt')),
        // A fitted fixed-aspect game canvas. The entire puzzle, goals, timer,
        // stages and feedback remain on-screen in compact Android layouts;
        // the only independent overlay is the optional external ad footer.
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: LayoutBuilder(builder: (context, constraints) =>
              FittedBox(
                key: const Key('word-fit-canvas'),
                fit: BoxFit.contain,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 360,
                  height: 580,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 58, child: Row(children: [
                        const Game3DArt(kind: GameArtKind.words, size: 59),
                        const SizedBox(width: 9),
                        Expanded(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.t('صيد الكلمات', 'Word Hunt'),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20, color: Brand.navy,
                                fontWeight: FontWeight.w900)),
                            Text(s.t('ابحث أفقيًا ورأسيًا وقطريًا ↔ ↕ ⤢',
                              'Search across, down & diagonally ↔ ↕ ⤢'),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Brand.muted, fontSize: 11)),
                          ],
                        )),
                      ])),
                      const SizedBox(height: 6),
                      GameStageStrip(
                        current: _stage,
                        unlocked: widget.store.unlockedGameStage('words'),
                        english: english,
                        onSelect: _selectStage,
                      ),
                      const SizedBox(height: 5),
                      SizedBox(height: 39, child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GameCountdown(clock: _clock),
                          if (!widget.store.hasUsedWordHint(_stage) &&
                              !_resultOpen)
                            TextButton.icon(
                              key: const Key('word-hint-button'),
                              onPressed: _hint,
                              icon: const Icon(Icons.lightbulb_rounded,
                                size: 18),
                              label: Text(s.t('تلميح واحد', 'One hint')),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9)),
                            ),
                        ],
                      )),
                      const SizedBox(height: 3),
                      SizedBox(height: 42, child: Column(children: [
                        Row(children: [
                          Text(s.t('الكلمات: ', 'Words: ') +
                              game.progress.toString() + '/' +
                              game.targets.length.toString(),
                            style: const TextStyle(
                              color: Brand.blue, fontWeight: FontWeight.w900,
                              fontSize: 12)),
                          const Spacer(),
                          Text('🏆 ' + game.score.toString(),
                            key: const Key('word-score'),
                            style: const TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Brand.navy)),
                          if (game.combo > 1) ...[
                            const SizedBox(width: 10),
                            Text('🔥 ×' + game.combo.toString(),
                              key: const Key('word-combo'),
                              style: const TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFD46112))),
                          ],
                        ]),
                        const SizedBox(height: 2),
                        SizedBox(height: 20,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 230),
                            transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: .92, end: 1)
                                      .animate(animation), child: child)),
                            child: game.finished ||
                                game.lastFound != null || game.lastMiss
                              ? Text(
                                  game.finished
                                    ? s.t('ممتاز! أنهيت التحدي 🎉',
                                        'Challenge complete! 🎉')
                                    : game.lastFound != null
                                      ? s.t('ممتاز! ', 'Found! ') +
                                          game.lastFound! + '  +2s' +
                                          (game.combo > 1
                                            ? '  COMBO ×' + game.combo.toString()
                                            : '')
                                      : s.t('مش المسار الصحيح، جرّب تاني!',
                                          'Not the path — try again!'),
                                  key: const Key('word-feedback'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: game.lastMiss
                                      ? const Color(0xFFBB4261)
                                      : const Color(0xFF178B67),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900),
                                )
                              : const SizedBox.shrink(
                                  key: Key('word-feedback-empty')),
                          ),
                        ),
                      ])),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Stack(fit: StackFit.expand, children: [
                                GridView.builder(
                                key: const Key('word-letter-grid'),
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: game.letters.length,
                                gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: WordHuntGame.size,
                                    mainAxisSpacing: 3,
                                    crossAxisSpacing: 3,
                                  ),
                                itemBuilder: (context, index) {
                                  final found =
                                      game.foundCells.contains(index);
                                  final active = game.start == index;
                                  return AnimatedScale(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutBack,
                                    scale: _hintCell == index ? 1.09 : 1,
                                    child: Game3DTile(
                                      key: Key('word-cell-$index'),
                                      label: 'Letter ' + game.letters[index],
                                      radius: 8,
                                      selected: active,
                                      color: _hintCell == index
                                        ? const Color(0xFFFFD04D)
                                        : found
                                          ? const Color(0xFF5DE3C0)
                                          : active
                                            ? const Color(0xFFFFD46E)
                                            : const Color(0xFFC4DEFF),
                                      onTap: game.finished || _resultOpen
                                        ? null : () => _chooseLetter(index),
                                      child: Text(game.letters[index],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: found
                                            ? const Color(0xFF055944)
                                            : Brand.navy,
                                          shadows: const [
                                            Shadow(
                                              color: Color(0x88FFFFFF),
                                              offset: Offset(-1, -1),
                                              blurRadius: 1),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                ),
                                IgnorePointer(child: TweenAnimationBuilder<double>(
                                  key: ValueKey('word-trail-' +
                                    game.progress.toString()),
                                  tween: Tween(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 460),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, progress, _) => CustomPaint(
                                    painter: _WordTrailPainter(
                                      paths: [
                                        for (final word in game.found)
                                          game.wordPath(word),
                                      ],
                                      latest: game.lastFoundCells,
                                      progress: progress,
                                    ),
                                  ),
                                )),
                              ]),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(s.t('الكلمات المطلوبة', 'Find these words'),
                        style: const TextStyle(
                          color: Brand.navy, fontSize: 12,
                          fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      // Fixed three-column layout. Even levels with five
                      // targets use only two compact rows without scrolling.
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          for (final word in game.targets)
                            SizedBox(
                              width: 116,
                              height: 35,
                              child: Game3DTile(
                                key: Key('word-target-$word'),
                                radius: 10,
                                color: game.found.contains(word)
                                  ? const Color(0xFF8CECC5)
                                  : const Color(0xFFC5D6FF),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (game.found.contains(word))
                                      const Icon(Icons.check_circle,
                                        size: 13,
                                        color: Color(0xFF087E57)),
                                    Flexible(child: Text(word,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Brand.navy,
                                        fontWeight: FontWeight.w900,
                                        decoration: game.found.contains(word)
                                          ? TextDecoration.lineThrough
                                          : null))),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SafeArea(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 7, 20, 10),
              child: FilledButton.icon(
                key: const Key('word-reset'),
                onPressed: _resultOpen ? null : _replay,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(game.finished && _stage < GameStages.count
                  ? s.t('المرحلة التالية', 'Next stage')
                  : s.t('لعبة جديدة', 'New puzzle')),
              ),
            )),
            SchoolBanner(store: widget.store),
          ],
        ),
      ),
    );
  }
}


/// Soft connecting trails make vertical/diagonal discoveries visible while
/// preserving legible letters and never intercepting touches.
class _WordTrailPainter extends CustomPainter {
  const _WordTrailPainter({required this.paths,
    required this.latest, required this.progress});
  final List<List<int>> paths;
  final List<int> latest;
  final double progress;

  Offset _center(int index, Size size) {
    const gaps = 3.0;
    final cell = (size.width - 6 * gaps) / WordHuntGame.size;
    final step = cell + gaps;
    return Offset((index % WordHuntGame.size) * step + cell / 2,
      (index ~/ WordHuntGame.size) * step + cell / 2);
  }

  @override void paint(Canvas canvas, Size size) {
    for (final path in paths) {
      if (path.length < 2) continue;
      final isLatest = _same(path, latest);
      final begin = _center(path.first, size);
      final end = _center(path.last, size);
      canvas.drawLine(begin, end, Paint()
        ..color = isLatest ? const Color(0x6631D0A2)
                          : const Color(0x3331D0A2)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round);
      if (isLatest) {
        final tip = Offset.lerp(begin, end, progress)!;
        canvas.drawLine(begin, tip, Paint()
          ..color = const Color(0xAAFFD25D)
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round);
        canvas.drawCircle(tip, 4.2, Paint()
          ..color = const Color(0xD6FFD35B));
      }
    }
  }

  bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override bool shouldRepaint(covariant _WordTrailPainter old) =>
      old.progress != progress || old.paths.length != paths.length ||
      !_same(old.latest, latest);
}
