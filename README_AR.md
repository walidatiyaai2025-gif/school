# School PDF — Full Stack v1.1.2 (Flutter + Laravel + Setup Source)

## جديد: فولدر `setup/` لتجهيز التثبيت على sclpdf.50sols.com

أضفنا فولدر **`setup/` داخل السورس** وفيه أداة بناء Setup ZIP، فحص أهلية الإصدار، اختبارات أمان، تعليمات cPanel، وسجل حالة Build. وتم تحديث معالج `/install` إلى ثلاث خطوات وفحص صارم للمتطلبات.

**الحالة الحالية: SOURCE WITH SETUP TOOLING / NOT PRODUCTION READY.** لا توجد مكتبات `vendor` أو `composer.lock` في بيئة البناء الحالية، ولم تنجح اختبارات Fresh Install/Upgrade/Recovery على حزمة فعلية؛ ولذلك **لا يوجد `SchoolPDF-Setup-v1.1.2.zip` قابل للرفع بعد**. هذا يمنع وضع واجهة تثبيت شكلية على خادم الإنتاج. تعليمات استكمال الحزمة موجودة داخل `setup/README_AR.md`، وسبب المنع داخل `setup/output/BUILD_STATUS.json`.

---

**اسم العرض:** School PDF

**Android applicationId:** `com.fiftysols.schoolpdf`

**iOS Bundle ID:** `com.fiftysols.schoolpdf`

**Firebase project ID (موثق بملفي Firebase المرفوعين):** `schoolpdf-50sols`

**Public/Developer Website:** `https://sclpdf.50sols.com`

**Laravel Admin:** `https://sclpdf.50sols.com/admin/login`

**Laravel Installer:** `https://sclpdf.50sols.com/install`

**API:** `https://sclpdf.50sols.com/api/v1`

## محتويات هذه الحزمة

- `mobile/`: تطبيق Flutter بالهوية المرئية، تصوير الواجبات، اختيار الصور، تصحيح المنظور، تجهيز PDF، السجل، عداد محاولات المشاركة، إشعارات محلية، Firebase Push opt-in، AdMob adapter، رابط سياسة الخصوصية، وقياس مجهول قائم على موافقة المستخدم البالغ فقط.
- `backend/`: مصدر Laravel 12 مستقل: لوحة Super Admin، إحصاءات الأجهزة المسجلة النشطة وتوزيع الدول، حملات FCM تستهدف الدولة، إعدادات الإعلانات ومزوّديها، app-ads.txt، سياسة الخصوصية والدعم، API للأجهزة مع حذف السجل، قالب استيراد تقارير المتاجر، ومعالج تثبيت ويب مشروط بالحصول على dependencies.
- `docs/`: دليل Firebase/AdMob/الخصوصية والاستضافة وإيضاح حدود الإصدار.
- `.github/workflows/`: CI يهدف لبناء APK وفحص PHPUnit؛ **لم يتم تشغيل CI في هذه الجلسة**.

## ما الذي يعمل وما الذي لا يمكن إثباته هنا؟

كل الملفات السابقة **Source Code**. تم إجراء فحص PHP syntax وYAML/static checks فقط؛ **لم يتم تشغيل Laravel أو Flutter أو DB integration أو APK**: لا توجد SDKs أو Composer vendor في بيئة التنفيذ. **لا توجد شهادة Fresh Install/Upgrade**، ولا يعتبر مشروع Laravel جاهزًا للإنتاج أو الإطلاق بعد. 

- ملف `SchoolPDF-Setup-v1.1.1.zip` النهائي الجاهز لـcPanel لا يمكن بناؤه في بيئة بلا Composer dependencies/Composer lock. `scripts/build_setup_zip.py` يرفض الإنشاء إذا لم تتوفر الاعتمادات وملف lock؛ يُبنى من CI بعد اختبار حقيقي وحسم التبعيات.
- صفحة تحديثات ZIP في لوحة Laravel موجودة لكنها **Safety Locked**. لا يعمل Apply Update لحين تنفيذ توقيع Ed25519 موثوق، Backup/Recovery واختبارات الترقية؛ لا تدّعي جاهزية التحديث.
- سياسة الخصوصية ثنائية اللغة في `backend/resources/views/legal/privacy.blade.php` **مسودة تحتاج اسم الجهة القانونية والبريد وصياغة قانونية نهائية قبل النشر**.
- تم تضمين ملفات **Firebase العميل** لـAndroid وiOS التي زوّدنا بها المستخدم، في `mobile/config/firebase/`، وجرى توليد `mobile/lib/firebase_options.dart`. لم يتم توفير **Firebase Server Service Account** أو APNs `.p8` أو AdMob IDs إنتاجية. يجب ألا توضع مفاتيح الخادم في تطبيق الهاتف أو `public/`.
- روابط الدومين لا تعمل إلا بعد إعداد DNS وTLS ونشر backend فعليًا على الاستضافة.

## إعداد Firebase

1. أنشئ مشروع Firebase باسم `schoolpdf-50sols` إن كان متاحًا (الاسم الفعلي اختياري؛ استخدم ID النهائي في إعدادات الخادم).
2. أنشئ تطبيق Android بالـPackage ID الدقيق: `com.fiftysols.schoolpdf`، وتطبيق iOS بالـBundle ID نفسه.
3. تم دمج Firebase App ID وAPI key وSender ID وProject ID في إعدادات العميل من الملفين المرفوعين (`mobile/config/firebase/` و`mobile/lib/firebase_options.dart`). يشغّل `tool/patch_platforms.py` الربط الأصلي عند إنشاء مشاريع Android/iOS. فعّل Cloud Messaging واضبط APNs على iOS في Apple Developer/Firebase؛ راجع `docs/FIREBASE_NOTIFICATIONS_V1_1_1_AR.md`.
4. ضع **Service Account JSON** على الخادم خارج `public/`، وأدخل مساره في `SCHOOLPDF_GOOGLE_SERVICE_ACCOUNT_FILE`، واسم مشروع Firebase في `SCHOOLPDF_FIREBASE_PROJECT_ID`.
5. لا تختبر Push الحقيقي إلا بعد التحقق من الجهاز، إذن النظام، صلاحية FCM token ونتيجة HTTP v1؛ قبول FCM طلب الإرسال لا يعني وصوله أو قراءته.

## خصوصية المستخدمين والدول

- لا يرفع التطبيق صورًا أو ملفات PDF أو اسم الطالب أو فصله أو مواده إلى Backend.
- **قياس عدد الأجهزة والدولة متاح فقط للبالغين 18+ عند الموافقة الصريحة**، ويبدأ عند فتح التطبيق، وليس عند الضغط على زر تنزيله في المتجر. القاصرون والمجهولو العمر غير مسجلين في القياس الحالي. لا يمكن الجزم بعدد تنزيلات الجميع بهذا الأسلوب.
- الدولة تُحدد من ترويسة `CF-IPCountry` فقط عند اتصال الطلب من Proxy ذي CIDR موثوق يُضبط في `SCHOOLPDF_COUNTRY_PROXY_CIDRS`. لا GPS ولا تخزين IP بجدول الأجهزة. إذا لم يتوفر مصدر موثوق، النتيجة `Unknown`.
- لرقم تنزيلات Google Play وApp Store الرسمي، استورد CSV مهيئًا من إحصاءات المتاجر داخل الداشبورد، **مع فهم أن النظام لا يتحقق آليًا من أصل الملف**. نموذج: `backend/docs/store-installs-template.csv`.
- تسجيل الجهاز يستخدم UUID عشوائيًا وsecret على الهاتف. حذف سجل الخادم يتطلب secret. مراجعة حماية سوء الاستخدام وApp Check مطلوبة للإطلاق عالي الحجم.
- امتثال الأطفال والخصوصية والإعلانات يحتاج مراجعة قانونية وConsent Management Platform متوافقة قبل تفعيل Ads.

## تثبيت Laravel على cPanel

1. استخدم الحزمة الإنتاجية المولدة بواسطة CI مع `vendor/` و`composer.lock` و`setup-access.key`، وليس ZIP المصدر الحالي.
2. ارفع ZIP وافك الضغط، اضبط DocumentRoot ليشير إلى `backend/public`، وأنشئ قاعدة بيانات MySQL من cPanel.
3. فعّل HTTPS، وامنح المجلدات `storage/` و`bootstrap/` صلاحيات الكتابة، وافتح `/install`، وأدخل كود `setup-access.key` من جذر المشروع (خارج public) وبيانات DB وSuper Admin.
4. المعالج يختبر DB، يولد APP_KEY، ينفّذ migrations، ينشئ حساب Super Admin، يسجل lock وينظف setup-access.key بعد النجاح.
5. لجدولة الإشعارات، اختر Database Queue + Cron إذا كانت الاستضافة تدعمه؛ البديل: زر `معالجة حتى 20 مهمة معلّقة` من لوحة الإدارة. لا يوجد ضمان تشغيل مستمر للـQueue على Shared Hosting بلا Cron.

## بيانات الدومين

- `https://sclpdf.50sols.com/` — الموقع والتعريف
- `https://sclpdf.50sols.com/privacy` — Privacy Policy
- `https://sclpdf.50sols.com/terms` — Terms
- `https://sclpdf.50sols.com/support` — Support
- `https://sclpdf.50sols.com/app-ads.txt` — جميع Authorized Sellers (بعد إدخالها)
- `https://sclpdf.50sols.com/admin/ads` — إدارة مزودي الإعلانات
- `https://sclpdf.50sols.com/admin` — التقارير وحملات الإشعارات

## لماذا الإعلانات معطلة؟

هذا تطبيق يشمل الأطفال. معرف App ID الخاص بـGoogle Mobile Ads يحتاج تثبيته في ملفات Android/iOS الأصلية وإصدارًا جديدًا، وليس تغييرًا من لوحة Laravel فقط. Banner unit IDs يمكن قراءة المسموح منها من `/api/v1/config` بشرط علمَي الخادم `SCHOOLPDF_ALLOW_ADS=true` و`SCHOOLPDF_ADS_POLICY_APPROVED=true`، وعلمَي بناء التطبيق، ومعالجة UMP الفعلية والتوافق العمري. لا تُفعّل هذه الأعلام قبل إكمال UMP/المتاجر/الحماية. وسطاء مثل AppLovin MAX وUnity LevelPlay يحتاجون SDK adapters ومراجعة الأهلية ولا يتم تفعيلهم تلقائيًا بمجرد إدخال رقم.

## التنفيذ السريع على بيئة Flutter

```bash
cd mobile
bash tool/bootstrap.sh
flutter run --dart-define=SCHOOLPDF_API_BASE=https://sclpdf.50sols.com/api
```

الحزمة كاملة في ZIP واحد من حيث **السورس**. ليست حزمة نشر تشغيلية معتمدة بعد.

## تحديث Firebase للإصدار 1.1.1

أُضيفت ملفات Firebase الفعلية من المستخدم وربط Gradle/Xcode وFirebaseOptions والتعامل مع Push بالخلفية وفتح التطبيق من الإشعار. دليل التنفيذ والتشغيل: `docs/FIREBASE_NOTIFICATIONS_V1_1_1_AR.md`. لا يعني هذا أن إرسال FCM من Laravel تم اختباره أو تشغيله فعليًا.
