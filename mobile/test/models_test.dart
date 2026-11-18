import 'package:flutter_test/flutter_test.dart';
import 'package:school_pdf/data/models.dart';
import 'package:school_pdf/data/app_store.dart';
import 'package:school_pdf/services/pdf_service.dart';

void main(){
  test('student settings serialize and preserve optional header',(){
    final s=StudentSettings()..name='أحمد محمد'..schoolClass='6-A'
      ..pdfHeader=true..level='primary'..introDone=true;
    final restored=StudentSettings.fromJson(s.toJson());
    expect(restored.name,'أحمد محمد');
    expect(restored.pdfHeader,isTrue);
    expect(restored.ready,isTrue);
  });
  test('PDF metadata preserves historical snapshot and share attempts',(){
    final r=PdfRecord(id:'1',filename:'Math_A.pdf',path:'/private/file.pdf',
      student:'A',schoolClass:'6-A',subject:'Math',level:'primary',
      createdAt:DateTime.utc(2026,11,18),pageCount:3,bytes:500,
      shareAttempts:2);
    final restored=PdfRecord.fromJson(r.toJson());
    expect(restored.pageCount,3);
    expect(restored.shareAttempts,2);
    expect(restored.copyWith(shareAttempts:3).shareAttempts,3);
    expect(restored.student,'A');
  });
  test('filenames sanitize traversal and reserved characters',(){
    expect(safeFilename('../Math:Ahmed\\test?'),isNot(contains('/')));
    expect(safeFilename('school|paper'),isNot(contains('|')));
  });
  test('scanner starts with convex full-paper manual crop',(){
    final corners=ScanEngine.insetCorners();
    expect(corners.isConvex,isTrue);
    expect(corners.area,greaterThan(.8));
  });
}
