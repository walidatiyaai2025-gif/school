import 'package:flutter_test/flutter_test.dart';
import 'package:school_pdf/data/models.dart';
import 'package:school_pdf/data/app_store.dart';
import 'package:school_pdf/services/pdf_service.dart';
import 'package:school_pdf/services/scan_models.dart';
import 'package:school_pdf/core/strings.dart';
import 'package:school_pdf/core/page_order.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

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
  test('English is the first-launch default; stored Arabic choice survives',(){
    final initial=StudentSettings();
    expect(initial.english,isTrue);
    expect(StudentSettings.fromJson({}).english,isTrue);
    expect(StudentSettings.fromJson({'english':false}).english,isFalse);
  });
  test('subjects display in the chosen language without rewriting stored IDs',(){
    expect(S(true).subjectName('الرياضيات'),'Mathematics');
    expect(S(false).subjectName('الرياضيات'),'الرياضيات');
    expect(S(true).subjectName('الفيزياء'),'Physics');
    expect(S(true).subjectName('علوم أخرى'),'علوم أخرى');
    expect(S(false).grade('other'),'أخرى');
    expect(S(true).grade('other'),'Other');
    expect(schoolSubjects['other'],isNotEmpty);
  });
  test('moving a numbered page preserves order and page references',(){
    final pages=['p1','p2','p3','p4'];
    moveToPosition(pages,0,2);
    expect(pages,['p2','p3','p1','p4']);
    moveToPosition(pages,3,0);
    expect(pages,['p4','p2','p3','p1']);
    moveToPosition(pages,2,2);
    expect(pages,['p4','p2','p3','p1']);
    expect(()=>moveToPosition(pages,-1,1),throwsRangeError);
  });
  test('offline Dart-only detection returns plausible corners for a contrasting paper',(){
    final source=img.Image(width:240,height:320);
    for(var y=0;y<320;y++) {
      for(var x=0;x<240;x++) {
        final paper=x>=25 && x<=211 && y>=30 && y<=280;
        source.setPixelRgb(x,y,paper?240:15,paper?240:15,paper?240:15);
      }
    }
    final corners=guessPaperCorners(Uint8List.fromList(img.encodePng(source)));
    expect(corners,isNotNull);
    expect(corners!.isConvex,isTrue);
    expect(corners.area,greaterThan(.45));
    expect(corners.area,lessThan(.85));
  });
  test('scan geometry rejects crossed corners',(){
    const crossed=DocumentCorners(
      topLeft:(x:.1,y:.1), topRight:(x:.9,y:.9),
      bottomRight:(x:.9,y:.1), bottomLeft:(x:.1,y:.9),
    );
    expect(crossed.isConvex,isFalse);
    expect(ScanEngine.insetCorners().isConvex,isTrue);
  });
  test('scanner starts with convex full-paper manual crop',(){
    final corners=ScanEngine.insetCorners();
    expect(corners.isConvex,isTrue);
    expect(corners.area,greaterThan(.8));
  });
}
