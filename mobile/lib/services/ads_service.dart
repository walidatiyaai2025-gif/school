import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../data/app_store.dart';
import 'families_ad_policy.dart';

/// School PDF's only production ad placement: one clearly marked AdMob banner.
///
/// Unknown/child/teen users receive CHILD age treatment before the SDK starts.
/// All requests are non-personalized, G-rated. No AD_ID manifest permission,
/// custom mediation adapters, interstitials or rewarded ads are used.
/// Ads need a positive Admin-approved remote config and UMP eligibility. When
/// the server, UMP, or SDK is unavailable, scanning works without ads.
class SchoolBanner extends StatefulWidget {
  const SchoolBanner({super.key, required this.store});
  final AppStore store;
  @override State<SchoolBanner> createState() => _SchoolBannerState();
}

class _SchoolBannerState extends State<SchoolBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requesting = false;
  bool _remoteEnabled = false;
  String _remoteBannerId = '';
  int _generation = 0;
  // Discard an adult-configured ad when the age group changes.
  String? _adAge;

  static const remoteApi = String.fromEnvironment('SCHOOLPDF_API_BASE',
      defaultValue: 'https://sclpdf.50sols.com/api');
  static const testAds =
      bool.fromEnvironment('SCHOOLPDF_TEST_ADS', defaultValue: false);
  static const productionAds =
      bool.fromEnvironment('SCHOOLPDF_PRODUCTION_ADS', defaultValue: false);
  static const androidId = String.fromEnvironment('ADMOB_ANDROID_BANNER_ID');
  static const iosId = String.fromEnvironment('ADMOB_IOS_BANNER_ID');

  String get _configuredId => _remoteBannerId.isNotEmpty
      ? _remoteBannerId : (Platform.isAndroid ? androidId : iosId);
  bool get _eligible => testAds ||
      (productionAds && _remoteEnabled && _configuredId.isNotEmpty);
  String get _age => widget.store.settings.ageGroup;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_sync);
    _loadRemote();
  }

  Future<void> _loadRemote() async {
    if (!productionAds || testAds) {
      _sync();
      return;
    }
    final uri = Uri.tryParse('$remoteApi/v1/config');
    if (uri == null || uri.scheme != 'https') return;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);
    try {
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 6));
      final response = await req.close().timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;
      final data = jsonDecode(await utf8.decoder.bind(response).join());
      if (data is! Map || data['ads'] is! Map) return;
      final ads = data['ads'] as Map;
      if (ads['enabled'] != true || ads['providers'] is! List) return;
      for (final entry in ads['providers'] as List) {
        if (entry is! Map || entry['provider'] != 'admob' ||
            entry['platform'] != (Platform.isAndroid ? 'android' : 'ios')) {
          continue;
        }
        final id = entry['banner_unit_id'];
        if (id is String &&
            RegExp(r'^ca-app-pub-[0-9]+/[0-9]+$').hasMatch(id)) {
          _remoteBannerId = id;
          _remoteEnabled = true;
          if (mounted) _sync();
          return;
        }
      }
    } catch (_) {
      // Never block document work or bypass a negative approval on failure.
    } finally {
      client.close(force: true);
    }
  }

  void _sync() {
    if (_adAge != _age) {
      _adAge = _age;
      ++_generation;
      _ad?.dispose();
      _ad = null;
      _loaded = false;
      _requesting = false;
      if (mounted) setState(() {});
    }
    if (!_eligible) {
      ++_generation;
      _ad?.dispose();
      _ad = null;
      _loaded = false;
      _requesting = false;
      if (mounted) setState(() {});
      return;
    }
    if (_ad == null && !_requesting) _load();
  }

  /// UMP must run at every ad-serving app launch. Child/teen/unknown users
  /// are tagged under age of consent so they are never presented adult GDPR
  /// consent forms. The Mobile Ads age treatment is separately configured.
  Future<bool> _privacyEligible() async {
    final completer = Completer<bool>();
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(
          tagForUnderAgeOfConsent:
              FamiliesAdPolicy.requiresUnderAgeConsentTreatment(_age)),
        () async {
          if (FamiliesAdPolicy.requiresUnderAgeConsentTreatment(_age)) {
            // Underage is not an exemption from UMP readiness checks. No
            // ad requests unless UMP explicitly allows serving ads.
            try {
              final allowed = await ConsentInformation.instance.canRequestAds();
              if (!completer.isCompleted) completer.complete(allowed);
            } catch (_) {
              if (!completer.isCompleted) completer.complete(false);
            }
            return;
          }
          ConsentForm.loadAndShowConsentFormIfRequired((error) async {
            if (error != null) {
              if (!completer.isCompleted) completer.complete(false);
              return;
            }
            try {
              final allowed = await ConsentInformation.instance.canRequestAds();
              if (!completer.isCompleted) completer.complete(allowed);
            } catch (_) {
              if (!completer.isCompleted) completer.complete(false);
            }
          });
        },
        (_) {
          if (!completer.isCompleted) completer.complete(false);
        },
      );
      return await completer.future.timeout(const Duration(seconds: 20),
          onTimeout: () => false);
    } catch (_) {
      return false;
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _requesting = true;
    final id = _configuredId;
    final age = _age;
    try {
      final children = FamiliesAdPolicy.forAgeGroup(age) ==
          FamiliesAgeTreatment.child;
      // Before ANY Mobile Ads SDK initialization or ad request, constrain
      // global treatment. All banners are nonpersonalized and rated G.
      await MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
        ageRestrictedTreatment: children
            ? AgeRestrictedTreatment.child
            : AgeRestrictedTreatment.unspecified,
        maxAdContentRating: MaxAdContentRating.g,
      ));
      if (!await _privacyEligible() || !mounted ||
          generation != _generation || age != _age || !_eligible) return;
      await MobileAds.instance.initialize();
      if (!mounted || generation != _generation || !_eligible) return;
      final ad = BannerAd(
        size: AdSize.banner,
        adUnitId: testAds
            ? (Platform.isAndroid
                ? 'ca-app-pub-3940256099942544/6300978111'
                : 'ca-app-pub-3940256099942544/2934735716')
            : id,
        request: const AdRequest(nonPersonalizedAds: true),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted || generation != _generation || !_eligible) {
              ad.dispose();
              return;
            }
            setState(() => _loaded = true);
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (mounted && generation == _generation) {
              setState(() { _loaded = false; _ad = null; });
            }
          },
        ),
      );
      _ad = ad;
      await ad.load();
    } catch (_) {
      // No ad network error may prevent document scanning.
      if (mounted && generation == _generation) setState(() => _loaded = false);
    } finally {
      if (mounted && generation == _generation) {
        _requesting = false;
      }
    }
  }

  @override
  void dispose() {
    ++_generation;
    widget.store.removeListener(_sync);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_eligible) return const SizedBox.shrink();
    // Reserve a stable slot so an arriving ad cannot move navigation buttons
    // under a child's finger; separate from content and clearly label it.
    return Semantics(
      label: 'Advertisement',
      child: Container(
        height: 84,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: [
          const Text('Advertisement • إعلان',
              style: TextStyle(fontSize: 10, color: Colors.black54)),
          const SizedBox(height: 3),
          const Divider(height: 1),
          const SizedBox(height: 4),
          if (_loaded && _ad != null)
            SizedBox(
              width: _ad!.size.width.toDouble(),
              height: _ad!.size.height.toDouble(),
              child: AdWidget(ad: _ad!),
            )
          else
            const SizedBox(height: 50),
        ]),
      ),
    );
  }
}
