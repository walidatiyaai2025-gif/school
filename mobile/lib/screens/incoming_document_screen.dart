import 'dart:io';
import '../widgets/clean_3d_dialog.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:open_filex/open_filex.dart';
import '../services/incoming_documents.dart';
import '../services/office_text_reader.dart';
import '../services/office_conversion_service.dart';


/// Explicit, privacy-first choice between on-device preview and server conversion.
/// Server conversion is disabled on shared hosting unless explicitly enabled in a verified build.
class OfficePreviewChoice extends StatelessWidget {
  const OfficePreviewChoice({super.key, required this.english,
    required this.onLocal, required this.onExternal, required this.onServer});
  final bool english;
  final VoidCallback onLocal;
  final VoidCallback onExternal;
  final VoidCallback onServer;
  static const serverEnabled = bool.fromEnvironment('SCHOOLPDF_SERVER_CONVERSION_ENABLED', defaultValue: false);

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
          Text(english ? '2. Server PDF conversion'
              : '٢. تحويل إلى PDF عبر الخادم',
            style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(english
              ? serverEnabled
                  ? 'With your explicit approval, this file will be uploaded over HTTPS for PDF conversion. Do not upload sensitive files.'
                  : 'Unavailable on the current shared hosting. No document will be uploaded. Use the on-device preview or a compatible viewer.'
              : serverEnabled
                  ? 'بعد موافقتك الصريحة، سيُرفع هذا الملف عبر HTTPS لتحويله إلى PDF. لا ترفع ملفات حساسة.'
                  : 'غير متاح على الاستضافة المشتركة الحالية. لن يتم رفع أي ملف. استخدم المعاينة على الجهاز أو تطبيق عرض متوافق.'),
          const SizedBox(height: 10),
          FilledButton(onPressed: serverEnabled ? onServer : null,
            child: Text(english
                ? (serverEnabled ? 'Convert via server' : 'Server conversion unavailable')
                : (serverEnabled ? 'تحويل عبر الخادم' : 'التحويل عبر الخادم غير متاح حاليًا'))),
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
  String? convertedPath;
  bool converting = false;
  String? conversionError;

  Future<void> convertWithConsent() async {
    final english = widget.english;
    final accepted = await showClean3DDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(english ? 'Upload this document?' : 'هل توافق على رفع هذا المستند؟'),
      content: Text(english
        ? 'Only this selected document will be sent over HTTPS for conversion. The server should delete temporary files after conversion. Do not upload confidential files. Continue?'
        : 'سيُرسل هذا المستند فقط عبر HTTPS للتحويل. يجب أن يحذف الخادم الملفات المؤقتة بعد التحويل. لا ترفع ملفات سرية. هل تريد المتابعة؟'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(english ? 'Cancel' : 'إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(english ? 'I agree, upload' : 'أوافق على الرفع'))],
    ));
    if (accepted != true || !mounted) return;
    setState(() { converting = true; conversionError = null; });
    try {
      final pdf = await OfficeConversionService.convert(widget.path);
      if (mounted) setState(() { convertedPath = pdf; localSelected = true; });
    } catch (_) {
      if (mounted) setState(() { conversionError = english
          ? 'Server conversion is unavailable. You can still use the on-device option.'
          : 'التحويل عبر الخادم غير متاح. يمكنك استخدام المعاينة على الجهاز.'; });
    } finally {
      if (mounted) setState(() => converting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = IncomingDocuments.extension(widget.path);
    final file = File(widget.path);
    final english = widget.english;
    final path = widget.path;
    final title = english ? 'Open document' : 'فتح المستند';
    Widget content;
    if (convertedPath != null) {
      content = PdfPreview(build: (_) => File(convertedPath!).readAsBytes(), allowPrinting: false);
    } else if (ext == 'pdf') {
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
    if (const {'doc','docx','xls','xlsx','ppt','pptx'}.contains(ext) && !localSelected && convertedPath == null) {
      content = converting ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(child: Column(children: [
        if (conversionError != null) Padding(padding: const EdgeInsets.all(12), child: Text(conversionError!)),
        OfficePreviewChoice(
        english: english,
        onLocal: () => setState(() => localSelected = true),
        onServer: convertWithConsent,
        onExternal: () async {
          final result = await OpenFilex.open(path);
          if (!mounted || result.type == ResultType.done) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
            english ? 'No compatible viewer installed' : 'لا يوجد تطبيق عرض متوافق مثبت')));
        },
      )]));
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
