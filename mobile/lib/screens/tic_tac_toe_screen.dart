import 'dart:async';

import 'package:flutter/material.dart';

import '../core/brand.dart';
import '../core/strings.dart';
import '../games/tic_tac_toe.dart';
import '../games/xo_ad_frequency.dart';
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

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  late final TicTacToeGame game = TicTacToeGame(widget.mode);
  late final GameInterstitialAds _interstitial =
      GameInterstitialAds(ageGroup: widget.store.settings.ageGroup);
  bool _replayPending = false;

  @override
  void initState() {
    super.initState();
    if (widget.store.xoAdRounds >= XoAdFrequency.roundsPerBreak - 1) {
      unawaited(_interstitial.preload());
    }
  }

  @override
  void dispose() {
    _interstitial.dispose();
    super.dispose();
  }

  void _move(int index) {
    if (!game.play(index)) return;
    setState(() {});
    if (game.finished) {
      unawaited(widget.store.noteXoGameCompleted());
      if (widget.store.xoAdRounds >= XoAdFrequency.roundsPerBreak - 1) {
        unawaited(_interstitial.preload());
      }
    }
  }

  Future<void> _playAgain() async {
    if (_replayPending) return;
    if (!game.finished || !widget.store.xoAdBreakDue ||
        !_interstitial.isReady) {
      setState(game.reset);
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
          game.reset();
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22)),
                child: Column(children: [
                  Text(widget.mode == GameMode.computer
                      ? s.t('أنت X • الكمبيوتر O', 'You: X • Computer: O')
                      : s.t('لاعب X • لاعب O', 'Player X • Player O'),
                    style: const TextStyle(color: Brand.muted,
                        fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(status, key: const Key('xo-status'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Brand.navy, fontSize: 24,
                        fontWeight: FontWeight.w900)),
                ]),
              ),
              const SizedBox(height: 24),
              Center(child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 9,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 9,
                      mainAxisSpacing: 9),
                    itemBuilder: (context, index) {
                      final mark = game.cells[index];
                      return Semantics(
                        label: 'Cell ' + (index + 1).toString() +
                            (mark.isEmpty ? ' empty' : ' ' + mark),
                        button: true,
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            key: Key('xo-cell-' + index.toString()),
                            borderRadius: BorderRadius.circular(16),
                            onTap: game.finished || mark.isNotEmpty
                                ? null : () => _move(index),
                            child: Center(child: Text(mark,
                              style: TextStyle(
                                fontSize: 54,
                                fontWeight: FontWeight.w900,
                                color: mark == 'X'
                                    ? Brand.blue : Brand.green))),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )),
              const SizedBox(height: 18),
              Text(s.t('رتّب 3 علامات في صف أو عمود أو قطر لتفوز.',
                  'Get three marks in a row, column or diagonal to win.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Brand.muted)),
            ],
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_replayPending)
              SchoolBanner(key: const Key('xo-footer-ad'), store: widget.store),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: FilledButton.icon(
                  key: const Key('xo-reset'),
                  onPressed: _replayPending ? null : _playAgain,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(_replayPending
                      ? s.t('جاري فتح الإعلان...', 'Opening ad...')
                      : (game.finished && widget.store.xoAdBreakDue &&
                              _interstitial.isReady)
                          ? s.t('متابعة (إعلان ثم جولة جديدة)',
                              'Continue (ad, then next round)')
                          : s.t('العب من جديد', 'Play again')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
