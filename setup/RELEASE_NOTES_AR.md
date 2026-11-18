# School PDF v1.1.2 — Setup source improvements

- تحسين معالج `/install` بتصميم RTL وثلاث خطوات وفحص تفصيلي لمتطلبات cPanel وHTTPS.
- طلب بيانات MySQL وSuper Admin وتوليد `.env` وAPP_KEY مع قفل متزامن وفحص قاعدة البيانات قبل التهيئة.
- منع إعادة التثبيت أو الكتابة فوق `.env` موجود، مع رسالة استعادة حذرة عند فشل Migrations.
- إضافة مدير حزم `setup/build_setup.py` يرفض خروج Release بدون lock وvendor وإثبات CI مطابق لـSHA والاختبارات المطلوبة.
- مراجعة ZIP manifest وSHA-256، واستبعاد الملفات الحساسة، ورفض الروابط الرمزية والملفات الخطرة.
- إضافة اختبارات بناء مستقلة ودليل استضافة cPanel داخل `setup/`.
- **لا إصدار إنتاج حتى اجتياز Composer + Fresh Install + Upgrade + Recovery وتفعيل نظام تحديثات ZIP الموقعة.**
