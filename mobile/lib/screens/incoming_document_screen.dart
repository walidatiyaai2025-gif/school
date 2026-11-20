import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:open_filex/open_filex.dart';
import '../services/incoming_documents.dart';
import '../services/office_text_reader.dart';


/// Explicit, privacy-first choice between on-device preview and server conversion.
/// Server conversion is intentionally unavailable until a verified secure endpoint exists.
class OfficePreviewChoice extends StatelessWidget {
  const OfficePreviewChoice({super.key, required this.english,
    required this.onLocal, required this.onExternal});
  final bool english;
  final VoidCallback onLocal;
  final VoidCallback onExternal;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(english ? 'Choose how to view this document'
          : 'اختر طريقة عرض المستند',
        style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 14),
      Card(child: Padding(padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(english ? '1. On this device — private'
              : '١. على هذا الجهاز — خاص',
            style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(english
              ? 'No upload. View extracted text here, or open the original in a compatible installed app. Formatting in the text preview may differ.'
              : 'بدون رفع الملف. اعرض النص داخل التطبيق، أو افتح الأصل بتطبيق متوافق مثبت. قد يختلف تنسيق المعاينة النصية.'),
          const SizedBox(height: 10),
          FilledButton(onPressed: onLocal,
            child: Text(english ? 'Preview on device' : 'معاينة على الجهاز')),
          TextButton(onPressed: onExternal,
            child: Text(english ? 'Open in another app' : 'فتح في تطبيق آخر')),
        ]))),
      const SizedBox(height: 10),
      Card(child: Padding(padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(english ? '2. Server conversion — coming soon'
              : '٢. تحويل عبر الخادم — قريبًا',
            style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(english
              ? 'This option would upload the selected document over an encrypted connection for PDF conversion. It will require your separate approval each time. Never automatic. Not available until security and deletion checks pass.'
              : 'هذه الطريقة سترفع المستند المختار عبر اتصال مشفر لتحويله إلى PDF، بعد موافقتك الصريحة في كل مرة. لن يتم الرفع تلقائيًا. غير متاحة حتى اجتياز اختبارات الأمان وحذف الملفات.'),
          const SizedBox(height: 10),
          FilledButton(onPressed: null,
            child: Text(english ? 'Server conversion unavailable'
                : 'التحويل عبر الخادم غير متاح حاليًا')),
        ]))),
    ]),
  );
}

class IncomingDocumentScreen extends StatefulWidget {
  const IncomingDocumentScreen({super.key, required this.path, required this.english});
  final String path;
  final bool english;

  @override
  State<IncomingDocumentScreen> createState() => _IncomingDocumentScreenState();
}

class _IncomingDocumentScreenState extends State<IncomingDocumentScreen> {
  bool localSelected = false;

  @override
  Widget build(BuildContext context) {
    final ext = IncomingDocuments.extension(widget.path);
    final file = File(widget.path);
    final english = widget.english;
    final path = widget.path;
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
    if (const {'doc','docx','xls','xlsx','ppt','pptx'}.contains(ext) && !localSelected) {
      content = SingleChildScrollView(child: OfficePreviewChoice(
        english: english,
        onLocal: () => setState(() => localSelected = true),
        onExternal: () async {
          final result = await OpenFilex.open(path);
          if (!mounted || result.type == ResultType.done) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
            english ? 'No compatible viewer installed' : 'لا يوجد تطبيق عرض متوافق مثبت')));
        },
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
