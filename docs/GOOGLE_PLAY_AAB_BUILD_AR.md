# School PDF — تجهيز AAB على GitHub بدون نشر أسرار التوقيع

الإصدار: **1.1.3+3** · Package: **com.fiftysols.schoolpdf** · Target API **36**.

## البناء الآلي
تعمل GitHub Actions `School PDF 1.1.3 Google Play AAB` على Pull Requests وmain.
- Pull Request: يبني AAB **غير موقّع** لا يجوز رفعه للمتجر، لاختبار Gradle وFlutter و16KB.
- main: يقرأ فقط مفاتيح رفع ثابتة من Secrets، ويوقع الـAAB ويختبر توقيعه. عند غيابها، يتيح نسخة اختبار غير موقّعة ويرجع Status فشل مقصود، **ولا يدّعي الجاهزية**.
- لا يستخدم مفتاح Debug أو مفتاحًا يولد لكل تشغيل. لا تنشر ملفات keystore أو كلمات المرور ضمن الكود أو الـArtifacts.
- إعدادات الإنتاج تترك الإعلانات مغلقة وتزيل `com.google.android.gms.permission.AD_ID` من Manifest؛ أي تفعيل لاحق يتطلب إصدارًا مراجعًا.

## مفاتيح GitHub Actions التي يضيفها مالك مفتاح الرفع
من Repository Settings → Secrets and variables → Actions أضف:
1. `SCHOOLPDF_ANDROID_UPLOAD_KEYSTORE_B64` — محتوى ملف JKS/PKCS12 ثابت مُشفّر Base64، ليس كلمة المرور.
2. `SCHOOLPDF_ANDROID_UPLOAD_STORE_PASSWORD` — كلمة مرور الـKeystore.
3. `SCHOOLPDF_ANDROID_UPLOAD_KEY_ALIAS` — Alias الشهادة.
4. `SCHOOLPDF_ANDROID_UPLOAD_KEY_PASSWORD` — كلمة مرور المفتاح.

أنشئ أو استرجع مفتاح الرفع في Android Studio بطريقة موثوقة، واحتفظ بنسخة احتياطية مشفّرة خارج GitHub. استخدم **نفس مفتاح الرفع** لإصدارات Google Play المستقبلية. لا ترسل هذه الأسرار بالمحادثة.

## التحقق قبل الرفع
- النجاح الأخضر وحده لا يعني أن النسخة موجودة في Google Play.
- تحقق أن **App Signing → Upload key certificate** في Play Console يطابق الشهادة التي وقّعت الـAAB (SHA-256)، أو حدّد شهادة الرفع في أول إنشاء للتطبيق.
- افحص **Data safety / Families / Target audience / Ads** مقابل الحزمة النهائية، وأكمل سياسة الخصوصية وقائمة صور Screenshots الحقيقية.
- تنزيل `SchoolPDF-v1.1.3-GooglePlay-AAB-SIGNED` من Actions فقط إذا كانت موجودة مع نجاح التوقيع؛ `UNSIGNED-NOT-FOR-PLAY` غير صالحة للنشر.
- يتم رفع AAB من Play Console → Testing → Internal testing أولًا، ثم مراجعة تقرير ما قبل الإطلاق.
