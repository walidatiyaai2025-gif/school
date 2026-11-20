import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:open_filex/open_filex.dart';
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
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async {
                  final result = await OpenFilex.open(path);
                  if (!context.mounted) return;
                  if (result.type != ResultType.done) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(english
                        ? 'No compatible document viewer is available on this device.'
                        : 'لا يوجد تطبيق متوافق لعرض المستند على هذا الجهاز.'),
                    ));
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: Text(english
                  ? 'View original formatting in a compatible app'
                  : 'عرض التنسيق الأصلي في تطبيق متوافق'),
              ),
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(english
              ? 'Legacy Office documents require a compatible viewer.'
              : 'مستندات Office القديمة تحتاج تطبيق عرض متوافق.',
              textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                final result = await OpenFilex.open(path);
                if (!context.mounted) return;
                if (result.type != ResultType.done) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(english ? 'No compatible viewer installed'
                        : 'لا يوجد تطبيق عرض متوافق مثبت'),
                  ));
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: Text(english ? 'Open original document' : 'فتح المستند الأصلي'),
            ),
          ]),
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
