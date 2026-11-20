import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Read-only, offline text extraction for modern Office OOXML files.
/// Does not execute macros, fetch remote resources, or promise layout fidelity.
class OfficeTextReader {
  static Future<String> read(String path) async {
    final ext = path.split('.').last.toLowerCase();
    if (!{'docx','xlsx','pptx'}.contains(ext)) {
      throw const FormatException('Legacy Office binary formats are not supported');
    }
    final file = File(path);
    if (await file.length() > 25 * 1024 * 1024) {
      throw const FormatException('Document exceeds 25 MB preview limit');
    }
    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    final entries = archive.files.where((e) => e.isFile && e.size <= 8 * 1024 * 1024).toList();
    final selected = entries.where((e) {
      if (ext == 'docx') return e.name == 'word/document.xml';
      if (ext == 'xlsx') return e.name == 'xl/sharedStrings.xml' ||
          RegExp(r'^xl/worksheets/sheet[0-9]+\.xml$').hasMatch(e.name);
      return RegExp(r'^ppt/slides/slide[0-9]+\.xml$').hasMatch(e.name);
    }).take(100).toList();
    if (selected.isEmpty) throw const FormatException('No readable Office document parts found');
    final strings = <String>[];
    if (ext == 'xlsx') {
      final shared = selected.where((e) => e.name == 'xl/sharedStrings.xml');
      if (shared.isNotEmpty) {
        final xml = XmlDocument.parse(utf8.decode(shared.first.content as List<int>, allowMalformed: true));
        for (final si in xml.descendants.whereType<XmlElement>().where((e) => e.name.local == 'si')) {
          strings.add(si.descendants.whereType<XmlElement>()
              .where((e) => e.name.local == 't').map((e) => e.innerText).join());
        }
      }
    }
    final out = StringBuffer();
    for (final part in selected) {
      if (part.name.endsWith('sharedStrings.xml')) continue;
      final xml = XmlDocument.parse(utf8.decode(part.content as List<int>, allowMalformed: true));
      if (ext == 'xlsx') {
        out.writeln('\n${part.name.split('/').last}\n');
        for (final row in xml.descendants.whereType<XmlElement>().where((e) => e.name.local == 'row')) {
          final cells = <String>[];
          for (final cell in row.children.whereType<XmlElement>().where((e) => e.name.local == 'c')) {
            final raw = cell.descendants.whereType<XmlElement>()
                .where((e) => e.name.local == 'v' || e.name.local == 't')
                .map((e) => e.innerText).join(' ');
            final index = int.tryParse(raw);
            cells.add(cell.getAttribute('t') == 's' && index != null && index >= 0 && index < strings.length
                ? strings[index] : raw);
          }
          out.writeln(cells.join('  |  '));
        }
      } else {
        if (ext == 'pptx') out.writeln('\n${part.name.split('/').last}\n');
        final nodes = xml.descendants.whereType<XmlElement>()
            .where((e) => e.name.local == 't' && (ext == 'pptx' || e.name.prefix == 'w'));
        out.writeln(nodes.map((e) => e.innerText).where((s) => s.trim().isNotEmpty).join('  '));
      }
      if (out.length > 500000) throw const FormatException('Document preview exceeds text limit');
    }
    if (out.toString().trim().isEmpty) throw const FormatException('No readable text in document');
    return out.toString();
  }
}
