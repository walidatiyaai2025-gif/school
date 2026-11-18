import 'dart:io';
import 'dart:math' as math;
import 'package:document_scan/document_scan.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../core/brand.dart';
import '../services/pdf_service.dart';
import '../widgets/brand_widgets.dart';

/// Four independent corner handles mapped onto the actual BoxFit.contain image rect.
class CornerEditor extends StatefulWidget {
  const CornerEditor({super.key,required this.scanner,required this.page,
    required this.quality});
  final ScanEngine scanner;final ScanPage page;final String quality;
  @override State<CornerEditor> createState()=>_CornerEditorState();
}
class _CornerEditorState extends State<CornerEditor> {
  late String source=widget.page.originalPath;
  List<Offset> corners=[const Offset(.03,.03),const Offset(.97,.03),
    const Offset(.97,.97),const Offset(.03,.97)];
  int imageWidth=1,imageHeight=1;int? draggedCorner;
  ScanFilter filter=ScanFilter.enhance;
  bool loading=true,saving=false;
  @override void initState(){super.initState();_detect();}
  Future<void> _detect()async{
    if(mounted)setState(()=>loading=true);
    try {
      final raw=await File(source).readAsBytes();
      final image=img.decodeImage(raw);
      if(image==null)throw const FormatException('Image is unreadable');
      final detected=await widget.scanner.detect(source);
      if(!mounted)return;
      setState((){
        imageWidth=image.width;imageHeight=image.height;
        if(detected!=null && detected.isConvex && detected.area>.10){
          corners=detected.toList().map((pt)=>Offset(pt.x,pt.y)).toList();
        }else{
          corners=[const Offset(.03,.03),const Offset(.97,.03),
            const Offset(.97,.97),const Offset(.03,.97)];
        }
      });
    }catch(e){if(mounted)feedback(context,'تعذر التعرف على الورقة: $e');}
    finally{if(mounted)setState(()=>loading=false);}
  }
  Rect _imageRect(Size bounds){
    final scale=math.min(bounds.width/imageWidth,bounds.height/imageHeight);
    final w=imageWidth*scale,h=imageHeight*scale;
    return Rect.fromLTWH((bounds.width-w)/2,(bounds.height-h)/2,w,h);
  }
  Offset _fromNormalized(Offset point,Rect rect)=>Offset(
    rect.left+point.dx*rect.width,rect.top+point.dy*rect.height);
  void _touch(Offset local,Rect rect,{required bool start}){
    if(start){
      double shortest=double.infinity;int? closest;
      for(var i=0;i<4;i++){
        final distance=(_fromNormalized(corners[i],rect)-local).distance;
        if(distance<shortest){shortest=distance;closest=i;}
      }
      draggedCorner=shortest<55?closest:null;
    }
    if(draggedCorner==null)return;
    final x=((local.dx-rect.left)/rect.width).clamp(0.0,1.0);
    final y=((local.dy-rect.top)/rect.height).clamp(0.0,1.0);
    setState(()=>corners[draggedCorner!]=Offset(x,y));
  }
  DocumentCorners _makeCorners()=>DocumentCorners(
    topLeft:(x:corners[0].dx,y:corners[0].dy),
    topRight:(x:corners[1].dx,y:corners[1].dy),
    bottomRight:(x:corners[2].dx,y:corners[2].dy),
    bottomLeft:(x:corners[3].dx,y:corners[3].dy));
  Future<void> _rotate()async{
    if(loading||saving)return;
    setState(()=>loading=true);
    try {source=await widget.scanner.rotate(source);await _detect();}
    catch(e){if(mounted)feedback(context,'فشل التدوير: $e');}
    finally {if(mounted)setState(()=>loading=false);}
  }
  Future<void> _apply()async{
    final chosen=_makeCorners();
    if(!chosen.isConvex || chosen.area<.035){
      feedback(context,'اضبط الزوايا الأربع على حدود الورقة بدون تقاطع');return;
    }
    setState(()=>saving=true);
    try {
      final path=await widget.scanner.process(source,chosen,filter,widget.quality);
      if(path==null)throw const FormatException('Could not process image');
      if(!mounted)return;
      final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(
        title:const Text('معاينة الورقة بعد التصحيح'),
        content:SizedBox(width:300,height:420,child:Image.file(File(path),fit:BoxFit.contain)),
        actions:[TextButton(onPressed:()=>Navigator.pop(context,false),
          child:const Text('تعديل مجددًا')),
          FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('اعتماد الصورة'))]));
      if(ok==true && mounted)Navigator.pop(context,path);
    } catch(e){if(mounted)feedback(context,'فشل تصحيح الصورة: $e');}
    finally{if(mounted)setState(()=>saving=false);}
  }
  @override Widget build(BuildContext context){
    return Scaffold(backgroundColor:const Color(0xFF0B1733),
      appBar:AppBar(title:const Text('تعديل الصورة',style:TextStyle(color:Colors.white)),
        foregroundColor:Colors.white,backgroundColor:const Color(0xFF0B1733),
        actions:[IconButton(onPressed:loading||saving?null:_apply,
          icon:const Icon(Icons.check_circle,color:Brand.aqua,size:30))]),
      body:SafeArea(child:Column(children:[
        const SizedBox(height:5),const Text('اسحب الزوايا الأربع لتحديد الورقة فقط',
          style:TextStyle(color:Colors.white70)),
        Expanded(child:Padding(padding:const EdgeInsets.all(12),
          child:LayoutBuilder(builder:(context,constraints){
            final rect=_imageRect(Size(constraints.maxWidth,constraints.maxHeight));
            return Stack(children:[
              Positioned.fromRect(rect:rect,child:Image.file(File(source),fit:BoxFit.fill)),
              Positioned.fill(child:GestureDetector(behavior:HitTestBehavior.opaque,
                onPanStart:(d)=>_touch(d.localPosition,rect,start:true),
                onPanUpdate:(d)=>_touch(d.localPosition,rect,start:false),
                onPanEnd:(_)=>draggedCorner=null,
                child:CustomPaint(painter:_CornerPainter(rect,corners)))),
              if(loading)const Center(child:CircularProgressIndicator(color:Colors.white)),
            ]);
          }))),
        const Divider(color:Colors.white12),
        SingleChildScrollView(scrollDirection:Axis.horizontal,
          padding:const EdgeInsets.symmetric(horizontal:12),child:Row(children:[
            _darkAction(Icons.crop_free,'اكتشاف تلقائي',_detect),
            _darkAction(Icons.rotate_right,'تدوير',_rotate),
            ...<ScanFilter,String>{
              ScanFilter.none:'أصلي',ScanFilter.enhance:'محسن',
              ScanFilter.magicColor:'مستند',ScanFilter.grayscale:'رمادي',
              ScanFilter.blackWhite:'أبيض وأسود',ScanFilter.sharpen:'حدة',
            }.entries.map((entry)=>Padding(padding:const EdgeInsets.symmetric(horizontal:4),
              child:ChoiceChip(label:Text(entry.value),selected:filter==entry.key,
                onSelected:(_)=>setState(()=>filter=entry.key)))),
          ])),
        Padding(padding:const EdgeInsets.all(16),child:FilledButton.icon(
          onPressed:saving||loading?null:_apply,
          icon:saving?const SizedBox(width:20,height:20,child:CircularProgressIndicator(
            strokeWidth:2,color:Colors.white)):const Icon(Icons.done_all),
          label:const Text('تطبيق تصحيح المنظور والتحسين'))),
      ])));
  }
  Widget _darkAction(IconData icon,String title,VoidCallback onTap)=>TextButton.icon(
    onPressed:loading||saving?null:onTap,icon:Icon(icon,color:Brand.aqua),
    label:Text(title,style:const TextStyle(color:Colors.white)));
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter(this.imageRect,this.corners);
  final Rect imageRect;final List<Offset> corners;
  @override void paint(Canvas canvas,Size size){
    final rect=Path()..addRect(imageRect);
    final pts=corners.map((c)=>Offset(imageRect.left+c.dx*imageRect.width,
      imageRect.top+c.dy*imageRect.height)).toList();
    final quad=Path()..moveTo(pts[0].dx,pts[0].dy);
    for(var i=1;i<4;i++)quad.lineTo(pts[i].dx,pts[i].dy);
    quad.close();
    canvas.drawPath(Path.combine(PathOperation.difference,rect,quad),
      Paint()..color=Colors.black.withValues(alpha:.54));
    canvas.drawPath(quad,Paint()..color=const Color(0xFF3EBBFF)
      ..style=PaintingStyle.stroke..strokeWidth=2.5);
    for(final p in pts){
      canvas.drawCircle(p,11,Paint()..color=Colors.white);
      canvas.drawCircle(p,7,Paint()..color=Brand.blue);
    }
  }
  @override bool shouldRepaint(covariant _CornerPainter old)=>
    old.imageRect!=imageRect || old.corners!=corners;
}
