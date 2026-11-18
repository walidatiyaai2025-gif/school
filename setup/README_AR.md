# School PDF — setup/ | Version 1.1.2

هذا المجلد هو نقطة الدخول الرسمية لتجهيز نشر Laravel على استضافة `sclpdf.50sols.com`، بنظام **ZIP واحد → فكّ الضغط → /install → لوحة الإدارة**.

## الملفات

- `build_setup.py`: يصنع ملف `setup/output/SchoolPDF-Setup-v1.1.2.zip` **فقط** عندما تكون مكتبات Laravel الإنتاجية موجودة ومثبتة من lock موثق، وتكون نتائج بوابات القبول الحقيقية ناجحة على نفس Git SHA.
- `installer/install.php`: نسخة تدقيق من معالج الويب الفعلي، ويُفحص تطابقها قبل البناء.
- `tests/`: اختبارات فشل البناء عند نقص البيانات ورفض تسريب الأسرار والروابط الرمزية، وفحص checksum وmanifest.
- `output/BUILD_STATUS.json`: الحالة الفعلية الحالية؛ لا يعني وجود فولدر output وجود ZIP قابل للنشر.
- `RELEASE_NOTES_AR.md`: وصف تغييرات المصدر.
- `CPANEL_DEPLOY_AR.md`: دليل الرفع والاستضافة وخطة الاستعادة.
- معالج الويب الفعلي في `backend/public/install.php` ويُضمّن تلقائيًا داخل Setup ZIP النهائية.

## الحالة الحالية عند إنشاء هذه النسخة

**NOT_PRODUCTION_READY**؛ لا يوجد `backend/composer.lock` ولا `backend/vendor/autoload.php`، وبيئة الإنشاء الحالية لا تحتوي على Composer أو PHP extensions اللازمة ولا اتصال مباشر بPackagist. لا توجد نتائج Fresh Install أو Upgrade أو Recovery حقيقية.

لذلك **لم تتم صناعة ZIP إنتاجية وهمية**. لن يكون من الآمن رفع سورس ZIP مباشرة إلى cPanel على أساس أنه جاهز للتثبيت. هذا المنع متعمد حتى لا تتعطل الاستضافة أو تتعرض بياناتها للخطر.

## بناء النسخة النهائية (على CI / Builder، وليس على استضافة الإنتاج)

1. إنشاء وتثبيت `composer.lock` للـLaravel 12 من بيئة تطوير موثوقة، وحفظه في نفس commit الخاص بالإصدار.
2. تشغيل `composer install` لاختبارات Laravel والتأمين وFresh Install وUpgrade/Recovery من الحزم نفسها. اختبار ZIP الذي سيتلقى المستخدم نفسه إلزامي.
3. بناء `vendor/` باستخدام `composer install --no-dev --prefer-dist --optimize-autoloader` مع `composer.lock` نفسه.
4. تسجيل دليل قبول CI **حقيقي** يتضمن: `laravel_tests`, `security_checks`, `fresh_install`, `upgrade`, `recovery` بحالة PASS، مع SHA مطابق لأحدث commit؛ لا تكتب PASS تجريبيًا.
5. تشغيل `python3 setup/build_setup.py --git-sha <EXACT_40_CHAR_SHA>`؛ سيظهر ZIP وSHA-256 وmanifest وbuild info في `setup/output/` عند تحقق الشروط.
6. التحقق من سلامة ZIP والتوقيع/منظومة التحديث والاختبارات على cPanel قبل اعتبارها Release.

> لا تُدرج Service Account الخاص بـFirebase أو ملف .env أو كلمات مرور القاعدة في ZIP، ولا تضع مشروع Laravel كاملًا داخل Document Root العام. المفتاح الذي يتولد مع حزمة التثبيت `setup-access.key` سري ومخصص للمشرف، ويُحذف بعد النجاح.

## خصائص معالج التثبيت

يتحقق من HTTPS، الدومين، PHP 8.2+، الامتدادات، `vendor`، صلاحيات الكتابة، وعدم وجود `.env` سابق. يختبر MySQL، يولد APP_KEY و`.env`، يشغّل Migrations، ينشئ Super Admin، ويقفل التثبيت بملف خاص خارج public. لا ينفذ أوامر Terminal من جهاز المستخدم.

الـQueue الافتراضية database، والأوضاع الحساسة للإعلانات مغلقة افتراضيًا. إعداد Cron على cPanel قد يكون يدويًا، وإعداد Mail/Firebase Service Account يتم بعد التثبيت من الاستضافة بأذونات آمنة. فشل Migration لا يعكس قاعدة البيانات تلقائيًا؛ راجع الدليل قبل إعادة المحاولة.

## التحديثات

`Settings → System → System Updates` موجودة حاليًا لكن تثبيت ZIP **مقفل** إلى حين توقيع Ed25519 والنسخ الاحتياطي والاسترجاع واختبار الترقية. لا تعتبر هذه النسخة معتمدة للإنتاج أو للإطلاق.
