import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../core/brand.dart';
import '../core/strings.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../services/sharing_service.dart';
import '../widgets/brand_widgets.dart';
import '../widgets/language_toggle.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key,required this.store});
  final AppStore store;
  @override State<HistoryScreen> createState()=>_HistoryScreenState();
}
class _HistoryScreenState extends State<HistoryScreen> {
  String search='',filter='';
  @override Widget build(BuildContext context){
    final s=S(widget.store.settings.english);
    return AnimatedBuilder(animation:widget.store,builder:(ctx,_) {
      final files=widget.store.records.where((r)=>
        (filter.isEmpty||r.subject==filter) &&
        ('${r.filename} ${r.student} ${r.schoolClass} ${r.subject} ${s.subjectName(r.subject)}'
          .toLowerCase().contains(search.trim().toLowerCase()))).toList();
      final subjects=widget.store.records.map((x)=>x.subject).toSet().toList();
      return ListView(padding:const EdgeInsets.fromLTRB(17,20,17,28),children:[
        Row(children:[const Icon(Icons.folder_copy_rounded,color:Brand.blue,size:30),
          const SizedBox(width:9),Text(s.files,style:const TextStyle(fontSize:27,
            fontWeight:FontWeight.w900,color:Brand.navy)),const Spacer(),
          Text('${widget.store.records.length}',style:const TextStyle(color:Brand.muted))]),
        const SizedBox(height:20),TextField(onChanged:(x)=>setState(()=>search=x),
          decoration:InputDecoration(prefixIcon:const Icon(Icons.search_rounded),
            hintText:s.t('ابحث بالاسم أو المادة أو الفصل','Search files, subjects, classes'))),
        const SizedBox(height:13),SingleChildScrollView(scrollDirection:Axis.horizontal,
          child:Row(children:[
            Padding(padding:const EdgeInsetsDirectional.only(end:7),
              child:ChoiceChip(label:Text(s.t('الكل','All')),
                selected:filter.isEmpty,onSelected:(_)=>setState(()=>filter=''))),
            ...subjects.map((v)=>Padding(padding:const EdgeInsetsDirectional.only(end:7),
              child:ChoiceChip(label:Text(s.subjectName(v)),selected:filter==v,
                onSelected:(_)=>setState(()=>filter=v)))),
          ])),const SizedBox(height:12),
        if(files.isEmpty)Padding(padding:const EdgeInsets.only(top:85),child:Column(
          children:[const Icon(Icons.folder_open_rounded,size:75,color:Brand.muted),
            const SizedBox(height:14),Text(s.noFiles,style:const TextStyle(color:Brand.muted))]))
        else ...files.map((r)=>Padding(padding:const EdgeInsets.only(bottom:10),
          child:_FileCard(store:widget.store,record:r))),
      ]);
    });
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({required this.store,required this.record});
  final AppStore store;final PdfRecord record;
  @override Widget build(BuildContext context){
    final s=S(store.settings.english),share=SharingService(store);
    Future<void> action(Future<void> Function() f)async{
      try {await f();}catch(e){if(context.mounted)feedback(context,e.toString());}
    }
    return WhitePanel(padding:const EdgeInsets.symmetric(horizontal:12,vertical:11),
      child:Column(children:[
        Row(children:[
          Container(padding:const EdgeInsets.all(11),
            decoration:BoxDecoration(color:const Color(0xFFFFEFF1),
              borderRadius:BorderRadius.circular(12)),
            child:const Icon(Icons.picture_as_pdf_rounded,color:Color(0xFFDD3348),size:28)),
          const SizedBox(width:10),
          Expanded(child:InkWell(onTap:()=>Navigator.push(context,
            MaterialPageRoute(builder:(_)=>PdfDetailScreen(store:store,recordId:record.id))),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(record.filename,maxLines:2,overflow:TextOverflow.ellipsis,
                style:const TextStyle(fontWeight:FontWeight.w800,color:Brand.navy,fontSize:12)),
              const SizedBox(height:5),Text('${s.subjectName(record.subject)} • ${record.schoolClass}',
                style:const TextStyle(color:Brand.muted,fontSize:12)),
              Text('${record.pageCount} ${s.pages} • ${
                (record.bytes/1024).toStringAsFixed(0)} KB • ${DateFormat('yyyy/MM/dd').format(record.createdAt)}',
                style:const TextStyle(color:Brand.muted,fontSize:11)),
            ]))),
          PopupMenuButton<String>(icon:const Icon(Icons.more_vert_rounded),
            onSelected:(v) {
              if(v=='open')action(()=>share.open(record));
              if(v=='details')Navigator.push(context,MaterialPageRoute(
                builder:(_)=>PdfDetailScreen(store:store,recordId:record.id)));
              if(v=='rename')_renameDialog(context,store,record);
              if(v=='export')action(()=>share.export(record));
              if(v=='delete')_deleteDialog(context,store,record);
            },itemBuilder:(_)=>[
              PopupMenuItem(value:'open',child:Text(s.open)),
              PopupMenuItem(value:'details',child:Text(s.t('تفاصيل الملف','Details'))),
              PopupMenuItem(value:'rename',child:Text(s.t('إعادة تسمية','Rename'))),
              PopupMenuItem(value:'export',child:Text(s.t('حفظ نسخة','Export'))),
              PopupMenuItem(value:'delete',child:Text(s.delete,
                style:const TextStyle(color:Colors.red))),
            ]),
        ]),
        const Divider(height:15),
        Row(children:[
          Icon(Icons.ios_share_rounded,size:16,color:Brand.blue),
          const SizedBox(width:5),Expanded(child:Text(
            s.t('فتح المشاركة: ${record.shareAttempts} مرة',
              'Share sheet opens: ${record.shareAttempts}'),
            style:const TextStyle(fontSize:11,color:Brand.muted))),
          TextButton.icon(onPressed:()=>action(()=>share.share(record,context)),
            icon:const Icon(Icons.share_outlined,size:18),label:Text(s.t('مشاركة','Share'))),
        ]),
      ]));
  }
}

Future<void> _renameDialog(BuildContext context,AppStore store,PdfRecord r) async {
  var name=r.filename.replaceAll(RegExp(r'\.pdf
  final s=S(store.settings.english);
  final result=await showDialog<String>(context:context,builder:(_)=>AlertDialog(
    title:Text(s.t('إعادة تسمية الملف','Rename PDF')),
    content:TextFormField(initialValue:name,autofocus:true,
      onChanged:(v)=>name=v),
    actions:[TextButton(onPressed:()=>Navigator.pop(context),child:Text(s.cancel)),
      FilledButton(onPressed:()=>Navigator.pop(context,name.trim()),child:Text(s.save))]));
  if(result!=null && result.trim().isNotEmpty){
    try {await store.rename(r.id,result);} catch(e){if(context.mounted)feedback(context,e.toString());}
  }
}
Future<void> _deleteDialog(BuildContext context,AppStore store,PdfRecord r) async {
  final s=S(store.settings.english);
  final yes=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(
    title:Text(s.t('حذف الملف نهائيًا؟','Delete this PDF?')),
    content:Text(s.t('سيُحذف الملف المحفوظ داخل التطبيق، ولا يمكن التراجع.',
      'The app copy will be permanently deleted.')),
    actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:Text(s.cancel)),
      FilledButton(onPressed:()=>Navigator.pop(context,true),child:Text(s.delete))]));
  if(yes==true){
    try {await store.delete(r.id);}catch(e){if(context.mounted)feedback(context,e.toString());}
  }
}

class PdfDetailScreen extends StatelessWidget {
  const PdfDetailScreen({super.key,required this.store,required this.recordId});
  final AppStore store;final String recordId;
  @override Widget build(BuildContext context) {
    final s=S(store.settings.english), share=SharingService(store);
    return AnimatedBuilder(animation:store,builder:(ctx,_){
      final results=store.records.where((r)=>r.id==recordId);
      if(results.isEmpty)return Scaffold(appBar:AppBar(),
        body:Center(child:Text(s.t('الملف غير موجود','File not found'))));
      final r=results.first;
      return Scaffold(appBar:AppBar(title:Text(s.t('معاينة الملف','PDF Preview')),
        actions:[LanguageToggle(store:store)]),
        body:Column(children:[
          Expanded(child:PdfPreview(
            build:(_)=>File(r.path).readAsBytes(),
            allowPrinting:false,allowSharing:false,canChangeOrientation:false,
            canChangePageFormat:false,pdfFileName:r.filename)),
          WhitePanel(child:Column(children:[
            Text(r.filename,style:const TextStyle(color:Brand.navy,fontWeight:FontWeight.w800)),
            const SizedBox(height:7),Text('${r.student} • ${r.schoolClass} • ${s.subjectName(r.subject)}',
              style:const TextStyle(color:Brand.muted,fontSize:12)),
            Text('${r.pageCount} ${s.pages} • ${(r.bytes/1048576).toStringAsFixed(2)} MB',
              style:const TextStyle(color:Brand.muted,fontSize:12)),
            const SizedBox(height:7),Text(s.t('عدد مرات فتح المشاركة: ${r.shareAttempts}',
              'Share sheet opened ${r.shareAttempts} times'),
              style:const TextStyle(color:Brand.blue,fontWeight:FontWeight.w700)),
            if(r.lastShareAttempt!=null)Text(s.t('آخر محاولة:','Last attempt:')+
              ' ${DateFormat('yyyy/MM/dd HH:mm').format(r.lastShareAttempt!)}',
              style:const TextStyle(color:Brand.muted,fontSize:11)),
            const SizedBox(height:10),FilledButton.icon(
              onPressed:()async{
                try {await share.share(r,context);}catch(e){if(context.mounted)feedback(context,e.toString());}
              },icon:const Icon(Icons.share_outlined),label:Text(s.share)),
          ])),
        ]));
    });
  }
}
,caseSensitive:false),'');
  final s=S(store.settings.english);
  final result=await showDialog<String>(context:context,builder:(_)=>AlertDialog(
    title:Text(s.t('إعادة تسمية الملف','Rename PDF')),
    content:TextFormField(initialValue:name,autofocus:true,
      onChanged:(v)=>name=v),
    actions:[TextButton(onPressed:()=>Navigator.pop(context),child:Text(s.cancel)),
      FilledButton(onPressed:()=>Navigator.pop(context,name.trim()),child:Text(s.save))]));
  if(result!=null && result.trim().isNotEmpty){
    try {await store.rename(r.id,result);} catch(e){if(context.mounted)feedback(context,e.toString());}
  }
}
Future<void> _deleteDialog(BuildContext context,AppStore store,PdfRecord r) async {
  final s=S(store.settings.english);
  final yes=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(
    title:Text(s.t('حذف الملف نهائيًا؟','Delete this PDF?')),
    content:Text(s.t('سيُحذف الملف المحفوظ داخل التطبيق، ولا يمكن التراجع.',
      'The app copy will be permanently deleted.')),
    actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:Text(s.cancel)),
      FilledButton(onPressed:()=>Navigator.pop(context,true),child:Text(s.delete))]));
  if(yes==true){
    try {await store.delete(r.id);}catch(e){if(context.mounted)feedback(context,e.toString());}
  }
}

class PdfDetailScreen extends StatelessWidget {
  const PdfDetailScreen({super.key,required this.store,required this.recordId});
  final AppStore store;final String recordId;
  @override Widget build(BuildContext context) {
    final s=S(store.settings.english), share=SharingService(store);
    return AnimatedBuilder(animation:store,builder:(ctx,_){
      final results=store.records.where((r)=>r.id==recordId);
      if(results.isEmpty)return Scaffold(appBar:AppBar(),
        body:Center(child:Text(s.t('الملف غير موجود','File not found'))));
      final r=results.first;
      return Scaffold(appBar:AppBar(title:Text(s.t('معاينة الملف','PDF Preview')),
        actions:[LanguageToggle(store:store)]),
        body:Column(children:[
          Expanded(child:PdfPreview(
            build:(_)=>File(r.path).readAsBytes(),
            allowPrinting:false,allowSharing:false,canChangeOrientation:false,
            canChangePageFormat:false,pdfFileName:r.filename)),
          WhitePanel(child:Column(children:[
            Text(r.filename,style:const TextStyle(color:Brand.navy,fontWeight:FontWeight.w800)),
            const SizedBox(height:7),Text('${r.student} • ${r.schoolClass} • ${s.subjectName(r.subject)}',
              style:const TextStyle(color:Brand.muted,fontSize:12)),
            Text('${r.pageCount} ${s.pages} • ${(r.bytes/1048576).toStringAsFixed(2)} MB',
              style:const TextStyle(color:Brand.muted,fontSize:12)),
            const SizedBox(height:7),Text(s.t('عدد مرات فتح المشاركة: ${r.shareAttempts}',
              'Share sheet opened ${r.shareAttempts} times'),
              style:const TextStyle(color:Brand.blue,fontWeight:FontWeight.w700)),
            if(r.lastShareAttempt!=null)Text(s.t('آخر محاولة:','Last attempt:')+
              ' ${DateFormat('yyyy/MM/dd HH:mm').format(r.lastShareAttempt!)}',
              style:const TextStyle(color:Brand.muted,fontSize:11)),
            const SizedBox(height:10),FilledButton.icon(
              onPressed:()async{
                try {await share.share(r,context);}catch(e){if(context.mounted)feedback(context,e.toString());}
              },icon:const Icon(Icons.share_outlined),label:Text(s.share)),
          ])),
        ]));
    });
  }
}
