<x-shell title="School PDF — Support">
<div class="card"><h1>الدعم والمساعدة | School PDF Support</h1>
<p>للاستفسارات المتعلقة بتطبيق School PDF والخصوصية وطلبات حذف البيانات، تواصل معنا على البريد الرسمي:</p>
<p><a class="btn" href="mailto:{{ config('schoolpdf.support_email') }}">{{ config('schoolpdf.support_email') }}</a></p>
<p>لا يتطلب التطبيق إنشاء حساب مستخدم. يمكنك تعديل بيانات الطالب من إعدادات التطبيق، وحذف سجل الجهاز من الخادم أو مسح الملفات المحلية من قسم الخصوصية.</p>
<p><a href="{{ url('/data-deletion') }}">تعليمات حذف البيانات / Data deletion instructions</a> · <a href="{{ url('/privacy') }}">سياسة الخصوصية / Privacy policy</a></p>
<p class="muted">يرجى عدم إرسال صور الطلاب أو كلمات المرور أو معرّفات الأجهزة السرية في رسائل الدعم. لا نطلب أبدًا إرسال مفتاح الجهاز الخاص.</p></div>
<div class="card en" lang="en"><h2>Contact School PDF</h2>
<p>Official support and privacy contact: <a href="mailto:{{ config('schoolpdf.support_email') }}">{{ config('schoolpdf.support_email') }}</a>.</p>
<p>The student-facing app has no user sign-up or login. Profile and generated PDFs are stored on the device. Visit <a href="{{ url('/data-deletion') }}">Delete my data</a> for in-app deletion instructions and what to do if your device is unavailable.</p>
<p>Do not send student documents, passwords, installation credentials, or device keys to support.</p></div>
</x-shell>
