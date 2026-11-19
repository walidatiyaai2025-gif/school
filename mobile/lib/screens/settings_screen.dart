import 'package:flutter/material.dart';
import '../core/brand.dart';
import '../core/strings.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../services/notifications_service.dart';
import '../widgets/brand_widgets.dart';
import '../services/telemetry_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key,required this.store,required this.notifications});
  final AppStore store;final NotificationService notifications;
  @override State<SettingsScreen> createState()=>_SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController name=TextEditingController(text:widget.store.settings.name);
  late final TextEditingController group=TextEditingController(text:widget.store.settings.schoolClass);
  @override void dispose(){name.dispose();group.dispose();super.dispose();}
  Future<void> _save() async {
    if(name.text.trim().isEmpty||group.text.trim().isEmpty){
      feedback(context,'الاسم والفصل مطلوبان');return;
    }
    widget.store.settings..name=name.text.trim()..schoolClass=group.text.trim();
    await widget.store.saveSettings();
    if(mounted)feedback(context,S(widget.store.settings.english).t('تم حفظ الإعدادات','Settings saved'));
  }
  Future<void> _notificationPermission()async{
    try{
      final ok=await widget.notifications.requestPermission();
      if(ok) TelemetryService.sync(widget.store,widget.notifications);
      if(mounted){setState((){});feedback(context,ok?'الإشعارات مفعّلة':'لم يُمنح الإذن. راجع إعدادات الهاتف.');}
    }catch(e){if(mounted)feedback(context,'تعذر طلب الإذن: $e');}
  }
  Future<void> _syncReminders()async{
    try{
      await widget.notifications.configureReminder(
        enabled:widget.store.settings.notifyReminders,
        time:widget.store.settings.reminderTime);
    }catch(e){if(mounted)feedback(context,'تعذر جدولة التذكير: $e');}
  }
  TimeOfDay get _reminderTime {
    final parts = widget.store.settings.reminderTime.split(':');
    final hour = int.tryParse(parts.first) ?? 18;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  Future<void> _chooseReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (time == null) return;
    widget.store.settings.reminderTime =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await widget.store.saveSettings();
    await _syncReminders();
    if (mounted) setState(() {});
  }

  Future<void> _addSubject() async {
    // Read the value directly, avoiding disposing a TextEditingController
    // while Flutter's dialog exit animation still owns its TextField.
    var entered = '';
    final strings = S(widget.store.settings.english);
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.t('أضف مادة', 'Add subject')),
        content: TextField(
          autofocus: true,
          maxLength: 60,
          onChanged: (value) => entered = value,
          decoration: InputDecoration(
            hintText: strings.t('مثلاً: رياضيات متقدمة', 'E.g. Advanced Mathematics'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, entered.trim()),
            child: Text(strings.add),
          ),
        ],
      ),
    );
    if (selected == null || selected.isEmpty) return;
    final base = schoolSubjects[widget.store.settings.level] ?? const <String>[];
    if (base.contains(selected) ||
        base.any((v) => S(true).subjectName(v).toLowerCase() == selected.toLowerCase()) ||
        widget.store.settings.customSubjects.any(
            (v) => v.toLowerCase() == selected.toLowerCase())) {
      if (mounted) feedback(context, strings.t('المادة موجودة بالفعل', 'Subject already exists'));
      return;
    }
    widget.store.settings.customSubjects.add(selected);
    await widget.store.saveSettings();
    if (mounted) setState(() {});
  }
  @override Widget build(BuildContext context){
    final s=S(widget.store.settings.english),u=widget.store.settings;
    return ListView(padding:const EdgeInsets.fromLTRB(17,18,17,30),children:[
      Row(children:[const Icon(Icons.settings_rounded,color:Brand.blue,size:31),
        const SizedBox(width:9),Text(s.settings,style:const TextStyle(
          color:Brand.navy,fontWeight:FontWeight.w900,fontSize:27))]),
      const SizedBox(height:17),SectionHeader(s.t('بيانات الطالب','Student information')),
      WhitePanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(s.name,style:const TextStyle(fontWeight:FontWeight.w700)),
        const SizedBox(height:8),TextField(controller:name),
        const SizedBox(height:14),Text(s.level,
          style:const TextStyle(fontWeight:FontWeight.w700)),
        const SizedBox(height:8),DropdownButtonFormField<String>(
          initialValue:u.level,isExpanded:true,
          items:['primary','middle','secondary','university','other'].map((x)=>DropdownMenuItem(
            value:x,child:Text(s.grade(x)))).toList(),
          onChanged:(v)async{if(v!=null){u.level=v;await widget.store.saveSettings();setState((){});}}),
        const SizedBox(height:14),Text(s.className,
          style:const TextStyle(fontWeight:FontWeight.w700)),
        const SizedBox(height:8),TextField(controller:group),
        const SizedBox(height:16),FilledButton(onPressed:_save,child:Text(s.t('حفظ البيانات','Save profile'))),
      ])),
      const SizedBox(height:20),SectionHeader(s.t('المواد الدراسية','Subjects'),
        action:TextButton.icon(onPressed:_addSubject,icon:const Icon(Icons.add),
          label:Text(s.t('إضافة مادة','Add')))),
      WhitePanel(child:Column(children:[
        Text(s.t('المواد الإضافية فقط يمكن حذفها. المواد المدرسية الافتراضية محفوظة.',
          'Custom subjects can be removed; standard subjects are built in.'),
          style:const TextStyle(color:Brand.muted,fontSize:12)),
        ...u.customSubjects.map((item)=>ListTile(
          contentPadding:EdgeInsets.zero,title:Text(item),
          trailing:IconButton(icon:const Icon(Icons.close_rounded,color:Colors.redAccent),
            onPressed:()async{u.customSubjects.remove(item);
              await widget.store.saveSettings();if(mounted)setState((){});}))),
      ])),
      const SizedBox(height:20),SectionHeader(s.t('خيارات PDF','PDF options')),
      WhitePanel(child:Column(children:[
        SwitchListTile.adaptive(value:u.pdfHeader,
          title:Text(s.t('إظهار البيانات داخل PDF','Student details inside PDF')),
          subtitle:Text(s.t('في رأس الصفحة الأولى فقط','Header on first page only')),
          onChanged:(v)async{u.pdfHeader=v;await widget.store.saveSettings();setState((){});}),
        const Divider(),
        DropdownButtonFormField<String>(initialValue:u.pdfQuality,
          decoration:InputDecoration(labelText:s.t('جودة صور PDF','PDF image quality')),
          items:[DropdownMenuItem(value:'small',child:Text(s.t('حجم أصغر','Smaller file'))),
            DropdownMenuItem(value:'balanced',child:Text(s.t('متوازنة','Balanced'))),
            DropdownMenuItem(value:'high',child:Text(s.t('عالية','High quality')))],
          onChanged:(value)async{if(value!=null){u.pdfQuality=value;
            await widget.store.saveSettings();setState((){});}}),
        const SizedBox(height:12),
        InfoBanner(text:s.t('ملفات History القديمة لا تتغير عند تعديل الإعدادات.',
          'Changing settings does not modify previous PDFs.')),
      ])),
      const SizedBox(height:20),SectionHeader(s.t('الإشعارات','Notifications')),
      WhitePanel(child:Column(children:[
        Row(children:[Icon(widget.notifications.permissionGranted
          ?Icons.notifications_active_rounded:Icons.notifications_off_outlined,
          color:widget.notifications.permissionGranted?Brand.green:Brand.muted),
          const SizedBox(width:8),Expanded(child:Text(widget.notifications.permissionGranted
            ?s.t('إشعارات الهاتف مفعلة','Device notifications on')
            :s.t('إشعارات الهاتف غير مفعلة','Device notifications off')))]),
        if(!widget.notifications.permissionGranted)...[
          const SizedBox(height:12),OutlinedButton.icon(
            onPressed:_notificationPermission,icon:const Icon(Icons.notifications_active_outlined),
            label:Text(s.t('طلب تفعيل الإشعارات','Enable notifications'))),
          Text(s.t('إذا رفضت الإذن سابقًا، يمكنك تفعيله من إعدادات نظام الهاتف.',
            'If previously denied, enable permission in device settings.'),
            style:const TextStyle(fontSize:11,color:Brand.muted)),
        ],
        const Divider(height:22),
        SwitchListTile.adaptive(value:u.notifyReady,
          title:Text(s.t('ملف PDF جاهز','PDF ready alerts')),
          onChanged:(v)async{u.notifyReady=v;await widget.store.saveSettings();setState((){});}),
        SwitchListTile.adaptive(value:u.notifyReminders,
          title:Text(s.t('تذكير يومي للمذاكرة','Daily study reminder')),
          onChanged:widget.notifications.permissionGranted?(v)async{
            u.notifyReminders=v;await widget.store.saveSettings();await _syncReminders();
            setState((){});
          }:null),
        if(u.notifyReminders)ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.schedule_outlined),
          title: Text(s.t('وقت التذكير', 'Reminder time')),
          subtitle: Text(MaterialLocalizations.of(context).formatTimeOfDay(
            _reminderTime, alwaysUse24HourFormat: false)),
          trailing: const Icon(Icons.edit_calendar_outlined),
          onTap: _chooseReminderTime,
        ),
        SwitchListTile.adaptive(value:u.notifyUpdates,
          title:Text(s.t('أخبار الخدمة المهمة','Important service updates')),
          onChanged:(v)async{u.notifyUpdates=v;await widget.store.saveSettings();setState((){});}),
        const SizedBox(height:7),Text(s.t('الإشعارات التي تتطلب إذن النظام لا تعمل دون الموافقة. جميع أدوات PDF ستظل متاحة.',
          'Permission-dependent notifications are unavailable without approval. PDF tools remain available.'),
          style:const TextStyle(fontSize:11,color:Brand.muted)),
      ])),
      const SizedBox(height:20),SectionHeader(s.t('اللغة والخصوصية','Language & privacy')),
      WhitePanel(child:Column(children:[
        SwitchListTile.adaptive(value:u.english,
          title:Text(s.t('عرض التطبيق بالإنجليزية','Use English interface')),
          onChanged:(v)async{u.english=v;await widget.store.saveSettings();setState((){});}),
        const Divider(),
        ListTile(title:Text(s.t('الفئة العمرية','Age group')),
          subtitle:Text(s.t('لا نستخدم اسمك أو ملفاتك لاستهداف الإعلانات.',
            'We do not use your name or PDFs for ad targeting.')),
          trailing:DropdownButton<String>(value:u.ageGroup,items:[
            DropdownMenuItem(value:'unknown',child:Text(s.t('غير محددة','Unknown'))),
            DropdownMenuItem(value:'child',child:Text(s.t('أقل من 13','Under 13'))),
            DropdownMenuItem(value:'teen',child:Text(s.t('13-17','13-17'))),
            DropdownMenuItem(value:'adult',child:Text(s.t('18+','18+'))),
          ],onChanged:(v)async{if(v!=null){u.ageGroup=v;
            if(v!='adult') {u.analyticsConsent=false;await TelemetryService.unregister();}
            await widget.store.saveSettings();setState((){});}})),
        if(u.ageGroup=='adult') SwitchListTile.adaptive(
          value:u.analyticsConsent,
          title:Text(s.t('إحصاءات أجهزة مجهولة','Anonymous install analytics')),
          subtitle:Text(s.t('عدد الأجهزة والدولة التقريبية فقط؛ اختياري','Approximate country and device counts; optional')),
          onChanged:(v)async{u.analyticsConsent=v;await widget.store.saveSettings();
            if(v){await TelemetryService.sync(widget.store,widget.notifications);}
            else {await TelemetryService.unregister();} if(mounted)setState((){});}),
        ListTile(leading:const Icon(Icons.privacy_tip_outlined),
          title:Text(s.t('سياسة الخصوصية','Privacy policy')),
          onTap:()=>launchUrl(Uri.parse('https://sclpdf.50sols.com/privacy'),mode:LaunchMode.externalApplication)),
        ListTile(leading:const Icon(Icons.delete_outline),
          title:Text(s.t('حذف سجل الجهاز من الخادم','Delete server device record')),
          subtitle:Text(s.t('لا يحذف ملفات PDF من جهازك','Does not delete local PDFs')),
          onTap:()async{u.analyticsConsent=false;await widget.store.saveSettings();
            final deleted=await TelemetryService.unregister();if(mounted){setState((){});feedback(context,deleted?s.t('تم حذف سجل هذا الجهاز','Device record deleted'):s.t('لم يتصل بالخادم؛ سيتم إعادة محاولة الحذف عند التشغيل','Deletion pending; will retry on next launch'));}}),
        InfoBanner(text:s.t('الصور والملفات محفوظة محليًا. حذف التطبيق قد يحذف الملفات التي لم تحفظ نسخة منها.',
          'Scans stay locally on your device. Unexported files can be lost on uninstall.'),
          icon:Icons.shield_outlined),
      ])),
      const SizedBox(height:15),const Center(child:Text('School PDF 1.1.1',
        style:TextStyle(color:Brand.muted,fontSize:11))),
    ]);
  }
}
