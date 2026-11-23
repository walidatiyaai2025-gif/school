import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/brand.dart';
import '../core/strings.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../services/pdf_service.dart';
import '../services/notifications_service.dart';
import '../services/sharing_service.dart';
import '../widgets/brand_widgets.dart';
import 'review_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key,required this.store,required this.scanner,
    required this.notifications,required this.onGoFiles,
    this.onCaptureFlowChanged});
  final AppStore store;final ScanEngine scanner;
  final NotificationService notifications;final VoidCallback onGoFiles;
  final ValueChanged<bool>? onCaptureFlowChanged;
  @override State<HomeScreen> createState()=>_HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  String? selectedSubject;bool picking=false;
  final picker=ImagePicker();
  @override void initState(){super.initState();_recoverPicker();}
  Future<void> _recoverPicker() async {
    // Android may reclaim this process while the external picker is open.
    // The chosen subject is persisted so recovered images remain usable.
    try {
      final lost = await picker.retrieveLostData();
      if (!mounted) return;
      if (lost.files?.isNotEmpty == true) {
        final subject = selectedSubject ?? widget.store.pendingCaptureSubject;
        if (subject == null || subject.isEmpty) {
          feedback(context, S(widget.store.settings.english).t(
            'تم استرجاع صور؛ اختر المادة ثم أعد تحديدها',
            'Photos were recovered; select a subject and choose them again.'));
        } else {
          setState(() => selectedSubject = subject);
          widget.onCaptureFlowChanged?.call(true);
          try {
            await _openReview(lost.files!, subject);
          } finally {
            widget.onCaptureFlowChanged?.call(false);
          }
        }
      }
    } catch (_) {
      // A failed restore must not block creating a new PDF.
    } finally {
      await widget.store.clearPendingCaptureSubject();
    }
  }

  Future<void> _pick(bool camera) async {
    final subject = selectedSubject;
    if (subject == null || picking) return;
    setState(() => picking = true);
    widget.onCaptureFlowChanged?.call(true);
    try {
      await widget.store.rememberCaptureSubject(subject);
      // Dispose banner platform views before launching the external camera.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final List<XFile> photos;
      if (camera) {
        final shot = await picker.pickImage(
          source: ImageSource.camera, imageQuality: 88, maxWidth: 2400);
        photos = shot == null ? <XFile>[] : <XFile>[shot];
      } else {
        photos = await picker.pickMultiImage(
          imageQuality: 88, maxWidth: 2400);
      }
      if (photos.isNotEmpty && mounted) await _openReview(photos, subject);
    } catch (_) {
      if (mounted) {
        feedback(context, S(widget.store.settings.english).t(
          'تعذر الوصول للصور أو الكاميرا. راجع الأذونات وحاول مجددًا.',
          'Could not access photos or camera. Check permissions and try again.'));
      }
    } finally {
      await widget.store.clearPendingCaptureSubject();
      if (mounted) setState(() => picking = false);
      widget.onCaptureFlowChanged?.call(false);
    }
  }

  Future<void> _openReview(List<XFile> files, String subject) async {
    if (!mounted) return;
    await Navigator.push<void>(context, MaterialPageRoute<void>(
      builder: (_) => ReviewScreen(
        store: widget.store, scanner: widget.scanner,
        notifications: widget.notifications,
        subject: subject,
        images: files.map((x) => ScanPage(x.path)).toList())));
  }

  @override Widget build(BuildContext context){
    final s=S(widget.store.settings.english), u=widget.store.settings;
    final subjects=<String>{
      ...(schoolSubjects[u.level]??const <String>[]),
      ...u.customSubjects,
    }.toList();
    final latest=widget.store.records.isEmpty?null:widget.store.records.first;
    return ListView(padding:const EdgeInsets.fromLTRB(20,16,20,24),children:[
      Row(children:[const Logo(size:46),const SizedBox(width:10),
        const Expanded(child:Text('School PDF',style:TextStyle(color:Brand.navy,
          fontSize:21,fontWeight:FontWeight.w900))),
        IconButton(onPressed:widget.onGoFiles,icon:const Icon(Icons.folder_open_rounded,
          color:Brand.blue))]),
      const SizedBox(height:18),
      Container(padding:const EdgeInsets.all(22),
        decoration:BoxDecoration(borderRadius:BorderRadius.circular(26),
          gradient:const LinearGradient(begin:Alignment.topRight,end:Alignment.bottomLeft,
            colors:[Color(0xFF095BE8),Color(0xFF072D88)])),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(s.t('أهلًا، ${u.name.split(' ').first} 👋','Hello, ${u.name.split(' ').first} 👋'),
            style:const TextStyle(fontSize:25,fontWeight:FontWeight.w800,color:Colors.white)),
          const SizedBox(height:7),
          Text('${s.grade(u.level)} • ${u.schoolClass}',
            style:const TextStyle(color:Color(0xFFD9E8FF),fontSize:13)),
          const SizedBox(height:24),
          Row(children:[const Icon(Icons.auto_awesome,color:Brand.aqua),const SizedBox(width:9),
            Expanded(child:Text(s.t('حوّل صور واجبك إلى PDF واضح ومرتب.',
              'Turn homework photos into a clean, organized PDF.'),
              style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700,height:1.5)))]),
        ])),
      const SizedBox(height:24),SectionHeader(s.subject),
      DropdownButtonFormField<String>(initialValue:subjects.contains(selectedSubject)?selectedSubject:null,
        isExpanded:true,hint:Text(s.t('اختر المادة أولًا','Choose a subject first')),
        items:subjects.map((x)=>DropdownMenuItem(value:x,child:Text(s.subjectName(x),overflow:TextOverflow.ellipsis))).toList(),
        onChanged:(value)=>setState(()=>selectedSubject=value)),
      const SizedBox(height:20),
      Row(children:[
        Expanded(child:_LaunchCard(icon:Icons.camera_alt_rounded,
          label:s.camera,active:selectedSubject!=null&&!picking,
          gradient:const [Color(0xFF0966F5),Color(0xFF043FB8)],
          onTap:()=>_pick(true))),
        const SizedBox(width:12),
        Expanded(child:_LaunchCard(icon:Icons.photo_library_rounded,
          label:s.gallery,active:selectedSubject!=null&&!picking,
          gradient:const [Color(0xFF6854F6),Color(0xFF4329BF)],
          onTap:()=>_pick(false))),
      ]),
      if(picking)...[const SizedBox(height:18),const Center(child:CircularProgressIndicator())],
      const SizedBox(height:16),
      InfoBanner(text:s.t('بعد اختيار الصور، يمكنك تعديل زوايا الورقة وقص الخلفية وتحسين الوضوح قبل إنشاء PDF.',
        'Adjust paper corners, remove the background and enhance text before saving your PDF.'),
        icon:Icons.crop_rotate_rounded),
      const SizedBox(height:24),
      SectionHeader(s.t('آخر الملفات','Recent files'),action:TextButton(
        onPressed:widget.onGoFiles,child:Text(s.t('عرض الكل','See all')))),
      if(latest==null) WhitePanel(child:Center(child:Padding(
        padding:const EdgeInsets.all(10),child:Text(s.noFiles,
          style:const TextStyle(color:Brand.muted)))))
      else WhitePanel(child:Row(children:[
        const Icon(Icons.picture_as_pdf_rounded,color:Color(0xFFE33444),size:37),
        const SizedBox(width:12),Expanded(child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(latest.filename,maxLines:2,overflow:TextOverflow.ellipsis,
              style:const TextStyle(fontWeight:FontWeight.w700,color:Brand.navy)),
            Text('${latest.pageCount} ${s.pages} • ${s.subjectName(latest.subject)}',
              style:const TextStyle(fontSize:12,color:Brand.muted)),
          ])),IconButton(icon:const Icon(Icons.share_outlined,color:Brand.blue),
          onPressed:()=>SharingService(widget.store).share(latest,context).catchError(
            (Object _){if(context.mounted)feedback(context,S(widget.store.settings.english).t('تعذرت مشاركة الملف. حاول مرة أخرى.','Could not share the PDF. Please try again.'));})),
      ])),
    ]);
  }
}
class _LaunchCard extends StatelessWidget {
  const _LaunchCard({required this.icon,required this.label,
    required this.active,required this.gradient,required this.onTap});
  final IconData icon;final String label;final bool active;
  final List<Color> gradient;final VoidCallback onTap;
  @override Widget build(BuildContext context)=>Opacity(opacity:active?1:.5,
    child:Material(color:Colors.transparent,child:InkWell(onTap:active?onTap:null,
      borderRadius:BorderRadius.circular(20),child:Ink(
        height:155,decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),
          gradient:LinearGradient(colors:gradient)),
        child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
          Icon(icon,size:47,color:Colors.white),const SizedBox(height:14),
          Padding(padding:const EdgeInsets.symmetric(horizontal:8),child:Text(label,
            textAlign:TextAlign.center,style:const TextStyle(color:Colors.white,
              fontWeight:FontWeight.w800,fontSize:14))),
        ])))));
}
