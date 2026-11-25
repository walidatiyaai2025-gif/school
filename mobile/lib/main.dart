import 'dart:async';
import 'package:flutter/material.dart';
import 'services/incoming_documents.dart';
import 'screens/incoming_document_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/history_screen.dart';
import 'widgets/language_toggle.dart';
import 'core/brand.dart';
import 'core/strings.dart';
import 'data/app_store.dart';
import 'services/notifications_service.dart';
import 'services/pdf_service.dart';
import 'screens/onboarding.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/play_screen.dart';
import 'services/ads_service.dart';
import 'widgets/footer_3d_icon.dart';
import 'services/telemetry_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store=await AppStore.load();
  // Optional privacy cleanup must not prevent the offline app from launching.
  // A failed deletion stays queued and is retried on a later launch.
  try {
    await TelemetryService.purgePending();
  } catch (error) {
    debugPrint('Deferred optional privacy cleanup: ${error.runtimeType}');
  }
  final notifications=NotificationService();
  try { await notifications.initialize(); await notifications.refreshPermissionStatus(); }
  catch (_) { /* Offline scanning must work even when notification init fails. */ }
  runApp(SchoolPdfApp(store:store,notifications:notifications));
}

class SchoolPdfApp extends StatefulWidget {
  const SchoolPdfApp({super.key,required this.store,required this.notifications});
  final AppStore store;
  final NotificationService notifications;
  @override State<SchoolPdfApp> createState()=>_SchoolPdfAppState();
}
class _SchoolPdfAppState extends State<SchoolPdfApp> with WidgetsBindingObserver {
  int tab=0;
  bool _overlayFlowOpen = false;
  StreamSubscription<String>? incomingSubscription;
  String? pendingIncoming;
  void openIncoming(String path) {
    if (!mounted) return;
    if (!widget.store.settings.ready) { pendingIncoming = path; return; }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) navKey.currentState?.push(MaterialPageRoute<void>(
        builder: (_) => IncomingDocumentScreen(
          path: path, english: widget.store.settings.english)));
    });
  }
  final navKey=GlobalKey<NavigatorState>();
  @override void initState(){
    super.initState();WidgetsBinding.instance.addObserver(this);
    widget.store.addListener(_updated);
    incomingSubscription = IncomingDocuments.events.stream.listen(openIncoming);
    IncomingDocuments.initialize().then((path) {
      if (path != null) openIncoming(path);
    }).catchError((Object _) {});
    widget.notifications.onTokenRefresh=(_) {TelemetryService.sync(widget.store,widget.notifications);};
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TelemetryService.sync(widget.store, widget.notifications);
      if (!widget.store.settings.ready) return;
      final initialId = widget.notifications.initialDocumentId;
      if (initialId != null) {
        widget.notifications.initialDocumentId = null;
        widget.notifications.onTap?.call(initialId);
      }
    });
    widget.notifications.onTap=(id){
      if(!mounted)return;
      setState(()=>tab=1);
      if(id!=null && widget.store.records.any((r)=>r.id==id)) {
        navKey.currentState?.push(MaterialPageRoute<void>(builder:(_)=>
          PdfDetailScreen(store:widget.store,recordId:id)));
      }
    };
  }
  void _updated(){
    if (!mounted) return;
    setState(() {});
    if (widget.store.settings.ready && pendingIncoming != null) {
      final path = pendingIncoming!;
      pendingIncoming = null;
      openIncoming(path);
    }
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state){
    if(state==AppLifecycleState.resumed){
      widget.notifications.refreshPermissionStatus().then((_) {
        TelemetryService.sync(widget.store,widget.notifications);
        if(mounted)setState((){});
      }).catchError((Object _){});
    }
  }
  @override void dispose(){incomingSubscription?.cancel();widget.store.removeListener(_updated);
    WidgetsBinding.instance.removeObserver(this);super.dispose();}
  @override Widget build(BuildContext context){
    final store=widget.store, s=S(store.settings.english);
    return MaterialApp(
      title:'School PDF',debugShowCheckedModeBanner:false,
      navigatorKey:navKey,
      locale:Locale(store.settings.english?'en':'ar'),
      supportedLocales:const [Locale('ar'),Locale('en')],
      localizationsDelegates:const [GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,GlobalCupertinoLocalizations.delegate],
      theme:Brand.theme,
      home:Directionality(textDirection:store.settings.english?TextDirection.ltr:TextDirection.rtl,
        child:store.settings.ready?_main(s):OnboardingScreen(
          store:store,notifications:widget.notifications)),
    );
  }
  Widget _main(S s){
    final screens=<Widget>[
      HomeScreen(store:widget.store,scanner:ScanEngine(),notifications:widget.notifications,
        onGoFiles:()=>setState(()=>tab=1),
        onCaptureFlowChanged:(active) {
          if (mounted) setState(() => _overlayFlowOpen = active);
        }),
      HistoryScreen(store:widget.store),
      PlayScreen(store:widget.store,
        onGameVisibilityChanged:(active) {
          if (mounted) setState(() => _overlayFlowOpen = active);
        }),
      SettingsScreen(store:widget.store,notifications:widget.notifications),
    ];
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('School PDF'),
        actions: [LanguageToggle(store: widget.store, notifications: widget.notifications)],
      ),
      body:SafeArea(bottom:false,child:IndexedStack(index:tab,children:screens)),
      bottomNavigationBar:Column(mainAxisSize:MainAxisSize.min,children:[
        NavigationBar(height:76,backgroundColor:Colors.white,
          indicatorColor:const Color(0xFFE5EFFF),
          selectedIndex:tab,onDestinationSelected:(index)=>setState(()=>tab=index),
          destinations:[
            NavigationDestination(icon:const Footer3DIcon(icon:Icons.home_outlined),
              selectedIcon:const Footer3DIcon(icon:Icons.home_rounded,selected:true),label:s.home),
            NavigationDestination(icon:const Footer3DIcon(icon:Icons.folder_copy_outlined),
              selectedIcon:const Footer3DIcon(icon:Icons.folder_copy,selected:true),label:s.files),
            NavigationDestination(icon:const Footer3DIcon(icon:Icons.sports_esports_outlined),
              selectedIcon:const Footer3DIcon(icon:Icons.sports_esports_rounded,selected:true),label:s.play),
            NavigationDestination(icon:const Footer3DIcon(icon:Icons.settings_outlined),
              selectedIcon:const Footer3DIcon(icon:Icons.settings,selected:true),label:s.settings),
          ]),
        if(!_overlayFlowOpen && (tab==0 || tab==1 || tab==2))
          SchoolBanner(store:widget.store),
      ]),
    );
  }
}
