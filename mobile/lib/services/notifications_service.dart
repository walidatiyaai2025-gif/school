import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../firebase_options.dart';

/// FCM background entry point. Never uploads a student's name, images or PDFs.
@pragma('vm:entry-point')
Future<void> schoolPdfFcmBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}

/// Permission is requested only after an explicit user action.
/// Core scanning/PDF tools work even when the permission is denied.
class NotificationService {
  final FlutterLocalNotificationsPlugin local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool pushConnected = false;
  bool permissionGranted = false;
  static const _optInPreference = 'schoolpdf_notifications_opt_in';
  String? initialDocumentId;
  void Function(String? id)? onTap;
  void Function(String token)? onTokenRefresh;

  Future<String?> getPushToken() async {
    if (!pushConnected || !permissionGranted) return null;
    if (Platform.isIOS && await FirebaseMessaging.instance.getAPNSToken() == null) {
      // The APNs token may not exist until Apple capabilities and the APNs key
      // are configured and the device has registered with APNs.
      return null;
    }
    return FirebaseMessaging.instance.getToken();
  }

  static const _tasks = NotificationDetails(
    android: AndroidNotificationDetails('schoolpdf_tasks', 'School PDF tasks',
      channelDescription: 'Finished PDFs and study reminders',
      importance: Importance.high, priority: Priority.high),
    iOS: DarwinNotificationDetails(),
  );
  static const _updates = NotificationDetails(
    android: AndroidNotificationDetails('schoolpdf_updates', 'School PDF updates',
      channelDescription: 'Important School PDF service announcements',
      importance: Importance.defaultImportance, priority: Priority.defaultPriority),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) { /* Use UTC until the OS timezone maps to an IANA location. */ }
    await local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(requestAlertPermission: false,
          requestBadgePermission: false, requestSoundPermission: false)),
      onDidReceiveNotificationResponse: (response) => onTap?.call(response.payload),
    );
    final android = local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(const AndroidNotificationChannel(
        'schoolpdf_tasks', 'School PDF tasks',
        description: 'Finished PDFs and study reminders',
        importance: Importance.high));
      await android.createNotificationChannel(const AndroidNotificationChannel(
        'schoolpdf_updates', 'School PDF updates',
        description: 'Important School PDF service announcements',
        importance: Importance.defaultImportance));
    }
    _initialized = true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
      pushConnected = true;
      FirebaseMessaging.onBackgroundMessage(schoolPdfFcmBackgroundHandler);
      final fcm = FirebaseMessaging.instance;
      // Prevent duplicate foreground notifications; display one local alert.
      await fcm.setForegroundNotificationPresentationOptions(
          alert: false, badge: false, sound: false);
      fcm.onTokenRefresh.listen((token) => onTokenRefresh?.call(token));
      FirebaseMessaging.onMessage.listen((message) async {
        if (!permissionGranted || message.notification == null) return;
        final notice = message.notification!;
        await local.show(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: notice.title ?? 'School PDF',
          body: notice.body ?? '',
          notificationDetails: _updates,
          payload: message.data['document_id']?.toString());
      });
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => onTap?.call(message.data['document_id']?.toString()));
      final fromTerminated = await fcm.getInitialMessage();
      if (fromTerminated != null) {
        initialDocumentId = fromTerminated.data['document_id']?.toString() ?? '';
      }
    } catch (_) {
      pushConnected = false;
      // Offline PDF scanning and local notifications still work.
    }
  }

  Future<bool> requestPermission() async {
    await initialize();
    bool granted = false;
    if (Platform.isAndroid) {
      granted = await local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission() ?? false;
    } else if (Platform.isIOS) {
      if (pushConnected) {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true, badge: true, sound: true);
        granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      } else {
        granted = await local.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
                alert: true, badge: true, sound: true) ?? false;
      }
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_optInPreference, granted);
    permissionGranted = granted;
    if (pushConnected) {
      try {
        await FirebaseMessaging.instance.setAutoInitEnabled(granted);
        if (granted) await getPushToken();
      } catch (_) { /* A missing APNs token must not block PDF conversion. */ }
    }
    return granted;
  }

  Future<void> refreshPermissionStatus() async {
    await initialize();
    // Android <13 reports OS notification access without a runtime prompt.
    // Do not interpret that as opt-in to FCM or scheduled reminders.
    final preferences = await SharedPreferences.getInstance();
    final explicitlyApproved = preferences.getBool(_optInPreference) ?? false;
    bool allowedBySystem = false;
    if (Platform.isAndroid) {
      allowedBySystem = await local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      final settings = await local.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()?.checkPermissions();
      allowedBySystem = settings?.isEnabled ?? false;
    }
    permissionGranted = explicitlyApproved && allowedBySystem;
    if (pushConnected) {
      try {
        await FirebaseMessaging.instance.setAutoInitEnabled(permissionGranted);
      } catch (_) { /* Offline behavior is unchanged. */ }
    }
  }

  /// Cancel app reminders and withdraw consent for future FCM registration
  /// when the local profile is erased. OS permission can remain enabled;
  /// in-app consent is stored independently and must be explicitly re-granted.
  Future<void> disableForDataReset() async {
    await local.cancelAll();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_optInPreference, false);
    permissionGranted = false;
    if (pushConnected) {
      try {
        await FirebaseMessaging.instance.setAutoInitEnabled(false);
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {
        // The server registration is removed separately and never inferred
        // from a local Firebase call. Offline PDF access remains available.
      }
    }
  }

  Future<void> pdfReady(String recordId) async {
    if (!permissionGranted) return;
    await local.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'School PDF', body: 'ملف PDF جاهز للمشاركة',
      notificationDetails: _tasks, payload: recordId);
  }

  /// Inexact daily notifications: avoids SCHEDULE_EXACT_ALARM privileged access.
  Future<void> configureReminder({required bool enabled, required String time}) async {
    await local.cancel(id: 9211);
    if (!enabled || !permissionGranted) return;
    final parts = time.split(':');
    final hour = int.parse(parts[0]), minute = int.parse(parts[1]);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) scheduled = scheduled.add(const Duration(days: 1));
    await local.zonedSchedule(
      id: 9211, title: 'School PDF', body: 'وقت مراجعة واجباتك 📚',
      scheduledDate: scheduled, notificationDetails: _tasks,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time);
  }
}
