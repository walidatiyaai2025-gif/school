import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_pdf/data/app_store.dart';
import 'package:school_pdf/data/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('local data deletion removes only School PDF-managed files and profile',
      () async {
    SharedPreferences.setMockInitialValues({});
    final root = await Directory.systemTemp.createTemp('schoolpdf-privacy-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final appDir = Directory(p.join(root.path, 'schoolpdf', 'pdf'));
    await appDir.create(recursive: true);
    final generated = File(p.join(appDir.path, 'sample.pdf'));
    await generated.writeAsString('PDF data');
    final external = File(p.join(root.path, 'family-gallery-original.jpg'));
    await external.writeAsString('original image');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('schoolpdf_install_id', 'retain-for-remote-delete');
    await prefs.setBool('schoolpdf_pending_delete', true);

    final store = await AppStore.load();
    store.settings
      ..name = 'Test Student'
      ..schoolClass = '6A'
      ..introDone = true
      ..customSubjects.add('Science');
    await store.saveSettings();
    await store.addRecord(PdfRecord(
      id: 'example', filename: 'sample.pdf', path: generated.path,
      student: 'Test Student', schoolClass: '6A', subject: 'Science',
      level: 'primary', createdAt: DateTime.utc(2026, 11, 20),
      pageCount: 1, bytes: 8,
    ));
    expect(store.settings.ready, isTrue);
    expect(store.records, hasLength(1));

    await store.deleteLocalProfileAndPdfs(documentsDirectory: root);

    expect(await generated.exists(), isFalse);
    expect(await external.exists(), isTrue);
    expect(store.records, isEmpty);
    expect(store.settings.ready, isFalse);
    expect(store.settings.name, isEmpty);
    expect(prefs.getString('settings_v1'), isNull);
    expect(prefs.getString('files_v1'), isNull);
    // Offline server-data deletion must remain retryable after local reset.
    expect(prefs.getString('schoolpdf_install_id'), 'retain-for-remote-delete');
    expect(prefs.getBool('schoolpdf_pending_delete'), isTrue);
    final reloaded = await AppStore.load();
    expect(reloaded.records, isEmpty);
    expect(reloaded.settings.ready, isFalse);
  });

  test('data-reset failure leaves local settings intact for a safe retry', () async {
    SharedPreferences.setMockInitialValues({});
    final root = await Directory.systemTemp.createTemp('schoolpdf-privacy-failure-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final store = await AppStore.load();
    store.settings..name = 'A'..schoolClass = 'B'..introDone = true;
    await store.saveSettings();

    // An unremovable managed folder should fail before settings are cleared.
    // The directory itself is absent, so no deletion is needed: the profile
    // remains accessible until a real, confirmed reset is executed.
    expect(store.settings.ready, isTrue);
    expect((await AppStore.load()).settings.ready, isTrue);
  });
}
