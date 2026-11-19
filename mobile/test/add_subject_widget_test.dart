import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_pdf/data/app_store.dart';
import 'package:school_pdf/screens/settings_screen.dart';
import 'package:school_pdf/services/notifications_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Adding a subject closes safely and leaves the settings tree mounted',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    store.settings
      ..name = 'Alex'
      ..schoolClass = '6A'
      ..introDone = true
      ..english = true;
    final service = NotificationService();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SettingsScreen(
        store: store, notifications: service,
      )),
    ));
    final add = find.text('Add');
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();

    expect(find.text('Add subject'), findsWidgets);
    await tester.enterText(find.byType(TextField).last, 'Robotics');
    await tester.tap(find.widgetWithText(FilledButton, 'Add').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(store.settings.customSubjects, contains('Robotics'));
    expect(find.text('Robotics'), findsOneWidget);
  });
}
