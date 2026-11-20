/// Restrictive ad-treatment policy for mixed child/adult audiences.
///
/// Never infer adult status from a school level or missing profile. Underage
/// and unknown ages use child-directed treatment, G-rated inventory and no
/// interest-based ads. AdMob's Families self-certified Android SDK is the only
/// ad SDK enabled for these placements.
enum FamiliesAgeTreatment { child, adult }

class FamiliesAdPolicy {
  static FamiliesAgeTreatment forAgeGroup(String? ageGroup) =>
      ageGroup == 'adult' ? FamiliesAgeTreatment.adult : FamiliesAgeTreatment.child;

  static bool requiresUnderAgeConsentTreatment(String? ageGroup) =>
      forAgeGroup(ageGroup) == FamiliesAgeTreatment.child;

  static const bool personalizedAds = false;
  static const String maximumRating = 'G';
  static const bool usesAdvertisingIdPermission = false;
  static const bool usesOtherMediationAdapters = false;
}
