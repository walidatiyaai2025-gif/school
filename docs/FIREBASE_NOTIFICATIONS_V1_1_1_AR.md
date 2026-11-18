# School PDF 1.1.1 — تهيئة إشعارات Firebase

## الملفات الفعلية التي أُضيفت من المستخدم

- `mobile/config/firebase/google-services.json` — إعدادات **Android**.
- `mobile/config/firebase/GoogleService-Info.plist` — إعدادات **iOS**.
- `mobile/lib/firebase_options.dart` — الخيارات متعددة المنصات المولدة من الملفين.
- `mobile/lib/services/notifications_service.dart` — إشعارات محلية، استقبال FCM، موافقة المستخدم، قناتا Android، فتح التطبيق عبر الإشعار.
- `mobile/tool/patch_platforms.py` — ينسخ الملفين إلى مواضعهما الأصلية بعد `flutter create`، ويجهز Google Services Gradle plugin وXcode Resources وInfo.plist.

**معرّف المشروع:** `schoolpdf-50sols` — **اسم التطبيق:** `School PDF` — **Android package / iOS bundle:** `com.fiftysols.schoolpdf`.

الإعدادات المرفوعة هي **Firebase client configuration** وليست بيانات FCM Server Service Account. لا تتضمن مفتاحًا خاصًا للخادم. احتفظ بمفتاح APNs `.p8` وFirebase Admin Service Account خارج السورس والمجلد العام للخادم.

## Android

من داخل `mobile/` في جهاز تطوير مجهز بآخر Flutter stable وAndroid SDK:

```bash
bash tool/bootstrap.sh
flutter run
```

يسجل السكربت ملف `google-services.json` تحت `android/app` ويربط `com.google.gms.google-services` في Gradle. أما GitHub Actions فتنفّذ الإعداد نفسه. عند نجاح بناء APK، اختبر الموافقة ثم استقبال رسالة Firebase Test Message على جهاز Android حقيقي أو Emulator فيه Google Play Services.

## iOS

نفس سكربت Bootstrap ينشئ مشروع iOS ويضيف `GoogleService-Info.plist` إلى **Runner target Resources**، ويضبط Background Mode `remote-notification` في `Info.plist`.

لا يكتمل Push على iOS بهذه الملفات وحدها. يلزم:

1. تسجيل Bundle ID `com.fiftysols.schoolpdf` في Apple Developer.
2. ضبط **Signing & Capabilities** في Xcode: `Push Notifications` و`Background Modes → Remote notifications`.
3. إنشاء مفتاح APNs بصيغة `.p8` ورفعه في Firebase Console → Project Settings → Cloud Messaging → Apple app configuration، مع Key ID وTeam ID الصحيحين.
4. إجراء اختبار على **iPhone فعلي موقّع**، لأن سلوك APNs وطلب الإذن لا يثبت من الملفات وحدها.

## ربط Laravel وإرسال الإشعارات بحسب الدولة

- المشروع الخلفي: `backend/`، وتستهدف لوحة الإدارة `https://sclpdf.50sols.com/admin` عند نشره.
- يلزم **Firebase Admin Service Account JSON** ذي صلاحية FCM HTTP v1 على **الخادم فقط**، خارج `public/`.
- اضبط `SCHOOLPDF_FIREBASE_PROJECT_ID=schoolpdf-50sols`، و`SCHOOLPDF_GOOGLE_SERVICE_ACCOUNT_FILE` إلى مسار ملف الخدمة الآمن في إعدادات البيئة.
- يلزم تشغيل Queue/Cron أو معالجة وظائف الإرسال من لوحة الإدارة؛ بدون ذلك قد تبقى الحملات في الانتظار.
- السجل الجغرافي والتقسيم حسب الدولة في الكود الحالي مقيدان **بالبالغين الموافقين صراحةً على القياس**. لا يُعد هذا إحصاءً لكل التنزيلات ولا تسجيلًا شاملًا لجميع الطلاب.
- لا تستخدم بيانات الموقع الدقيقة أو صور الواجب أو اسم الطالب أو الفصل في Payload.

## خصوصية وتنبيهات التشغيل

- يُطلب إذن الإشعارات بعد اختيار المستخدم تفعيله، ولا يمنع رفضه وظائف PDF الأساسية.
- FCM Auto Init معطل مبدئيًا في Android/iOS، ولا يُفعّل إلا عند الموافقة الصريحة وتوفر إذن النظام.
- `schoolpdf_tasks`: إشعار تحويل الملفات والتذكيرات المحلية.
- `schoolpdf_updates`: رسائل تحديث الخدمة من Laravel/FCM.
- عند وصول Push والتطبيق مفتوح، تظهر نسخة محلية واحدة لتفادي ازدواج التنبيهات.
- اختبار وصول الرسائل بالحالات Foreground/Background/Terminated، والإذن مرفوض/مقبول، وAndroid 12/13+، وiOS/APNs ضروري قبل الإطلاق.
- Firebase `google-services.json` / `GoogleService-Info.plist` ملفات إعداد عميل وليست أسرار خادم، لكن أي مفاتيح خادم أو شهادات توقيع تبقى خارج الحزمة.

## الحالة المختبرة

تم اختبار تطابق مشروع Firebase وPackage/Bundle ID، والتحقق من نسخ الإعدادات والمحاكاة الثابتة لإضافة Gradle/Xcode، وفحص بنية السورس وZIP. **لم يُبنَ APK ولم يجرِ اختبار إرسال فعلي أو تشغيل Flutter/Laravel** في هذه البيئة.
