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

## 3. بوابات الإصدار

- تثبيت كامل من **Setup ZIP الناتج نفسه** على قاعدة نظيفة.
- تحديث فعلي من **حزمة Setup سابقة مدعومة** باستخدام **Update ZIP الناتج نفسه**، لا مجرد fixture اصطناعية.
- الحفاظ على البيانات والملفات، واختبار فشل Migration والاستعادة إلى قاعدة منفصلة.
- Composer lock لا يتغير بدون مسار ترقية تم اختباره.
- نتائج Exact Git SHA، Laravel/security tests، وتوقيع Ed25519.
- إصدار Setup وUpdate من نفس Commit، وعدم تخزين مفاتيح أو `.env` حية في الحزم.
- عدم الادعاء بجاهزية إصدار بمجرد نجاح فحوصات المصدر.

**حاليًا لا توجد حزمة Setup إنتاجية معتمدة**. لا تستخدم `PREVIEW-UNVERIFIED` على موقع حي. لا حاجة إلى Composer أو Artisan أو npm على cPanel؛ كل البناء والاختبار يجب أن يحدثا في CI قبل الرفع.
