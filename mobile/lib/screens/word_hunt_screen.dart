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
    if (won) await widget.store.completeGameStage('words', _stage);
    if (!mounted) return;
    final action = await GameResultDialog.show(context,
      game: 'Word Hunt',
      outcome: won ? GameOutcome.win : GameOutcome.timeout,
      english: widget.store.settings.english,
      result: game.progress.toString() + ' / ' +
        game.targets.length.toString() +
        (widget.store.settings.english ? ' words' : ' كلمات'),
      stage: _stage,
      stars: won ? (widget.store.hasUsedWordHint(_stage) ? 2 : 3) :
          game.progress > 0 ? 1 : 0,
      remaining: _clock.seconds.value,
      hasNext: won && _stage < GameStages.count);
    if (!mounted) return;
    if (action == GameResultAction.list) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        if (action == GameResultAction.next &&
            won && _stage < GameStages.count) _stage++;
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
    seed: 2026 + stage);
  void _selectStage(int stage) {
    if (_resultOpen || stage > widget.store.unlockedGameStage('words')) return;
    setState(() {
      _stage = stage;
      game = _newGame(_stage);
      _hintTimer?.cancel();
      _hintCell = null;
    });
    _startClock();
  }
  void _chooseLetter(int index) {
    if (_resultOpen || !game.tap(index)) return;
    if (game.lastFound != null) {
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
      if (game.finished && _stage < GameStages.count) _stage++;
      _hintCell = null;
      game = _newGame(_stage);
    });
    _startClock();
  }

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
            const SizedBox(height: 10),
            GameStageStrip(current: _stage,
              unlocked: widget.store.unlockedGameStage('words'),
              english: widget.store.settings.english,
              onSelect: _selectStage),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              GameCountdown(clock: _clock),
              if (!widget.store.hasUsedWordHint(_stage) && !_resultOpen)
                TextButton.icon(
                  key: const Key('word-hint-button'),
                  onPressed: _hint,
                  icon: const Icon(Icons.lightbulb_rounded),
                  label: Text(s.t('تلميح واحد', 'One hint')),
                ),
            ]),
            const SizedBox(height: 8),
            Text(s.t('الكلمات: ', 'Words: ') + game.progress.toString() +
                 '/' + game.targets.length.toString(),
              style: const TextStyle(color: Brand.blue,
                fontWeight: FontWeight.w800)),
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
                  fontWeight: FontWeight.w800)),            const SizedBox(height: 12),
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
                      return AnimatedScale(
                        duration: const Duration(milliseconds: 370),
                        curve: Curves.elasticOut,
                        scale: _hintCell == index ? 1.12 : 1.0,
                        child: Game3DTile(
                        key: Key('word-cell-' + index.toString()),
                        label: 'Letter ' + game.letters[index],
                        radius: 9,
                        selected: active,
                        color: _hintCell == index
                            ? const Color(0xFFFFD04D)
                            : found ? const Color(0xFF5DE3C0)
                            : active ? const Color(0xFFFFD46E)
                            : const Color(0xFFC4DEFF),
                        onTap: game.finished || _resultOpen ? null :
                            () => _chooseLetter(index),
                        child: Text(game.letters[index],
                          style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: found ? const Color(0xFF055944)
                                : Brand.navy,
                            shadows: const [
                              Shadow(color: Color(0x88FFFFFF),
                                offset: Offset(-1, -1), blurRadius: 1),
                            ],
                          )),
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
              children: [for (final word in game.targets)
                SizedBox(width: 101, height: 48,
                  child: Game3DTile(
                    key: Key('word-target-' + word),
                    radius: 12,
                    color: game.found.contains(word)
                        ? const Color(0xFF8CECC5)
                        : const Color(0xFFC5D6FF),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min, children: [
                        if (game.found.contains(word))
                          const Icon(Icons.check_circle, size: 15,
                            color: Color(0xFF087E57)),
                        Flexible(child: Text(word, textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12,
                            color: Brand.navy, fontWeight: FontWeight.w900,
                            decoration: game.found.contains(word)
                                ? TextDecoration.lineThrough : null))),
                      ]),
                  ),
                ),
              ]),

            const SizedBox(height: 14),

          ],
        )),
        bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
          SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: FilledButton.icon(
              key: const Key('word-reset'),
              onPressed: _resultOpen ? null : _replay,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(game.finished && _stage < GameStages.count
                ? s.t('المرحلة التالية', 'Next stage')
                : s.t('لعبة جديدة', 'New puzzle'))))),
          SchoolBanner(store: widget.store),
        ]),
      ),
    );
  }
}
