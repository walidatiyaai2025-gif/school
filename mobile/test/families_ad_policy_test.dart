import 'package:flutter_test/flutter_test.dart';
import 'package:school_pdf/services/families_ad_policy.dart';

void main() {
  test('unknown, child, teen are always child-directed with safe default', () {
    for (final age in [null, '', 'unknown', 'child', 'teen', 'invalid']) {
      expect(FamiliesAdPolicy.forAgeGroup(age), FamiliesAgeTreatment.child);
      expect(FamiliesAdPolicy.requiresUnderAgeConsentTreatment(age), true);
    }
  });
  test('only explicit adult group gets adult treatment', () {
    expect(FamiliesAdPolicy.forAgeGroup('adult'), FamiliesAgeTreatment.adult);
    expect(FamiliesAdPolicy.requiresUnderAgeConsentTreatment('adult'), false);
  });
  test('all audiences prohibit personalization and apply G rating', () {
    expect(FamiliesAdPolicy.personalizedAds, false);
    expect(FamiliesAdPolicy.maximumRating, 'G');
    expect(FamiliesAdPolicy.usesAdvertisingIdPermission, false);
    expect(FamiliesAdPolicy.usesOtherMediationAdapters, false);
  });
}
