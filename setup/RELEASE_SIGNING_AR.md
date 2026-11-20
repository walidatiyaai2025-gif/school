> **تنبيه بتاريخ 2026-11-20:** هذا المستند يحتوي معلومات تاريخية قديمة. الحالة المعتمدة الحالية لإصدار 1.1.3، وملفات GitHub الموقّعة، وخطوات المالك والـWorkers موثقة في [سجل تسليم School PDF v1.1.3](../docs/SCHOOLPDF_V1_1_3_RELEASE_HANDOFF_AR.md) و[Issue #10](https://github.com/walidatiyaai2025-gif/school/issues/10). لا تفترض SOURCE-ONLY أو عدم وجود ZIP موثّق بالاعتماد على الأسطر التاريخية أدناه؛ تحقق من CI الحالي دائمًا.

---

# School PDF — إعداد توقيع تحديثات ZIP الإنتاجية

هذه خطوة **مرة واحدة فقط** على جهاز المالك. لا تُرسل المفتاح الخاص إلى ChatGPT، ولا تضعه في Git Commit أو ZIP أو حزمة cPanel. لا تُنشئ زوج مفاتيح جديد لكل إصدار؛ الاستبدال غير المخطط سيمنع التحقق من التحديثات القديمة.

## 1. توليد المفتاح على Mac (محليًا، لا على cPanel)

افتح Terminal على الماك، ونفّذ:

```bash
mkdir -p "$HOME/.schoolpdf-release"
chmod 700 "$HOME/.schoolpdf-release"

php <<'PHP'
<?php
$directory = getenv('HOME').'/.schoolpdf-release';
$secretFile = $directory.'/ed25519-private-base64.txt';
$publicFile = $directory.'/ed25519-public-base64.txt';
if (file_exists($secretFile) || file_exists($publicFile)) {
    fwrite(STDERR, "Existing signing key preserved. Do not overwrite.\n");
    exit(1);
}
$pair = sodium_crypto_sign_keypair();
$private = base64_encode(sodium_crypto_sign_secretkey($pair));
$public = base64_encode(sodium_crypto_sign_publickey($pair));
file_put_contents($secretFile, $private."\n", LOCK_EX);
chmod($secretFile, 0600);
file_put_contents($publicFile, $public."\n", LOCK_EX);
chmod($publicFile, 0644);
echo "Ed25519 key pair generated privately. No secret printed.\n";
PHP
```

احتفظ بنسخة احتياطية مشفرة من `ed25519-private-base64.txt` خارج GitHub، في مدير كلمات مرور أو مخزن أسرار موثوق.

## 2. حفظ المفتاح الخاص في GitHub Actions

1. افتح [School PDF → Settings → Secrets and variables → Actions](https://github.com/walidatiyaai2025-gif/school/settings/secrets/actions).
2. اختر **New repository secret**.
3. اكتب الاسم `SCHOOLPDF_RELEASE_ED25519_KEY_B64`.
4. في خانة Secret الصق المحتوى المحلي لملف `ed25519-private-base64.txt`، واحفظه.
5. **لا تضع المفتاح الخاص في Issue أو PR أو المحادثة أو GitHub Variable أو Release Asset.**

الـPublic Key من `ed25519-public-base64.txt` ليس سرًا؛ نظام البناء يشتقه من Secret ويزرعه داخل `.env.example` في حزمة Setup، ويستعمله Laravel للتحقق من التحديثات.

## 3. معالجة خطأ التوقيع في CI

إذا فشل `Validate protected release signer` برسالة `invalid protected Ed25519 signer`، تحقق من **قيمة GitHub Actions Secret** باسم `SCHOOLPDF_RELEASE_ED25519_KEY_B64` في إعدادات المستودع. لا ترسل السر في المحادثات أو Logs.

- يقبل البناء الآن صيغة **Ed25519 seed** بطول **32 بايت بعد فك Base64**، أو مفتاح libsodium الخاص بطول **64 بايت بعد فك Base64**. يجب أن تكون صيغة الـ64 بايت متسقة داخليًا (الجزء العام مطابق للمشتق من الـSeed).
- لا تقبل القيمة نصًا عاديًا أو Hex أو المفتاح العام أو Base64 غير صالح. لا يجوز نسخ الـPublic Key إلى خانة الـSecret.
- إن كان السر الموجود تالفًا، استرجع **نفس المفتاح الخاص الأصلي** من التخزين المشفر، واستبدل قيمة Repository Secret يدويًا. لا تغيّر هوية التوقيع إن سبق نشر أي Setup لعملاء؛ تدوير المفتاح يحتاج مسار ثقة/انتقال مُراجع.
- تُنفّذ Pull Requests الاختبارات باستخدام مفتاح مؤقت خاص بالـCI فقط، **ولا تحصل على سر الإنتاج ولا تنشر Verified Artifact**. وحده نجاح Workflow على `main` مع سر محمي صالح يسمح بإصدار ZIP معتمد.
- بعد إصلاح السر، أعد تشغيل `School PDF cPanel Setup v1.1.2 - Verified First Install` على `main`، وتأكد من نجاح `build-candidate` ثم `independently-install-exact-setup` ثم `publish-verified-cpanel-setup`. لا ترفع `CANDIDATE-UNVERIFIED` أو `PREVIEW-UNVERIFIED` إلى الإنتاج.

## 4. بوابات الإصدار

- تثبيت كامل من **Setup ZIP الناتج نفسه** على قاعدة نظيفة.
- تحديث فعلي من **حزمة Setup سابقة مدعومة** باستخدام **Update ZIP الناتج نفسه**، لا مجرد fixture اصطناعية.
- الحفاظ على البيانات والملفات، واختبار فشل Migration والاستعادة إلى قاعدة منفصلة.
- Composer lock لا يتغير بدون مسار ترقية تم اختباره.
- نتائج Exact Git SHA، Laravel/security tests، وتوقيع Ed25519.
- إصدار Setup وUpdate من نفس Commit، وعدم تخزين مفاتيح أو `.env` حية في الحزم.
- عدم الادعاء بجاهزية إصدار بمجرد نجاح فحوصات المصدر.

**حاليًا لا توجد حزمة Setup إنتاجية معتمدة**. لا تستخدم `PREVIEW-UNVERIFIED` على موقع حي. لا حاجة إلى Composer أو Artisan أو npm على cPanel؛ كل البناء والاختبار يجب أن يحدثا في CI قبل الرفع.
