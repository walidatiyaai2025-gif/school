import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:document_scan/document_scan.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/models.dart';
import '../data/app_store.dart';

class ScanPage {
  ScanPage(this.originalPath,{this.editedPath});
  String originalPath;
  String? editedPath;
  String get outputPath => editedPath??originalPath;
}

class ScanEngine {
  final DocumentDetector detector = DocumentDetector();
  final DocumentProcessor processor = const DocumentProcessor();

  Future<DocumentCorners?> detect(String file) async {
    try { return await detector.detect(ScanInput.file(file)); }
    catch (_) { return null; }
  }
  static DocumentCorners insetCorners() => const DocumentCorners(
    topLeft:(x:.02,y:.02), topRight:(x:.98,y:.02),
    bottomRight:(x:.98,y:.98), bottomLeft:(x:.02,y:.98));

  Future<String?> process(String path,DocumentCorners corners,
      ScanFilter filter,String quality) async {
    final result = await processor.crop(ScanInput.file(path),corners,
      filter:filter, output:ScanOutputFormat.jpeg,background:true,
      maxDimension:switch(quality){'high'=>2400,'small'=>1200,_=>1800});
    if(result==null) return null;
    final dir=Directory(p.join((await getTemporaryDirectory()).path,'school_pdf_scans'));
    if(!await dir.exists()) await dir.create(recursive:true);
    final out=File(p.join(dir.path,'scan_${DateTime.now().microsecondsSinceEpoch}.jpg'));
    await out.writeAsBytes(result.bytes,flush:true);
    return out.path;
  }
  Future<String> autoProcess(String originalPath,String quality) async {
    final corners=await detect(originalPath);
    if (corners==null || !corners.isConvex || corners.area<.15) {
      return originalPath; // Never silently crop homework without a valid document.
    }
    try {
      return await process(originalPath,corners,ScanFilter.enhance,quality)??originalPath;
    } catch (_) { return originalPath; }
  }
  Future<String> rotate(String source) async {
    final raw=await File(source).readAsBytes();
    final photo=img.decodeImage(raw);
    if(photo==null) throw const FormatException('Cannot decode image');
    final rotated=img.copyRotate(img.bakeOrientation(photo),angle:90);
    final target=File(p.join((await getTemporaryDirectory()).path,
      'rotated_${DateTime.now().microsecondsSinceEpoch}.jpg'));
    await target.writeAsBytes(img.encodeJpg(rotated,quality:92));
    return target.path;
  }
}

class PdfService {
  PdfService(this._scanner);
  final ScanEngine _scanner;

  Future<PdfRecord> create({required List<ScanPage> pages,
      required String subject,required StudentSettings settings,
      void Function(int complete,int total)? onProgress}) async {
    if (pages.isEmpty || subject.trim().isEmpty) {
      throw const FormatException('Select a subject and one or more photos');
    }
    final pdf = pw.Document(compress:true);
    final header = settings.pdfHeader ? await _renderHeader(settings,subject) : null;
    for(var i=0;i<pages.length;i++) {
      final path=pages[i].editedPath??await _scanner.autoProcess(
        pages[i].originalPath,settings.pdfQuality);
      final photo=File(path);
      final bytes=await photo.readAsBytes();
      final decoded=img.decodeImage(bytes);
      if(decoded==null) throw FormatException('Invalid image on page ${i+1}');
      // Pre-encode large input images to limit PDF memory and output size.
      final maxSide=switch(settings.pdfQuality){'high'=>2400,'small'=>1200,_=>1800};
      final reduced=(decoded.width>maxSide || decoded.height>maxSide)
          ? img.copyResize(decoded,width:decoded.width>=decoded.height?maxSide:null,
              height:decoded.height>decoded.width?maxSide:null)
          :decoded;
      final jpeg=img.encodeJpg(img.bakeOrientation(reduced),
        quality:switch(settings.pdfQuality){'high'=>94,'small'=>69,_=>83});
      final image=pw.MemoryImage(Uint8List.fromList(jpeg));
      pdf.addPage(pw.Page(pageFormat:PdfPageFormat.a4, margin:const pw.EdgeInsets.all(18),
        build:(ctx)=>pw.Column(children:[
          if(i==0 && header!=null) ...[
            pw.SizedBox(height:56,child:pw.Image(pw.MemoryImage(header),fit:pw.BoxFit.contain)),
            pw.SizedBox(height:10),
          ],
          pw.Expanded(child:pw.Center(child:pw.Image(image,fit:pw.BoxFit.contain))),
        ])));
      onProgress?.call(i+1,pages.length);
    }
    final root=Directory(p.join((await getApplicationDocumentsDirectory()).path,'schoolpdf','pdf'));
    if(!await root.exists()) await root.create(recursive:true);
    final now=DateTime.now();
    final id=now.microsecondsSinceEpoch.toString();
    final stamp=DateFormat('yyyyMMdd_HHmmss').format(now);
    final base=safeFilename('${subject}_${settings.name}_${settings.schoolClass}_$stamp');
    final filename='$base.pdf';
    final finalFile=File(p.join(root.path,filename));
    final temp=File(p.join(root.path,'.$id.tmp'));
    try {
      await temp.writeAsBytes(await pdf.save(),flush:true);
      await temp.rename(finalFile.path);
    } catch (_) {
      if(await temp.exists()) await temp.delete();
      rethrow;
    }
    return PdfRecord(id:id, filename:filename, path:finalFile.path,
      student:settings.name,schoolClass:settings.schoolClass,
      subject:subject,level:settings.level,createdAt:now,
      pageCount:pages.length,bytes:await finalFile.length());
  }

  /// Rasterize multilingual header with the OS text shaping engine. No bundled font
  /// and no Arabic glyph gaps from PDF core fonts. The homework image is untouched.
  Future<Uint8List> _renderHeader(StudentSettings user,String subject) async {
    final recorder=ui.PictureRecorder();
    final canvas=Canvas(recorder);
    const width=1200.0, height=180.0;
    canvas.drawColor(Colors.white,BlendMode.src);
    void line(String value,double y,{double fontSize=35,bool bold=false}){
      final painter=TextPainter(
        text:TextSpan(text:value,style:TextStyle(fontSize:fontSize,
          color:const Color(0xFF102448),fontWeight:bold?FontWeight.w700:FontWeight.w400)),
        textDirection:TextDirection.rtl,maxLines:1,ellipsis:'…');
      painter.layout(maxWidth:width-60);
      painter.paint(canvas,Offset(width-painter.width-25,y));
      painter.dispose();
    }
    line(user.name,10,fontSize:44,bold:true);
    line('${user.schoolClass}  •  $subject',76,fontSize:34);
    canvas.drawLine(const Offset(25,156),const Offset(1175,156),
      Paint()..color=const Color(0xFFDBE7F7)..strokeWidth=2);
    final picture=recorder.endRecording();
    final result=await picture.toImage(width.toInt(),height.toInt());
    final data=await result.toByteData(format:ui.ImageByteFormat.png);
    result.dispose();picture.dispose();
    return data!.buffer.asUint8List();
  }
}
