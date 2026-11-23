import 'package:flutter_test/flutter_test.dart';
import 'package:school_pdf/services/remote_ads_config.dart';

void main() {
  const id = 'ca-app-pub-3218037275900725/8379591348';
  Map<String, dynamic> payload() => {
    'ads': {
      'enabled': true,
      'families_safe': true,
      'max_content_rating': 'G',
      'third_party_mediation': false,
      'providers': [
        {'provider': 'admob', 'platform': 'android', 'banner_unit_id': id},
      ],
    },
  };

  test('accepts only an approved AdMob unit for the current platform', () {
    expect(RemoteAdsConfig.approvedBannerId(payload(), 'android'), id);
    expect(RemoteAdsConfig.approvedBannerId(payload(), 'ios'), isNull);
  });

  test('game interstitial requires explicit approval and a distinct AdMob unit', () {
    const interstitial = 'ca-app-pub-3218037275900725/1234567890';
    final data = payload();
    final provider = ((data['ads'] as Map)['providers'] as List).first as Map;
    expect(RemoteAdsConfig.approvedInterstitialId(data, 'android'), isNull);
    provider['interstitial_enabled'] = true;
    provider['interstitial_unit_id'] = interstitial;
    expect(RemoteAdsConfig.approvedInterstitialId(data, 'android'), interstitial);
    expect(RemoteAdsConfig.approvedInterstitialId(data, 'ios'), isNull);
    provider['interstitial_unit_id'] = id;
    expect(RemoteAdsConfig.approvedInterstitialId(data, 'android'), isNull);
    provider['interstitial_unit_id'] = 'ca-app-pub-9999999999999999/1234567890';
    expect(RemoteAdsConfig.approvedInterstitialId(data, 'android'), isNull);
    provider['interstitial_unit_id'] = interstitial;
    (data['ads'] as Map)['enabled'] = false;
    expect(RemoteAdsConfig.approvedInterstitialId(data, 'android'), isNull);
  });

  test('fails closed on missing, revoked or unsafe policy', () {
    expect(RemoteAdsConfig.approvedBannerId(null, 'android'), isNull);
    for (final field in ['enabled', 'families_safe', 'third_party_mediation']) {
      final data = payload();
      (data['ads'] as Map)[field] = field == 'third_party_mediation';
      expect(RemoteAdsConfig.approvedBannerId(data, 'android'), isNull);
    }
    final data = payload();
    (data['ads'] as Map)['max_content_rating'] = 'T';
    expect(RemoteAdsConfig.approvedBannerId(data, 'android'), isNull);
    (data['ads'] as Map)['max_content_rating'] = 'G';
    ((data['ads'] as Map)['providers'] as List).first['banner_unit_id'] = 'fake';
    expect(RemoteAdsConfig.approvedBannerId(data, 'android'), isNull);
  });
}
