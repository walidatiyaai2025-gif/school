import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_pdf/screens/incoming_document_screen.dart';

void main() {
  testWidgets('Arabic choices explain no upload and disabled server conversion', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SingleChildScrollView(child: OfficePreviewChoice(
        english: false, onLocal: () {}, onExternal: () {}, onServer: () {},
      )),
    )));
    expect(find.textContaining('بدون رفع الملف'), findsOneWidget);
    expect(find.textContaining('موافقتك الصريحة'), findsOneWidget);
    expect(find.text('تحويل عبر الخادم'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(
      FilledButton, 'تحويل عبر الخادم')).onPressed, isNotNull);
  });

  testWidgets('English choices disclose per-file approval', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SingleChildScrollView(child: OfficePreviewChoice(
        english: true, onLocal: () {}, onExternal: () {}, onServer: () {},
      )),
    )));
    expect(find.textContaining('No upload'), findsOneWidget);
    expect(find.textContaining('explicit approval'), findsOneWidget);
  });
}
