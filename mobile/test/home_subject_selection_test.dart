import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_pdf/data/app_store.dart';
import 'package:school_pdf/screens/home_screen.dart';
import 'package:school_pdf/services/notifications_service.dart';
import 'package:school_pdf/services/pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('selecting a subject never crashes with duplicated custom subjects',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    store.settings
      ..name = 'Student'
      ..schoolClass = '6A'
      ..introDone = true
      ..customSubjects.add('الرياضيات');
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: HomeScreen(
        store: store,
        scanner: ScanEngine(),
        notifications: NotificationService(),
        onGoFiles: () {},
      ),
    )));
    expect(find.byKey(const Key('subject-required-warning')), findsOneWidget);
    expect(find.byKey(const Key('home-promo-image')), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose a subject first'));
    await tester.pumpAndSettle();
    final math = find.text('Mathematics').last;
    await tester.tap(math);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
    // Selecting a subject must never hide the red instructional message.
    expect(find.byKey(const Key('subject-required-warning')), findsOneWidget);
  });

  test('unfinished capture retains selected subject across app store reload', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    await store.rememberCaptureSubject('English');
    final restarted = await AppStore.load();
    expect(restarted.pendingCaptureSubject, 'English');
    await restarted.clearPendingCaptureSubject();
    expect((await AppStore.load()).pendingCaptureSubject, isNull);
  });
}
