from PIL import Image, ImageDraw
from pathlib import Path

out = Path(__file__).resolve().parents[1] / "WorkshopLedger" / "Assets.xcassets" / "AppIcon.appiconset"
base_size = 1024
base = Image.new("RGB", (base_size, base_size), (232, 117, 36))
pix = base.load()
for y in range(base_size):
    for x in range(base_size):
        t = (x + y) / (2 * (base_size - 1))
        r = int(238 - 20 * t)
        g = int(126 - 38 * t)
        b = int(42 - 8 * t)
        vignette = max(0.0, (abs(x - 512) + abs(y - 512)) / 1400)
        pix[x, y] = (max(0, int(r - 8 * vignette)), max(0, int(g - 10 * vignette)), max(0, int(b - 4 * vignette)))

draw = ImageDraw.Draw(base)
draw.ellipse((-180, -220, 520, 480), fill=(255, 171, 92))
draw.ellipse((610, 590, 1240, 1220), fill=(196, 79, 16))
draw.rounded_rectangle((214, 146, 810, 850), radius=116, fill=(255, 255, 255))
draw.rounded_rectangle((214, 146, 810, 318), radius=116, fill=(23, 32, 45))
draw.rectangle((214, 238, 810, 318), fill=(23, 32, 45))
draw.rounded_rectangle((288, 390, 736, 420), radius=15, fill=(23, 32, 45))
draw.rounded_rectangle((288, 488, 648, 518), radius=15, fill=(23, 32, 45))
draw.rounded_rectangle((288, 586, 570, 616), radius=15, fill=(23, 32, 45))
draw.rounded_rectangle((606, 552, 744, 770), radius=42, fill=(232, 117, 36))
draw.rounded_rectangle((650, 598, 700, 724), radius=20, fill=(255, 255, 255))
draw.rounded_rectangle((600, 637, 750, 687), radius=20, fill=(255, 255, 255))

for name, size in {
    "Icon-20.png": 20,
    "Icon-20@2x.png": 40,
    "Icon-29.png": 29,
    "Icon-29@2x.png": 58,
    "Icon-40.png": 40,
    "Icon-40@2x.png": 80,
    "Icon-76.png": 76,
    "Icon-76@2x.png": 152,
    "Icon-83.5@2x.png": 167,
    "Icon-1024.png": 1024,
}.items():
    base.resize((size, size), Image.Resampling.LANCZOS).save(out / name, "PNG", optimize=True)
print("generated", len(list(out.glob("*.png"))), "icons")
