import 'package:flutter/material.dart';
import '../core/brand.dart';
import '../core/strings.dart';
import '../data/app_store.dart';
import '../services/notifications_service.dart';
import '../widgets/brand_widgets.dart';
import '../widgets/language_toggle.dart';
import '../services/telemetry_service.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key,required this.store,required this.notifications});
  final AppStore store;final NotificationService notifications;
  @override State<OnboardingScreen> createState()=>_OnboardingScreenState();
}
class _OnboardingScreenState extends State<OnboardingScreen> {
  late final TextEditingController name=TextEditingController(text:widget.store.settings.name);
  late final TextEditingController group=TextEditingController(text:widget.store.settings.schoolClass);
  late String level=widget.store.settings.level;
  late String age=widget.store.settings.ageGroup;
  int step=0;bool busy=false;
  bool analyticsAllowed=false;
  @override void dispose(){name.dispose();group.dispose();super.dispose();}
  Future<void> _continue()async{
    if(name.text.trim().isEmpty || group.text.trim().isEmpty || age=='unknown'){
      feedback(context,S(widget.store.settings.english).t('أدخل الاسم والفصل والفئة العمرية','Complete your name, class and age group'));return;
    }
    widget.store.settings
      ..name=name.text.trim()..schoolClass=group.text.trim()
      ..level=level..ageGroup=age..analyticsConsent=(age=='adult' && analyticsAllowed);
    await widget.store.saveSettings();
    if(mounted)setState(()=>step=1);
  }
  Future<void> _finish({required bool request})async{
    if(busy)return;setState(()=>busy=true);
    if(request){
      try {await widget.notifications.requestPermission();}catch(_){
        if(mounted)feedback(context,S(widget.store.settings.english).t('يمكنك تفعيل الإشعارات لاحقًا من إعدادات الهاتف','You can enable notifications later in your device settings'));
      }
    }
    widget.store.settings.introDone=true;
    await widget.store.saveSettings();
    await TelemetryService.sync(widget.store,widget.notifications);
    if(mounted)setState(()=>busy=false);
  }
  @override Widget build(BuildContext context){
    final s=S(widget.store.settings.english);
    return Scaffold(appBar:AppBar(automaticallyImplyLeading:false,
      actions:[LanguageToggle(store:widget.store,notifications:widget.notifications,onChanged:()=>setState((){}))]),
      body:SafeArea(child:ListView(padding:const EdgeInsets.all(24),children:[
      const SizedBox(height:22),Center(child:const Logo(size:90)),const SizedBox(height:12),
      const Center(child:Text('School PDF',style:TextStyle(color:Brand.navy,
        fontSize:28,fontWeight:FontWeight.w900))),const SizedBox(height:8),
      Center(child:Text(step==0?s.t('بياناتك مرة واحدة فقط','Your details, just once'):
        s.t('خليك على اطلاع 🔔','Stay in the loop 🔔'),
        style:const TextStyle(color:Brand.muted))),
      const SizedBox(height:22),
      if(step==0)...[
        WhitePanel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Text(s.name,style:const TextStyle(fontWeight:FontWeight.w700)),
          const SizedBox(height:8),TextField(controller:name,textInputAction:TextInputAction.next,
            decoration:InputDecoration(hintText:s.t('الاسم الكامل','Full name'))),
          const SizedBox(height:17),
          Text(s.level,style:const TextStyle(fontWeight:FontWeight.w700)),
          const SizedBox(height:8),DropdownButtonFormField<String>(
            initialValue:level,isExpanded:true,items:['primary','middle','secondary','university','other']
              .map((x)=>DropdownMenuItem(value:x,child:Text(s.grade(x)))).toList(),
            onChanged:(x){if(x!=null)setState(()=>level=x);}),
          const SizedBox(height:17),
          Text(s.className,style:const TextStyle(fontWeight:FontWeight.w700)),
          const SizedBox(height:8),TextField(controller:group,
            decoration:InputDecoration(hintText:level=='university'
              ?s.t('الفرقة الثالثة - محاسبة - B','Year 3 - Accounting - B')
              :s.t('الصف السادس - A','Grade 6 - A'))),
          const SizedBox(height:17),
          Text(s.t('الفئة العمرية (لحماية خصوصيتك والإعلانات)','Age group (for privacy and safe ads)'),
            style:const TextStyle(fontWeight:FontWeight.w700)),
          const SizedBox(height:8),DropdownButtonFormField<String>(initialValue:age,
            items:[
              DropdownMenuItem(value:'unknown',child:Text(s.t('اختر الفئة العمرية','Choose age group'))),
              DropdownMenuItem(value:'child',child:Text(s.t('أقل من 13 سنة','Under 13'))),
              DropdownMenuItem(value:'teen',child:Text(s.t('من 13 إلى 17 سنة','13 to 17'))),
              DropdownMenuItem(value:'adult',child:Text(s.t('18 سنة فأكثر','18 or older'))),
            ],onChanged:(x){if(x!=null)setState(()=>age=x);}),
        ])),
        const SizedBox(height:12),
        if(age=='adult') CheckboxListTile(
          value:analyticsAllowed,
          onChanged:(v)=>setState(()=>analyticsAllowed=v??false),
          title:Text(s.t('أوافق على إحصاءات أجهزة مجهولة','Allow anonymous device analytics')),
          subtitle:Text(s.t('اختياري: نوع الجهاز وإصدار التطبيق والدولة التقريبية، بدون اسمك أو صورك.',
            'Optional: device platform, version and approximate country; never your name or files.')),
        ),
        TextButton.icon(onPressed:()=>launchUrl(Uri.https('sclpdf.50sols.com','/privacy',{'lang':widget.store.settings.english?'en':'ar'}),mode:LaunchMode.externalApplication),
          icon:const Icon(Icons.privacy_tip_outlined),label:Text(s.t('سياسة الخصوصية','Privacy policy'))),
        const SizedBox(height:18),
        InfoBanner(text:s.t('صورك وملفات PDF تظل على جهازك. لا يلزم إنشاء حساب.',
          'Photos and PDFs stay on your device. No account is required.'),
          icon:Icons.verified_user_outlined),
        const SizedBox(height:24),FilledButton(onPressed:_continue,
          child:Text(s.t('التالي','Continue'))),
      ]else...[
        const SizedBox(height:10),const Icon(Icons.notifications_active_outlined,
          size:90,color:Brand.blue),const SizedBox(height:16),
        InfoBanner(text:s.t('فعّل إشعارات الجهاز لتصلك تنبيهات اكتمال PDF وتذكيرات الدراسة. يمكنك استخدام أدوات PDF حتى إذا رفضت الإذن.',
          'Enable device notifications for completed PDFs and study reminders. PDF tools work even if you decline.'),
          icon:Icons.notifications_none),
        const SizedBox(height:25),FilledButton.icon(onPressed:busy?null:()=>_finish(request:true),
          icon:const Icon(Icons.notifications_active),label:Text(s.t('تفعيل الإشعارات','Enable notifications'))),
        const SizedBox(height:12),TextButton(onPressed:busy?null:()=>_finish(request:false),
          child:Text(s.t('ليس الآن — متابعة للتطبيق','Not now — continue to app'))),
      ],
    ])));
  }
}
