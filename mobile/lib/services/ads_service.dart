import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../data/app_store.dart';

/// AdMob mediation-ready adapter boundary. Does not send student data for targeting.
/// Production ads stay OFF until a compliant CMP and certified mediation adapters
/// are configured. Unknown ages and minors never receive advertising in this build.
class SchoolBanner extends StatefulWidget {
  const SchoolBanner({super.key,required this.store});
  final AppStore store;
  @override State<SchoolBanner> createState()=>_SchoolBannerState();
}
class _SchoolBannerState extends State<SchoolBanner> {
  BannerAd? _ad;
  bool _loaded=false;
  bool _remoteEnabled=false;
  String _remoteBannerId='';
  static const remoteApi = String.fromEnvironment('SCHOOLPDF_API_BASE',defaultValue:'https://sclpdf.50sols.com/api');
  static const testAds=bool.fromEnvironment('SCHOOLPDF_TEST_ADS',defaultValue:false);
  static const productionAds=bool.fromEnvironment('SCHOOLPDF_PRODUCTION_ADS',defaultValue:false);
  static const consentReviewed=bool.fromEnvironment('SCHOOLPDF_PRIVACY_CMP_REVIEWED',defaultValue:false);
  static const androidId=String.fromEnvironment('ADMOB_ANDROID_BANNER_ID');
  static const iosId=String.fromEnvironment('ADMOB_IOS_BANNER_ID');
  bool get _eligible => widget.store.settings.ageGroup=='adult' &&
      (testAds || (productionAds && consentReviewed &&
      (_remoteBannerId.isNotEmpty || (Platform.isAndroid?androidId:iosId).isNotEmpty) && _remoteEnabled));
  @override void initState(){super.initState();widget.store.addListener(_sync);_sync();_loadRemote();}
  Future<void> _loadRemote() async {
    if(!productionAds || !consentReviewed || widget.store.settings.ageGroup!='adult')return;
    final uri=Uri.parse('$remoteApi/v1/config');
    if(uri.scheme!='https')return;
    final client=HttpClient()..connectionTimeout=const Duration(seconds:5);
    try {
      final req=await client.getUrl(uri).timeout(const Duration(seconds:6));
      final res=await req.close().timeout(const Duration(seconds:8));
      if(res.statusCode!=200)return;
      final payload=jsonDecode(await utf8.decoder.bind(res).join()) as Map<String,dynamic>;
      final ads=payload['ads'];if(ads is! Map || ads['enabled']!=true)return;
      final records=ads['providers'];if(records is! List)return;
      for(final record in records){
        if(record is Map && record['provider']=='admob' &&
            record['platform']==(Platform.isAndroid?'android':'ios')) {
          final id=record['banner_unit_id'];
          if(id is String && RegExp(r'^ca-app-pub-[0-9]+/[0-9]+$').hasMatch(id)) {
            _remoteBannerId=id; _remoteEnabled=true;
            if(mounted)_sync();
          }
        }
      }
    } catch (_) { /* No network must never affect conversion. */ }
    finally {client.close(force:true);}
  }
  void _sync(){
    if(!_eligible){_ad?.dispose();_ad=null;_loaded=false;if(mounted)setState((){});return;}
    if(_ad!=null)return;
    _load();
  }
  Future<void> _load() async {
    try {
      await MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
        maxAdContentRating:MaxAdContentRating.g));
      await MobileAds.instance.initialize();
      final ad=BannerAd(size:AdSize.banner,
        adUnitId:testAds?(Platform.isAndroid
          ?'ca-app-pub-3940256099942544/6300978111'
          :'ca-app-pub-3940256099942544/2934735716'):
          (_remoteBannerId.isNotEmpty?_remoteBannerId:(Platform.isAndroid?androidId:iosId)),
        request:const AdRequest(nonPersonalizedAds:true),
        listener:BannerAdListener(
          onAdLoaded:(ad){if(mounted)setState(()=>_loaded=true);},
          onAdFailedToLoad:(ad,error){ad.dispose();if(mounted)setState(()=>_loaded=false);},
        ));
      _ad=ad;await ad.load();
    } catch (_) {if(mounted)setState(()=>_loaded=false);}
  }
  @override void dispose(){widget.store.removeListener(_sync);_ad?.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    final ad=_ad;
    if(!_eligible || !_loaded || ad==null)return const SizedBox.shrink();
    return Semantics(label:'Advertisement',child:SafeArea(top:false,child:Container(
      alignment:Alignment.center,color:Colors.white,height:58,
      child:SizedBox(width:ad.size.width.toDouble(),height:ad.size.height.toDouble(),
        child:AdWidget(ad:ad)))));
  }
}
