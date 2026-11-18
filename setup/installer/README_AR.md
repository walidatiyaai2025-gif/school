# ملفات Web Installer

هذا الملف نسخة مراجعة من معالج التثبيت الفعلي الموجود في `backend/public/install.php`.

- **مكان التشغيل الحقيقي داخل حزمة Laravel:** `public/install.php`، وتدخل إليه عن طريق `https://sclpdf.50sols.com/install`.
- **لا ترفع هذا الملف منفردًا**؛ يحتاج Laravel production dependencies وملف `setup-access.key` الخاص بحزمة Setup المكتملة.
- `setup/build_setup.py` يرفض توليد إصدار إذا اختلفت نسخة المعالج هنا عن نسخة التشغيل الفعلية.
- نسخة السورس الحالية ليست حزمة Laravel Setup إنتاجية جاهزة؛ راجع `../output/BUILD_STATUS.json`.
