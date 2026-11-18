/// Small bilingual string catalog. The primary build defaults to Arabic.
class S {
  final bool en;
  const S(this.en);
  String t(String ar, String english) => en ? english : ar;
  String get app => 'School PDF';
  String get home => t('الرئيسية','Home');
  String get files => t('ملفاتي','My Files');
  String get settings => t('الإعدادات','Settings');
  String get name => t('اسم الطالب','Student name');
  String get level => t('المرحلة الدراسية','Education level');
  String get className => t('الصف / الفصل / المجموعة','Class / year / group');
  String get subject => t('المادة الدراسية','Subject');
  String get camera => t('تصوير بالكاميرا','Take a photo');
  String get gallery => t('اختيار صور من المعرض','Choose photos');
  String get share => t('مشاركة PDF','Share PDF');
  String get add => t('إضافة صور','Add photos');
  String get done => t('تم','Done');
  String get save => t('حفظ','Save');
  String get ready => t('ملفك جاهز!','Your PDF is ready!');
  String get pages => t('الصفحات','Pages');
  String get cancel => t('إلغاء','Cancel');
  String get retry => t('إعادة المحاولة','Try again');
  String get noFiles => t('لسه ما أنشأتش ملفات PDF','No PDFs created yet');
  String get open => t('فتح الملف','Open file');
  String get delete => t('حذف','Delete');
  String get error => t('حدث خطأ. جرّب مرة أخرى.','Something went wrong. Please retry.');
  String grade(String level) => switch (level) {
    'primary' => t('ابتدائي','Primary'),
    'middle' => t('إعدادي','Middle school'),
    'secondary' => t('ثانوي','Secondary'),
    _ => t('جامعة','University'),
  };
}
