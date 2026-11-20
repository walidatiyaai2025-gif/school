# School PDF v1.1.4 — إعداد إعلانات AdMob لجميع الأعمار بأمان

**الحالة:** متطلبات كود/CI قيد التنفيذ. ممنوع افتراض أن إعلانات الإنتاج أو اعتماد Google Play يعملان تلقائيًا.

## المعرّفات التي لا يجب الخلط بينها

- **AdMob App ID:** `ca-app-pub-3218037275900725~8048418854`.
- **Standard Banner Ad Unit ID:** `ca-app-pub-3218037275900725/8379591348`.
- **Publisher ID:** `pub-3218037275900725` في `app-ads.txt`.
- **Advertising ID/AAID:** ليس رقمًا تأخذه من AdMob؛ هو معرّف خاص بكل هاتف Android. مشروع School PDF يحذف صلاحية `com.google.android.gms.permission.AD_ID` عمدًا في إصدار الأطفال المختلط. لا تجمعه أو تشاركه من الأطفال أو العمر غير المعروف.

## التنفيذ في التطبيق

- شاشة فئة عمرية محايدة قبل عرض أي إعلان (Child/Teen/Adult). مجهول أو ملف تالف → **Child**.
- الأولاد والمراهقون وغير المعروفين: `AgeRestrictedTreatment.child` و`MaxAdContentRating.g` قبل تهيئة SDK، والطلبات كلها `AdRequest(nonPersonalizedAds:true)`.
- يستخدم **Google AdMob فقط** دون أي Adapter آخر؛ SDK Android `play-services-ads` متوافق مع قائمة Families Self-Certified عند اعتماد نسخة الـDependency المستعملة.
- الموافقات UMP: `tagForUnderAgeOfConsent:true` للقاصرين، وللبالغين مسار UMP ورسائل Privacy & messaging المطلوبة. عدم توافر الموافقة/الشبكة يعني عدم تحميل بانر.
- بانر واحد بإشارة «إعلان / Advertisement»، بمكان ثابت ولا ينقل زرار التصفح تحت يد الطفل.
- بناء Android `1.1.4+4` مع `SCHOOLPDF_PRODUCTION_ADS=true` لا يكفي وحده للعرض: **لوحة الإدارة يجب أن تراجع وتوافق وتفعّل الوحدة**.

## ما على صاحب المشروع

1. في AdMob → Apps → School PDF → Ad units: تأكد من أن `8379591348` وحدة **Standard Banner** وليست Partner bidding.
2. في AdMob → **Privacy & messaging**: جهّز رسالة UMP للبالغين في المناطق المعنية، وتحقق من قصر الرسائل على الأعمار المؤهلة.
3. لا تضف AppLovin/Meta/Mintegral/Custom Events أو أي Mediation غير معتمد للعائلات؛ يفضل Google AdMob direct فقط لهذا الإصدار.
4. من لوحة cPanel أولًا تأكد من نسخة `1.1.3` والتوقيع والـBackup؛ استخدم فقط **SchoolPDF-Update-v1.1.4.zip** الموقّع بعد نجاح اختبارات التحديث الحقيقية، ولا تستعمل Setup ZIP فوق الموقع.
5. بعد الترقية، افتح **Admin → Ads** وسجّل اعتماد قائمة Families **فقط بعد التحقق الفعلي** من بنودها، ثم فعّل وحدة AdMob Android المحفوظة.
6. تحقق من `https://sclpdf.50sols.com/api/v1/config`: `ads.enabled=true` وتوجد وحدة AdMob واحدة، والتعطيل الطارئ يعمل.
7. نزّل Signed AAB من نفس Commit النهائي بعد نجاح CI، ثم في Google Play اختر **Contains ads: Yes**؛ راجع Advertising ID حسب السلوك الحقيقي للـAAB وData Safety/Target audience/Families/Photos & Videos وTrader status.
8. اختبر عمليًا عرض الطفل والمراهق والبالغ وعدم ظهور إعلانات ذات محتوى غير مناسب أو إعلانات مخصصة، وعدم وجود Ads قبل اختيار العمر.
9. تأكد من نشر صفحة الخصوصية المحدثة وصفحات الحذف و`app-ads.txt` وحالة AdMob App Readiness قبل إعلان نجاح الإيرادات.

**الأمان:** الإعلانات اختيارية في التشغيل؛ فشل CMP أو الخادم أو SDK لا يوقف التصوير/PDF. إيقاف الإعلانات من Dashboard فوري عند عودة الاتصال؛ إعداد `SCHOOLPDF_ADS_EMERGENCY_STOP=true` في الاستضافة يوقف الطلبات دائمًا.

## قبول فني إلزامي

- اختبارات Child/Teen/Unknown/Adult + No personalized + G rated + no AD_ID.
- منع تفعيل Dashboard دون اعتماد شامل وحظر أي مزود غير AdMob.
- اختبارات RBAC، CSRF، إيقاف فوري، ومطابقة App ID مع Banner Unit.
- اختبار تثبيت نظيف من Setup 1.1.4، وترقية من Setup 1.1.3 باستخدام Update ZIP 1.1.4 الأصلي الموقّع مع بقاء DB/.env/Files/app-ads.txt.
- فحص شهادات توقيع Android، الـManifest، SDK Families Self-Certified والـAAB الجديد ونتائج Play Console.

## مراجع رسمية
https://support.google.com/googleplay/android-developer/answer/9893335
https://support.google.com/googleplay/android-developer/answer/12955712
https://support.google.com/admob/answer/6223431
https://developers.google.com/admob/flutter/targeting
https://developers.google.com/admob/flutter/privacy

## Google Play Photos and Videos permission gate

The app uses Flutter `image_picker` / Android system Photo Picker for explicit single/multi-image selection. The 1.1.4 Manifest uses `tools:node="remove"` for `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_VISUAL_USER_SELECTED` and `READ_EXTERNAL_STORAGE`. The AAB workflow checks both merged Manifest and final bundle. This addresses the broad photo/video-access policy without claiming access to all photos. Camera and gallery picker runtime must still be tested on API 24/32/33/36; the app only receives user-selected content.
