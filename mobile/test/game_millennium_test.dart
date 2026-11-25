import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_pdf/data/app_store.dart';
import 'package:school_pdf/games/game_stages.dart';
import 'package:school_pdf/games/word_hunt.dart';
import 'package:school_pdf/games/math_match.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('level 1 and 1000 generate finite valid games for every age', () {
    for (final stage in [1, 2, 3, 4, 12, 80, 500, 999, 1000]) {
      for (final level in ['primary','middle','secondary','university']) {
        final word = WordHuntGame(level: level, stage: stage, seed: stage);
        for (final target in word.targets) {
          expect(word.wordPath(target).length, target.length,
              reason: '$level $stage: $target');
          expect(target.length, lessThanOrEqualTo(7));
        }
        final math = MathMatchGame(level: level, stage: stage,
          schoolClass: 'Year 6', seed: stage,
          totalRounds: GameStages.mathRounds(stage));
        expect(math.question.choices.toSet().length, 4);
        expect(GameStages.secondsFor('math', stage), greaterThan(0));
      }
    }
  });

  test('word hint can only be used once per stage even after relaunch', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    expect(store.hasUsedWordHint(1), isFalse);
    expect(await store.useWordHint(1), isTrue);
    expect(await store.useWordHint(1), isFalse);
    expect((await AppStore.load()).hasUsedWordHint(1), isTrue);
    expect((await AppStore.load()).hasUsedWordHint(2), isFalse);
    final game = WordHuntGame(level: 'primary');
    expect(game.hintCell, isNotNull);
    expect(game.hintCell, inInclusiveRange(0, 48));
  });
}
