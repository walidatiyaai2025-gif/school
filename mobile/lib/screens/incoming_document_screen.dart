import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../services/incoming_documents.dart';

class IncomingDocumentScreen extends StatelessWidget {
  const IncomingDocumentScreen({super.key, required this.path, required this.english});
  final String path;
  final bool english;

  @override
  Widget build(BuildContext context) {
    final ext = IncomingDocuments.extension(path);
    final file = File(path);
    final title = english ? 'Open document' : 'فتح المستند';
    Widget content;
    if (ext == 'pdf') {
      content = PdfPreview(build: (_) => file.readAsBytes(), allowPrinting: false);
    } else if (const {'jpg','jpeg','png','webp'}.contains(ext)) {
      content = InteractiveViewer(child: Center(child: Image.file(file)));
    } else {
      // Do not misrepresent unimplemented Office rendering as a successful preview.
      content = Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(english
            ? 'Office preview is not available in this build. The file was received safely.'
            : 'معاينة ملفات Office غير متاحة في هذا الإصدار. تم استقبال الملف بأمان.',
          textAlign: TextAlign.center),
      ));
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data != true || ext == null) {
            return Center(child: Text(english ? 'File unavailable or unsupported'
                : 'الملف غير موجود أو غير مدعوم'));
          }
          return content;
        },
      ),
    );
  }
}
