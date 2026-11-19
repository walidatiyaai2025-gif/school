# School PDF v1.1.2 — cPanel مع Document Root ثابت

هذا المسار مخصص للاستضافة التي تجبر الدومين `sclpdf.50sols.com` على `public_html/sclpdf.50sols.com` ولا تسمح بتغييره.

## المسارات الملزمة

- جذر Laravel الخاص: `/home/ACCOUNT/sclpdf/` (خارج `public_html` تمامًا).
- جذر الويب الثابت: `/home/ACCOUNT/public_html/sclpdf.50sols.com/`.
- داخل جذر الويب فقط: `.htaccess` و`.schoolpdf-bridge.php` و`index.php` و`install.php`. لا تضع `vendor` أو `storage` أو `.env` هنا.
- الجسر لا يستخدم Symlink، ولا يطلب SSH أو Composer/Artisan على الإنتاج. ويستدعي مُثبّت Laravel الأصلي في المجلد الخاص، ولذلك يُنشأ رمز `setup-access.key` داخل `sclpdf` وليس داخل الدومين.
- ملفات الإعلانات والروبوتات والصور العامة تُقدّم من `sclpdf/public` عبر مسارات مقيدة، حتى تظهر التغييرات من لوحة الإدارة والتحديثات مباشرة.

## إذا كان مجلد sclpdf موجودًا عندك بالفعل (كما ظهر بالصورة)

1. افتح `sclpdf` من File Manager، وتأكد من وجود `SETUP_MANIFEST.json` و`composer.lock` و`vendor/autoload.php` و`public/install.php` و`public/index.php`. لا تكشف محتويات `.env` أو أي سر.
2. **لا تفك حزمة التثبيت الكاملة فوق `sclpdf` الموجود**. إذا كان الملف `.env` أو `storage/app/private/install.lock` موجودًا، احتفظ بهما ولا تُعِد التثبيت. 
3. ادخل `public_html/sclpdf.50sols.com`، ويُفضَّل التأكد أنه فارغ أو أخذ نسخة من محتوياته العامة القائمة.
4. ارفع فقط `SchoolPDF-WebBridge-v1.1.2.zip` إلى هذا المجلد، ثم Extract مرة واحدة داخله. بعد الفك يجب أن تشاهد ملفات الجسر الأربعة فقط. فعّل خيار عرض الملفات المخفية في cPanel لرؤية `.htaccess` و`.schoolpdf-bridge.php`.
5. لا تغيّر Document Root (يبقى `public_html/sclpdf.50sols.com`). افحص HTTPS وPHP 8.2+ والامتدادات `pdo_mysql`, `mbstring`, `fileinfo`, `openssl`, `zip`, `sodium`.
6. افتح `https://sclpdf.50sols.com/install`. إن كان التثبيت مُقفَلًا، فهو مُنجَز مسبقًا؛ انتقل للوحة الإدارة ولا تحذف القفل. إن ظهر المعالج، سيُنشئ رمز التثبيت داخل `sclpdf/setup-access.key`. اقرأه من File Manager الخاص فقط، ولا تشاركه في المحادثات.
7. إذا لم تكن قاعدة MySQL جاهزة، أنشئ قاعدة ومستخدمًا من cPanel Database Wizard وأعطه الصلاحيات اللازمة، ثم أدخل بياناتها في المعالج مع بيانات Super Admin.

## لتثبيت جديد تمامًا — ONE ZIP

استخدم `SchoolPDF-FixedRoot-Setup-v1.1.2.zip` **فقط إذا لم يوجد مشروع/موقع School PDF مثبت مسبقًا**.

1. ارفع الحزمة إلى **Home** الخاص بحساب cPanel (الذي يحتوي على `public_html`)، وليس إلى `public_html` نفسه.
2. فك الضغط مرة واحدة داخل Home، ليُنشئ المجلدين `sclpdf` و`public_html/sclpdf.50sols.com` من نفس الحزمة.
3. أكمل PHP/SSL/MySQL ومعالج `/install` كما بالأعلى.
4. إذا كان `sclpdf` موجودًا أو يحتوي على بيانات حية، **لا تستخدم هذا المسار**؛ حزمة WebBridge فقط هي المسموحة على الموجود.

## عند ظهور خطأ

- **503 School PDF: private Laravel package missing or unsafe**: راجع المسارات الخاصة، وتأكد أنك رفعت **Setup الإنتاجي VERIFIED** وليس Source ZIP/Preview، وأن `SETUP_MANIFEST.json` و`vendor/autoload.php` موجودان.
- **403 /install already installed**: التثبيت مقفل؛ افتح `/admin/login`. لا تحذف `install.lock`.
- **500 مع رسالة .htaccess**: تأكد أن الاستضافة تستخدم Apache/LiteSpeed وتسمح `Options -Indexes` و`Require all denied`؛ لا تحذف قيود الحماية لمجرد إخفاء الخطأ. تواصل مع الدعم بشأن توافق هذه التوجيهات.
- **403 أو 404 بعد التثبيت**: راجع إعداد PHP وإعادة الكتابة `mod_rewrite` وHTTPS من cPanel. لا تنقل Laravel إلى `public_html`.
- **.env موجود بدون install.lock**: تثبيت غير مكتمل؛ لا تحذف .env أو قاعدة البيانات. استخدم Backup/Recovery وراجع السجلات قبل أي إعادة محاولة.
- **تحديثات ZIP من لوحة الإدارة**: تعمل على الجذر الخاص. راجع توافق التحديث مع الإصدار والتوقيع والنسخ الاحتياطي قبل Install Update. لا تستبدل الجسر بملفات Laravel الكاملة.

## فحوصات السلامة

- افتح `https://sclpdf.50sols.com/` و`https://sclpdf.50sols.com/install`.
- يجب ألا تظهر محتويات `/.env` أو `/vendor/autoload.php` أو `/storage/` أو `/.schoolpdf-bridge.php` عبر الدومين، حتى لو طلبتها مباشرة.
- جرّب `/robots.txt` و`/app-ads.txt`، وتحقق من أن المحتوى العام يتم تقديمه.
- لا تفعل Live Ads أو Push الحقيقي قبل استكمال الإعدادات ومراجعة الامتثال.

الحزم تُبنى من نفس Setup ZIP المجتاز للتثبيت المستقل، ولا تُعتمد بدون Evidence وSHA-256.
