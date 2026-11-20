<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="theme-color" content="#084699">
<meta name="description" content="School PDF تطبيق لتحويل صور الأوراق والواجبات إلى ملفات PDF بجودة عالية، مع تصحيح المنظور وترتيب الصفحات والمشاركة.">
<title>School PDF | صوّر أوراقك، جهّز ملفك، وشارك</title>
<link rel="icon" href="{{ asset('brand-icon.png') }}">
<style>
:root{font-family:Tahoma,'Segoe UI',Arial,sans-serif;color:#102b61;background:#f8fbff;scroll-behavior:smooth}
*{box-sizing:border-box}body{margin:0;overflow-x:hidden}a{color:inherit;text-decoration:none}button{font:inherit}a:focus-visible,button:focus-visible{outline:3px solid #ffc85e;outline-offset:4px}
.wrap{max-width:1390px;margin:auto;padding-inline:28px}
.site-nav{height:66px;background:linear-gradient(105deg,#0755bd,#06275e);color:#fff;position:relative;z-index:5;box-shadow:0 5px 20px #00235830}
.nav-inner{height:100%;display:flex;align-items:center;gap:48px;justify-content:space-between}.brand{display:flex;align-items:center;gap:12px;white-space:nowrap}.brand img{width:48px;height:48px;border-radius:13px;box-shadow:0 4px 14px #031b5170}.brand strong{font-size:25px;letter-spacing:-.8px}.brand strong span{color:#56ceff}.brand small{display:block;font-size:12px;color:#dcecff;margin-top:2px;text-align:left;direction:ltr}.navlinks{display:flex;align-items:center;gap:31px;font-size:14px;font-weight:700}.navlinks a{padding:23px 0;white-space:nowrap;border-bottom:3px solid transparent}.navlinks a:hover,.navlinks a:first-child{border-color:white}.languages{display:flex;border:2px solid #2c74cf;border-radius:50px;padding:3px;direction:ltr;gap:2px}.languages button{padding:5px 11px;font-size:12px;font-weight:700;color:#fff;background:transparent;border:0;border-radius:30px;cursor:pointer}.languages button.active{border-radius:30px;background:#fff;color:#1769d8}
.hero{position:relative;min-height:370px;color:#fff;background:radial-gradient(circle at 19% 25%,#56a9f7 0%,#236bc2 35%,#1354ae 58%,#0a3b8f 100%);overflow:hidden}
.hero:before{content:'PDF';position:absolute;font-size:120px;font-weight:900;color:#ffffff10;left:44%;top:70px;transform:rotate(-22deg);border:8px solid #ffffff12;border-radius:26px;padding:10px 28px}
.hero:after{content:'✎   ▱   ✧';position:absolute;font-size:95px;letter-spacing:50px;color:#ffffff18;inset:45px auto auto -45px;pointer-events:none}
.hero-inner{min-height:370px;display:grid;grid-template-columns:1fr 1fr;align-items:center;gap:35px;position:relative;z-index:1}
.hero-copy{padding:34px 0 24px;text-align:right}.soon-pill{display:inline-flex;background:#ffcb64;color:#173b75;padding:8px 15px;border-radius:11px;font-size:13px;font-weight:800;box-shadow:0 5px 14px #57360022}.hero-title{font-size:clamp(46px,5vw,77px);line-height:1.08;margin:14px 0 12px;direction:ltr;text-align:right;letter-spacing:-2.5px;color:white}.hero-title span{color:#51c9ff}.hero-desc{font-size:clamp(16px,1.5vw,21px);line-height:1.65;max-width:590px;margin:0 0 16px}.trust{display:flex;flex-wrap:wrap;gap:12px 25px;font-size:12px;font-weight:700;margin-bottom:25px}.trust span:before{content:'✓';display:inline-grid;place-items:center;width:20px;height:20px;background:#82e4ac;color:#096747;border-radius:50%;margin-left:5px}
.store-row{display:flex;align-items:center;gap:16px;flex-wrap:wrap}.store{min-width:187px;height:68px;border:1px solid #ffffff18;border-radius:16px;background:linear-gradient(#9ba8ba,#78889e);box-shadow:0 10px 18px #10325e4a;display:flex;align-items:center;justify-content:center;gap:12px;filter:saturate(.55);opacity:.76;color:#fff;cursor:not-allowed;direction:ltr;user-select:none}.store svg{width:35px;height:35px;fill:white}.store strong{display:block;font-size:18px;font-weight:500}.store small{display:block;font-size:12px;text-align:center}.store span{line-height:1.25}
.hero-art{height:370px;display:flex;align-items:flex-end;justify-content:center;position:relative;direction:ltr}.hero-art:before{content:'';position:absolute;bottom:0;left:6%;width:90%;height:23px;background:#0930613b;filter:blur(15px);border-radius:50%}
.phone{border:6px solid #101725;border-radius:34px;background:#111827;padding:4px;box-shadow:14px 13px 25px #001c4c69,inset 0 0 0 2px #9db1cf;position:relative;overflow:hidden}.phone:before{content:'';position:absolute;top:8px;left:50%;transform:translateX(-50%);width:35%;height:14px;background:#111827;border-radius:0 0 12px 12px;z-index:3}.phone.screen-splash{width:184px;height:345px;transform:rotate(-4deg) translate(26px,14px);z-index:2}.phone.screen-home{width:183px;height:323px;transform:rotate(4deg) translate(-17px,5px);z-index:1}.phone-screen{width:100%;height:100%;border-radius:25px;overflow:hidden;background:#f9fbff;color:#143268}.splash-screen{background:linear-gradient(152deg,#00a3ff,#0757c8 64%,#042c79);display:flex;align-items:center;justify-content:center;flex-direction:column;color:white;text-align:center;gap:11px}.splash-screen img{width:82px;height:82px;border-radius:20px;box-shadow:0 12px 22px #003e86aa}.splash-screen b{font-size:23px}.splash-screen small{font-size:11px;line-height:1.7}.app-head{background:#075bc1;color:white;height:32px;text-align:center;padding:14px 4px 4px;font-size:11px;font-weight:bold}.app-welcome{padding:17px 10px 9px;font-size:12px;text-align:right;font-weight:800}.app-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px;padding:0 9px}.app-tile{height:62px;border-radius:10px;background:#eff4fe;text-align:center;padding:7px 2px;font-size:10px;font-weight:800}.app-tile:nth-child(1){background:#dbf0ff}.app-tile:nth-child(2){background:#eee5ff}.app-tile:nth-child(3){background:#e8f9ef}.app-tile:nth-child(4){background:#ffecef}.app-tile i{display:block;font-size:23px;font-style:normal;margin-bottom:1px}
.section{padding:24px 0}.section-heading{font-size:24px;font-weight:900;color:#08285d;text-align:right;margin:0 0 20px}.section-heading:after{content:'';display:block;width:55px;height:4px;background:#1678ed;border-radius:4px;margin-top:6px}.features{display:grid;grid-template-columns:repeat(7,minmax(0,1fr));gap:13px}.feature{height:105px;background:#fff;border:1px solid #e3ebf8;box-shadow:0 8px 22px #1e47721c;border-radius:16px;text-align:center;display:flex;flex-direction:column;justify-content:center;align-items:center;gap:9px;padding:9px}.feature .glyph{font-size:30px;line-height:1}.feature b{font-size:12px;line-height:1.55}.feature:nth-child(2n) .glyph{color:#1479f7}.feature:nth-child(3n) .glyph{color:#8154f1}
.screens-section{padding:12px 0}.screens-layout{display:grid;grid-template-columns:190px 1fr;gap:24px;align-items:start}.section-sub{font-size:12px;color:#687b9b;line-height:1.8}.shots{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:23px;direction:rtl}.shot{height:180px;background:white;border-radius:14px;overflow:hidden;box-shadow:0 6px 17px #153d8025;border:1px solid #e0e8f5}.shot-head{background:#0755bb;color:white;height:26px;padding:6px 8px;font-size:10px;font-weight:bold;text-align:center}.shot-body{height:154px;background:#fbfdff;padding:10px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:7px;font-size:10px;color:#234572}.paper{width:70px;height:99px;border:1px solid #c6d1df;background:repeating-linear-gradient(#fff 0 9px,#d5dce7 10px,#fff 11px);box-shadow:0 2px 6px #002b6b15;transform:rotate(-3deg)}.crop-paper{border:3px solid #1e8dfb;position:relative;width:100px;height:112px;transform:rotate(3deg);background:repeating-linear-gradient(#fff 0 12px,#cdd7e7 13px,#fff 14px)}.crop-paper:before,.crop-paper:after{content:'●';font-size:12px;color:#197bfa;position:absolute;top:-10px;left:-9px}.crop-paper:after{top:auto;bottom:-10px;left:auto;right:-8px}.paper-row{display:flex;direction:ltr;gap:9px}.paper-row .paper{width:43px;height:64px}.shot:first-child .shot-body{background-image:url("{{ asset('landing/worksheet-scene.svg') }}")!important;background-size:cover!important;background-position:center!important}.shot:first-child .paper{opacity:.12}.shot-actions{background:#eaf2ff;width:100%;padding:6px 4px;border-radius:8px;text-align:center;color:#1768d0;font-size:10px}.done{font-size:39px;color:#17bc6b;font-weight:bold}.step-band{background:#eef5ff;border-radius:28px;padding:17px 25px;display:grid;grid-template-columns:repeat(3,1fr);gap:24px}.step{background:white;border-radius:100px;padding:12px 15px;display:flex;align-items:center;gap:13px;box-shadow:0 4px 15px #1661b312}.step-num{width:51px;height:51px;flex:none;display:grid;place-items:center;background:#e1f1ff;color:#1684ff;border-radius:50%;font-size:28px;font-weight:900}.step:nth-child(3) .step-num{background:#d3f6e4;color:#119558}.step strong{font-size:14px;display:block}.step small{font-size:11px;color:#667c9b;line-height:1.55}
.launch{margin-top:20px;background:linear-gradient(110deg,#247df2,#0646aa 64%,#063478);color:white;overflow:hidden}.launch-inner{min-height:125px;display:flex;align-items:center;justify-content:center;gap:55px}.launch h2{font-size:24px;margin:0 0 7px}.launch p{font-size:13px;margin:0;line-height:1.6}.launch a{display:inline-flex;background:white;color:#0c5dc8;border-radius:50px;padding:15px 22px;font-size:13px;font-weight:bold;white-space:nowrap}
.site-footer{background:#06295c;color:#dae8ff;padding:25px 0;font-size:12px}.footer-inner{display:flex;align-items:center;justify-content:space-between;gap:20px;flex-wrap:wrap}.footer-links{display:flex;gap:20px;flex-wrap:wrap}.footer-links a:hover{text-decoration:underline}
@media(max-width:1050px){.features{grid-template-columns:repeat(4,1fr)}.navlinks{gap:13px}.screens-layout{grid-template-columns:1fr}.shots{gap:12px}.hero-title{font-size:55px}}
@media(max-width:700px){.wrap{padding-inline:18px}.site-nav{height:auto;min-height:65px}.nav-inner{padding-block:10px;gap:12px;flex-wrap:wrap}.brand img{width:38px;height:38px}.brand strong{font-size:20px}.navlinks{order:3;overflow:auto;width:100%;gap:20px;font-size:12px}.navlinks a{padding:10px 0}.hero-inner{grid-template-columns:1fr;gap:0}.hero-copy{padding-top:28px;text-align:center}.hero-title{text-align:center;font-size:49px}.hero-desc{margin-inline:auto}.trust,.store-row{justify-content:center}.hero-art{height:310px}.phone.screen-splash{height:296px;width:162px}.phone.screen-home{height:277px;width:160px}.features{grid-template-columns:repeat(2,1fr)}.shots{display:flex;overflow-x:auto;scroll-snap-type:x mandatory;padding:4px 2px 16px}.shot{min-width:165px;scroll-snap-align:center}.step-band{grid-template-columns:1fr;gap:10px}.launch-inner{padding-block:28px;flex-direction:column;gap:18px;text-align:center}.footer-inner{justify-content:center;text-align:center}.footer-links{justify-content:center}}
@media(prefers-reduced-motion:reduce){:root{scroll-behavior:auto}}

/* Reference-aligned desktop art direction, Nov 2026. Adjustments are scoped to the public landing only. */
:root{scroll-padding-top:70px}
.nav-inner{direction:ltr}.brand{direction:ltr}.navlinks{direction:rtl}.languages{flex:none}
.hero{isolation:isolate;background:radial-gradient(ellipse at 27% 36%,#66a4e5 0%,#377ac4 33%,#1553aa 69%,#0a398d 100%)}
.hero::after{content:"";position:absolute;inset:0;background-image:url("{{ asset('landing/hero-ornaments.svg') }}");background-position:center center;background-size:100% 100%;pointer-events:none;opacity:.94}
.hero::before{content:"";position:absolute;inset:auto 0 0;background:linear-gradient(180deg,#ffffff00,#ffffff40 68%,#edf5ffb0);height:58px;border:0;border-radius:0;transform:none;font-size:0}
.hero-brand{display:flex;align-items:center;justify-content:center;gap:20px;direction:rtl;margin:5px auto 9px}
.hero-brand>img{width:80px;height:80px;object-fit:contain;border-radius:20px;filter:drop-shadow(0 10px 15px #00428390)}
.hero-brand .hero-title{margin:0;direction:ltr;text-align:center;white-space:nowrap}
.hero-copy{text-align:center}.hero-desc{margin-inline:auto;text-align:center}.trust,.store-row{justify-content:center}
.soon-pill{border-radius:12px;box-shadow:0 8px 24px #0e367b38}
.phone{border-color:#172032;border-width:5px;box-shadow:12px 10px 16px #092b5888,inset 0 0 0 2px #b9c7d7}
.hero-art::after{content:"";position:absolute;bottom:4px;left:0;right:0;height:16px;background:linear-gradient(90deg,transparent,#e0eeffbf 25%,#f7f9ffb8 65%,transparent);filter:blur(5px);z-index:0}
.hero-art .phone{z-index:2}
.feature .glyph{display:block;height:32px;color:#1379f5}
.feature .glyph svg{display:block;width:32px;height:32px;stroke:currentColor;stroke-width:2.5;stroke-linecap:round;stroke-linejoin:round;fill:none}
.feature:nth-child(1) .glyph{color:#247aff}.feature:nth-child(2) .glyph{color:#1685fb}.feature:nth-child(3) .glyph{color:#7d42f3}
.feature:nth-child(4) .glyph{color:#17b976}.feature:nth-child(5) .glyph{color:#8143ed}.feature:nth-child(6) .glyph{color:#197af0}.feature:nth-child(7) .glyph{color:#ffaa13}
.shots{position:relative}.shot{transition:box-shadow .15s,transform .15s}.shot:hover{box-shadow:0 10px 22px #153d8035;transform:translateY(-2px)}
.shot .shot-head{border-radius:8px 8px 0 0}.shot .shot-actions{font-weight:700}
#how .section-heading{align-self:end}#how .section-sub{align-self:start;margin-top:0}
.step-band{background:#edf4fe}.step-num{box-shadow:0 0 0 5px #fff}
@media(min-width:1101px){
.site-nav{height:63px}.nav-inner{gap:22px}.brand img{width:50px;height:50px}.brand strong{font-size:23px}
.navlinks{gap:30px}.navlinks a{padding:21px 0}
.hero,.hero-inner{min-height:338px;height:338px}
.hero-inner{grid-template-columns:1fr 1fr;gap:20px}
.hero-copy{padding:10px 0 10px}.hero-title{font-size:64px;line-height:1.04;letter-spacing:-2px}
.hero-brand{margin:0 auto 8px;gap:16px}.hero-brand>img{width:81px;height:81px}
.hero-desc{font-size:19px;line-height:1.48;max-width:545px;margin-bottom:13px}
.soon-pill{font-size:13px;padding:7px 14px}
.trust{gap:10px 24px;font-size:12px;margin-bottom:18px}
.store{height:69px;min-width:222px;border-radius:17px}.store-row{gap:22px}
.hero-art{height:338px}
.phone.screen-splash{height:339px;width:184px;transform:rotate(-3deg) translate(27px,12px)}
.phone.screen-home{height:324px;width:182px;transform:rotate(4deg) translate(-16px,4px)}
#features.section{padding:0 0 13px}
#features .section-heading{font-size:22px;line-height:1.2;margin:0 0 10px;padding-top:0}
#features .feature{height:96px;gap:7px;border-radius:15px}
#features .feature b{font-size:12px}
.screens-section{padding:11px 0 7px}
.screens-layout{grid-template-columns:195px minmax(0,1fr);gap:22px}
.screens-layout .section-heading{font-size:22px;margin:0 0 4px}
.screens-layout .section-sub{margin:0;font-size:12px}
.shots{gap:24px}.shot{height:173px}.shot-body{height:147px}
#how.section{padding:11px 0 15px}
#how>.wrap{display:grid;grid-template-columns:195px minmax(0,1fr);grid-template-rows:auto auto;column-gap:22px;align-items:center}
#how .section-heading{grid-column:1;grid-row:1;font-size:22px;margin:0 0 5px}
#how .section-sub{grid-column:1;grid-row:2;font-size:12px;margin:0}
#how .step-band{grid-column:2;grid-row:1 / span 2;min-height:84px;align-self:center}
.step-band{padding:12px 17px;gap:14px;border-radius:25px}
.step{padding:7px 12px;min-width:0;gap:10px}
.step-num{width:50px;height:50px;font-size:26px}
.step strong{font-size:14px}.step small{font-size:11px}
.launch{margin-top:0}.launch-inner{min-height:108px}
.launch h2{font-size:23px}
}
@media(max-width:1100px){
.nav-inner{direction:ltr}.navlinks{gap:14px}
.hero-brand>img{width:58px;height:58px}.hero-brand{gap:10px}
.hero-brand .hero-title{font-size:clamp(34px,5vw,58px)}
}
@media(max-width:700px){
.nav-inner{justify-content:space-between}.navlinks{direction:rtl}
.hero,.hero-inner{min-height:0}
.hero::after{background-size:auto 100%;background-position:left center;opacity:.4}
.hero-copy{padding:25px 0 12px}.hero-brand .hero-title{font-size:clamp(33px,8vw,48px)}
.hero-brand>img{width:55px;height:55px}
.hero-desc{line-height:1.65}.trust{gap:12px 14px}.store{min-width:145px;height:60px}.store strong{font-size:14px}.store svg{width:29px;height:29px}.store-row{gap:9px}
#how>.wrap{display:block}.step-band{grid-template-columns:1fr}
.feature .glyph svg{width:30px;height:30px}
}
</style>
</head>
<body>
<header class="site-nav"><div class="wrap nav-inner">
<a class="brand" href="{{ url('/') }}" aria-label="School PDF الرئيسية"><img src="{{ asset('brand-icon.png') }}" alt=""><span><strong>School <span>PDF</span></strong><small>sclpdf.50sols.com</small></span></a>
<nav class="navlinks" aria-label="القائمة الرئيسية"><a href="#home" data-i18n-ar="الرئيسية" data-i18n-en="Home">الرئيسية</a><a href="#features" data-i18n-ar="المميزات" data-i18n-en="Features">المميزات</a><a href="#screens" data-i18n-ar="صور التطبيق" data-i18n-en="App Screens">صور التطبيق</a><a href="#how" data-i18n-ar="طريقة الاستخدام" data-i18n-en="How It Works">طريقة الاستخدام</a><a href="{{ url('/support') }}" data-i18n-ar="الأسئلة الشائعة" data-i18n-en="FAQs">الأسئلة الشائعة</a><a href="mailto:{{ config('schoolpdf.support_email') }}" data-i18n-ar="تواصل معنا" data-i18n-en="Contact Us">تواصل معنا</a></nav>
<div class="languages" aria-label="اختيار اللغة"><button type="button" data-lang="en" aria-pressed="false">EN</button><button type="button" data-lang="ar" class="active" aria-pressed="true">AR</button></div>
</div></header>
<main id="landing-main">
<section id="home" class="hero"><div class="wrap hero-inner">
<div class="hero-copy"><span class="soon-pill" data-i18n-ar="قريبًا إطلاق التطبيق الرسمي" data-i18n-en="Official App Launching Soon">قريبًا إطلاق التطبيق الرسمي</span><div class="hero-brand"><img src="{{ asset('brand-icon.png') }}" alt="" width="80" height="80"><h1 class="hero-title">School <span>PDF</span></h1></div>
<p class="hero-desc" data-i18n-ar="تطبيق ذكي لتحويل صور الأوراق والملفات إلى PDF بجودة عالية، مصمم خصيصًا للطلاب في جميع المراحل." data-i18n-en="A smart way to turn photos of worksheets and documents into quality PDF files, made for students of every level.">تطبيق ذكي لتحويل صور الأوراق والملفات إلى PDF بجودة عالية، مصمم خصيصًا للطلاب في جميع المراحل.</p>
<div class="trust"><span data-i18n-ar="سهل الاستخدام" data-i18n-en="Easy to use">سهل الاستخدام</span><span data-i18n-ar="جودة عالية" data-i18n-en="High quality">جودة عالية</span><span data-i18n-ar="أدوات قوية" data-i18n-en="Powerful tools">أدوات قوية</span><span data-i18n-ar="مناسب للمدرسة والجامعة" data-i18n-en="Made for school and university">مناسب للمدرسة والجامعة</span></div>
<div class="store-row" aria-label="روابط التحميل غير متاحة قبل الإطلاق">
<div class="store" aria-disabled="true" title="Google Play — قريبًا"><svg viewBox="0 0 32 32" aria-hidden="true"><path d="M4 2v28l15-14L4 2zm2-1 18 10-5 4L6 1zm18 20L6 31l13-14 5 4zm2-9 5 3c1 .6 1 1.4 0 2l-5 3-5-4 5-4z"/></svg><span><strong>Google Play</strong><small>Coming Soon</small></span></div>
<div class="store" aria-disabled="true" title="App Store — قريبًا"><svg viewBox="0 0 32 32" aria-hidden="true"><path d="M22.8 16.2c0-3.6 3-5.3 3.1-5.4-1.7-2.5-4.3-2.8-5.2-2.8-2.2-.2-4.4 1.3-5.5 1.3-1.2 0-3-1.2-4.9-1.1-2.5 0-4.8 1.5-6 3.6-2.6 4.3-.7 10.6 1.8 14.1 1.3 1.7 2.7 3.6 4.6 3.5 1.9-.1 2.6-1.1 4.9-1.1 2.2 0 3.1 1.1 4.9 1.1 1.8 0 2.9-1.6 4.2-3.3-3.9-1.5-4.2-4.3-4.2-4.3zM19.3 5.8c1-1.3 1.7-3 1.5-4.8-1.5.1-3.2 1-4.3 2.3-1 1.2-1.8 2.9-1.6 4.5 1.7.1 3.3-.8 4.4-2z"/></svg><span><small>Download on the</small><strong>App Store</strong><small>Coming Soon</small></span></div>
</div></div>
<div class="hero-art" aria-label="معاينة توضيحية لتطبيق School PDF">
<div class="phone screen-splash"><div class="phone-screen splash-screen"><img src="{{ asset('brand-icon.png') }}" alt=""><b>School PDF</b><small>حوّل صورك إلى PDF<br>بجودة عالية</small></div></div>
<div class="phone screen-home"><div class="phone-screen" dir="rtl"><div class="app-head">School PDF</div><div class="app-welcome">👋 مرحبًا بك</div><div class="app-grid"><div class="app-tile"><i>📷</i>تصوير وتحويل</div><div class="app-tile"><i>▧</i>اختيار من المعرض</div><div class="app-tile"><i>📚</i>دمج ملفات</div><div class="app-tile"><i>▤</i>ترتيب الصفحات</div><div class="app-tile"><i>📁</i>حفظ الملفات</div><div class="app-tile"><i>🔗</i>مشاركة PDF</div></div></div></div>
</div></div></section>
<section id="features" class="section"><div class="wrap"><h2 class="section-heading" data-i18n-ar="أهم المميزات" data-i18n-en="Key Features">أهم المميزات</h2><div class="features">
<div class="feature"><span class="glyph" aria-hidden="true"><svg viewBox="0 0 24 24" focusable="false"><rect x="3" y="7" width="18" height="14" rx="3"/><path d="M7 7l2-3h6l2 3"/><circle cx="12" cy="14" r="4"/></svg></span><b data-i18n-ar="تصوير ذكي" data-i18n-en="Smart scanning">تصوير ذكي<br data-i18n-ar="للأوراق" data-i18n-en="for papers">للأوراق</b></div><div class="feature"><span class="glyph" aria-hidden="true"><svg viewBox="0 0 24 24" focusable="false"><path d="M6 3h12l3 3v12l-3 3H6l-3-3V6z"/><path d="M9 2v4M15 2v4M9 22v-4M15 22v-4M2 9h4M2 15h4M22 9h-4M22 15h-4"/></svg></span><b data-i18n-ar="تصحيح منظور" data-i18n-en="Perspective">تصحيح منظور<br data-i18n-ar="الورقة تلقائيًا" data-i18n-en="correction">الورقة تلقائيًا</b></div><div class="feature"><span class="glyph" aria-hidden="true"><svg viewBox="0 0 24 24" focusable="false"><path d="M12 3 2 8l10 5 10-5-10-5Z"/><path d="m2 13 10 5 10-5M2 18l10 4 10-4"/></svg></span><b data-i18n-ar="دمج عدة صور" data-i18n-en="Combine photos">دمج عدة صور<br data-i18n-ar="في ملف واحد" data-i18n-en="into one PDF">في ملف واحد</b></div><div class="feature"><span class="glyph" aria-hidden="true"><svg viewBox="0 0 24 24" focusable="false"><path d="M8 3v17m0 0-4-4m4 4 4-4M16 21V4m0 0-4 4m4-4 4 4"/></svg></span><b data-i18n-ar="ترتيب الصفحات" data-i18n-en="Reorder pages">ترتيب الصفحات<br data-i18n-ar="بسهولة" data-i18n-en="with ease">بسهولة</b></div><div class="feature"><span class="glyph" aria-hidden="true"><svg viewBox="0 0 24 24" focusable="false"><path d="M7 2h9l4 4v16H7z"/><path d="M16 2v5h5M10 12h7M10 16h7"/></svg></span><b data-i18n-ar="ضغط حجم" data-i18n-en="Compress">ضغط حجم<br data-i18n-ar="ملف PDF" data-i18n-en="PDF file">ملف PDF</b></div><div class="feature"><span class="glyph" aria-hidden="true"><svg viewBox="0 0 24 24" focusable="false"><circle cx="18" cy="5" r="3"/><circle cx="5" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="m7.8 10.7 7.4-4.3M7.8 13.3l7.4 4.3"/></svg></span><b data-i18n-ar="مشاركة وحفظ" data-i18n-en="Save and share">مشاركة وحفظ<br data-i18n-ar="الملف" data-i18n-en="your file">الملف</b></div><div class="feature"><span class="glyph" aria-hidden="true"><svg viewBox="0 0 24 24" focusable="false"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 8-3 9h18c0-1-3-2-3-9M10 21h4"/></svg></span><b data-i18n-ar="إشعارات وتنبيهات" data-i18n-en="Useful alerts">إشعارات وتنبيهات<br data-i18n-ar="مفيدة" data-i18n-en="and reminders">مفيدة</b></div>
</div></div></section>
<section id="screens" class="screens-section"><div class="wrap screens-layout"><div><h2 class="section-heading" data-i18n-ar="صور من التطبيق" data-i18n-en="App Screens">صور من التطبيق</h2><p class="section-sub" data-i18n-ar="تعرّف على واجهة التطبيق وتجربة الاستخدام." data-i18n-en="Explore the app interface and workflow.">تعرّف على واجهة التطبيق وتجربة الاستخدام.</p></div>
<div class="shots" aria-label="نماذج توضيحية للشاشات وليست لقطات فعلية من التطبيق">
<div class="shot"><div class="shot-head">التصوير</div><div class="shot-body" style="background:#eee6dc"><div class="paper"></div><div style="width:35px;height:35px;background:white;border:6px solid #244b7a;border-radius:50%"></div></div></div>
<div class="shot"><div class="shot-head">تصحيح المنظور</div><div class="shot-body" style="background:#e6e5e3"><div class="crop-paper"></div><div class="shot-actions">تطبيق &nbsp; | &nbsp; إعادة</div></div></div>
<div class="shot"><div class="shot-head">معاينة الملف</div><div class="shot-body"><b>1 / 4</b><div class="paper"></div><div class="shot-actions">↶ &nbsp; ◀ &nbsp; ▶ &nbsp; ↷</div></div></div>
<div class="shot"><div class="shot-head" data-i18n-ar="ترتيب الصفحات" data-i18n-en="Reorder pages">ترتيب الصفحات</div><div class="shot-body"><b data-i18n-ar="ترتيب الصفحات" data-i18n-en="Reorder pages">ترتيب الصفحات</b><div class="paper-row"><div class="paper"></div><div class="paper"></div><div class="paper"></div></div><small>1 &nbsp;&nbsp;&nbsp;&nbsp; 2 &nbsp;&nbsp;&nbsp;&nbsp; 3</small></div></div>
<div class="shot"><div class="shot-head" data-i18n-ar="مشاركة وحفظ" data-i18n-en="Save and share">مشاركة وحفظ</div><div class="shot-body"><span class="done">✓</span><b>تم إنشاء ملف PDF بنجاح</b><div class="shot-actions">مشاركة الملف</div><div class="shot-actions">حفظ على الجهاز</div></div></div>
</div></div></section>
<section id="how" class="section"><div class="wrap"><h2 class="section-heading" data-i18n-ar="كيف يعمل التطبيق؟" data-i18n-en="How Does It Work?">كيف يعمل التطبيق؟</h2><p class="section-sub" data-i18n-ar="في 3 خطوات بسيطة فقط." data-i18n-en="In just three simple steps.">في 3 خطوات بسيطة فقط.</p><div class="step-band">
<div class="step"><span class="step-num">1</span><span><strong data-i18n-ar="التقط صورة" data-i18n-en="Capture a photo">التقط صورة</strong><small data-i18n-ar="للورقة أو اخترها من المعرض" data-i18n-en="Scan a page or choose from your gallery">للورقة أو اخترها من المعرض</small></span></div>
<div class="step"><span class="step-num">2</span><span><strong data-i18n-ar="عدّل ورتّب" data-i18n-en="Edit and arrange">عدّل ورتّب</strong><small data-i18n-ar="يمكنك تصحيح الصورة وترتيب الصفحات" data-i18n-en="Correct the image and reorder pages">يمكنك تصحيح الصورة وترتيب الصفحات</small></span></div>
<div class="step"><span class="step-num">3</span><span><strong data-i18n-ar="احفظ وشارك" data-i18n-en="Save and share">احفظ وشارك</strong><small data-i18n-ar="احصل على ملف PDF جاهز للمذاكرة أو الإرسال" data-i18n-en="Get a PDF ready to study or share">احصل على ملف PDF جاهز للمذاكرة أو الإرسال</small></span></div>
</div></div></section>
<section class="launch"><div class="wrap launch-inner"><div><h2>🔔 كن أول من يعرف بموعد الإطلاق</h2><p data-i18n-ar="قريبًا على Google Play وApp Store — تواصل معنا للاستفسارات عن موعد الإصدار." data-i18n-en="Coming soon to Google Play and App Store — contact us for launch updates.">قريبًا على Google Play وApp Store — تواصل معنا للاستفسارات عن موعد الإصدار.</p></div><a href="mailto:{{ config('schoolpdf.support_email') }}?subject=School%20PDF%20Launch">تواصل معنا ✉</a></div></section>
</main>
<footer class="site-footer"><div class="wrap footer-inner"><span>© {{ date('Y') }} School PDF · sclpdf.50sols.com</span><div class="footer-links"><a href="{{ url('/privacy') }}" data-i18n-ar="سياسة الخصوصية" data-i18n-en="Privacy Policy">سياسة الخصوصية</a><a href="{{ url('/terms') }}" data-i18n-ar="الشروط والأحكام" data-i18n-en="Terms">الشروط والأحكام</a><a href="{{ url('/support') }}" data-i18n-ar="الدعم" data-i18n-en="Support">الدعم</a><a href="{{ url('/data-deletion') }}" data-i18n-ar="حذف البيانات" data-i18n-en="Delete Data">حذف البيانات</a><a href="{{ url('/admin') }}" data-i18n-ar="لوحة الإدارة" data-i18n-en="Admin Dashboard">لوحة الإدارة</a></div></div></footer>
<script>
(function(){
const buttons=document.querySelectorAll('[data-lang]');
const translated=document.querySelectorAll('[data-i18n-ar][data-i18n-en]');
function setLanguage(lang){
 const english=lang==='en';
 document.documentElement.lang=lang;
 document.documentElement.dir=english?'ltr':'rtl';
 document.title=english?'School PDF | Scan, organize, share':'School PDF | صوّر أوراقك، جهّز ملفك، وشارك';
 translated.forEach(el=>{el.textContent=el.getAttribute(english?'data-i18n-en':'data-i18n-ar');});
 buttons.forEach(el=>{const active=el.dataset.lang===lang;el.classList.toggle('active',active);el.setAttribute('aria-pressed',active?'true':'false')});
}
 buttons.forEach(el=>el.addEventListener('click',()=>setLanguage(el.dataset.lang)));
})();
</script></body></html>