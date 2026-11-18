# School PDF 1.1.1 — Source delivery

- Flutter v1.0.0 feature base retained: paper-camera / gallery, perspective corner editor, enhancement, PDFs, history, shares and share-attempt count.
- Fixed proposed native app IDs: `com.fiftysols.schoolpdf` Android/iOS; platform patcher updates Kotlin activity namespace.
- New Laravel 12 backend source with public privacy/support/terms, admin, API and migrations.
- Anonymous opt-in first-open analytics for 18+; country attribution only from trusted proxy header, no GPS or student-file uploads.
- FCM service-account sender, country-filtered drafts, dispatch and queue processor.
- AdMob-mediated configuration in dashboard and app-ads.txt editor. Production ads locked pending compliance.
- User-requested domain links mapped to `sclpdf.50sols.com`.
- Standalone web installer source with generated APP_KEY, db migrations, admin creation and lock. Complete Setup ZIP not built or tested in this session due missing Composer environment.
- Admin system updates interface is a safety-locked placeholder, NOT an operating updater.

Build/tests: static checks only; no green CI, APK, production credentials, DNS or cloud deployment evidence.

## Firebase notification integration in v1.1.1

- Embedded the **owner-provided Firebase client files** for Android and iOS with verified project/application identifiers.
- Generated the Android/iOS `FirebaseOptions` constants and removed the old requirement to supply `FIREBASE_*` values at runtime.
- Added native configuration installation for Gradle, Xcode Runner Resources and iOS remote notification background mode.
- Added FCM background handler, foreground push channel and cold-start notification handling; APNs device test is still pending.
- Added an explicit notification opt-in preference and disabled Firebase Messaging auto-init before permission.
- Added `mobile/tool/verify_firebase_config.py` to CI.
- **Not included:** Firebase Admin private key, APNs signing key, production ad credentials. No verified APK or live push delivery.


## Setup improvements in v1.1.2

- Added `setup/` packaging and seven offline regression tests, improving the Laravel install wizard.
- Refuses release ZIP until same exact Git SHA has pinned production dependencies and real Fresh Install/Upgrade/Recovery evidence.
- Installer enforces HTTPS, canonical domain, extension and writability checks before DB provisioning.
- Current delivery is **SOURCE WITH SETUP TOOLING** — no production vendor, no Setup ZIP, no deployment claimed.
