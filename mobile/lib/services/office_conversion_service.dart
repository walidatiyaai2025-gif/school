import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Uploads only after the user explicitly confirms in the document UI.
/// The API URL must be HTTPS; no background retries or silent uploads.
class OfficeConversionService {
  static const base = String.fromEnvironment('SCHOOLPDF_API_BASE',
      defaultValue: 'https://sclpdf.50sols.com/api');

  static Future<String> convert(String path) async {
    final uri = Uri.parse('$base/v1/documents/convert');
    if (uri.scheme != 'https') throw const FormatException('HTTPS required');
    final file = File(path);
    if (await file.length() > 10 * 1024 * 1024) {
      throw const FormatException('File exceeds 10 MB limit');
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.postUrl(uri).timeout(const Duration(seconds: 12));
      final boundary = 'schoolpdf${DateTime.now().microsecondsSinceEpoch}';
      request.headers.set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary');
      request.headers.set('Accept', 'application/pdf');
      request.write('--$boundary\r\nContent-Disposition: form-data; name="document"; filename="document.${p.extension(path).replaceFirst('.', '')}"\r\nContent-Type: application/octet-stream\r\n\r\n');
      await request.addStream(file.openRead());
      request.write('\r\n--$boundary--\r\n');
      final response = await request.close().timeout(const Duration(seconds: 65));
      if (response.statusCode != 200 || response.headers.contentType?.mimeType != 'application/pdf') {
        await response.drain<void>();
        throw HttpException('Conversion unavailable (HTTP ${response.statusCode})');
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 65))) {
        bytes.addAll(chunk);
        if (bytes.length > 30 * 1024 * 1024) throw const FormatException('PDF too large');
      }
      if (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-') {
        throw const FormatException('Invalid PDF returned');
      }
      final output = File(p.join((await getTemporaryDirectory()).path,
          'converted_${DateTime.now().microsecondsSinceEpoch}.pdf'));
      await output.writeAsBytes(bytes, flush: true);
      return output.path;
    } finally {
      client.close(force: true);
    }
  }
}
