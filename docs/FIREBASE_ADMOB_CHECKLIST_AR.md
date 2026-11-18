# School PDF — حسابات وإعدادات الطرف الثالث

| النظام | الاسم/المعرف المقترح | المطلوب قبل الاختبار الحقيقي |
|---|---|---|
| Display Name | School PDF | تحقق من توفر الاسم والعلامة التجارية |
| Android Package | `com.fiftysols.schoolpdf` | ثبته في Firebase/Play Console وملفات Gradle |
| iOS Bundle ID | `com.fiftysols.schoolpdf` | ثبته في Apple Developer/Firebase |
| Firebase Project Display Name | `School PDF` | المشروع الفعلي في الملفات المرفوعة هو `schoolpdf-50sols` |
| Website | `https://sclpdf.50sols.com` | DNS/SSL/Document Root |
| API | `https://sclpdf.50sols.com/api/v1` | Laravel منشور ومستقر |
| Firebase FCM | Android Firebase config + APNs iOS | Android/iOS tokens, permissions, send test |
| Firebase Admin | JSON service account **Server only** | رفع خارج public وإضافة المسار في `.env` |
| AdMob Android/iOS | أدخل App ID منفصلًا لكل منصة | استبدل معرفات TEST في native build قبل الإنتاج |
| AdMob Mediation | Network adapters configured in AdMob | اختبار network-by-network واتفاقيات الناشرين |
| AdMob app-ads.txt | `https://sclpdf.50sols.com/app-ads.txt` | أضف أسطر sellers الحقيقية ثم تحقق عبر AdMob |
| Developer Website | `https://sclpdf.50sols.com` | أضفه في Play Console/App Store Connect |
| Privacy | `/privacy` | بيانات مشغل الخدمة، بريد، قانون حماية القُصّر، ضوابط موافقات |
| Terms | `/terms` | المراجعة القانونية |
| Support | `/support` | بريد دعم حقيقي |

*إعدادات وحدات الإعلانات يمكن حفظها في لوحة Laravel؛ لا تستضيف حسابات شركات الإعلان نفسها على هذا الدومين.*

## ما تحتاج توفيره أنت

- **تم توفير** ملفي إعداد Firebase للعميل (Android وiOS) ودمجهما في `mobile/config/firebase/`. ما زال مطلوبًا تجهيز شهادة APNs ومفاتيح إرسال الخادم بعيدًا عن السورس.
- Service Account JSON يوضع **مباشرة على الاستضافة خارج web root**، وليس في محادثة عامة أو Git.
- AdMob Android App ID، iOS App ID، Android/iOS Banner Unit IDs، وأرقام الشبكات الإضافية.
- ملكية الدومين والاستضافة وقاعدة MySQL، واسم الجهة القانونية وبريد الدعم.
- تصنيف عمر الجمهور وسياسة الـCMP؛ خلال هذه النسخة إعلانات الإنتاج مغلقة افتراضيًا.

## ملاحظة مهمة حول الدولة

استخدم Cloudflare Proxy بإعداد IP geolocation إن رغبت في توزيع الدول دون GPS. لا تثق بترويسة الدولة من مستخدم عادي. أدخل عناوين الـCIDR الصحيحة والمحدّثة للخادم الوكيل المباشر في `SCHOOLPDF_COUNTRY_PROXY_CIDRS`؛ لا تضع `0.0.0.0/0`. بدونها تعرض لوحة الإدارة `??` بصدق.
