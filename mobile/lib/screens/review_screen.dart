import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/brand.dart';
import '../core/page_order.dart';
import '../core/strings.dart';
import '../data/app_store.dart';
import '../services/pdf_service.dart';
import '../services/notifications_service.dart';
import '../widgets/brand_widgets.dart';
import '../widgets/language_toggle.dart';
import 'corner_editor.dart';
import 'ready_screen.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key,required this.store,required this.scanner,
    required this.notifications,required this.subject,required this.images});
  final AppStore store;final ScanEngine scanner;final NotificationService notifications;
  final String subject;final List<ScanPage> images;
  @override State<ReviewScreen> createState()=>_ReviewScreenState();
}
class _ReviewScreenState extends State<ReviewScreen> {
  late final List<ScanPage> pages=[...widget.images];
  bool busy=false;int completed=0;
  final picker=ImagePicker();

  void _moveTo(int from, int to) {
    if (busy || from == to || from < 0 || to < 0 ||
        from >= pages.length || to >= pages.length) return;
    setState(() => moveToPosition(pages, from, to));
  }
  Future<void> _addPhotos(bool camera)async{
    try {
      final XFile? shot=camera?await picker.pickImage(source:ImageSource.camera,
        imageQuality:94,maxWidth:3200):null;
      final List<XFile> selected=camera?(shot==null?<XFile>[]:[shot])
        :await picker.pickMultiImage(imageQuality:94,maxWidth:3200);
      if(mounted)setState(()=>pages.addAll(selected.map((x)=>ScanPage(x.path))));
    } catch(e){if(mounted)feedback(context,S(widget.store.settings.english).t(
      'تعذر إضافة الصور','Could not add photos'));}
  }
  Future<void> _edit(int index)async{
    final result=await Navigator.push<String>(context,MaterialPageRoute(
      builder:(_)=>CornerEditor(scanner:widget.scanner,page:pages[index],
        store:widget.store,quality:widget.store.settings.pdfQuality)));
    if(result!=null && mounted)setState(()=>pages[index].editedPath=result);
  }
  Future<void> _generate()async{
    if(pages.isEmpty || busy)return;
    setState((){busy=true;completed=0;});
    try {
      final doc=await PdfService(widget.scanner).create(
        pages:pages,subject:widget.subject,settings:widget.store.settings,
        onProgress:(n,total){if(mounted)setState(()=>completed=n);});
      await widget.store.addRecord(doc);
      if(widget.store.settings.notifyReady){
        try {await widget.notifications.pdfReady(doc.id);} catch(_){}
      }
      if(!mounted)return;
      Navigator.pushReplacement(context,MaterialPageRoute<void>(builder:(_)=>
        ReadyScreen(store:widget.store,record:doc)));
    } catch(e){if(mounted)feedback(context,S(widget.store.settings.english).t(
      'فشل إنشاء PDF','Could not create PDF: $e'));}
    finally {if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context){
    final s=S(widget.store.settings.english);
    return Scaffold(appBar:AppBar(title:Text(s.t('الصور المحددة','Selected photos')),
      actions:[LanguageToggle(store:widget.store,onChanged:()=>setState((){}))]),
      body:SafeArea(child:Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(18,6,18,12),child:InfoBanner(
          text:s.t('اضغط على الصورة للتعديل. اسحب الورقة أو اختر رقم ترتيب جديد.',
            'Tap a page to edit. Drag it or choose its new position number.'),
          icon:Icons.crop_free_rounded)),
        Expanded(child:ReorderableListView.builder(
          padding:const EdgeInsets.symmetric(horizontal:16),itemCount:pages.length,
          onReorder:(oldIndex,newIndex){if(newIndex>oldIndex)newIndex--;
            _moveTo(oldIndex,newIndex);},
          itemBuilder:(ctx,i){final page=pages[i];
            return Card(key:ValueKey(page),margin:const EdgeInsets.only(bottom:10),
              child:Padding(padding:const EdgeInsets.all(9),child:Row(children:[
                ClipRRect(borderRadius:BorderRadius.circular(10),child:Image.file(
                  File(page.outputPath),width:69,height:92,fit:BoxFit.cover,
                  errorBuilder:(_,__,___)=>const Icon(Icons.broken_image))),
                const SizedBox(width:10),
                PopupMenuButton<int>(
                  enabled: !busy,
                  tooltip:s.t('تغيير ترتيب الصفحة','Move page to position'),
                  onSelected:(position)=>_moveTo(i,position),
                  itemBuilder:(context)=>List<PopupMenuEntry<int>>.generate(
                    pages.length,(position)=>PopupMenuItem<int>(
                      value:position,
                      child:Text(s.t('الموضع ${position+1}','Position ${position+1}')),
                    ),
                  ),
                  child:CircleAvatar(
                    radius:19,backgroundColor:Brand.blue,
                    child:Text('${i+1}',style:const TextStyle(
                      color:Colors.white,fontWeight:FontWeight.w800)),
                  ),
                ),
                const SizedBox(width:8),Expanded(child:Column(
                  crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text(s.t('الصفحة ${i+1}','Page ${i+1}'),
                      style:const TextStyle(fontWeight:FontWeight.w800,color:Brand.navy)),
                    if(page.editedPath!=null)Text(s.t('تم التعديل','Edited'),
                      style:const TextStyle(fontSize:11,color:Brand.green)),
                    TextButton.icon(onPressed:busy?null:()=>_edit(i),
                      icon:const Icon(Icons.crop_rotate,size:17),label:Text(s.t('تعديل الورقة','Edit page'))),
                  ])),
                IconButton(onPressed:busy?null:()=>setState(()=>pages.removeAt(i)),
                  icon:const Icon(Icons.delete_outline,color:Colors.redAccent)),
                const Icon(Icons.drag_handle_rounded,color:Brand.muted),
              ])));
          })),
        Padding(padding:const EdgeInsets.fromLTRB(18,6,18,8),child:Row(children:[
          Expanded(child:OutlinedButton.icon(onPressed:busy?null:()=>_addPhotos(true),
            icon:const Icon(Icons.add_a_photo_outlined),label:Text(s.t('الكاميرا','Camera')))),
          const SizedBox(width:10),Expanded(child:OutlinedButton.icon(
            onPressed:busy?null:()=>_addPhotos(false),
            icon:const Icon(Icons.add_photo_alternate_outlined),label:Text(s.add))),
        ])),
        Padding(padding:const EdgeInsets.fromLTRB(18,5,18,16),child:Column(children:[
          if(busy)...[LinearProgressIndicator(value:pages.isNotEmpty?completed/pages.length:0),
            const SizedBox(height:7),Text('$completed / ${pages.length}')],
          FilledButton.icon(onPressed:busy||pages.isEmpty?null:_generate,
            icon:const Icon(Icons.picture_as_pdf_rounded),
            label:Text(busy?s.t('جاري إنشاء PDF...','Creating PDF...'):
              s.t('إنشاء ملف PDF','Create PDF'))),
        ])),
      ])));
  }
}
