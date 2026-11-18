import 'dart:convert';

class PdfRecord {
  const PdfRecord({required this.id, required this.filename,
    required this.path, required this.student, required this.schoolClass,
    required this.subject, required this.level, required this.createdAt,
    required this.pageCount, required this.bytes, this.shareAttempts = 0,
    this.lastShareAttempt});
  final String id;
  final String filename;
  final String path;
  final String student;
  final String schoolClass;
  final String subject;
  final String level;
  final DateTime createdAt;
  final int pageCount;
  final int bytes;
  final int shareAttempts;
  final DateTime? lastShareAttempt;

  PdfRecord copyWith({String? filename, int? shareAttempts,
    DateTime? lastShareAttempt}) => PdfRecord(
      id: id, filename: filename ?? this.filename, path: path,
      student: student, schoolClass: schoolClass, subject: subject,
      level: level, createdAt: createdAt, pageCount: pageCount, bytes: bytes,
      shareAttempts: shareAttempts ?? this.shareAttempts,
      lastShareAttempt: lastShareAttempt ?? this.lastShareAttempt);

  Map<String,dynamic> toJson() => {
    'id':id,'filename':filename,'path':path,'student':student,
    'schoolClass':schoolClass,'subject':subject,'level':level,
    'createdAt':createdAt.toIso8601String(),'pageCount':pageCount,
    'bytes':bytes,'shareAttempts':shareAttempts,
    'lastShareAttempt':lastShareAttempt?.toIso8601String(),
  };
  factory PdfRecord.fromJson(Map<String,dynamic> j) => PdfRecord(
    id:j['id'] as String,filename:j['filename'] as String,
    path:j['path'] as String,student:j['student'] as String,
    schoolClass:j['schoolClass'] as String,subject:j['subject'] as String,
    level:j['level'] as String,createdAt:DateTime.parse(j['createdAt'] as String),
    pageCount:j['pageCount'] as int,bytes:j['bytes'] as int,
    shareAttempts:(j['shareAttempts'] as int?)??0,
    lastShareAttempt:j['lastShareAttempt'] == null ? null : DateTime.parse(j['lastShareAttempt'] as String));
}

class StudentSettings {
  String name = '';
  String schoolClass = '';
  String level = 'primary';
  String ageGroup = 'unknown'; // unknown, child, teen, adult
  bool english = false;
  bool pdfHeader = false;
  String pdfQuality = 'balanced';
  bool notifyReady = true;
  bool notifyReminders = false;
  bool notifyUpdates = true;
  String reminderTime = '18:00';
  bool introDone = false;
  bool analyticsConsent = false; // Adult opt-in only; off by default
  List<String> customSubjects = [];

  bool get ready => introDone && name.trim().isNotEmpty && schoolClass.trim().isNotEmpty;
  Map<String,dynamic> toJson() => {
    'name':name,'schoolClass':schoolClass,'level':level,
    'ageGroup':ageGroup,'english':english,'pdfHeader':pdfHeader,
    'pdfQuality':pdfQuality,'notifyReady':notifyReady,
    'notifyReminders':notifyReminders,'notifyUpdates':notifyUpdates,
    'reminderTime':reminderTime,'introDone':introDone,'analyticsConsent':analyticsConsent,
    'customSubjects':customSubjects,
  };
  factory StudentSettings.fromJson(Map<String,dynamic> j) {
    final x = StudentSettings();
    x.name = (j['name'] as String?)??'';
    x.schoolClass = (j['schoolClass'] as String?)??'';
    x.level = (j['level'] as String?)??'primary';
    x.ageGroup = (j['ageGroup'] as String?)??'unknown';
    x.english = (j['english'] as bool?)??false;
    x.pdfHeader = (j['pdfHeader'] as bool?)??false;
    x.pdfQuality = (j['pdfQuality'] as String?)??'balanced';
    x.notifyReady = (j['notifyReady'] as bool?)??true;
    x.notifyReminders = (j['notifyReminders'] as bool?)??false;
    x.notifyUpdates = (j['notifyUpdates'] as bool?)??true;
    x.reminderTime = (j['reminderTime'] as String?)??'18:00';
    x.introDone = (j['introDone'] as bool?)??false;
    x.analyticsConsent = (j['analyticsConsent'] as bool?)??false;
    x.customSubjects = ((j['customSubjects'] as List?)??[]).cast<String>();
    return x;
  }
}

const schoolSubjects = <String, List<String>>{
  'primary':['الرياضيات','اللغة العربية','English','العلوم','الدراسات الاجتماعية','ICT','التربية الدينية'],
  'middle':['الرياضيات','اللغة العربية','English','العلوم','الدراسات الاجتماعية','ICT','التربية الدينية'],
  'secondary':['الرياضيات','اللغة العربية','English','الفيزياء','الكيمياء','الأحياء','التاريخ','الجغرافيا','ICT'],
  'university':['Statistics','Accounting','Computer Science','Economics'],
};

String encodeRecords(List<PdfRecord> records) => jsonEncode(records.map((e)=>e.toJson()).toList());
