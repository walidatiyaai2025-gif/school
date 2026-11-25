import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_pdf/data/app_store.dart';
import 'package:school_pdf/games/achievement_rules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('first completion gives XP, stars, badge and next stage', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    final award = await store.earnGameStars('sudoku', 1, 3);
    expect(award.bestStars, 3);
    expect(award.earnedPoints, AchievementRules.pointsFor(3)+20);
    expect(award.newBadges, contains('first-win'));
    expect(store.unlockedGameStage('sudoku'), 2);
    expect(store.totalGameStars, 3);
    expect(store.totalGamePoints, 200);
    expect(store.clearedGameStages, 1);
    final repeat = await store.earnGameStars('sudoku', 1, 3);
    expect(repeat.earnedPoints, 0);
    expect(store.totalGamePoints, 200);
    expect((await AppStore.load()).totalGamePoints, 200);
    expect((await AppStore.load()).bestStarsFor('sudoku', 1), 3);
  });

  test('replay upgrades only the difference and locked levels earn nothing',
      () async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    expect((await store.earnGameStars('math', 2, 3)).earnedPoints, 0);
    expect((await store.earnGameStars('math', 1, 1)).earnedPoints, 60);
    expect((await store.earnGameStars('math', 1, 2)).earnedPoints, 60);
    expect((await store.earnGameStars('math', 1, 3)).earnedPoints, 80);
    expect((await store.earnGameStars('math', 1, 3)).earnedPoints, 0);
    expect(store.totalGamePoints, 200);
    expect(store.unlockedGameStage('math'), 2);
    expect(store.bestStarsFor('math', 1), 3);
    expect(store.bestStarsFor('words', 1), 0);
    store.settings.level = 'middle';
    expect(store.unlockedGameStage('math'), 1);
    expect(store.bestStarsFor('math', 1), 0);
  });

  test('prior unlocked stages migrate to bronze rewards once', () async {
    SharedPreferences.setMockInitialValues({});
    final old = await AppStore.load();
    await old.completeGameStage('words', 1);
    await old.completeGameStage('words', 2);
    final upgraded = await AppStore.load();
    expect(upgraded.unlockedGameStage('words'), 3);
    expect(upgraded.bestStarsFor('words', 1), 1);
    expect(upgraded.bestStarsFor('words', 2), 1);
    expect(upgraded.totalGamePoints, 120);
    expect((await AppStore.load()).totalGamePoints, 120);
  });

  test('badges and trophies require genuine unique stage clears', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    for (var stage = 1; stage <= 10; stage++) {
      final award = await store.earnGameStars('sudoku', stage, 3);
      expect(award.bestStars, 3);
      if (stage == 10) expect(award.trophyUnlocked, 10);
    }
    expect(store.clearedGameStages, 10);
    expect(store.gameTrophies, 1);
    expect(store.gameBadgeIds, containsAll([
      'first-win', 'five-perfect', 'ten-clears', 'sudoku-solver']));
    expect(store.totalGamePoints, 2000);
    final same = await store.earnGameStars('sudoku', 5, 3);
    expect(same.earnedPoints, 0);
    expect(store.gameTrophies, 1);
    expect((await AppStore.load()).gameTrophies, 1);
  });
}
