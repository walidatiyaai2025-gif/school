import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/app_store.dart';
import 'notifications_service.dart';

/// Privacy-minimal anonymous install registry. Never sends name, grade, subjects,
/// file names, PDF pages, image bytes or exact location. Opt-in adults only.
/// No telemetry request at all unless the toggle is enabled.
class TelemetryService {
  static const api = String.fromEnvironment('SCHOOLPDF_API_BASE',
      defaultValue: 'https://sclpdf.50sols.com/api');
  static const version = '1.1.1';
  static bool _sending = false;
  static const secure = FlutterSecureStorage();

  static String _uuid() {
    final r = Random.secure();
    final a = List<int>.generate(16, (_) => r.nextInt(256));
    a[6] = (a[6] & 0x0f) | 0x40;
    a[8] = (a[8] & 0x3f) | 0x80;
    final h = a.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0,8)}-${h.substring(8,12)}-${h.substring(12,16)}-${h.substring(16,20)}-${h.substring(20)}';
  }

  static Future<Map<String, dynamic>?> _request(String path, String method,
      Map<String,dynamic>? payload, {String? id, String? key}) async {
    final uri = Uri.parse('$api$path');
    if (uri.scheme != 'https') return null;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final req = await client.openUrl(method, uri).timeout(const Duration(seconds: 8));
      req.headers.contentType = ContentType.json;
      req.headers.set('Accept', 'application/json');
      if (id != null) req.headers.set('X-SchoolPDF-Install-ID', id);
      if (key != null) req.headers.set('X-SchoolPDF-Device-Key', key);
      if (payload != null) req.write(jsonEncode(payload));
      final resp = await req.close().timeout(const Duration(seconds: 9));
      final text = await utf8.decoder.bind(resp).join();
      if (resp.statusCode < 200 || resp.statusCode >= 300) return null;
      return text.isEmpty ? <String,dynamic>{} : (jsonDecode(text) as Map<String,dynamic>);
    } catch (_) {return null;} finally {client.close(force:true);}
  }

  static Future<void> sync(AppStore store, NotificationService notices) async {
    if (_sending) return;
    final pending=await SharedPreferences.getInstance();
    if(pending.getBool('schoolpdf_pending_delete')==true){await unregister();}
    // Do not register minors or unknown age groups. Consent is never inferred
    // from agreeing to push notifications.
    if (!store.settings.analyticsConsent || store.settings.ageGroup != 'adult') return;
    _sending = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString('schoolpdf_install_id');
      String? key = await secure.read(key:'schoolpdf_device_key');
      final canPush = notices.permissionGranted && notices.pushConnected &&
          store.settings.notifyUpdates;
      String? token;
      if (canPush) {
        try {token = await notices.getPushToken();}catch (_) {}
      }
      final fields = <String,dynamic>{
        'app_version': version,
        'locale': store.settings.english ? 'en' : 'ar',
        'notifications_enabled': notices.permissionGranted,
        'push_opt_in': canPush && token != null,
        if (canPush && token != null) 'fcm_token':token,
      };
      if (id == null || key == null) {
        id = _uuid();
        final result = await _request('/v1/device/register','POST', {
          ...fields, 'installation_id':id,
          'platform':Platform.isIOS?'ios':'android',
          'analytics_consent':true,'adult_confirmed':true,
        });
        if(result != null && result['device_key'] is String) {
          key = result['device_key'] as String;
          await prefs.setString('schoolpdf_install_id',id);
          await secure.write(key:'schoolpdf_device_key',value:key);
        }
      } else {
        await _request('/v1/device/heartbeat','POST',fields,id:id,key:key);
      }
    } catch (e) {debugPrint('Optional telemetry unavailable: ${e.runtimeType}');}
    finally {_sending = false;}
  }

  static Future<void> purgePending() async {
    final prefs=await SharedPreferences.getInstance();
    if(prefs.getBool('schoolpdf_pending_delete')==true) await unregister();
  }

  static Future<bool> unregister() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('schoolpdf_install_id');
    final key = await secure.read(key:'schoolpdf_device_key');
    await prefs.setBool('schoolpdf_pending_delete', true);
    if(id != null && key != null) {
      final result = await _request('/v1/device','DELETE',null,id:id,key:key);
      // Preserve the credential on failure to allow an eventual retry.
      if(result == null) return false;
    }
    await prefs.remove('schoolpdf_install_id');
    await secure.delete(key:'schoolpdf_device_key');
    await prefs.remove('schoolpdf_pending_delete');
    return true;
  }
}
