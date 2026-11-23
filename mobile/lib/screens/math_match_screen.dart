import 'package:flutter/material.dart';
import '../core/brand.dart';
import '../core/strings.dart';
import '../data/app_store.dart';
import '../games/math_match.dart';
import '../services/ads_service.dart';
import '../widgets/game_3d_art.dart';

class MathMatchScreen extends StatefulWidget {
  const MathMatchScreen({super.key, required this.store});
  final AppStore store;
  @override State<MathMatchScreen> createState() => _MathMatchScreenState();
}

class _MathMatchScreenState extends State<MathMatchScreen> {
  late final MathMatchGame game = MathMatchGame(
    level: widget.store.settings.level,
    schoolClass: widget.store.settings.schoolClass);

  @override Widget build(BuildContext context) {
    final s = S(widget.store.settings.english);
    return Directionality(
      textDirection: widget.store.settings.english
        ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('Math Match')),
        body: SafeArea(child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
            const SizedBox(height: 16),
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
                    ? s.t('انتهت الجولة! نتيجتك: ',
                        'Round complete! Your score: ') +
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
                return Material(
                  color: correct ? const Color(0xFFE2F9EB) :
                    wrong ? const Color(0xFFFFE6EC) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    key: Key('math-choice-' + index.toString()),
                    onTap: game.answered ? null :
                      () => setState(() => game.choose(value)),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(width: 2,
                          color: correct ? Brand.green :
                            wrong ? const Color(0xFFD85064) :
                            const Color(0xFFE3EAF3))),
                      child: Text(value.toString(), style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w900,
                        color: Brand.navy))),
                  ),
                );
              },
            ),

          ],
        )),
        bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
          SchoolBanner(store: widget.store),
          SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: FilledButton.icon(
              key: const Key('math-next'),
              onPressed: !game.answered ? null : () => setState(() {
                if (game.finished) { game.reset(); } else { game.next(); }
              }),
              icon: Icon(game.finished ? Icons.refresh : Icons.arrow_forward),
              label: Text(game.finished
                ? s.t('العب من جديد', 'Play again')
                : s.t('السؤال التالي', 'Next question'))))),
        ]),
      ),
    );
  }
}
