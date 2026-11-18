# School PDF v1.0.0 — acceptance matrix

The boxes below are deliberately **unchecked**; no device/CI run was possible at source-generation time.

## Build & static checks
- [ ] Flutter SDK version recorded and dependency resolution succeeds (`flutter pub get`).
- [ ] Android and iOS host platforms generated via `tool/bootstrap.sh` and reviewed.
- [ ] `flutter analyze` succeeds.
- [ ] `flutter test` succeeds and widget tests run on a device or CI.
- [ ] Android debug APK builds and launches on a physical device.
- [ ] iOS debug app builds and launches on a physical iPhone.

## PDF flow
- [ ] First-launch profile, school level, class, age group saved and restored.
- [ ] School and university subjects, custom subject add/remove, switching levels.
- [ ] Camera capture; gallery multiple selection including HEIC where supported.
- [ ] Denied permissions, cancelled selection, corrupted images safely handled.
- [ ] Four-corner detection and draggable manual perspective correction.
- [ ] Rotate image, change filters, preview result, no unintended crop of answers.
- [ ] Reorder/delete/add pages and create multi-page A4 PDF offline.
- [ ] Arabic and English names/subjects display correctly on optional PDF header.
- [ ] Export high/medium/low quality; sample PDF opens in other apps.
- [ ] Duplicate names prevented via timestamp, files survive app restart.
- [ ] Search/subject filters; rename, delete confirmation and local-file deletion.
- [ ] PDF share via WhatsApp, Files, Email, Telegram, Android and iOS share sheet.
- [ ] Counter updates once per completed share-sheet invocation, not on file open.
- [ ] Low-storage failure leaves no partial PDF; very long files performance.

## Notifications
- [ ] OS permission prompt appears from first-run user action, not automatically.
- [ ] Reject permission: base PDF features remain available; notification-only features blocked.
- [ ] Local PDF completed notification displays with valid record ID.
- [ ] Daily inexact reminder is scheduled/cancelled, honors timezone and preferences.
- [ ] Firebase Android push on a real device after project keys/platform registration.
- [ ] iOS APNs + Firebase real push on a signed physical iPhone.
- [ ] Foreground, background, terminated app behavior and deep links.

## Ads, age, policy
- [ ] Non-ad flow runs when age group is child, teen or unknown.
- [ ] AdMob test banner appears only on main/history for a development 18+ profile.
- [ ] UMP/CMP implemented and independently reviewed before live ad requests.
- [ ] AdMob production app IDs/units configured; mediation adapters verified.
- [ ] Child/family privacy compliance and any certified ad-network restrictions reviewed.
- [ ] Legal privacy policy & Google Play Families / Apple privacy declarations complete.
- [ ] No user PDFs, photos, class names or tokens leaked into ad/push/log payloads.

## UX
- [ ] Arabic RTL and English LTR across onboarding, camera, menus and settings.
- [ ] Accessible text scaling, small-screen portrait, landscape policy and notches.
- [ ] Splash/app icon asset inspected at all icon densities.
- [ ] Network offline mode & missing ad/push credentials do not crash scanning.
