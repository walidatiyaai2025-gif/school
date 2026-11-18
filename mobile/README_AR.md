# School PDF — تطبيق Flutter بالإصدار 1.1.1

يتضمن صور الطالب، تصحيح زوايا الورقة، إنشاء PDF، السجل والمشاركة، والإشعارات المحلية وPush.

**أُضيف ملفا Firebase الأصليان** إلى `config/firebase/`، مع `lib/firebase_options.dart`، وربط أصلي تلقائيًا عبر `tool/patch_platforms.py`، بعد إنشاء Android/iOS بواسطة Flutter SDK.

- المشروع: `schoolpdf-50sols`
- الحزمة على Android وiOS: `com.fiftysols.schoolpdf`
- التطبيق: `School PDF`

من جذر `mobile/` على جهاز يحتوي Flutter SDK:

```bash
bash tool/bootstrap.sh
flutter run --dart-define=SCHOOLPDF_API_BASE=https://sclpdf.50sols.com/api
```

تحتاج Push على iOS ربط حساب Apple Developer، Capability لتلقي Push ورفع مفتاح APNs إلى Firebase. ويحتاج Laravel إرسال إشعارات الدولة ملف Firebase Service Account **على السيرفر فقط** خارج `public/`، وتشغيل الـQueue. لا يوجد APK مختبر في هذا التسليم.

التعليمات الكاملة في `../docs/FIREBASE_NOTIFICATIONS_V1_1_1_AR.md`.
