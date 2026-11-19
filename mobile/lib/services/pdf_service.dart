import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'scan_models.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/models.dart';
import '../core/strings.dart';
import '../data/app_store.dart';

class ScanPage {
  ScanPage(this.originalPath,{this.editedPath});
  String originalPath;
  String? editedPath;
  String get outputPath => editedPath??originalPath;
}

/// A conservative, offline paper boundary proposal (no Android JNI).
/// If the paper/background contrast is uncertain, return null and use the
/// manual 4-corner editor instead of silently altering the student's photo.
DocumentCorners? guessPaperCorners(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final original = img.bakeOrientation(decoded);
  final source = original.width > 320
      ? img.copyResize(original, width: 320)
      : original;
  final width = source.width, height = source.height;
  if (width < 40 || height < 40) return null;

  double border = 0;
  var samples = 0;
  for (var x = 0; x < width; x += 8) {
    border += img.getLuminance(source.getPixel(x, 0));
    border += img.getLuminance(source.getPixel(x, height - 1));
    samples += 2;
  }
  for (var y = 0; y < height; y += 8) {
    border += img.getLuminance(source.getPixel(0, y));
    border += img.getLuminance(source.getPixel(width - 1, y));
    samples += 2;
  }
  border /= samples;
  final whitePaper = border < 135;
  final threshold = whitePaper ? border + 42 : border - 42;
  var minX = width, minY = height, maxX = 0, maxY = 0, count = 0;
  for (var y = 2; y < height - 2; y += 3) {
    for (var x = 2; x < width - 2; x += 3) {
      final lum = img.getLuminance(source.getPixel(x, y));
      if (whitePaper ? lum > threshold : lum < threshold) {
        minX = math.min(minX, x);
        minY = math.min(minY, y);
        maxX = math.max(maxX, x);
        maxY = math.max(maxY, y);
        count++;
      }
    }
  }
  final fraction = count / ((width / 3) * (height / 3));
  final detectedWidth = maxX - minX, detectedHeight = maxY - minY;
  if (fraction < 0.15 || fraction > 0.90 ||
      detectedWidth < width * 0.45 || detectedHeight < height * 0.45 ||
      detectedWidth > width * 0.99 || detectedHeight > height * 0.99) {
    return null;
  }
  const margin = 2;
  final left = math.max(0, minX - margin) / width;
  final top = math.max(0, minY - margin) / height;
  final right = math.min(width, maxX + margin) / width;
  final bottom = math.min(height, maxY + margin) / height;
  return DocumentCorners(
    topLeft: (x: left, y: top),
    topRight: (x: right, y: top),
    bottomRight: (x: right, y: bottom),
    bottomLeft: (x: left, y: bottom),
  );
}

class _ScanTask {
  const _ScanTask(this.bytes, this.corners, this.filter, this.quality);
  final Uint8List bytes;
  final DocumentCorners corners;
  final ScanFilter filter;
  final String quality;
}

Uint8List _renderScan(_ScanTask request) {
  final decoded = img.decodeImage(request.bytes);
  if (decoded == null) throw const FormatException('Cannot decode image');
  final source = img.bakeOrientation(decoded);
  final corner = request.corners;
  if (!corner.isConvex || corner.area < 0.035) {
    throw const FormatException('Invalid document corners');
  }
  final width = source.width.toDouble(), height = source.height.toDouble();
  double distance(ScanPoint a, ScanPoint b) => math.sqrt(
    math.pow((a.x - b.x) * width, 2) +
    math.pow((a.y - b.y) * height, 2)
  );
  var outWidth = math.max(distance(corner.topLeft, corner.topRight),
      distance(corner.bottomLeft, corner.bottomRight));
  var outHeight = math.max(distance(corner.topLeft, corner.bottomLeft),
      distance(corner.topRight, corner.bottomRight));
  final maxSide = switch (request.quality) {
    'high' => 2400, 'small' => 1200, _ => 1800,
  };
  final scale = math.min(1.0, maxSide / math.max(outWidth, outHeight));
  outWidth *= scale;
  outHeight *= scale;

  img.Point point(ScanPoint v) => img.Point(
      (v.x * (source.width - 1)).round(),
      (v.y * (source.height - 1)).round());
  var output = img.copyRectify(
    source,
    topLeft: point(corner.topLeft),
    topRight: point(corner.topRight),
    bottomRight: point(corner.bottomRight),
    bottomLeft: point(corner.bottomLeft),
    interpolation: img.Interpolation.linear,
    toImage: img.Image(
      width: math.max(1, outWidth.round()),
      height: math.max(1, outHeight.round()),
    ),
  );
  switch (request.filter) {
    case ScanFilter.none:
      break;
    case ScanFilter.enhance:
      output = img.adjustColor(output, contrast: 1.12);
    case ScanFilter.magicColor:
      output = img.adjustColor(output, contrast: 1.20, saturation: 1.15);
    case ScanFilter.grayscale:
      output = img.grayscale(output);
    case ScanFilter.blackWhite:
      output = img.adjustColor(img.grayscale(output), contrast: 1.75);
    case ScanFilter.sharpen:
      output = img.adjustColor(output, contrast: 1.3);
  }
  return Uint8List.fromList(img.encodeJpg(output, quality: 88));
}

class ScanEngine {
  Future<DocumentCorners?> detect(String file) async {
    try {
      final bytes = await File(file).readAsBytes();
      return await compute(guessPaperCorners, bytes);
    } catch (_) {
      return null;
    }
  }

  static DocumentCorners insetCorners() => const DocumentCorners(
    topLeft: (x: .02, y: .02), topRight: (x: .98, y: .02),
    bottomRight: (x: .98, y: .98), bottomLeft: (x: .02, y: .98),
  );

  Future<String?> process(String path, DocumentCorners corners,
      ScanFilter filter, String quality) async {
    if (!corners.isConvex || corners.area < .035) {
      throw const FormatException('Invalid document corners');
    }
    final bytes = await File(path).readAsBytes();
    final result = await compute(
      _renderScan, _ScanTask(bytes, corners, filter, quality),
    );
    final dir = Directory(p.join(
      (await getTemporaryDirectory()).path, 'school_pdf_scans',
    ));
    if (!await dir.exists()) await dir.create(recursive: true);
    final out = File(p.join(
      dir.path, 'scan_${DateTime.now().microsecondsSinceEpoch}.jpg',
    ));
    await out.writeAsBytes(result, flush: true);
    return out.path;
  }

  Future<String> autoProcess(String originalPath, String quality) async {
    final corners = await detect(originalPath);
    if (corners == null || !corners.isConvex || corners.area < .15) {
      return originalPath;
    }
    try {
      return await process(originalPath, corners, ScanFilter.enhance, quality)
          ?? originalPath;
    } catch (_) {
      return originalPath;
    }
  }

  Future<String> rotate(String source) async {
    final raw = await File(source).readAsBytes();
    final photo = img.decodeImage(raw);
    if (photo == null) throw const FormatException('Cannot decode image');
    final rotated = img.copyRotate(img.bakeOrientation(photo), angle: 90);
    final target = File(p.join((await getTemporaryDirectory()).path,
      'rotated_${DateTime.now().microsecondsSinceEpoch}.jpg'));
    await target.writeAsBytes(img.encodeJpg(rotated, quality: 92));
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
    final subjectLabel=S(settings.english).subjectName(subject);
    final header = settings.pdfHeader ? await _renderHeader(settings,subjectLabel) : null;
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
    final base=safeFilename('${subjectLabel}_${settings.name}_${settings.schoolClass}_$stamp');
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
        textDirection:ui.TextDirection.rtl,maxLines:1,ellipsis:'…');
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
