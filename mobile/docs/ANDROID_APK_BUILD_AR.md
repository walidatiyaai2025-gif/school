# طريقة إنتاج APK للتجربة — School PDF

**مهم:** لم يتم بناء APK في بيئة إنشاء الحزمة. لا تتضمن هذه الحزمة ملف APK. سكربتات البناء تحتاج Flutter وAndroid SDK وخدمة اعتماديات Flutter/Gradle متاحة عبر الإنترنت. `flutter analyze` و`flutter test` و`flutter build apk` لم تنجح بعد على جهاز بناء فعلي.

## الاختيار الأول: GitHub Actions (لا تحتاج Flutter على جهازك)

1. أنشئ مستودع GitHub **خاصًا بالمشروع**، ولا ترفع هذه الملفات إلى مستودع FOODEX.
2. ارفع محتويات مجلد `SchoolPDF-Flutter-v1.0.0`، مع الاحتفاظ بالمسار `.github/workflows/android-debug-apk.yml`.
3. افتح تبويب `Actions` واختر `Build School PDF Android APK` ثم `Run workflow`.
4. بعد انتهاء البناء بنتيجة **Success** افتح نفس التشغيل، قسم **Artifacts**، وحمّل `SchoolPDF-v1.0.0-Android-debug-APK`.
5. فك ضغط ملف Artifact، ثم افتح `SchoolPDF-v1.0.0-debug.apk` على هاتف Android لتثبيته بعد السماح بالتثبيت من المصدر المعني.
6. إن فشل البناء، لا يوجد APK صالح. راجع سجل الخطوة الفاشلة وأصلح السبب قبل إعادة التشغيل. **هذا الـWorkflow غير مُختبر فعليًا حتى الآن.**

الإصدار هنا **Debug** للتجربة فقط، وليس نشرًا رسميًا عبر Google Play.

## الاختيار الثاني: على Mac أو Linux مثبت عليه Flutter

```bash
bash tool/build_android_apk.sh
```

المخرج بعد نجاح جميع مراحل الفحص والبناء:

`dist/SchoolPDF-v1.0.0-debug.apk`

## الاختيار الثالث: على Windows مثبت عليه Flutter

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\build_android_apk.ps1
```

## شروط الاختبار

- عند الإنشاء الأول، `flutter create` يولّد قوالب Android الرسمية. يتبعها تعديل الأذونات وتجهيز أيقونة البراندنج.
- اختبار الكاميرا والمعرض وقص الزوايا اليدوي وتحويل PDF ومشاركة مرفق PDF الحقيقي وعدّاد المشاركة وإشعارات الجهاز يجب أن يتم على هاتف فعلي.
- **إعلانات AdMob الحقيقية وFirebase Push الإنتاجي غير مفعّلين** في APK التجريبي؛ يحتاجان إعدادات وحسابات ومراجعة خصوصية منفصلة.
- في Android قد تحتاج السماح بالتثبيت من التطبيق الذي تفتح منه APK، ثم إلغاء السماح بعد التجربة إن رغبت.
