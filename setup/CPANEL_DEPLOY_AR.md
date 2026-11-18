# خطوات الرفع إلى sclpdf.50sols.com — بعد قبول Build الإنتاج

**لا ترفع SOURCE ZIP الحالي إلى مجلد public_html كأنه Setup نهائي.** ارفع فقط `SchoolPDF-Setup-v1.1.2.zip` الذي ينتج بعد نجاح جميع CI gates، والذي يحتوي على `vendor/` و`composer.lock` و`SETUP_MANIFEST.json`.

1. من cPanel > Domains: أضف `sclpdf.50sols.com`، فعّل SSL وتأكد من فتح HTTPS.
2. من PHP Selector/MultiPHP: اختر PHP 8.2+ وفعل `pdo_mysql`, `openssl`, `mbstring`, `fileinfo`, `zip`, `sodium` وأذونات `storage` و`bootstrap/cache`.
3. أنشئ قاعدة MySQL/MariaDB ومستخدمًا لها من Database Wizard؛ لا تضع كلمة المرور داخل ZIP.
4. ارفع ZIP إلى مسار خاص مثل `/home/CPANEL_USER/schoolpdf-app/` وافكّه **مرة واحدة**. تجنب استخراج Laravel داخل public_html بكامله.
5. من Domains اضبط Document Root للدومين **`sclpdf.50sols.com`** على المسار `/home/CPANEL_USER/schoolpdf-app/public`. إن لم تسمح الاستضافة بتعديل الجذر، راجع دعم الاستضافة ولا تنشر جذر Laravel علنًا.
6. افتح `https://sclpdf.50sols.com/install`، راجع فحص الاستضافة، أدخل الرمز من `setup-access.key` خارج public، ثم DB وSuper Admin، وأكمل Finish.
7. افحص `https://sclpdf.50sols.com/admin/login` وصفحات `/privacy`, `/terms`, `/support`, `/app-ads.txt` والـAPI.
8. ضع Firebase Admin Service Account خارج `public` بصلاحيات مقيدة واضبط مساره في `.env` بأمان. لا تضع مفتاح الخادم في تطبيق Flutter أو مجلد الويب.
9. في cPanel Cron Jobs، إن كان مسموحًا، اضبط Laravel Scheduler باستخدام مسار PHP الصحيح وتعليمات مسؤول الاستضافة. عند عدم توفر Cron، استخدم آلية المعالجة اليدوية المتاحة باللوحة مع فهم أن وصول الإشعارات لن يكون تلقائيًا مضمونًا.
10. احتفظ بنسخة آمنة من القاعدة والملفات. لا تستخدم صفحة ZIP Update حتى تستوفي بوابات التوقيع والاستعادة والاختبارات.

## في حالة فشل التثبيت

- قد تكون Migrations عدّلت القاعدة بالفعل. **لا تحذف الجداول أو تعكس Migration عشوائيًا.** راجع سجلات أخطاء الاستضافة باستخدام مدير الملفات وصلاحيات مسؤول النظام.
- إذا وُجد `.env` بدون `install.lock`، سيوقف معالج التثبيت المحاولة التالية لحماية البيانات. افحص السبب ثم استأنف من نسخة احتياطية مثبتة أو بإجراء إصلاح مراجع.
- لا تعرض `.env` وFirebase Service Account ورمز التثبيت عبر رابط عام، واحذف الحزمة المؤقتة من المساحة العامة بعد النجاح.
