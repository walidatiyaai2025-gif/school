/// Validate the backend's Families-approved ad response before using any ID.
class RemoteAdsConfig {
  static String? approvedInterstitialId(Object? payload, String platform) {
    if (payload is! Map || payload['ads'] is! Map) return null;
    final ads = payload['ads'] as Map;
    if (ads['enabled'] != true ||
        ads['families_safe'] != true ||
        ads['max_content_rating'] != 'G' ||
        ads['third_party_mediation'] != false ||
        ads['providers'] is! List) return null;
    for (final item in ads['providers'] as List) {
      if (item is! Map || item['provider'] != 'admob' ||
          item['platform'] != platform ||
          item['interstitial_enabled'] != true) continue;
      final id = item['interstitial_unit_id'];
      final banner = item['banner_unit_id'];
      if (id is String && banner is String &&
          RegExp(r'^ca-app-pub-[0-9]{16}/[0-9]+
    if (payload is! Map || payload['ads'] is! Map) return null;
    final ads = payload['ads'] as Map;
    if (ads['enabled'] != true ||
        ads['families_safe'] != true ||
        ads['max_content_rating'] != 'G' ||
        ads['third_party_mediation'] != false ||
        ads['providers'] is! List) return null;
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
}
).hasMatch(id) &&
          RegExp(r'^ca-app-pub-[0-9]{16}/[0-9]+
    if (payload is! Map || payload['ads'] is! Map) return null;
    final ads = payload['ads'] as Map;
    if (ads['enabled'] != true ||
        ads['families_safe'] != true ||
        ads['max_content_rating'] != 'G' ||
        ads['third_party_mediation'] != false ||
        ads['providers'] is! List) return null;
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
}
).hasMatch(banner) &&
          id != banner &&
          id.split('/').first == banner.split('/').first) return id;
    }
    return null;
  }

  static String? approvedBannerId(Object? payload, String platform) {
    if (payload is! Map || payload['ads'] is! Map) return null;
    final ads = payload['ads'] as Map;
    if (ads['enabled'] != true ||
        ads['families_safe'] != true ||
        ads['max_content_rating'] != 'G' ||
        ads['third_party_mediation'] != false ||
        ads['providers'] is! List) return null;
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
}
