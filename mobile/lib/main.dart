import 'package:flutter/material.dart';
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
import 'services/ads_service.dart';
import 'services/telemetry_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store=await AppStore.load();
  await TelemetryService.purgePending();
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
  final navKey=GlobalKey<NavigatorState>();
  @override void initState(){
    super.initState();WidgetsBinding.instance.addObserver(this);
    widget.store.addListener(_updated);
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
  void _updated(){if(mounted)setState((){});}
  @override void didChangeAppLifecycleState(AppLifecycleState state){
    if(state==AppLifecycleState.resumed){
      widget.notifications.refreshPermissionStatus().then((_) {
        TelemetryService.sync(widget.store,widget.notifications);
        if(mounted)setState((){});
      }).catchError((Object _){});
    }
  }
  @override void dispose(){widget.store.removeListener(_updated);
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
        onGoFiles:()=>setState(()=>tab=1)),
      HistoryScreen(store:widget.store),
      SettingsScreen(store:widget.store,notifications:widget.notifications),
    ];
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('School PDF'),
        actions: [LanguageToggle(store: widget.store)],
      ),
      body:SafeArea(bottom:false,child:IndexedStack(index:tab,children:screens)),
      bottomNavigationBar:Column(mainAxisSize:MainAxisSize.min,children:[
        if(tab==0 || tab==1)SchoolBanner(store:widget.store),
        NavigationBar(height:70,backgroundColor:Colors.white,
          indicatorColor:const Color(0xFFE5EFFF),
          selectedIndex:tab,onDestinationSelected:(index)=>setState(()=>tab=index),
          destinations:[
            NavigationDestination(icon:const Icon(Icons.home_outlined),
              selectedIcon:const Icon(Icons.home_rounded),label:s.home),
            NavigationDestination(icon:const Icon(Icons.folder_copy_outlined),
              selectedIcon:const Icon(Icons.folder_copy),label:s.files),
            NavigationDestination(icon:const Icon(Icons.settings_outlined),
              selectedIcon:const Icon(Icons.settings),label:s.settings),
          ]),
      ]),
    );
  }
}
