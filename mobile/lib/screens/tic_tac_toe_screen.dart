import 'dart:async';

import 'package:flutter/material.dart';

import '../core/brand.dart';
import '../core/strings.dart';
import '../games/tic_tac_toe.dart';
import '../games/xo_ad_frequency.dart';
import '../games/game_stages.dart';
import '../games/stage_clock.dart';
import '../widgets/game_countdown.dart';
import '../widgets/game_result_dialog.dart';
import '../services/game_audio.dart';
import '../widgets/game_3d_tile.dart';
import '../widgets/game_stage_strip.dart';
import '../services/game_interstitial_ads.dart';
import '../data/app_store.dart';
import '../services/ads_service.dart';

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key, required this.mode,
    required this.english, required this.store});
  final GameMode mode;
  final bool english;
  final AppStore store;

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen>
    with WidgetsBindingObserver {
  final StageClock _clock = StageClock();
  bool _resultOpen = false;
  void _startClock() {
    _clock.start(GameStages.secondsFor('xo', _stage),
      () => _showEnd(timedOut: true));
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_resultOpen) {
      _clock.resume();
    } else { _clock.pause(); }
  }
  Future<void> _showEnd({bool timedOut = false}) async {
    if (!mounted || _resultOpen) return;
    _resultOpen = true;
    _clock.stop();
    final outcome = timedOut ? GameOutcome.timeout :
      game.isDraw ? GameOutcome.draw :
      widget.mode == GameMode.computer && game.winner == 'O'
        ? GameOutcome.loss : GameOutcome.win;
    final result = timedOut
      ? (widget.english ? 'Round timed out' : 'انتهى وقت الجولة')
      : game.isDraw ? (widget.english ? 'Draw' : 'تعادل')
      : (widget.english ? 'Winner: ' : 'الفائز: ') + (game.winner ?? '');
    final earned = _stageComplete &&
        !timedOut && outcome == GameOutcome.win;
    final stars = earned
        ? (widget.mode == GameMode.computer ? 3 : 2)
        : outcome == GameOutcome.win ? 1 : 0;
    final award = earned
        ? await widget.store.earnGameStars('xo', _stage, stars)
        : null;
    if (!mounted) return;
    final action = await GameResultDialog.show(context,
      game: 'XO', outcome: outcome, english: widget.english,
      result: result, stage: _stage,
      stars: stars,
      remaining: _clock.seconds.value,
      hasNext: _stageComplete && _stage < GameStages.count,
      pointsEarned: award?.earnedPoints ?? 0,
      badgeEarned: award?.newBadges.isNotEmpty == true
          ? award!.newBadges.first : null,
      trophyUnlocked: award?.trophyUnlocked);
    if (!mounted) return;
    _resultOpen = false;
    if (action == GameResultAction.list) {
      Navigator.of(context).pop();
    } else {
      await _playAgain();
    }
  }

  late TicTacToeGame game;
  int _stage = 1;
  int _matchesFinished = 0;
  bool _stageComplete = false;
  void _selectStage(int stage) {
    if (_resultOpen || _replayPending ||
        stage > widget.store.unlockedGameStage('xo')) return;
    setState(() {
      _stage = stage;
      _matchesFinished = 0;
      _stageComplete = false;
      game = TicTacToeGame(widget.mode, difficulty: _stage);
    });
    _startClock();
  }
  void _startNewRound() {
    if (_stageComplete && _stage < GameStages.count) {
      _stage++;
      _matchesFinished = 0;
      _stageComplete = false;
      game = TicTacToeGame(widget.mode, difficulty: _stage);
    } else {
      game.reset();
      if (_stageComplete) {
        _stageComplete = false;
        _matchesFinished = 0;
      }
    }
    _startClock();
  }
  late final GameInterstitialAds _interstitial =
      GameInterstitialAds(ageGroup: widget.store.settings.ageGroup);
  bool _replayPending = false;

  @override
  void initState() {
    super.initState();
    _stage = widget.store.unlockedGameStage('xo');
    game = TicTacToeGame(widget.mode, difficulty: _stage);
    WidgetsBinding.instance.addObserver(this);
    _startClock();
    if (widget.store.xoAdRounds >= XoAdFrequency.roundsPerBreak - 1) {
      unawaited(_interstitial.preload());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    _interstitial.dispose();
    super.dispose();
  }

  void _move(int index) {
    if (_resultOpen || !game.play(index)) return;
    GameAudio.play(GameSound.tap);
    if (game.finished) {
      final earned = game.winner != null &&
          (widget.mode == GameMode.friend || game.winner == 'X');
      if (earned) _matchesFinished++;
      if (_matchesFinished >= GameStages.xoRounds(_stage)) {
        _stageComplete = true;
      }
      unawaited(widget.store.noteXoGameCompleted());
      if (widget.store.xoAdRounds >= XoAdFrequency.roundsPerBreak - 1) {
        unawaited(_interstitial.preload());
      }
    }
    setState(() {});
    if (game.finished) unawaited(_showEnd());
  }

  Future<void> _playAgain() async {
    if (_replayPending) return;
    if (!game.finished || !widget.store.xoAdBreakDue ||
        !_interstitial.isReady) {
      setState(_startNewRound);
      return;
    }
    // Remove the bottom banner before opening a full-screen placement.
    // Avoid concurrent ad views and release the WebView before the transition.
    setState(() => _replayPending = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    try {
      final shown = await _interstitial.showIfStillApproved(
          canShow: () => mounted &&
              (ModalRoute.of(context)?.isCurrent ?? false));
      if (shown) await widget.store.noteXoInterstitialShown();
    } catch (_) {
      // No ad failures may block the next round.
    } finally {
      if (mounted) {
        setState(() {
          _startNewRound();
          _replayPending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S(widget.english);
    final status = game.winner != null
        ? (game.winner == 'X'
            ? s.t('الفائز X 🎉', 'X wins! 🎉')
            : s.t('الفائز O 🎉', 'O wins! 🎉'))
        : game.isDraw
            ? s.t('تعادل! 🤝', "It's a draw! 🤝")
            : s.t('دور اللاعب ', 'Player ') + game.currentPlayer;
    return Directionality(
      textDirection: widget.english ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('XO • Tic Tac Toe')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            child: LayoutBuilder(
              builder: (context, bounds) => Center(
                child: FittedBox(
                  key: const Key('xo-fit-canvas'),
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 365,
                    height: 560,
                    child: Column(children: [
                      Container(
                        width: double.infinity,
                        height: 83,
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(21),
                          boxShadow: const [BoxShadow(
                            color: Color(0x2C5984BF),
                            blurRadius: 8, offset: Offset(0, 4))]),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(widget.mode == GameMode.computer
                                ? s.t('أنت X • الكمبيوتر O',
                                    'You: X • Computer: O')
                                : s.t('لاعب X • لاعب O',
                                    'Player X • Player O'),
                              maxLines: 1,
                              style: const TextStyle(
                                color: Brand.muted,
                                fontWeight: FontWeight.w700)),
                            const SizedBox(height: 5),
                            Text(status,
                              key: const Key('xo-status'),
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Brand.navy, fontSize: 23,
                                fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(child: GameCountdown(clock: _clock)),
                      const SizedBox(height: 9),
                      GameStageStrip(
                        current: _stage,
                        unlocked: widget.store.unlockedGameStage('xo'),
                        english: widget.english,
                        onSelect: _selectStage,
                      ),
                      const SizedBox(height: 9),
                      Text(_stageComplete
                          ? s.t('أحسنت! المرحلة اكتملت ⭐',
                              'Stage cleared! ⭐')
                          : s.t('جولات المرحلة: ', 'Stage rounds: ') +
                              _matchesFinished.toString() + ' / ' +
                              GameStages.xoRounds(_stage).toString(),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Brand.navy, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Expanded(child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: GridView.builder(
                            key: const Key('xo-board'),
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 9,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8),
                            itemBuilder: (context, index) {
                              final mark = game.cells[index];
                              final color = mark == 'X'
                                  ? const Color(0xFF8AE7FF)
                                  : mark == 'O'
                                      ? const Color(0xFFFFA9D4)
                                      : const Color(0xFFDCEBFF);
                              return Game3DTile(
                                key: Key('xo-cell-' + index.toString()),
                                label: 'Cell ' + (index + 1).toString() +
                                    (mark.isEmpty ? ' empty' : ' ' + mark),
                                color: color,
                                radius: 18,
                                onTap: _resultOpen || game.finished ||
                                        mark.isNotEmpty
                                    ? null : () => _move(index),
                                child: Text(mark,
                                  style: TextStyle(
                                    fontSize: 53,
                                    fontWeight: FontWeight.w900,
                                    color: mark == 'X'
                                        ? const Color(0xFF006BCD)
                                        : const Color(0xFFC81D8B),
                                    shadows: const [
                                      Shadow(color: Color(0x77FFFFFF),
                                        blurRadius: 2,
                                        offset: Offset(-1, -2)),
                                      Shadow(color: Color(0x551B2C7F),
                                        blurRadius: 3,
                                        offset: Offset(2, 4)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      )),
                      const SizedBox(height: 8),
                      Text(s.t('رتّب 3 علامات في صف أو عمود أو قطر لتفوز.',
                          'Get three marks in a row, column or diagonal to win.'),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Brand.muted, fontSize: 12)),
                    ]),
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
              padding: const EdgeInsets.fromLTRB(20, 7, 20, 9),
              child: FilledButton.icon(
                key: const Key('xo-reset'),
                onPressed: _replayPending || _resultOpen
                    ? null : _playAgain,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(_replayPending
                    ? s.t('جاري فتح الإعلان...', 'Opening ad...')
                    : (game.finished && widget.store.xoAdBreakDue &&
                            _interstitial.isReady)
                        ? s.t('متابعة (إعلان ثم جولة جديدة)',
                            'Continue (ad, then next round)')
                        : _stageComplete && _stage < GameStages.count
                            ? s.t('المرحلة التالية', 'Next stage')
                            : s.t('العب من جديد', 'Play again')),
              ),
            )),
            if (!_replayPending)
              SchoolBanner(key: const Key('xo-footer-ad'), store: widget.store),
          ],
        ),
      ),
    );
  }
}
