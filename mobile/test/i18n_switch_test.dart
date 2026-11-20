import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_pdf/core/strings.dart';
import 'package:school_pdf/data/app_store.dart';
import 'package:school_pdf/widgets/language_toggle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('notification copy follows English and Arabic preferences', () {
    expect(S(true).pdfReadyBody, 'Your PDF is ready to share');
    expect(S(false).pdfReadyBody, 'ملف PDF جاهز للمشاركة');
    expect(S(true).reminderBody, 'Time to review your homework 📚');
    expect(S(false).reminderBody, 'وقت مراجعة واجباتك 📚');
  });

  testWidgets('header language switch persists preference and updates text',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    expect(store.settings.english, isTrue);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => LanguageToggle(
            store: store, onChanged: () => setState(() {}),
          ),
        ),
      ),
    ));
    expect(find.text('العربية'), findsOneWidget);
    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();
    expect(store.settings.english, isFalse);
    expect(find.text('English'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(store.settings.english, isTrue);
    final restored = await AppStore.load();
    expect(restored.settings.english, isTrue);
  });
}
