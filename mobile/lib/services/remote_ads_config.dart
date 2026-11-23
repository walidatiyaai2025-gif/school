/// Validate the backend's Families-approved ad response before using any ID.
class RemoteAdsConfig {
  static bool _approvedPolicy(Object? payload) {
    if (payload is! Map || payload['ads'] is! Map) return false;
    final ads = payload['ads'] as Map;
    return ads['enabled'] == true &&
        ads['families_safe'] == true &&
        ads['max_content_rating'] == 'G' &&
        ads['third_party_mediation'] == false &&
        ads['providers'] is List;
  }

  static String? approvedBannerId(Object? payload, String platform) {
    if (!_approvedPolicy(payload)) return null;
    final ads = (payload as Map)['ads'] as Map;
    for (final item in ads['providers'] as List) {
      if (item is! Map ||
          item['provider'] != 'admob' ||
          item['platform'] != platform) continue;
      final id = item['banner_unit_id'];
      if (id is String &&
          RegExp(r'^ca-app-pub-[0-9]{16}/[0-9]+$').hasMatch(id)) {
        return id;
      }
    }
    return null;
  }

  /// Interstitials are independently enabled and must use a different unit.
  static String? approvedInterstitialId(Object? payload, String platform) {
    if (!_approvedPolicy(payload)) return null;
    final ads = (payload as Map)['ads'] as Map;
    for (final item in ads['providers'] as List) {
      if (item is! Map ||
          item['provider'] != 'admob' ||
          item['platform'] != platform ||
          item['interstitial_enabled'] != true) continue;
      final unit = item['interstitial_unit_id'];
      final banner = item['banner_unit_id'];
      if (unit is String && banner is String &&
          RegExp(r'^ca-app-pub-[0-9]{16}/[0-9]+$').hasMatch(unit) &&
          RegExp(r'^ca-app-pub-[0-9]{16}/[0-9]+$').hasMatch(banner) &&
          unit != banner &&
          unit.split('/').first == banner.split('/').first) {
        return unit;
      }
    }
    return null;
  }
}
