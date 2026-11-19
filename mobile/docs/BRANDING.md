# School PDF — official launcher and store branding

Owner-provided design: blue graduation cap, document with PDF text and cyan
swoosh, white background.

## Canonical source

`mobile/assets/branding/icon.png` is the white-background square launcher
source derived from the provided raster art. Do not use the older blue-gradient
launcher asset. Both mobile operating systems regenerate their native icon
sizes from this one source via `flutter_launcher_icons`.

Android adaptive background is white (not the old blue), consistent across
`mobile/pubspec.yaml` and `mobile/tool/flutter_launcher_icons_android.yaml`.

## Android

From `mobile/` (after `flutter create --platforms android`, `flutter pub get`):

```sh
dart run flutter_launcher_icons -f tool/flutter_launcher_icons_android.yaml
```

This populates Android launcher mipmaps during the existing APK build.

## Apple / iOS

On a macOS host with Xcode, from `mobile/` (after creating the iOS platform
and running `flutter pub get`):

```sh
dart run flutter_launcher_icons -f tool/flutter_launcher_icons_ios.yaml
python3 tool/verify_branding.py --ios
```

This populates `ios/Runner/Assets.xcassets/AppIcon.appiconset` (including
the 1024px App Store icon). Shipping an iOS app still requires code signing
and a separate release build.

## Store marketing graphics

```sh
python3 -m pip install Pillow
python3 mobile/tool/generate_store_assets.py
python3 mobile/tool/verify_branding.py --stores
```

Generated:
- `mobile/store_assets/Google_Play/icon_512.png`
- `mobile/store_assets/Google_Play/feature_graphic_1024x500.png`
- `mobile/store_assets/Apple_App_Store/icon_1024.png`

The CI workflow publishes those three files as the
`schoolpdf-store-branding` artifact. Because the owner source is raster,
the larger sizes are upscaled: review at 100% before store submission.
No changes are made to store listing credentials or live app releases.
