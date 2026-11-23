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
      Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 9, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0E70F0), Color(0xFF10338F)]),
          boxShadow: const [BoxShadow(color: Color(0x55345AB6),
            blurRadius: 16, offset: Offset(0, 8))]),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.t('أهلًا، ' + u.name.split(' ').first + ' 👋',
                'Hello, ' + u.name.split(' ').first + ' 👋'),
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 22,
                  fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 6),
              Text(s.grade(u.level) + ' • ' + u.schoolClass,
                style: const TextStyle(color: Color(0xFFDCEAFF),
                  fontSize: 12)),
              const SizedBox(height: 15),
              Text(s.t('واجبك جاهز في دقائق!',
                'Homework ready in minutes!'),
                style: const TextStyle(color: Colors.white,
                  fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(s.t('صوّر • حسّن • احفظ PDF',
                'Capture • Enhance • Save PDF'),
                style: const TextStyle(color: Color(0xFFE3F7FF),
                  fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          )),
          Image.asset('assets/branding/home_promo.webp',
            key: const Key('home-promo-image'),
            width: 127, height: 151, fit: BoxFit.contain),
        ]),
      ),
      const SizedBox(height: 20),
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text(s.subject, style: const TextStyle(color: Brand.navy,
          fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(width: 8),
        if (selectedSubject == null)
          Expanded(child: Text(s.t(
            'من فضلك اختر المادة لتستطيع تجهيز الواجب أو الملف',
            'Please select a subject to prepare your homework or file'),
            key: const Key('subject-required-warning'),
            style: const TextStyle(color: Color(0xFFCB2438),
              fontSize: 12, fontWeight: FontWeight.w900))),
      ]),
      const SizedBox(height: 10),
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
  const _LaunchCard({required this.icon, required this.label,
    required this.active, required this.gradient, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override Widget build(BuildContext context) {
    return Opacity(
      opacity: active ? 1 : .55,
      child: SizedBox(height: 162, child: Stack(children: [
        Positioned.fill(top: 9, child: DecoratedBox(
          decoration: BoxDecoration(color: gradient.last.withValues(alpha: .9),
            borderRadius: BorderRadius.circular(22)))),
        Positioned.fill(bottom: 7,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: gradient),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x88FFFFFF), width: 1.2),
              boxShadow: const [BoxShadow(color: Color(0x330A39A3),
                blurRadius: 10, offset: Offset(0, 6))]),
            child: Material(color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: active ? onTap : null,
                child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 67, height: 67,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Color(0xCCFFFFFF), Color(0x22FFFFFF)]),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(color: const Color(0x99FFFFFF)),
                        boxShadow: const [BoxShadow(color: Color(0x44051C64),
                          blurRadius: 7, offset: Offset(2, 5))]),
                      child: Icon(icon, size: 38, color: Colors.white,
                        shadows: const [Shadow(color: Color(0x88002980),
                          blurRadius: 3, offset: Offset(2, 3))])),
                    const SizedBox(height: 12),
                    Text(label, textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white,
                        fontSize: 13, fontWeight: FontWeight.w900)),
                  ]),
              )),
          )),
      ])),
    );
  }
}
