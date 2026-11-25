import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_service.dart';
import 'families_ad_policy.dart';
import 'remote_ads_config.dart';

/// Preload only near XO's sixth completed round to avoid unnecessary ad SDK
/// pressure while scanning. Real monetization requires backend approval and
/// a dedicated Interstitial Ad Unit; debug uses Google's official test units.
class GameInterstitialAds {
  GameInterstitialAds({required this.ageGroup});

  final String ageGroup;
  InterstitialAd? _ad;
  String? _loadedUnit;
  bool _disposed = false;
  bool _loading = false;
  bool _showing = false;

  static const _apiBase = String.fromEnvironment('SCHOOLPDF_API_BASE',
      defaultValue: 'https://sclpdf.50sols.com/api');
  static const _production = bool.fromEnvironment(
      'SCHOOLPDF_PRODUCTION_ADS', defaultValue: true);
  static const _testOverride = bool.fromEnvironment(
      'SCHOOLPDF_TEST_GAME_INTERSTITIALS', defaultValue: false);

  static bool get _testMode => kDebugMode && _testOverride;
  String get _platform => Platform.isAndroid ? 'android' : 'ios';
  bool get isReady => _ad != null && !_disposed && !_showing;

  Future<String?> _approvedUnit() async {
    // Only a deliberate developer-only test preview bypasses remote approval.
    // The flag never bypasses the backend in release/profile builds.
    if (_testMode) return 'debug-test-only';
    if (!_production || (!Platform.isAndroid && !Platform.isIOS)) return null;
    final uri = Uri.tryParse('$_apiBase/v1/config');
    if (uri == null || uri.scheme != 'https') return null;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 3));
      final response = await request.close().timeout(const Duration(seconds: 3));
      if (response.statusCode != HttpStatus.ok) return null;
      final body = await utf8.decoder.bind(response).join()
          .timeout(const Duration(seconds: 3));
      return RemoteAdsConfig.approvedInterstitialId(
          jsonDecode(body), _platform);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> preload() async {
    if (_disposed || _ad != null || _loading || _showing) return;
    _loading = true;
    try {
      final unit = await _approvedUnit();
      if (unit == null || _disposed) {
        _loading = false;
        return;
      }
      final child = FamiliesAdPolicy.forAgeGroup(ageGroup) ==
          FamiliesAgeTreatment.child;
      await MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
        ageRestrictedTreatment: child
            ? AgeRestrictedTreatment.child
            : AgeRestrictedTreatment.unspecified,
        maxAdContentRating: MaxAdContentRating.g,
      ));
      if (!await SchoolAdPrivacy.privacyEligible(ageGroup) || _disposed) {
        _loading = false;
        return;
      }
      await MobileAds.instance.initialize();
      if (_disposed) {
        _loading = false;
        return;
      }
      await InterstitialAd.load(
        adUnitId: kDebugMode
            ? (Platform.isAndroid
                ? 'ca-app-pub-3940256099942544/1033173712'
                : 'ca-app-pub-3940256099942544/4411468910')
            : unit,
        request: const AdRequest(nonPersonalizedAds: true),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _loading = false;
            if (_disposed || _showing) {
              ad.dispose();
            } else {
              _ad = ad;
              _loadedUnit = unit;
            }
          },
          onAdFailedToLoad: (_) {
            _loading = false;
            _loadedUnit = null;
          },
        ),
      );
    } catch (_) {
      _loading = false;
    }
  }

  /// Invoked on Play Again after match six. No ad is shown if not ready,
  /// if the user left this route, or if remote consent/approval was revoked.
  /// True means the SDK actually showed the interstitial.
  Future<bool> showIfStillApproved({required bool Function() canShow}) async {
    if (!isReady || !canShow()) return false;
    _showing = true;
    try {
      final currentUnit = await _approvedUnit();
      if (_disposed || !canShow() || currentUnit == null ||
          currentUnit != _loadedUnit) {
        _ad?.dispose();
        _ad = null;
        _loadedUnit = null;
        return false;
      }
      final ad = _ad!;
      _ad = null;
      _loadedUnit = null;
      final done = Completer<bool>();
      var wasShown = false;

      void finish(bool success) {
        if (!done.isCompleted) done.complete(success);
        ad.dispose();
      }

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (_) => wasShown = true,
        onAdDismissedFullScreenContent: (_) => finish(wasShown),
        onAdFailedToShowFullScreenContent: (_, __) => finish(false),
      );
      try {
        await ad.show();
        return await done.future.timeout(const Duration(minutes: 2),
            onTimeout: () => false);
      } catch (_) {
        if (!done.isCompleted) ad.dispose();
        return false;
      }
    } finally {
      _showing = false;
    }
  }

  void dispose() {
    _disposed = true;
    _ad?.dispose();
    _ad = null;
    _loadedUnit = null;
  }
}
