import 'dart:async';
import 'package:flutter/material.dart';
import '../core/brand.dart';
import '../core/strings.dart';
import '../data/app_store.dart';
import '../games/math_match.dart';
import '../games/game_stages.dart';
import '../games/stage_clock.dart';
import '../widgets/game_countdown.dart';
import '../widgets/game_result_dialog.dart';
import '../services/game_audio.dart';
import '../widgets/game_stage_strip.dart';
import '../widgets/game_3d_tile.dart';
import '../services/ads_service.dart';
import '../widgets/game_3d_art.dart';

class MathMatchScreen extends StatefulWidget {
  const MathMatchScreen({super.key, required this.store});
  final AppStore store;
  @override State<MathMatchScreen> createState() => _MathMatchScreenState();
}

class _MathMatchScreenState extends State<MathMatchScreen>
    with WidgetsBindingObserver {
  final StageClock _clock = StageClock();
  bool _resultOpen = false;
  bool _timedOut = false;
  void _startClock() {
    _clock.start(GameStages.secondsFor('math', _stage),
      () => _finishStage(timedOut: true));
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

  Future<void> _finishStage({bool timedOut = false}) async {
    if (_resultOpen || !mounted) return;
    _resultOpen = true;
    _timedOut = timedOut;
    _clock.stop();
    final passed = !timedOut && _passed;
    if (passed) await widget.store.completeGameStage('math', _stage);
    if (!mounted) return;
    final action = await GameResultDialog.show(context,
      game: 'Math Match',
      outcome: timedOut ? GameOutcome.timeout :
        passed ? GameOutcome.win : GameOutcome.loss,
      english: widget.store.settings.english,
      result: game.score.toString() + ' / ' + game.totalRounds.toString(),
      stage: _stage, remaining: _clock.seconds.value,
      stars: passed ? (game.score == game.totalRounds ? 3 : 2) : 1,
      hasNext: passed && _stage < GameStages.count);
    if (!mounted) return;
    if (action == GameResultAction.list) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      if (action == GameResultAction.next &&
          passed && _stage < GameStages.count) _stage++;
      game = _createGame(_stage);
      _timedOut = false;
      _resultOpen = false;
    });
    _startClock();
  }

  late MathMatchGame game;
  int _stage = 1;
  MathMatchGame _createGame(int stage) => MathMatchGame(
    level: widget.store.settings.level,
    schoolClass: widget.store.settings.schoolClass,
    stage: stage,
    totalRounds: GameStages.mathRounds(stage),
    seed: 2026 + stage,
  );
  @override void initState() {
    super.initState();
    _stage = widget.store.unlockedGameStage('math');
    game = _createGame(_stage);
    WidgetsBinding.instance.addObserver(this);
    _startClock();
  }
  void _selectStage(int stage) {
    if (_resultOpen || stage > widget.store.unlockedGameStage('math')) return;
    setState(() {
      _stage = stage;
      game = _createGame(stage);
    });
    _startClock();
  }
  bool get _passed => GameStages.mathPassed(
    correct: game.score, total: game.totalRounds);
  void _choose(int value) {
    if (_resultOpen || _timedOut || !game.choose(value)) return;
    GameAudio.play(game.correct ? GameSound.correct : GameSound.incorrect);
    setState(() {});
    if (game.finished) unawaited(_finishStage());
  }
  void _advance() {
    if (_resultOpen || game.finished || _timedOut || !game.answered) return;
    setState(game.next);
  }

  @override Widget build(BuildContext context) {
    final s = S(widget.store.settings.english);
    return Directionality(
      textDirection: widget.store.settings.english
        ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('Math Match')),
        body: SafeArea(child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 160),
          children: [
            Row(children: [
              const Game3DArt(kind: GameArtKind.math, size: 84),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.t('تحدي الرياضيات', 'Math Challenge'),
                    style: const TextStyle(fontSize: 22, color: Brand.navy,
                      fontWeight: FontWeight.w900)),
                  Text(s.t('اختار الإجابة الصحيحة.',
                    'Choose the right answer.'),
                    style: const TextStyle(color: Brand.muted)),
                ])),
            ]),
            const SizedBox(height: 10),
            GameStageStrip(current: _stage,
              unlocked: widget.store.unlockedGameStage('math'),
              english: widget.store.settings.english,
              onSelect: _selectStage),
            const SizedBox(height: 13),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              GameCountdown(clock: _clock),
              Text(s.t('السؤال ', 'Question ') + game.round.toString() +
                  ' / ' + game.totalRounds.toString(),
                style: const TextStyle(color: Brand.navy,
                    fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(s.t('السؤال ', 'Question ') + game.round.toString() +
                   ' / ' + game.totalRounds.toString(),
                style: const TextStyle(color: Brand.navy,
                  fontWeight: FontWeight.w800)),
              Text(s.t('النقاط: ', 'Score: ') + game.score.toString(),
                style: const TextStyle(color: Brand.blue,
                  fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 9),
            LinearProgressIndicator(
              value: game.round / game.totalRounds, minHeight: 7,
              borderRadius: BorderRadius.circular(7),
              backgroundColor: const Color(0xFFE1E9F4)),
            const SizedBox(height: 22),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color(0xFFF5EEFF), Color(0xFFDCEBFF)]),
                borderRadius: BorderRadius.circular(24)),
              child: Text(game.question.expression,
                key: const Key('math-question'),
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: Brand.navy,
                  fontSize: 34, fontWeight: FontWeight.w900))),
            if (game.answered) ...[
              const SizedBox(height: 17),
              Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: game.correct ? const Color(0xFFDDF9E8) :
                    const Color(0xFFFFF1DC),
                  borderRadius: BorderRadius.circular(16)),
                child: Text(game.finished
                    ? (_passed
                        ? s.t('تم اجتياز المرحلة! ⭐ النتيجة: ', 'Stage cleared! ⭐ Score: ')
                        : s.t('حاول مرة أخرى. النتيجة: ', 'Try again. Score: ')) +
                      game.score.toString() + '/' + game.totalRounds.toString()
                    : game.correct
                        ? s.t('ممتاز! إجابة صحيحة.', 'Great! Correct answer.')
                        : s.t('الإجابة الصحيحة: ', 'Correct answer: ') +
                          game.question.answer.toString(),
                  key: const Key('math-feedback'),
                  style: const TextStyle(color: Brand.navy,
                    fontWeight: FontWeight.w800))),
            ],            const SizedBox(height: 18),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: game.question.choices.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 2,
                mainAxisSpacing: 10, crossAxisSpacing: 10),
              itemBuilder: (_, index) {
                final value = game.question.choices[index];
                final correct = game.answered && value == game.question.answer;
                final wrong = game.selected == value && !game.correct;
                return Game3DTile(
                  key: Key('math-choice-' + index.toString()),
                  radius: 19,
                  color: correct ? const Color(0xFF92F2C7)
                      : wrong ? const Color(0xFFFFA1BC)
                      : const Color(0xFFC9DFFF),
                  onTap: game.answered || _resultOpen || _timedOut
                      ? null : () => _choose(value),
                  child: Text(value.toString(), style: const TextStyle(
                    fontSize: 27, fontWeight: FontWeight.w900,
                    color: Brand.navy,
                    shadows: [Shadow(color: Color(0x99FFFFFF),
                      offset: Offset(-1, -2), blurRadius: 2)],
                  )),
                );
              },
            ),

          ],
        )),
        bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
          SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: FilledButton.icon(
              key: const Key('math-next'),
              onPressed: !game.answered || game.finished || _resultOpen
                  ? null : _advance,
              icon: Icon(game.finished ? Icons.refresh : Icons.arrow_forward),
              label: Text(game.finished
                ? (_passed && _stage < GameStages.count
                  ? s.t('المرحلة التالية', 'Next stage')
                  : s.t('العب من جديد', 'Play again'))
                : s.t('السؤال التالي', 'Next question'))))),
          SchoolBanner(store: widget.store),
        ]),
      ),
    );
  }
}
