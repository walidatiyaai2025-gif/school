import 'package:flutter/material.dart';
import '../core/brand.dart';
import '../core/strings.dart';
import '../data/models.dart';
import '../data/app_store.dart';
import '../services/sharing_service.dart';
import '../widgets/brand_widgets.dart';
import '../widgets/language_toggle.dart';

class ReadyScreen extends StatelessWidget {
  const ReadyScreen({super.key,required this.store,required this.record});
  final AppStore store;final PdfRecord record;
  @override Widget build(BuildContext context){
    final s=S(store.settings.english), share=SharingService(store);
    Future<void> safe(Future<void> Function() f)async{
      try {await f();}catch(e){if(context.mounted)feedback(context,e.toString());}
    }
    return AnimatedBuilder(animation:store,builder:(context,_)=>Scaffold(
      appBar:AppBar(title:const Text('School PDF'),
        actions:[LanguageToggle(store:store)]),
      body:SafeArea(child:ListView(padding:const EdgeInsets.all(24),children:[
        const SizedBox(height:30),Center(child:Container(width:110,height:110,
          decoration:const BoxDecoration(color:Color(0xFFDCFBEA),shape:BoxShape.circle),
          child:const Icon(Icons.check_circle_rounded,color:Brand.green,size:80))),
        const SizedBox(height:20),Text(s.ready,textAlign:TextAlign.center,
          style:const TextStyle(color:Brand.navy,fontSize:28,fontWeight:FontWeight.w900)),
        const SizedBox(height:10),Text(s.t('تم حفظ ملفك في ملفاتي','Saved to My Files'),
          textAlign:TextAlign.center,style:const TextStyle(color:Brand.muted)),
        const SizedBox(height:28),WhitePanel(child:Row(children:[
          const Icon(Icons.picture_as_pdf,color:Color(0xFFE23949),size:54),
          const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
            children:[Text(record.filename,maxLines:3,overflow:TextOverflow.ellipsis,
              style:const TextStyle(fontWeight:FontWeight.w800,color:Brand.navy)),
              const SizedBox(height:7),Text('${record.pageCount} ${s.pages} • ${
                (record.bytes/1048576).toStringAsFixed(2)} MB',
                style:const TextStyle(color:Brand.muted,fontSize:12))]))])),
        const SizedBox(height:28),
        FilledButton.icon(onPressed:()=>safe(()=>share.share(record,context)),
          icon:const Icon(Icons.share_rounded),label:Text(s.share)),
        const SizedBox(height:12),
        OutlinedButton.icon(onPressed:()=>safe(()=>share.open(record)),
          icon:const Icon(Icons.visibility_outlined),label:Text(s.open)),
        const SizedBox(height:10),
        OutlinedButton.icon(onPressed:()=>safe(()=>share.export(record)),
          icon:const Icon(Icons.save_alt_rounded),label:Text(s.t('حفظ نسخة / تصدير','Save copy / export'))),
        const SizedBox(height:20),
        TextButton.icon(onPressed:()=>Navigator.pop(context),
          icon:const Icon(Icons.add_circle_outline),
          label:Text(s.t('إنشاء ملف آخر','Create another PDF'))),
        AnimatedBuilder(animation:store,builder:(ctx,_){
          final matches=store.records.where((x)=>x.id==record.id);
          final count=matches.isEmpty?record.shareAttempts:matches.first.shareAttempts;
          return Center(child:Text(s.t('مرات فتح المشاركة: $count',
            'Times share sheet opened: $count'),
            style:const TextStyle(color:Brand.muted,fontSize:12)));
        }),
      ]))));
  }
}
