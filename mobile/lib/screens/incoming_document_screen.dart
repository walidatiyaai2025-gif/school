import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../services/incoming_documents.dart';
import '../services/office_text_reader.dart';

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
      if (const {'docx','xlsx','pptx'}.contains(ext)) {
        content = FutureBuilder<String>(
          future: OfficeTextReader.read(path),
          builder: (context, snapshot) {
            if (!snapshot.hasData && !snapshot.hasError) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(english
                    ? 'Could not preview this Office file: ${snapshot.error}'
                    : 'تعذرت معاينة ملف Office: ${snapshot.error}'),
              ));
            }
            return ListView(padding: const EdgeInsets.all(20), children: [
              Text(english
                  ? 'Text-only preview. Original Office formatting is not preserved.'
                  : 'معاينة نصية فقط؛ تنسيق ملف Office الأصلي غير محفوظ.',
                style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              SelectableText(snapshot.data!),
            ]);
          },
        );
      } else {
        content = Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(english
              ? 'Legacy Office files (.doc, .xls, .ppt) cannot be previewed in this build.'
              : 'لا تتوفر معاينة ملفات Office القديمة (.doc و.xls و.ppt) في هذا الإصدار.',
            textAlign: TextAlign.center),
        ));
      }
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
