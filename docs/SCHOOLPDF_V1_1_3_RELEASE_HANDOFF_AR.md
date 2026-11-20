> **2026-11-20 — RELEASE 1.1.4 IN PROGRESS, NOT YET LIVE:** the previously verified 1.1.3 signed cPanel update and signed Play AAB remain the last confirmed released artifacts. School PDF 1.1.4 Families-safe AdMob work is on `feat/schoolpdf-1.1.4-families-safe-admob`. Do not upload 1.1.4 until real signed Setup/Update 1.1.3→1.1.4, AAB and exact-head CI all pass. See `docs/GOOGLE_PLAY_ADMOB_FAMILIES_1_1_4_AR.md`. Preserve Issue #10 as launch master record.

# School PDF — سجل التسليم المستمر / Worker Handoff (v1.1.3)

> **سجل العمل المعتمد لأي Worker جديد.** آخر فحص مباشر: **2026-11-20**. ارجع دائمًا إلى [Issue #10](https://github.com/walidatiyaai2025-gif/school/issues/10) وGitHub الحالي قبل التعديل. هذا سجل حالة موثّق وقت كتابته وليس تأكيدًا أن الاستضافة الحية أو Google Play تغيرا تلقائيًا.
>
> **Scope**: Laravel cPanel website/dashboard update + Android Google Play release + privacy/deletion/Families compliance. لا توسع نطاق المشروع أو تعِد بعملية نشر لا يوجد عليها إثبات. **الحساب الرسمي للدعم: info@50sols.com.**

## 1. مصدر الحقيقة والحالة المُثبتة

- Repo: https://github.com/walidatiyaai2025-gif/school ؛ base `main`. عند كتابة السجل، HEAD البرمجي المختبَر هو `d75116ece1bdaaac7fab68e6158d59d6dfa9d3af` (PR #12: إصلاحات GitHub Actions فقط).
- مصدر ملفات إصدار v1.1.3 الموقّعة هو **commit `b8c93ce4f967da23efd723c984fb2c069ad992a1`** (PR #11). إصلاحات #12 غيّرت الـWorkflows/الوثائق فقط؛ **لا تعِد إنشاء أو تسمية ZIP الموقّع بناءً على SHA توثيقي جديد**.
- [PR #9](https://github.com/walidatiyaai2025-gif/school/pull/9) — merged: سياسة الخصوصية، صفحة دعم وحذف البيانات، زر مسح بيانات الهاتف والسجل الاختياري؛ `info@50sols.com`.
- [PR #11](https://github.com/walidatiyaai2025-gif/school/pull/11) — merged: إصدار v1.1.3، Update ZIP موثّق/موقّع وSetup ZIP، واختبارات الترقية، منشئ AAB.
- [PR #12](https://github.com/walidatiyaai2025-gif/school/pull/12) — merged: إصلاح اسم Preview ZIP للنسخة الحالية، وتفريق أخضر الـBuild عن **حظر رفع AAB غير موقّع**.
- [CI Full Stack](https://github.com/walidatiyaai2025-gif/school/actions/runs/44731747753) — SUCCESS على `d75116e`: Laravel, iOS icons, branding, Android debug, setup tests.
- [CI Setup Preview](https://github.com/walidatiyaai2025-gif/school/actions/runs/44731747920) — SUCCESS على `d75116e`. Preview **غير صالح للإنتاج**.
- [CI AAB](https://github.com/walidatiyaai2025-gif/school/actions/runs/44731747851) — SUCCESS **للبناء غير الموقّع فقط**. Artifact: `SchoolPDF-v1.1.3-AAB-UNSIGNED-NOT-FOR-PLAY`. لا يوجد إثبات على AAB موقّع أو رفعه للمتجر.
- [CI cPanel VERIFIED](https://github.com/walidatiyaai2025-gif/school/actions/runs/44686475320) — SUCCESS على `b8c93ce`: توقيع Ed25519 بمفتاح متوافق مع Setup 1.1.2، Fresh Install من Setup 1.1.3، ترقية من **ZIP 1.1.2 الفعلي** إلى **Update ZIP 1.1.3 الفعلي** على MariaDB اختبارية، المحافظة على `.env` وبيانات الإدارة والأجهزة والملفات و`app-ads.txt`، التحقق من SHA-256، ورفض التلاعب وإعادة التنفيذ.
- **غير مُثبت**: إصدار الموقع المثبّت الآن، تطبيق تحديث الموقع الحي، تشغيل Cron الحقيقي، استقبال بريد الدعم، حذف فعلي على إنتاج، صحة تصريحات Google Play، اختبار APK على هاتف المستخدم، وجود Upload Key، توقيع AAB النهائي، أو تقديمه/الموافقة عليه في Google Play.

## 2. ملفات التسليم — لا تخلط ZIP الخارجي والداخلي

المصدر المعتمد: [GitHub run #44686475320](https://github.com/walidatiyaai2025-gif/school/actions/runs/44686475320) → **Artifacts**:

| Artifact الخارجي (GitHub) | الملف الداخلي | الاستخدام |
| --- | --- | --- |
| `SchoolPDF-Update-v1.1.3-VERIFIED` | `SchoolPDF-Update-v1.1.3.zip` وملف `.zip.sha256` | **تحديث موقع قائم فقط من نسخة 1.1.2 متوافقة بعد فحص المفتاح والنسخ الاحتياطية** |
| `SchoolPDF-Setup-v1.1.3-VERIFIED` | `SchoolPDF-Setup-v1.1.3.zip` وSHA-256 | **تثبيت نظيف فقط**، ممنوع استخراجه فوق موقع حي |
| `SchoolPDF-v1.1.3-AAB-UNSIGNED-NOT-FOR-PLAY` من [run #44731747851](https://github.com/walidatiyaai2025-gif/school/actions/runs/44731747851) | ملف AAB غير موقّع | **للفحص فقط؛ ممنوع رفعه إلى Google Play** |

- GitHub artifact retention للـUpdate والـSetup الموثّقين ينتهي **2026-12-20 UTC**؛ احتفظ بنسخ خاصة آمنة من الحزم وSHA-256 ودليل النتائج قبل الانتهاء.
- عند تنزيل Artifact من GitHub، يُستخرج منه ZIP الداخلي أولًا. **صفحة System Updates تستقبل `SchoolPDF-Update-v1.1.3.zip` الداخلي، لا GitHub artifact wrapper ولا Setup ZIP**.
- لا تبدّل مفتاح Ed25519 الموثوق أو تُنزّل إصدارًا أقدم لتجاوز التحقق. إن تغيرت نسخة الأساس أو هوية مفتاح التوقيع فلا تُجبر التحديث؛ افتح مسار ترقية مدعوم.

## 3. ما على المالك الآن (OWNER ACTIONS — ابدأ بهذا الترتيب)

### A. تحديث موقع cPanel / الداشبورد الموجود — أولوية 1

1. افتح **https://sclpdf.50sols.com/admin/system-updates** بحساب Super Admin؛ إن لم تفتح الصفحة، جرّب من قائمة **Settings → System → System Updates** بعد دخول لوحة الإدارة. **لا ترسل كلمات مرور أو `.env` أو أسرار للمحادثة/الإيشيو**.
2. سجّل **Current Version** و**Signed Update Verification** من الشاشة، وتأكد من تثبيت النسخة **1.1.2** ومفتاح تحقق **Configured** ومتوافق مع حزمة 1.1.2 الموثّقة. أرسل للـWorker **Screenshot يخفي الأسرار** أو النتيجة فقط.
3. إن كانت النسخة **1.1.3** أصلًا: لا تعِد تطبيق نفس ZIP؛ راجع صفحات الموقع فقط. إن كانت نسخة أخرى أو `Not configured`: **توقف**، ولا تستخدم Setup ZIP أو تعدّل مفاتيح `.env` عشوائيًا. أرسل الحالة للـWorker لعمل تشخيص متوافق.
4. نزّل **SchoolPDF-Update-v1.1.3-VERIFIED** من run #44686475320، ثم استخرج **الـZIP الداخلي**. افحص `SHA-256` باستخدام ملف الـChecksum المرفق قبل التحميل على الموقع.
5. من الداشبورد: **Backup Now → Verify Backup → Download Backup**. احتفظ بالنسخة بعيدًا عن `public_html`، وتأكد من إمكانية استعادة بياناتها؛ لا تمسح النسخ القديمة.
6. **Upload Update ZIP → Verify Package**. يجب أن تظهر رسالة نجاح أصالة التوقيع والتوافق والـpayload hashes. إن رُفضت: توقف واحتفظ بسجل الخطأ بلا بيانات حساسة.
7. اضغط **Install Verified Update** واكتب الكلمة `INSTALL` للتأكيد. لا تغلق موقعًا به `RECOVERY_REQUIRED` أو تعاود المحاولة دون خطة استرجاع. بعد التثبيت تحقق أن `Current Version = 1.1.3`.
8. اختبر علنًا وبدون تسجيل دخول:
   - https://sclpdf.50sols.com/privacy
   - https://sclpdf.50sols.com/support
   - https://sclpdf.50sols.com/data-deletion
   - https://sclpdf.50sols.com/delete-account
   - https://sclpdf.50sols.com/app-ads.txt
   تأكد من `info@50sols.com` ونص حذف البيانات واحتفاظ `app-ads.txt` بسطر AdMob الصحيح دون استبدال.
9. أرسل اختبار بريد فعلي إلى **info@50sols.com** من بريد آخر، وتأكد من وصوله، وأكد **الاسم القانوني للناشر** المطابق لحساب Google Play Organization للمراجعة القانونية.
10. افحص من الاستضافة أن **Laravel Scheduler / Cron** يعمل فعليًا قبل التعهد بمسح السجلات الخاملة بعد 90 يومًا؛ إن لم يعمل وثّق ذلك. لا تُجرِ أي reseed أو إعادة تثبيت أو تعديلات حية على قاعدة البيانات للاختبار.

### B. مفتاح رفع Google Play الثابت — أولوية 2

1. ادخل Play Console → **School PDF → App integrity / App signing**؛ افحص **Upload key certificate** إن كانت موجودة. **استخدم نفس المفتاح الأصلي** لكل إصدار لاحق. إذا كان أول إصدار ولم يوجد مفتاح، أنشئ مفتاح رفع آمنًا مرة واحدة على جهاز تملكه عبر Android Studio أو أداة `keytool` المحلية. لا تُنشئ مفتاحًا جديدًا إن سبق اعتماد مفتاح قديم.
2. خزّن الـKeystore وكلمات المرور في مكان احتياطي مشفّر **خارج GitHub**. لا ترفعها في PR أو Issues أو محادثة.
3. افتح [Repository Actions secrets](https://github.com/walidatiyaai2025-gif/school/settings/secrets/actions)، وأضف **الأربعة**:
   - `SCHOOLPDF_ANDROID_UPLOAD_KEYSTORE_B64`: **Base64 لبايتات ملف JKS/P12 بالكامل** وليس اسم الملف أو المسار. من جهاز Mac محلي فقط، يمكن استخراجها بعد التحقق من المسار: `base64 < /path/to/upload-key.jks | tr -d '\n' | pbcopy`، ثم الصق من الحافظة مباشرة في GitHub Secret.
   - `SCHOOLPDF_ANDROID_UPLOAD_STORE_PASSWORD`
   - `SCHOOLPDF_ANDROID_UPLOAD_KEY_ALIAS`
   - `SCHOOLPDF_ANDROID_UPLOAD_KEY_PASSWORD`
4. افتح [Google Play AAB workflow](https://github.com/walidatiyaai2025-gif/school/actions/workflows/google-play-aab.yml) → **Run workflow** على `main`. التشغيل اليدوي يفشل عمدًا إذا لم تُضف كل أسرار التوقيع؛ البناء التلقائي الأخضر غير كافٍ.
5. ابحث عن Artifact باسم **`SchoolPDF-v1.1.3-GooglePlay-AAB-SIGNED`**، وافحص `BUILD_INFO.json` وSHA-256 وشهادة التوقيع، وقارن **SHA-256 لUpload key certificate** مع Play Console. إن لم تتطابق: **لا ترفع الـAAB**.
6. حزمة Android المستهدفة: `com.fiftysols.schoolpdf`, `versionName=1.1.3`, `versionCode=3`, `targetSdk=36`; إعلانات الإنتاج مغلقة ومطلوب التأكد من غياب `AD_ID` في الـManifest النهائي.
7. **لا تكتب قيمة أي Secret أو تنسخ شهادة المفتاح الخاص هنا**. يمكن إرسال **أسماء الأسرار وحالة وجودها فقط** وصورة نجاح Actions مع إخفاء أي أسرار.

### C. Google Play Console / Compliance — أولوية 3

- **Screenshots الحقيقية للهاتف** غير مؤكدة: اصنع 2–8 صور من التطبيق الحقيقي باستخدام بيانات طالب تجريبية، وارفعها للـStore Listing. لا ترفع رسومًا متخيلة بدل Screenshots حقيقية.
- استكمل **Data safety, Target audience, Families, Ads, Advertising ID, App content, Content rating, Privacy policy URL, Trader status** بما يتوافق مع **AAB الموقّع الفعلي** وGoogle Play Organization. لا تُجب بأن التطبيق لا يجمع أي بيانات دون فحص Firebase/Google Mobile Ads SDK.
- التطبيق لا يدعم **إنشاء حساب طالب**؛ إدخال اسم الطالب محلي. صفحة `/delete-account` تشرح حذف البيانات وليس حذف حساب غير موجود.
- لا تفعّل إعلانات الإنتاج أو تغيّر `SCHOOLPDF_PRODUCTION_ADS` حتى مراجعة امتثال الأطفال، SDK/CMP وGoogle Play Families. إعداد AdMob من الداشبورد **لا يعني الإعلانات شغّالة**.
- ابدأ بنشر **Internal testing** للحزمة الموقّعة، راجع نتيجة Google Play pre-launch report، ثم انتقل إلى متطلبات الإنتاج بعد قبول التصريحات والمراجعات. لا تدّعِ اعتماد Google Play دون دليل من الـConsole.

## 4. بروتوكول أي Worker يستلم بعدي (NEXT WORKER)

1. ابدأ بقراءة **هذا الملف + [Issue #10](https://github.com/walidatiyaai2025-gif/school/issues/10) + التعليقات**، ثم fetch GitHub HEAD/PRs/Issues/Workflows/Artifacts/Checks من جديد. لا تعتمد على SHA قديم إذا تغير GitHub.
2. افصل بين **Source Verified** و**Production Verified** و**Owner Pending**. أخضر CI يعني فقط أن الاختبار الموصوف نجح، وليس أن cPanel أو Google Play تم تحديثهما.
3. إذا المالك أرسل إثبات **Current Version / trusted key**، تحقق من توافق Update ZIP قبل النشر. لا تطلب بيانات اعتماد ولا تنفّذ تغييرات إنتاج غير موثقة.
4. إذا المالك أضاف GitHub Secrets، استخدم الـWorkflow الموجود لإنتاج AAB موقّع من `main`، وافحص آخر HEAD وchecks وArtifacts وjarsigner/certificate. **لا تولد مفتاحًا جديدًا بدل المستخدم ولا ترفع ملفات JKS للمستودع**.
5. إذا ظهر أحمر: اقرأ سجل الفشل الحقيقي، أصلح المشكلة في فرع واحد وPR واحد، اختبر على آخر Commit ثم ادمج عند اكتمال Required Checks؛ لا تُخفِ إخفاقًا بإزالة فحوص السلامة. لا تُطلق Release جديدًا دون سبب/تغيير محتوى معتمد.
6. سجّل كل إغلاق بوضع رابط PR/commit/CI/artifact والتاريخ في Issue #10. تحديث الحالة من إثباتات فعلية فقط؛ **أبقِ #10 مفتوحًا** حتى نجاح التثبيت/التحديث الحي وسياسة الخصوصية والتوقيع/الرفع ومراجعة Google Play.
7. إن كان الملف السابق `setup/README_AR.md` أو `docs/STATUS_AND_ACCEPTANCE.md` يحتوي وصفًا قديمًا مثل SOURCE ONLY أو version 1.1.2، فالسجل **التاريخي قديم**؛ الحكم للحالة المثبتة في هذا الملف وروابط CI، مع التحقق دائمًا من GitHub الحالي.
8. لا تعبث بقاعدة الإنتاج أو `.env` أو Uploads أو مفاتيح الدفع والإعلانات؛ حافظ على بيانات المستخدمين والنسخ الاحتياطية. استخدم مسار Laravel Admin ZIP Update المختبر، لا أوامر SSH/Composer/npm/Artisan يدوية على استضافة الإنتاج.

## 5. بوابات إغلاق #10 (جميعها لازمة)

- [x] دعم `info@50sols.com`، صفحات الخصوصية والحذف، وواجهة الحذف في المصدر (PR #9).
- [x] Verified signed Setup & Update v1.1.3 مع Fresh Install وUpgrade حقيقي وBackup/Recovery على CI (run 44686475320).
- [x] إصلاح أحمر Preview/AAB CI؛ Full Stack/Preview/AAB build ناجحة على `main` (PR #12 + runs 447317...).
- [ ] تأكيد نسخة الموقع الحي، توقيع التحديث الموافق، Backup حقيقي قابل للتحقق.
- [ ] تحديث **الموقع الحي** عبر `SchoolPDF-Update-v1.1.3.zip` والتحقق من صفحات الدعم والحذف وإعدادات AdMob.
- [ ] التحقق من عمل Scheduler وطلب حذف السجل من الخادم والمسح المحلي على جهاز حقيقي/بيئة غير إنتاجية.
- [ ] استلام بريد الدعم فعليًا، ومراجعة هوية الناشر القانونية والسياسة النهائية.
- [ ] GitHub Actions secrets الخاصة بمفتاح **Google Play Upload** مُعدّة من مالك المفتاح؛ AAB موقّع ومُتحقق منه ومطابق للشهادة.
- [ ] Screenshots حقيقية، Data Safety وFamilies/Ads/AD_ID وتصريحات المتجر مطابقة للـAAB.
- [ ] Internal test/Google Play review and publication confirmed with URL/evidence.

**لا تغلق Issue #10 ولا تدّعِ "Google Play ready" بسبب نجاح Build وحده.**
