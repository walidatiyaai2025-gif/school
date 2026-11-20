> **Update 2026-11-20:** School PDF v1.1.4 is being built with child-safe non-personalized Google AdMob banners and explicit Super Admin approval. Families/Data Safety and AdMob privacy messaging are still owner-gated. See `docs/GOOGLE_PLAY_ADMOB_FAMILIES_1_1_4_AR.md`. The v1.1.3 no-ads answers must not be reused for v1.1.4 without checking the signed AAB.

# School PDF — Google Play privacy & deletion release gate

## Source verified on GitHub

- Student app: **no sign-up, login, or remote student account**. Local name, school class, subjects, photos, and PDFs are not server account credentials.
- Adult-opt-in analytics records can be deleted with the device-held key through `DELETE /api/v1/device`. No client can delete another installation's record without its secret.
- `Settings → Language & privacy` includes server-record deletion and (in this change) explicit local profile/PDF deletion with confirmation.
- Public instructions: `https://sclpdf.50sols.com/data-deletion` and `/delete-account` (same explanation; no account is created).
- Official support contact: **info@50sols.com**; no promise that an anonymous record can be matched to an email.
- Daily stale-device prune exists in Laravel as `Schedule::command('model:prune')->daily()` and `DeviceRegistration::prunable` at 90 days. This **does not prove that production cron/scheduler runs**.
- `backend/public/app-ads.txt` uses the publisher entry provided by the owner; AdMob verification and web availability still require checking.

## Google Play declaration guidance

- Account creation: **My app does not allow users to create an account**.
- Can users log in with a previously created account? **No**.
- Data deletion mechanism: **Yes**, only after verifying the device-credential deletion endpoint on staging/production, its network-retry behavior and the public instructions. Do not claim remote email-based identification.
- Privacy URL: `https://sclpdf.50sols.com/privacy`, public, secure, no login required. Validate after deploying.
- Data Safety disclosures must include actual SDK behavior in the release **AAB**; e.g., Firebase Messaging installation identifiers and any Google Mobile Ads data even if ad UI is disabled. Never submit unchecked checkbox answers.
- Child audience: Families policy applies. Verify SDK/advertising ID, runtime consent, and children's data constraints with the final signed AAB and targeted testing.

## Mandatory outstanding acceptance — do not claim release ready yet

- [ ] Confirm developer's **legal entity name** exactly as registered in Google Play and have privacy/terms reviewed for the countries of distribution.
- [ ] Verify actual mail reception at **info@50sols.com**.
- [ ] Deploy updated Laravel code and verify external anonymous GET for /privacy, /support, /data-deletion, /delete-account, /app-ads.txt.
- [ ] Test device-record registration/deletion, lost-connection retry, revoked-consent behavior, and isolated credentials on a disposable nonproduction database.
- [ ] Confirm cron/scheduler and 90-day record-pruning operation on the actual hosting; do not claim guaranteed deletion otherwise.
- [ ] Test local PDF/profile reset, exported-copy preservation, and failure handling on an Android test device.
- [ ] Verify actual AAB manifest/SDK disclosures/AD_ID against Play Console Data safety and Families declarations.
- [ ] Produce signed release AAB, run internal test, obtain real screenshots, and resolve all Play Console policy alerts.
- [ ] Confirm any production ads remain disabled until explicit child-safe ad compliance/CMP acceptance.

Do not run live DB reseeding, reset credentials, or remove a production installation to test these flows.
