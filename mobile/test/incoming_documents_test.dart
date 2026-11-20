import 'package:flutter_test/flutter_test.dart';
import 'package:school_pdf/services/incoming_documents.dart';

void main() {
  test('supported Office, PDF and image types are recognized', () {
    for (final ext in ['pdf','doc','docx','xls','xlsx','ppt','pptx','jpg','jpeg','png','webp']) {
      expect(IncomingDocuments.extension('/tmp/document.$ext'), ext);
    }
  });

  test('unsupported extensions are rejected', () {
    expect(IncomingDocuments.extension('/tmp/malicious.exe'), isNull);
    expect(IncomingDocuments.extension('/tmp/no-extension'), isNull);
  });
}
