<x-shell title="School PDF — Delete data / حذف البيانات">
<div class="card" lang="ar">
<h1>حذف بيانات School PDF | Delete School PDF data</h1>
<p><strong>School PDF لا ينشئ حسابات مستخدمين للطلاب.</strong> إدخال الاسم والصف في التطبيق لا ينشئ حسابًا على خوادمنا. بيانات مدير لوحة التحكم منفصلة عن حسابات مستخدمي التطبيق.</p>
<h2>١. حذف سجل الجهاز من الخادم (اختياري للبالغين)</h2>
<p>افتح تطبيق School PDF، ثم <strong>Settings → Language &amp; privacy → Delete server device record</strong>. يرسل التطبيق طلب حذف سجله بمفتاح خاص محفوظ على نفس الجهاز. عند تعذر الاتصال، تبقى محاولة الحذف معلّقة لإعادة المحاولة عند التشغيل التالي. هذه العملية لا تحذف صورك أو ملفات PDF المحلية.</p>
<h2>٢. حذف ملفات PDF وبيانات الطالب من الهاتف</h2>
<p>من <strong>Settings → Language &amp; privacy → Delete local profile and PDFs</strong>، راجع رسالة التأكيد ثم أكّد المسح. يُحذف الملف الدراسي وملفات PDF التي أنشأها التطبيق داخل مجلده الخاص. لا يمكن للتطبيق حذف الصور الأصلية من معرض الهاتف أو أي ملفات سبق تصديرها إلى تطبيقات أو خدمات أخرى.</p>
<p class="muted">ميزة المسح الشامل للملفات المحلية تتطلب تثبيت إصدار التطبيق الذي يتضمنها؛ في الإصدارات الأقدم يمكن حذف ملفات PDF من سجل الملفات وحذف التطبيق بعد حفظ النسخ المطلوبة.</p>
<h2>٣. عند فقد الهاتف أو تعذر الوصول إلى التطبيق</h2>
<p>تواصل مع <a href="mailto:{{ config('schoolpdf.support_email') }}">{{ config('schoolpdf.support_email') }}</a> بعنوان «طلب حذف بيانات School PDF». لا نجمع بريدًا مرتبطًا بسجل التثبيت المجهول؛ لذلك قد يتعذر تحديد سجل جهاز بعينه من البريد وحده. لا ترسل مفتاح الجهاز السري أو صور الطلاب. سنوضح الخيارات المتاحة دون الادعاء بحذف سجل لم نستطع تحديده أو التحقق منه.</p>
<p>تظل السجلات غير النشطة مرشحة للحذف بعد 90 يومًا <strong>عند تشغيل مهمة التنظيف المجدولة على الخادم</strong>؛ ولا نعتمد هذا بدل آلية طلب الحذف.</p>
</div>
<div class="card en" lang="en">
<h2>How to delete your data</h2>
<p><strong>No student account is created.</strong> School PDF stores your profile, subjects, photos and PDFs on your device. There is no account password to delete.</p>
<p><strong>Delete the server device record:</strong> In the app, open Settings → Language &amp; privacy → Delete server device record. This removes an optional adult opt-in installation record using a device-held credential. If offline, the request is queued for retry on next launch. Local PDFs remain.</p>
<p><strong>Delete local profile and generated PDFs:</strong> Use Settings → Language &amp; privacy → Delete local profile and PDFs, then confirm. This does not remove original photos in your gallery or copies you previously exported or shared. On older versions, delete files individually or uninstall the app after backing up exports.</p>
<p><strong>Device unavailable?</strong> Email <a href="mailto:{{ config('schoolpdf.support_email') }}">{{ config('schoolpdf.support_email') }}</a> with the subject “School PDF data deletion”. Anonymous records may not be identifiable by email; never send secret device credentials or student documents.</p>
<p>Inactive device records are eligible for pruning after 90 days only when the server scheduler is running. Review the <a href="{{ url('/privacy') }}">privacy policy</a> for data handling and third-party SDK details.</p>
</div>
</x-shell>
