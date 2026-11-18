<?php
/** School PDF — cPanel-first installer, PHP-only until Laravel is ready.
 * No terminal / Composer / npm commands run on the production server.
 * Installer is intentionally blocked if the *precompiled* vendor directory is absent.
 */
declare(strict_types=1);
$root=dirname(__DIR__);
$private=$root.'/storage/app/private';
$lock=$private.'/install.lock';
header('Content-Type: text/html; charset=utf-8');
header('Cache-Control: no-store, private');
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('Referrer-Policy: no-referrer');
header('Content-Security-Policy: default-src \'none\'; style-src \'unsafe-inline\'; script-src \'unsafe-inline\'; form-action \'self\'; base-uri \'none\'');
if (is_file($lock)) { http_response_code(403); exit('School PDF is already installed; setup is permanently locked.'); }
if (is_file($root.'/PREVIEW-NOT-FOR-PRODUCTION.txt') && getenv('SCHOOLPDF_CI_INSTALL_SMOKE') !== '1') {
    http_response_code(403); exit('School PDF setup preview is blocked from live deployment.');
}
$isHttps=isset($_SERVER['HTTPS']) && $_SERVER['HTTPS']!=='off' && $_SERVER['HTTPS']!=='';
$canonicalHost=strtolower((string)($_SERVER['HTTP_HOST']??''))==='sclpdf.50sols.com';
// Generate the installer secret ONLY on the destination server after a valid
// HTTPS request. Release artifacts must not contain a reusable access code.
if ($isHttps && $canonicalHost && is_dir($private) && is_writable($private) &&
    !is_file($root.'/setup-access.key')) {
    $keyfile=$root.'/setup-access.key';
    $keyhandle=@fopen($keyfile,'x');
    if ($keyhandle !== false) {
        chmod($keyfile,0600);
        $token=bin2hex(random_bytes(32))."\n";
        $written=fwrite($keyhandle,$token);
        fflush($keyhandle);
        fclose($keyhandle);
        if ($written !== strlen($token)) @unlink($keyfile);
    }
}

ini_set('session.use_strict_mode','1');
ini_set('session.cookie_httponly','1');
ini_set('session.cookie_secure','1');
ini_set('session.cookie_samesite','Strict');
if ($isHttps) session_start();
if ($isHttps) $_SESSION['schoolpdf_setup_csrf']??=bin2hex(random_bytes(32));
function input(string $key):string { return trim((string)($_POST[$key]??'')); }
function quoteEnv(string $key,string $value):string {
    return $key.'="'.str_replace(['\\','"',"\r","\n"],['\\\\','\\"','',''],$value).'"';
}
function setEnv(string $text,string $key,string $value):string {
    $line=quoteEnv($key,$value);
    return preg_match('/^'.preg_quote($key,'/').'=.*$/m',$text)
        ? (string)preg_replace_callback('/^'.preg_quote($key,'/').'=.*$/m',static fn()=>$line,$text,1)
        : $text."\n".$line;
}
function resultRow(string $name,bool $ok,string $reason):array {return ['name'=>$name,'ok'=>$ok,'help'=>$reason];}
$checks=[
    resultRow('HTTPS',$isHttps,'فعّل SSL على الدومين قبل بدء التثبيت'),
    resultRow('Domain: sclpdf.50sols.com',$canonicalHost,'وجّه DNS والدومين الصحيح إلى مجلد public'),
    resultRow('PHP 8.2+',version_compare(PHP_VERSION,'8.2','>='),'اختر PHP مناسبًا من MultiPHP Manager'),
];
foreach (['pdo_mysql','mbstring','openssl','fileinfo','zip','sodium'] as $extension)
    $checks[]=resultRow("PHP: $extension",extension_loaded($extension),'فعّل الامتداد من PHP Selector');
$checks[]=resultRow('Composer dependencies',is_file($root.'/vendor/autoload.php') && is_file($root.'/composer.lock'),'يجب رفع Setup ZIP المكتملة؛ لا تعمل Composer على الاستضافة');
$checks[]=resultRow('Storage writable',is_dir($private) && is_writable($private) && is_writable($root.'/storage/framework'),'امنح صلاحيات الكتابة لـstorage');
$checks[]=resultRow('Bootstrap cache writable',is_dir($root.'/bootstrap/cache') && is_writable($root.'/bootstrap/cache'),'اسمح للـWeb Server بالكتابة في bootstrap/cache');
$checks[]=resultRow('Laravel root writable',is_writable($root),'مطلوب لإنشاء .env بأمان');
$checks[]=resultRow('Access code outside public',is_file($root.'/setup-access.key'),'رمز التثبيت يرافق Setup ZIP في الجذر الخاص فقط');
$checks[]=resultRow('Clean first install',!is_file($root.'/.env'),'إن كان .env موجودًا، لا تستبدله: راجع الاستعادة/النسخة السابقة');
$ready=!in_array(false,array_column($checks,'ok'),true);
$errors=[];
$installed=false;
if (($_SERVER['REQUEST_METHOD']??'GET')==='POST') {
    if (!$isHttps || !$canonicalHost) { http_response_code(403); $errors[]='HTTPS والدومين المحدد مطلوبان.'; }
    elseif (!hash_equals((string)($_SESSION['schoolpdf_setup_csrf']??''),input('csrf'))) {
        http_response_code(419); $errors[]='انتهت الجلسة؛ أعد تحميل الصفحة.';
    } elseif (!$ready) { http_response_code(422); $errors[]='بيئة الاستضافة غير جاهزة؛ أصلح فحص المتطلبات.'; }
    elseif ((int)($_SESSION['setup_attempts']??0)>=5) { http_response_code(429); $errors[]='عدد محاولات الرمز تجاوز الحد في هذه الجلسة.'; }
    else {
        $access=input('access_code');
        $correct=trim((string)file_get_contents($root.'/setup-access.key'));
        if (strlen($correct)<32 || !hash_equals($correct,$access)) {
            $_SESSION['setup_attempts']=(int)($_SESSION['setup_attempts']??0)+1;
            http_response_code(403); $errors[]='رمز التثبيت غير صحيح.';
        } else {
            $host=input('db_host'); $db=input('db_database'); $user=input('db_username');
            $password=(string)($_POST['db_password']??''); $port=(int)input('db_port');
            $name=input('admin_name'); $email=input('admin_email');
            $adminPassword=(string)($_POST['admin_password']??'');
            if (!preg_match('/^[a-zA-Z0-9.\-_]{1,120}$/',$host) ||
                !preg_match('/^[a-zA-Z0-9_]{1,64}$/',$db) ||
                !preg_match('/^[a-zA-Z0-9_.$-]{1,64}$/',$user) ||
                $port<1 || $port>65535 || strlen($password)>300 ||
                mb_strlen($name)<2 || mb_strlen($name)>120 ||
                !filter_var($email,FILTER_VALIDATE_EMAIL) ||
                strlen($adminPassword)<14 || strlen($adminPassword)>200) {
                http_response_code(422); $errors[]='راجع اسم القاعدة والمستخدم وكلمة مرور المدير (14 حرفًا على الأقل).';
            } else {
                // Lock covers all DB writes and .env generation so only one installer may proceed.
                $mutex=@fopen($private.'/setup.mutex','c');
                if (!$mutex || !flock($mutex,LOCK_EX|LOCK_NB)) {
                    http_response_code(409); $errors[]='هناك عملية تثبيت أخرى تعمل.';
                } else {
                    try {
                        if (is_file($lock) || is_file($root.'/.env'))
                            throw new RuntimeException('Setup already initialized');
                        $pdo=new PDO("mysql:host=$host;port=$port;dbname=$db;charset=utf8mb4",$user,$password,[
                            PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION, PDO::ATTR_TIMEOUT=>6,
                        ]);
                        $pdo->query('SELECT 1'); unset($pdo);
                        $text=(string)file_get_contents($root.'/.env.example');
                        $values=[
                            'APP_NAME'=>'School PDF', 'APP_ENV'=>'production', 'APP_DEBUG'=>'false',
                            'APP_KEY'=>'base64:'.base64_encode(random_bytes(32)),
                            'APP_URL'=>'https://sclpdf.50sols.com',
                            'SCHOOLPDF_BASE_URL'=>'https://sclpdf.50sols.com',
                            'DB_CONNECTION'=>'mysql','DB_HOST'=>$host,'DB_PORT'=>(string)$port,
                            'DB_DATABASE'=>$db,'DB_USERNAME'=>$user,'DB_PASSWORD'=>$password,
                            'SESSION_DRIVER'=>'file','CACHE_STORE'=>'file',
                            'QUEUE_CONNECTION'=>'database','MAIL_MAILER'=>'log',
                            'SCHOOLPDF_ALLOW_ADS'=>'false','SCHOOLPDF_ADS_POLICY_APPROVED'=>'false',
                            'SCHOOLPDF_FIREBASE_PROJECT_ID'=>'schoolpdf-50sols',
                        ];
                        foreach ($values as $k=>$v) $text=setEnv($text,$k,$v);
                        $temporary=$root.'/.env.setup-'.bin2hex(random_bytes(8));
                        if (file_put_contents($temporary,$text,LOCK_EX)===false)
                            throw new RuntimeException('Cannot write environment configuration');
                        chmod($temporary,0600);
                        if (!rename($temporary,$root.'/.env'))
                            throw new RuntimeException('Cannot finalize environment configuration');
                        require $root.'/vendor/autoload.php';
                        $app=require $root.'/bootstrap/app.php';
                        $kernel=$app->make(\Illuminate\Contracts\Console\Kernel::class);
                        $kernel->bootstrap();
                        if ($kernel->call('migrate',['--force'=>true])!==0)
                            throw new RuntimeException('Migration failed');
                        \App\Models\User::updateOrCreate(['email'=>$email],[
                            'name'=>$name, 'password'=>$adminPassword,
                            'role'=>'super_admin','is_active'=>true,
                        ]);
                        // The database may already have been modified. Never attempt blind rollback.
                        $record=json_encode(['project'=>'School PDF','version'=>'1.1.2',
                            'installed_at'=>gmdate('c')],JSON_THROW_ON_ERROR);
                        if (file_put_contents($lock,$record."\n",LOCK_EX)===false)
                            throw new RuntimeException('Cannot lock installer');
                        chmod($lock,0640);
                        @unlink($root.'/setup-access.key');
                        session_regenerate_id(true);
                        $installed=true;
                    } catch (Throwable $exception) {
                        // Preserve DB and .env on failure for safe investigation; never auto-rollback data.
                        error_log('SchoolPDF installer incomplete: '.get_class($exception));
                        // Only the isolated CI installer smoke receives extra SQL diagnostics.
                        // Never expose database errors or credentials to a web visitor.
                        if (getenv('SCHOOLPDF_CI_INSTALL_SMOKE') === '1') {
                            error_log('SchoolPDF CI smoke SQL detail: '.substr($exception->getMessage(),0,600));
                        }
                        http_response_code(500);
                        $errors[]='تعذّر إكمال التثبيت. قد تكون قاعدة البيانات أو .env تغيرتا؛ لا تحذف البيانات. راجع سجلات الاستضافة وخطة الاستعادة قبل إعادة المحاولة.';
                    } finally {
                        flock($mutex,LOCK_UN); fclose($mutex);
                    }
                }
            }
        }
    }
}
function esc(string $s):string {return htmlspecialchars($s,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8');}
?><!doctype html>
<html lang="ar" dir="rtl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>School PDF — تثبيت الخادم</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#f2f6fc;font-family:system-ui,Tahoma,Arial,sans-serif;color:#16294b}
main{max-width:760px;margin:35px auto;background:#fff;border-radius:24px;padding:30px;box-shadow:0 16px 45px #19396818}
h1{font-size:24px;color:#245fe6;margin:0 0 8px}.sub{color:#62738a;margin-bottom:24px}
.steps{display:flex;gap:8px;flex-wrap:wrap;margin:18px 0}.step{background:#edf3ff;border-radius:10px;padding:9px 14px;color:#245fe6}
.panel{display:none}.panel.active{display:block}label{display:block;font-weight:600;margin:15px 0 6px}
input{width:100%;border:1px solid #bac9df;padding:12px 14px;border-radius:12px;font-size:15px}
button{border:0;border-radius:12px;padding:12px 20px;background:#2563eb;color:white;font-weight:650;cursor:pointer;margin:15px 0 0 8px}
button[disabled]{opacity:.45;cursor:not-allowed}.secondary{background:#dfe9fa;color:#193b7c}
.ok{color:#167747}.no{color:#ad2745}.row{padding:10px 0;border-bottom:1px solid #e9eef6;display:flex;gap:10px;align-items:center}
.alert{padding:14px;border-radius:12px;background:#fff0f0;color:#9a2546;margin:10px 0}.good{padding:14px;border-radius:12px;background:#e9f9ef;color:#116d40}
small{color:#5d718e}.cols{display:grid;grid-template-columns:1fr 1fr;gap:12px}@media(max-width:550px){main{margin:0;border-radius:0;padding:18px}.cols{grid-template-columns:1fr}}
</style></head><body><main>
<h1>📄 School PDF — إعداد Laravel</h1><div class="sub">sclpdf.50sols.com • Setup v1.1.2 • تثبيت بدون Terminal على الاستضافة</div>
<div class="steps"><span class="step">1 — فحص الاستضافة</span><span class="step">2 — البيانات</span><span class="step">3 — التأكيد والتشغيل</span></div>
<?php foreach ($errors as $error): ?><p class="alert"><?=esc($error)?></p><?php endforeach; ?>
<?php if ($installed): ?>
<div class="good"><h2>تم التثبيت وقفل المعالج بنجاح</h2><p>تم إنشاء قاعدة البيانات التشغيلية وحساب المدير.</p><a href="/admin/login">الدخول إلى لوحة الإدارة</a></div>
<?php else: ?>
<form method="post" autocomplete="off" id="installer"><input type="hidden" name="csrf" value="<?=esc((string)($_SESSION['schoolpdf_setup_csrf']??''))?>">
<section class="panel active" id="p1"><h2>فحص جاهزية الاستضافة</h2>
<?php foreach ($checks as $check): ?>
<div class="row"><strong class="<?= $check['ok']?'ok':'no' ?>"><?= $check['ok']?'✓':'✕' ?></strong>
<div><strong><?=esc($check['name'])?></strong><?php if (!$check['ok']): ?><div><small><?=esc($check['help'])?></small></div><?php endif; ?></div></div>
<?php endforeach; ?>
<p><small>أنشئ قاعدة MySQL/MariaDB ومستخدمًا من cPanel، واضبط Document Root على مجلد <code>public</code>. عند عدم توفر Cron، يمكن معالجة المهام من لوحة الإدارة، لكن الإرسال التلقائي لن يكون مضمونًا.</small></p>
<button type="button" data-next="p2" <?=$ready?'':'disabled'?>>التالي ← بيانات التثبيت</button></section>
<section class="panel" id="p2"><h2>قاعدة البيانات والمدير</h2>
<label>رمز التثبيت الخاص</label><input type="password" name="access_code" required minlength="32" autocomplete="off">
<div class="cols"><div><label>DB Host</label><input name="db_host" value="localhost" required></div><div><label>DB Port</label><input name="db_port" type="number" value="3306" min="1" max="65535" required></div></div>
<div class="cols"><div><label>اسم قاعدة البيانات</label><input name="db_database" required></div><div><label>مستخدم قاعدة البيانات</label><input name="db_username" required></div></div>
<label>كلمة مرور قاعدة البيانات</label><input name="db_password" type="password" autocomplete="new-password">
<label>اسم Super Admin</label><input name="admin_name" required minlength="2" maxlength="120">
<label>بريد Super Admin</label><input name="admin_email" type="email" required>
<label>كلمة مرور Super Admin قوية (14 حرفًا أو أكثر)</label><input name="admin_password" type="password" required minlength="14" autocomplete="new-password">
<button type="button" class="secondary" data-back="p1">رجوع</button><button type="button" data-next="p3">التالي ← مراجعة</button></section>
<section class="panel" id="p3"><h2>التأكيد النهائي</h2>
<p>سوف يختبر المعالج الاتصال بالقاعدة، ثم ينشئ <code>.env</code> وAPP_KEY، وينفّذ Migrations، وينشئ Super Admin، ويقفل التثبيت نهائيًا.</p>
<p><strong>الإشعارات:</strong> يعمل تكامل Firebase عند إضافة Service Account بأمان خارج public. إعدادات الإعلانات معطلة حتى استكمال موافقات وسياسات المتاجر. تجهيز Cron قد يحتاج إجراء داخل cPanel.</p>
<p><strong>تنبيه:</strong> إذا فشلت Migration بعد بدء الكتابة، لا تفترض أن قاعدة البيانات يمكن استعادتها تلقائيًا؛ راجع السجل وخطة الاستعادة.</p>
<button type="button" class="secondary" data-back="p2">رجوع</button><button type="submit" id="submit-install">Finish — تثبيت النظام</button></section>
</form>
<script>
(()=>{const panels=[...document.querySelectorAll('.panel')];const form=document.getElementById('installer');
function show(id){panels.forEach(p=>p.classList.toggle('active',p.id===id));window.scrollTo(0,0);}
document.querySelectorAll('[data-next]').forEach(btn=>btn.addEventListener('click',()=>{
  if(btn.dataset.next==='p3'){
    const inputs=[...document.querySelectorAll('#p2 input')];
    for(const input of inputs){if(!input.checkValidity()){input.reportValidity();return;}}
  }show(btn.dataset.next);
}));
document.querySelectorAll('[data-back]').forEach(btn=>btn.addEventListener('click',()=>show(btn.dataset.back)));
form.addEventListener('submit',()=>{document.getElementById('submit-install').disabled=true;});
})();
</script>
<?php endif; ?>
</main></body></html>
