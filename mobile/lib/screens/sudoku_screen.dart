import 'dart:async';
import 'package:flutter/material.dart';

import '../core/brand.dart';
import '../data/app_store.dart';
import '../games/game_stages.dart';
import '../games/sudoku_game.dart';
import '../games/stage_clock.dart';
import '../services/ads_service.dart';
import '../services/game_audio.dart';
import '../widgets/game_3d_tile.dart';
import '../widgets/game_countdown.dart';
import '../widgets/game_result_dialog.dart';
import '../widgets/game_stage_strip.dart';

/// One-screen Sudoku challenge with adaptive 4x4 / 9x9 boards.
/// Pencil notes, undo and two optional hints support actual puzzle solving.
class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key, required this.store});
  final AppStore store;

  @override State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen>
    with WidgetsBindingObserver {
  final StageClock _clock = StageClock();
  late SudokuGame game;
  int _stage = 1;
  int _attempt = 0;
  int? _selected;
  bool _pencil = false;
  bool _resultOpen = false;

  bool get _english => widget.store.settings.english;
  String _t(String ar, String en) => _english ? en : ar;

  SudokuGame _newGame() => SudokuGame(
    level: widget.store.settings.level,
    stage: _stage,
    seed: 2026 + _attempt * 8191,
  );

  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _stage = widget.store.unlockedGameStage('sudoku');
    game = _newGame();
    _selected = _firstOpenCell();
    _startClock();
  }

  int? _firstOpenCell() {
    for (var i = 0; i < game.entries.length; i++) {
      if (!game.isGiven(i)) return i;
    }
    return null;
  }

  void _startClock() {
    _clock.start(GameStages.secondsFor('sudoku', _stage),
      () => _finish(timedOut: true));
  }

  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_resultOpen) {
      _clock.resume();
    } else {
      _clock.pause();
    }
  }

  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    super.dispose();
  }

  void _restart({bool next = false}) {
    if (next && _stage < GameStages.count) {
      _stage++;
      _attempt = 0;
    } else {
      _attempt++;
    }
    setState(() {
      game = _newGame();
      _selected = _firstOpenCell();
      _pencil = false;
      _resultOpen = false;
    });
    _startClock();
  }

  void _selectStage(int stage) {
    if (_resultOpen || stage > widget.store.unlockedGameStage('sudoku')) return;
    _stage = stage;
    _attempt = 0;
    _restart();
  }

  Future<void> _finish({bool timedOut = false}) async {
    if (_resultOpen || !mounted) return;
    _resultOpen = true;
    _clock.stop();
    final won = !timedOut && game.completed;
    final stars = won ? game.starsForClear(_clock.seconds.value) : 0;
    final award = won
        ? await widget.store.earnGameStars('sudoku', _stage, stars)
        : null;
    if (!mounted) return;
    final action = await GameResultDialog.show(context,
      game: 'Sudoku',
      outcome: won ? GameOutcome.win : GameOutcome.timeout,
      english: _english,
      result: _t('أخطاء: ', 'Mistakes: ') + game.mistakes.toString() +
          ' • ' + game.size.toString() + '×' + game.size.toString(),
      stage: _stage,
      stars: stars,
      remaining: _clock.seconds.value,
      hasNext: won && _stage < GameStages.count,
      pointsEarned: award?.earnedPoints ?? 0,
      badgeEarned: award?.newBadges.isNotEmpty == true
          ? award!.newBadges.first : null,
      trophyUnlocked: award?.trophyUnlocked,
    );
    if (!mounted) return;
    if (action == GameResultAction.list) {
      Navigator.of(context).pop();
    } else {
      _restart(next: won && action == GameResultAction.next);
    }
  }

  void _enter(int digit) {
    final index = _selected;
    if (_resultOpen || index == null) return;
    final changed = game.put(index, digit, pencil: _pencil);
    if (!changed) return;
    GameAudio.play(_pencil || digit == 0 ? GameSound.tap :
        game.isCorrect(index) ? GameSound.correct : GameSound.incorrect);
    setState(() {});
    if (game.completed) unawaited(_finish());
  }

  void _hint() {
    if (_resultOpen) return;
    final index = game.revealHint();
    if (index == null) return;
    setState(() => _selected = index);
    GameAudio.play(GameSound.hint);
    if (game.completed) unawaited(_finish());
  }

  @override Widget build(BuildContext context) {
    return Directionality(
      textDirection: _english ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('Sudoku')),
        body: SafeArea(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: LayoutBuilder(builder: (context, size) =>
            FittedBox(
              key: const Key('sudoku-fit-canvas'),
              fit: BoxFit.contain,
              child: SizedBox(width: 360, height: 625,
                child: Column(children: [
                  Row(children: [
                    const Icon(Icons.grid_on_rounded,
                      color: Brand.blue, size: 31),
                    const SizedBox(width: 9),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_t('سودوكو الذكاء', 'Sudoku Challenge'),
                          style: const TextStyle(color: Brand.navy,
                            fontSize: 19, fontWeight: FontWeight.w900)),
                        Text(_t('املأ كل صف وعمود ومربع بدون تكرار',
                            'Every row, column and box gets unique digits'),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10, color: Brand.muted)),
                      ],
                    )),
                    GameCountdown(clock: _clock),
                  ]),
                  const SizedBox(height: 9),
                  GameStageStrip(
                    current: _stage,
                    unlocked: widget.store.unlockedGameStage('sudoku'),
                    english: _english,
                    onSelect: _selectStage,
                  ),
                  const SizedBox(height: 7),
                  Row(children: [
                    Text(_t('الأخطاء: ', 'Mistakes: ') +
                        game.mistakes.toString(),
                      key: const Key('sudoku-mistakes'),
                      style: const TextStyle(color: Brand.navy,
                        fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text(_t('مساعدة متبقية: ', 'Hints left: ') +
                        (game.maxHints - game.hintsUsed).toString(),
                      style: const TextStyle(color: Brand.blue,
                        fontSize: 12, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 10),
                  Expanded(child: Center(child: AspectRatio(
                    aspectRatio: 1,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: GridView.builder(
                        key: const Key('sudoku-board'),
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: game.entries.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: game.size,
                          mainAxisSpacing: game.size == 9 ? 2 : 5,
                          crossAxisSpacing: game.size == 9 ? 2 : 5),
                        itemBuilder: (context, index) {
                          final value = game.entries[index];
                          final selected = _selected == index;
                          final related = _selected != null &&
                            (index ~/ game.size == _selected! ~/ game.size ||
                             index % game.size == _selected! % game.size);
                          final given = game.isGiven(index);
                          final wrong = value != 0 && !game.isCorrect(index);
                          final color = wrong
                            ? const Color(0xFFFFB9C1)
                            : selected ? const Color(0xFF8CCBFF)
                            : related ? const Color(0xFFE1ECFF)
                            : given ? const Color(0xFFD0DDFC)
                            : const Color(0xFFF3F8FF);
                          return Game3DTile(
                            key: Key('sudoku-cell-$index'),
                            radius: game.size == 9 ? 6 : 13,
                            color: color,
                            selected: selected,
                            onTap: _resultOpen ? null :
                              () => setState(() => _selected = index),
                            child: value != 0
                              ? Text(value.toString(),
                                  style: TextStyle(
                                    fontSize: game.size == 9 ? 19 : 28,
                                    fontWeight: FontWeight.w900,
                                    color: wrong ? const Color(0xFFBE2D4D)
                                        : given ? Brand.navy : Brand.blue))
                              : Text(game.notesAt(index).join(' '),
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 8, color: Brand.muted)),
                          );
                        },
                      ),
                    ),
                  ))),
                  const SizedBox(height: 9),
                  SizedBox(height: 44,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var digit = 1; digit <= game.size; digit++)
                          Expanded(child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Game3DTile(
                              key: Key('sudoku-digit-$digit'),
                              color: const Color(0xFFBFD6FF),
                              radius: 9,
                              onTap: _resultOpen ? null : () => _enter(digit),
                              child: Text(digit.toString(),
                                style: const TextStyle(fontSize: 18,
                                  color: Brand.navy,
                                  fontWeight: FontWeight.w900)),
                            ),
                          )),
                      ],
                    )),
                  const SizedBox(height: 10),
                  Row(children: [
                    _action(Icons.undo_rounded,
                      _t('تراجع', 'Undo'), 'sudoku-undo',
                      game.canUndo ? () {
                        setState(game.undo);
                        GameAudio.play(GameSound.tap);
                      } : null),
                    _action(Icons.backspace_outlined,
                      _t('مسح', 'Erase'), 'sudoku-erase',
                      _selected == null ? null : () => _enter(0)),
                    _action(Icons.edit_note_rounded,
                      _t('ملاحظات', 'Notes'), 'sudoku-notes', () {
                        setState(() => _pencil = !_pencil);
                        GameAudio.play(GameSound.tap);
                      }, active: _pencil),
                    _action(Icons.lightbulb_outline_rounded,
                      _t('مساعدة', 'Hint'), 'sudoku-hint',
                      game.hintsUsed >= game.maxHints ? null : _hint),
                  ]),
                  const SizedBox(height: 8),
                  SizedBox(height: 38, width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key('sudoku-restart'),
                      onPressed: _resultOpen ? null : () => _restart(),
                      icon: const Icon(Icons.refresh_rounded, size: 17),
                      label: Text(_t('لغز جديد', 'New puzzle')),
                    )),
                ]),
              ),
            ),
          ),
        )),
        bottomNavigationBar: SchoolBanner(store: widget.store),
      ),
    );
  }

  Widget _action(IconData icon, String text, String key,
      VoidCallback? onTap, {bool active = false}) {
    return Expanded(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: OutlinedButton(
        key: Key(key),
        onPressed: _resultOpen ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: active ? const Color(0xFFD9E8FF) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 19),
          Text(text, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10,
              fontWeight: FontWeight.w800)),
        ]),
      ),
    ));
  }
}
