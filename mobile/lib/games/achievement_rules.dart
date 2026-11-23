import 'game_stages.dart';

/// Best-result rewards: no farming by replaying a previously cleared level.
class GameAward {
  const GameAward({
    required this.earnedPoints,
    required this.bestStars,
    required this.newBadges,
    required this.stageUnlocked,
  });
  final int earnedPoints;
  final int bestStars;
  final List<String> newBadges;
  final bool stageUnlocked;
}

class AchievementRules {
  static const games = ['xo', 'math', 'words', 'sudoku'];
  static const trophyMilestones = [10, 50, 100, 250, 500, 1000];
  static const badgeIds = [
    'first-win', 'five-perfect', 'ten-clears', 'word-explorer',
    'sudoku-solver', 'twenty-five', 'hundred-clears',
  ];

  static int pointsFor(int stars) {
    final s = stars.clamp(0, 3).toInt();
    return switch (s) { 0 => 0, 1 => 40, 2 => 100, _ => 180 };
  }

  static int earnedPoints(int oldStars, int newStars) {
    final old = pointsFor(oldStars);
    final next = pointsFor(newStars);
    return next > old ? next - old + (oldStars == 0 ? 20 : 0) : 0;
  }

  static List<String> badgesFor(Map<String, int> stars) {
    final clears = stars.values.where((s) => s > 0).length;
    final perfect = stars.values.where((s) => s == 3).length;
    final words = stars.entries.where((e) =>
      e.key.contains(':words:') && e.value > 0).length;
    final sudoku = stars.entries.where((e) =>
      e.key.contains(':sudoku:') && e.value > 0).length;
    return [
      if (clears >= 1) 'first-win',
      if (perfect >= 5) 'five-perfect',
      if (clears >= 10) 'ten-clears',
      if (words >= 10) 'word-explorer',
      if (sudoku >= 10) 'sudoku-solver',
      if (clears >= 25) 'twenty-five',
      if (clears >= 100) 'hundred-clears',
    ];
  }

  static int trophyCount(Map<String, int> stars) {
    final cleared = stars.values.where((s) => s > 0).length;
    return trophyMilestones.where((v) => cleared >= v).length;
  }

  static int maxLevel(int requested) => GameStages.clamp(requested);
}
