import 'dart:async';
import 'package:flutter/services.dart';

/// Platform entry point for files opened with School PDF.
class IncomingDocuments {
  IncomingDocuments._();
  static const channel = MethodChannel('com.fiftysols.schoolpdf/open_document');
  static final events = StreamController<String>.broadcast();
  static bool _initialized = false;

  static Future<String?> initialize() async {
    if (!_initialized) {
      _initialized = true;
      channel.setMethodCallHandler((call) async {
        if (call.method == 'onOpenDocument' && call.arguments is String) {
          events.add(call.arguments as String);
        }
      });
    }
    return channel.invokeMethod<String>('initialDocument');
  }

  static const supportedExtensions = <String>{
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
    'jpg', 'jpeg', 'png', 'webp',
  };

  static String? extension(String path) {
    final name = Uri.tryParse(path)?.pathSegments.lastOrNull ?? path;
    final dot = name.lastIndexOf('.');
    if (dot < 0) return null;
    final ext = name.substring(dot + 1).toLowerCase();
    return supportedExtensions.contains(ext) ? ext : null;
  }
}
