#!/usr/bin/env python3
"""Generate store-compliant static branding files from the canonical Flutter icon.

Requires Pillow; no native Android/iOS build tools or signing credentials.
"""
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError as exc:
    raise SystemExit("Install Pillow first: python3 -m pip install Pillow") from exc

MOBILE = Path(__file__).resolve().parent.parent
ICON = MOBILE / "assets/branding/icon.png"
OUT = MOBILE / "store_assets"
RESAMPLE = Image.Resampling.LANCZOS

def font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for candidate in (
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/Library/Fonts/Arial Unicode.ttf",
        "/Library/Fonts/Arial.ttf",
        "C:/Windows/Fonts/arialbd.ttf",
    ):
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            pass
    return ImageFont.load_default()

source = Image.open(ICON).convert("RGB")
if source.width != source.height or source.width < 192:
    raise SystemExit("Brand icon source must be a square raster at least 192px wide")

def save_icon(path: Path, dimension: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    source.resize((dimension, dimension), RESAMPLE).save(path, format="PNG", optimize=True)

save_icon(OUT / "Google_Play/icon_512.png", 512)
save_icon(OUT / "Apple_App_Store/icon_1024.png", 1024)

feature = Image.new("RGB", (1024, 500), "#F5FBFF")
draw = ImageDraw.Draw(feature)
draw.rounded_rectangle((24, 24, 1000, 476), radius=44, fill="#FFFFFF")
feature.paste(source.resize((365, 365), RESAMPLE), (610, 68))
draw.text((70, 156), "School PDF", font=font(72), fill="#075DEB")
draw.text((73, 270), "Scan. Organize. Share.", font=font(29), fill="#102448")
output = OUT / "Google_Play/feature_graphic_1024x500.png"
output.parent.mkdir(parents=True, exist_ok=True)
feature.save(output, format="PNG", optimize=True)

print("Generated Google Play 512 icon, 1024x500 feature graphic and Apple 1024 icon")
