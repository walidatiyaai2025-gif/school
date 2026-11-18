# School PDF Flutter — v1.1.1

Student PDF scanning app (Arabic/English), Android & iOS. Integrated with owner-supplied Firebase client configurations and the separate Laravel API source in `../backend`.

> Source deliverable only. APK, iOS/APNs delivery, full Laravel installer and upgrade have NOT been built or verified on production devices here.

## Features

- Student profile/level/class, subject selection, camera/gallery, corner correction, filtering and multi-page PDF creation.
- Local PDF History, document previews and sharing (counter counts openings of the share sheet, not confirmed delivery).
- Local completion and optional study-reminder notifications.
- Firebase Cloud Messaging for service notifications, OS permission opt-in and foreground/background/terminated handlers.
- AdMob integration guarded and disabled for real ads by default, subject to age-appropriate privacy/compliance review.
- Adult-only opt-in anonymous app-open metrics and approximate country from Laravel; not all downloads.

## Firebase client files already included

- `config/firebase/google-services.json`
- `config/firebase/GoogleService-Info.plist`
- `lib/firebase_options.dart`

`tool/patch_platforms.py` copies these files to `android/app/` and `ios/Runner/` after Flutter creates the platform project; it also configures Android Gradle and iOS Xcode Resource/Info.plist. No `--dart-define=FIREBASE_...` flags are needed. Do not commit private FCM service-account JSON or APNs `.p8` keys to the app.

## Build (requires Flutter SDK, Android SDK; Xcode for iOS)

```bash
bash tool/bootstrap.sh
flutter run --dart-define=SCHOOLPDF_API_BASE=https://sclpdf.50sols.com/api
```

For a debug APK on a configured developer machine:

```bash
bash tool/build_android_apk.sh
```

The package additionally includes GitHub Actions workflows. These scripts are source only and have not been run by a Flutter toolchain in this environment.

For Android/iOS signing, FCM APNs setup, Laravel service-account credentials, permissions and detailed test matrix, see `../docs/FIREBASE_NOTIFICATIONS_V1_1_1_AR.md` and `../README_AR.md`.
