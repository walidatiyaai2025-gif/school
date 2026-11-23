import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'models.dart';
import '../games/xo_ad_frequency.dart';
import '../games/game_stages.dart';

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

  String _gameKey(String game) => '${'${settings.level}'}:$game';

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
    _gameStages.clear();
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
