import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'models.dart';
import '../games/xo_ad_frequency.dart';
import '../games/game_stages.dart';
import '../games/achievement_rules.dart';

class AppStore extends ChangeNotifier {
  AppStore._(this._prefs);
  final SharedPreferences _prefs;
  StudentSettings settings = StudentSettings();
  final List<PdfRecord> records = [];
  static const _pendingCaptureKey = 'pending_capture_subject_v1';
  static const _xoAdRoundKey = 'xo_completed_since_interstitial_v1';
  int _xoAdRounds = 0;
  static const _stagesKey = 'game_unlocked_stages_v1';
  final Map<String, int> _gameStages = <String, int>{};
  static const _bestStarsKey = 'game_best_stars_v1';
  static const _rewardTotalKey = 'game_reward_points_v1';
  final Map<String, int> _bestStars = <String, int>{};
  int _rewardPoints = 0;

  Map<String, int> get bestGameStars => Map.unmodifiable(_bestStars);
  int get totalGamePoints => _rewardPoints;
  int get totalGameStars => _bestStars.values.fold<int>(0, (a, b) => a + b);
  int get clearedGameStages => _bestStars.values.where((s) => s > 0).length;
  int get gameTrophies => AchievementRules.trophyCount(_bestStars);
  List<String> get gameBadgeIds => AchievementRules.badgesFor(_bestStars);
  int bestStarsFor(String game, int stage) =>
      _bestStars['${settings.level}:$game:${GameStages.clamp(stage)}'] ?? 0;

  /// Replays may improve a personal best, but cannot farm points.
  Future<GameAward> earnGameStars(String game, int stage, int stars) async {
    final clampedStage = GameStages.clamp(stage);
    if (!AchievementRules.games.contains(game) || clampedStage != stage ||
        stars < 1 || stars > 3 || stage > unlockedGameStage(game)) {
      return const GameAward(earnedPoints: 0, bestStars: 0,
          newBadges: [], stageUnlocked: false);
    }
    final key = '${settings.level}:$game:$stage';
    final old = _bestStars[key] ?? 0;
    final previousBadges = gameBadgeIds.toSet();
    final priorTrophies = gameTrophies;
    final improved = stars > old;
    final wasFrontier = stage == unlockedGameStage(game) &&
        unlockedGameStage(game) < GameStages.count;
    final points = AchievementRules.earnedPoints(old, stars);
    if (improved) {
      _bestStars[key] = stars;
      _rewardPoints += points;
    }
    if (wasFrontier) _gameStages[_gameKey(game)] = stage + 1;
    if (improved || wasFrontier) {
      notifyListeners();
      await _prefs.setString(_bestStarsKey, jsonEncode(_bestStars));
      await _prefs.setInt(_rewardTotalKey, _rewardPoints);
      await _prefs.setString(_stagesKey, jsonEncode(_gameStages));
    }
    return GameAward(
      earnedPoints: points,
      bestStars: _bestStars[key] ?? 0,
      newBadges: gameBadgeIds.where((id) => !previousBadges.contains(id))
          .toList(growable: false),
      stageUnlocked: wasFrontier,
      trophyUnlocked: gameTrophies > priorTrophies
          ? AchievementRules.trophyMilestones[gameTrophies - 1] : null,
    );
  }

  static const _hintsKey = 'word_hint_used_stages_v1';
  final Set<String> _usedWordHints = <String>{};
  bool hasUsedWordHint(int stage) =>
      _usedWordHints.contains('words:${settings.level}:${GameStages.clamp(stage)}');
  Future<bool> useWordHint(int stage) async {
    final key = 'words:${settings.level}:${GameStages.clamp(stage)}';
    if (!_usedWordHints.add(key)) return false;
    await _prefs.setStringList(_hintsKey, _usedWordHints.toList());
    notifyListeners();
    return true;
  }

  String _gameKey(String game) => '${settings.level}:$game';

  int unlockedGameStage(String game) =>
      GameStages.clamp(_gameStages[_gameKey(game)] ?? 1);

  /// Persist only forward progress, scoped by school level and minigame.
  Future<void> completeGameStage(String game, int stage) async {
    final current = unlockedGameStage(game);
    if (stage != current || current >= GameStages.count) return;
    _gameStages[_gameKey(game)] = current + 1;
    await _prefs.setString(_stagesKey, jsonEncode(_gameStages));
    notifyListeners();
  }

  int get xoAdRounds => _xoAdRounds;
  bool get xoAdBreakDue => XoAdFrequency.isBreakDue(_xoAdRounds);

  Future<void> noteXoGameCompleted() async {
    _xoAdRounds = XoAdFrequency.recordCompleted(_xoAdRounds);
    await _prefs.setInt(_xoAdRoundKey, _xoAdRounds);
  }

  /// Reset the counter only after an interstitial has actually been shown.
  Future<void> noteXoInterstitialShown() async {
    _xoAdRounds = 0;
    await _prefs.setInt(_xoAdRoundKey, 0);
  }

  String? get pendingCaptureSubject => _prefs.getString(_pendingCaptureKey);

  Future<void> rememberCaptureSubject(String subject) async {
    await _prefs.setString(_pendingCaptureKey, subject);
  }

  Future<void> clearPendingCaptureSubject() async {
    await _prefs.remove(_pendingCaptureKey);
  }

  static Future<AppStore> load() async {
    final p = await SharedPreferences.getInstance();
    final store = AppStore._(p);
    final savedRounds = p.getInt(_xoAdRoundKey) ?? 0;
    store._xoAdRounds = savedRounds < 0 ? 0 :
        (savedRounds > XoAdFrequency.roundsPerBreak
            ? XoAdFrequency.roundsPerBreak : savedRounds);
    try {
      final raw = p.getString('settings_v1');
      if (raw != null) store.settings = StudentSettings.fromJson(jsonDecode(raw) as Map<String,dynamic>);
    } catch (_) { /* Corrupt settings should not crash startup. */ }
    try {
      final raw = p.getString('files_v1');
      if (raw != null) {
        for (final j in (jsonDecode(raw) as List)) {
          try {
            final doc = PdfRecord.fromJson(Map<String,dynamic>.from(j as Map));
            if (await File(doc.path).exists()) store.records.add(doc);
          } catch (_) { /* skip corrupt entry */ }
        }
      }
    } catch (_) { /* preserve documents on disk even if metadata is broken */ }
    try {
      final raw = p.getString(_stagesKey);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in json.entries) {
          if (entry.value is int) {
            store._gameStages[entry.key] = GameStages.clamp(entry.value as int);
          }
        }
      }
    } catch (_) { /* Damaged progress must not block offline game access. */ }
    try {
      final raw = p.getString(_bestStarsKey);
      if (raw != null) {
        final values = jsonDecode(raw);
        if (values is Map) {
          for (final entry in values.entries) {
            if (entry.key is String && entry.value is int &&
                (entry.value as int) >= 1 && (entry.value as int) <= 3) {
              store._bestStars[entry.key as String] = entry.value as int;
            }
          }
        }
      }
      store._rewardPoints = (p.getInt(_rewardTotalKey) ?? 0)
          .clamp(0, 1000000000).toInt();
    } catch (_) { /* Damaged rewards must not block the student. */ }
    // Previous game levels earn a bronze recognition once at first upgrade.
    if (p.getString(_bestStarsKey) == null && store._gameStages.isNotEmpty) {
      for (final item in store._gameStages.entries) {
        final pos = item.key.lastIndexOf(':');
        if (pos <= 0 || !AchievementRules.games.contains(
            item.key.substring(pos + 1))) continue;
        for (var stage = 1; stage < item.value; stage++) {
          store._bestStars['${item.key}:$stage'] = 1;
          store._rewardPoints += AchievementRules.earnedPoints(0, 1);
        }
      }
      await p.setString(_bestStarsKey, jsonEncode(store._bestStars));
      await p.setInt(_rewardTotalKey, store._rewardPoints);
    }
    try {
      store._usedWordHints.addAll(p.getStringList(_hintsKey) ?? const <String>[]);
    } catch (_) { /* Corrupt hint metadata must not block play. */ }
    store.records.sort((a,b)=>b.createdAt.compareTo(a.createdAt));
    return store;
  }
  Future<void> saveSettings() async {
    await _prefs.setString('settings_v1',jsonEncode(settings.toJson()));
    notifyListeners();
  }
  Future<void> addRecord(PdfRecord doc) async {
    records.insert(0, doc);
    await _persistRecords();
  }
  Future<void> noteShareOpened(String id) async {
    final i = records.indexWhere((x)=>x.id==id);
    if (i<0) return;
    records[i] = records[i].copyWith(
      shareAttempts: records[i].shareAttempts+1,
      lastShareAttempt: DateTime.now());
    await _persistRecords();
  }
  Future<void> rename(String id,String newName) async {
    final i = records.indexWhere((x)=>x.id==id);
    if (i<0) return;
    final old = records[i];
    final safe = safeFilename(newName).replaceAll(RegExp(r'\.pdf$',caseSensitive:false),'');
    if (safe.trim().isEmpty) throw const FormatException('Invalid name');
    final src = File(old.path);
    final dest = File('${src.parent.path}/$safe.pdf');
    if (await dest.exists() && dest.path!=src.path) {
      throw const FileSystemException('A file with that name already exists');
    }
    if (dest.path!=src.path) await src.rename(dest.path);
    records[i] = PdfRecord(id:old.id,filename:'$safe.pdf',path:dest.path,
      student:old.student,schoolClass:old.schoolClass,
      subject:old.subject,level:old.level,createdAt:old.createdAt,
      pageCount:old.pageCount,bytes:old.bytes,
      shareAttempts:old.shareAttempts,lastShareAttempt:old.lastShareAttempt);
    await _persistRecords();
  }
  Future<void> delete(String id) async {
    final i=records.indexWhere((x)=>x.id==id);
    if(i<0) return;
    final file=File(records[i].path);
    if(await file.exists()) await file.delete();
    records.removeAt(i);
    await _persistRecords();
  }
  /// Delete ONLY the app-managed PDF directory, not gallery originals or
  /// files the user exported to other locations. Keep server-deletion retry
  /// credentials in SharedPreferences until TelemetryService confirms removal.
  Future<void> deleteLocalProfileAndPdfs({Directory? documentsDirectory}) async {
    final documents = documentsDirectory ?? await getApplicationDocumentsDirectory();
    final appPdfDirectory = Directory(p.join(documents.path, 'schoolpdf', 'pdf'));
    // On failure, retain settings/metadata so the user can retry and see the
    // error instead of receiving a false "data deleted" confirmation.
    // Reject file/symlink substitutions rather than accidentally deleting
    // a directory outside app-managed storage.
    final appRoot = Directory(p.join(documents.path, 'schoolpdf'));
    final rootType = await FileSystemEntity.type(appRoot.path, followLinks: false);
    final pdfType = await FileSystemEntity.type(appPdfDirectory.path, followLinks: false);
    if (rootType == FileSystemEntityType.link ||
        pdfType == FileSystemEntityType.link ||
        pdfType == FileSystemEntityType.file) {
      throw FileSystemException('Unexpected School PDF storage path', appPdfDirectory.path);
    }
    if (pdfType == FileSystemEntityType.directory) {
      await appPdfDirectory.delete(recursive: true);
    }
    await _prefs.remove('files_v1');
    await _prefs.remove('settings_v1');
    await _prefs.remove(_pendingCaptureKey);
    await _prefs.remove(_xoAdRoundKey);
    await _prefs.remove(_stagesKey);
    await _prefs.remove(_bestStarsKey);
    await _prefs.remove(_rewardTotalKey);
    await _prefs.remove(_hintsKey);
    _usedWordHints.clear();
    _gameStages.clear();
    _bestStars.clear();
    _rewardPoints = 0;
    _xoAdRounds = 0;
    records.clear();
    settings = StudentSettings();
    notifyListeners();
  }

  Future<void> _persistRecords() async {
    await _prefs.setString('files_v1',encodeRecords(records));
    notifyListeners();
  }
}

String safeFilename(String input) {
  final stripped = input.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'),'_')
      .replaceAll(RegExp(r'\s+'),'_').replaceAll(RegExp(r'_{2,}'),'_').trim();
  return stripped.length>90?stripped.substring(0,90):stripped;
}
