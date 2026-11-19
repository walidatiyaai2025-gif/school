#!/usr/bin/env python3
"""Pure-stdlib validation of canonical source and generated store/iOS branding."""
from pathlib import Path
import json
import struct
import sys

MOBILE = Path(__file__).resolve().parent.parent

def png(path: Path, width: int, height: int, *, opaque: bool = False) -> None:
    with path.open("rb") as f:
        header = f.read(26)
    if len(header) < 26 or header[:8] != bytes.fromhex("89504e470d0a1a0a"):
        raise AssertionError(f"Not a PNG: {path}")
    if header[12:16] != b"IHDR":
        raise AssertionError(f"Missing PNG IHDR: {path}")
    w, h = struct.unpack(">II", header[16:24])
    if (w, h) != (width, height):
        raise AssertionError(f"Expected {width}x{height}, got {w}x{h}: {path}")
    if opaque and header[25] not in (2, 3):
        raise AssertionError(f"Store icon must not have alpha: {path}")

def validate_source() -> None:
    icon = MOBILE / "assets/branding/icon.png"
    png(icon, 256, 256, opaque=True)
    pub = (MOBILE / "pubspec.yaml").read_text(encoding="utf-8")
    android = (MOBILE / "tool/flutter_launcher_icons_android.yaml").read_text(encoding="utf-8")
    for name, content in (("pubspec", pub), ("android", android)):
        if "image_path: assets/branding/icon.png" not in content:
            raise AssertionError(f"{name}: wrong launcher icon source")
        if "adaptive_icon_background: '#FFFFFF'" not in content:
            raise AssertionError(f"{name}: adaptive background must match white logo")
    ios = (MOBILE / "tool/flutter_launcher_icons_ios.yaml").read_text(encoding="utf-8")
    if "ios: true" not in pub or "android: true" not in android or "ios: true" not in ios or "android: false" not in ios:
        raise AssertionError("Missing iOS/Android launcher icon targets")

def validate_stores() -> None:
    out = MOBILE / "store_assets"
    png(out / "Google_Play/icon_512.png", 512, 512, opaque=True)
    png(out / "Apple_App_Store/icon_1024.png", 1024, 1024, opaque=True)
    png(out / "Google_Play/feature_graphic_1024x500.png", 1024, 500, opaque=True)

def validate_ios() -> None:
    appicon = MOBILE / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((appicon / "Contents.json").read_text(encoding="utf-8"))
    images = contents["images"]
    if not images:
        raise AssertionError("No iOS AppIcon images generated")
    marketing = [i for i in images if i.get("idiom") == "ios-marketing"]
    if len(marketing) != 1:
        raise AssertionError("Expected exactly one App Store marketing icon")
    for item in images:
        if item.get("filename") and not (appicon / item["filename"]).is_file():
            raise AssertionError(f"Missing generated iOS icon: {item['filename']}")
    png(appicon / marketing[0]["filename"], 1024, 1024, opaque=True)

if __name__ == "__main__":
    validate_source()
    if "--stores" in sys.argv:
        validate_stores()
    if "--ios" in sys.argv:
        validate_ios()
    print("School PDF branding validated")
