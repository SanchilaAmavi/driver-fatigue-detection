from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parent
src = root / "App_icon.png"
if not src.exists():
    raise FileNotFoundError(f"Source icon not found: {src}")

def estimate_background_color(image):
    width, height = image.size
    pixels = image.load()
    corners = [
        pixels[0, 0][:3],
        pixels[width - 1, 0][:3],
        pixels[0, height - 1][:3],
        pixels[width - 1, height - 1][:3],
    ]
    return tuple(sum(c[i] for c in corners) / len(corners) for i in range(3))


def is_background_pixel(r, g, b, a, bg_color, threshold=30):
    if a == 0:
        return True
    dr = r - bg_color[0]
    dg = g - bg_color[1]
    db = b - bg_color[2]
    return dr * dr + dg * dg + db * db <= threshold * threshold


def crop_to_visible(image, threshold=30, padding=8):
    pixels = image.load()
    width, height = image.size
    bg_color = estimate_background_color(image)
    left = width
    top = height
    right = 0
    bottom = 0
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if not is_background_pixel(r, g, b, a, bg_color, threshold):
                left = min(left, x)
                top = min(top, y)
                right = max(right, x)
                bottom = max(bottom, y)
    if right < left or bottom < top:
        return image
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(width - 1, right + padding)
    bottom = min(height - 1, bottom + padding)
    return image.crop((left, top, right + 1, bottom + 1))

with Image.open(src) as raw:
    raw = raw.convert("RGBA")
    cropped = crop_to_visible(raw)
    square_size = max(cropped.width, cropped.height)
    square = Image.new("RGBA", (square_size, square_size), (0, 0, 0, 0))
    square.paste(cropped, ((square_size - cropped.width) // 2, (square_size - cropped.height) // 2), cropped)

android_targets = [
    (48, root / "mobile" / "flutter" / "android" / "app" / "src" / "main" / "res" / "mipmap-mdpi" / "ic_launcher.png"),
    (72, root / "mobile" / "flutter" / "android" / "app" / "src" / "main" / "res" / "mipmap-hdpi" / "ic_launcher.png"),
    (96, root / "mobile" / "flutter" / "android" / "app" / "src" / "main" / "res" / "mipmap-xhdpi" / "ic_launcher.png"),
    (144, root / "mobile" / "flutter" / "android" / "app" / "src" / "main" / "res" / "mipmap-xxhdpi" / "ic_launcher.png"),
    (192, root / "mobile" / "flutter" / "android" / "app" / "src" / "main" / "res" / "mipmap-xxxhdpi" / "ic_launcher.png"),
]

for size, path in android_targets:
    path.parent.mkdir(parents=True, exist_ok=True)
    square.resize((size, size), Image.LANCZOS).save(path, format="PNG")
    print(f"Saved Android icon {path} ({size}x{size})")

ios_appicon = root / "mobile" / "flutter" / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
macos_appicon = root / "mobile" / "flutter" / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"

ios_sizes = [
    (20, 1, "Icon-App-20x20@1x.png"),
    (20, 2, "Icon-App-20x20@2x.png"),
    (20, 3, "Icon-App-20x20@3x.png"),
    (29, 1, "Icon-App-29x29@1x.png"),
    (29, 2, "Icon-App-29x29@2x.png"),
    (29, 3, "Icon-App-29x29@3x.png"),
    (40, 1, "Icon-App-40x40@1x.png"),
    (40, 2, "Icon-App-40x40@2x.png"),
    (40, 3, "Icon-App-40x40@3x.png"),
    (60, 2, "Icon-App-60x60@2x.png"),
    (60, 3, "Icon-App-60x60@3x.png"),
    (76, 1, "Icon-App-76x76@1x.png"),
    (76, 2, "Icon-App-76x76@2x.png"),
    (83.5, 2, "Icon-App-83.5x83.5@2x.png"),
    (1024, 1, "Icon-App-1024x1024@1x.png"),
]

macos_sizes = [
    (16, 1, "app_icon_16.png"),
    (16, 2, "app_icon_32.png"),
    (32, 1, "app_icon_32.png"),
    (32, 2, "app_icon_64.png"),
    (128, 1, "app_icon_128.png"),
    (128, 2, "app_icon_256.png"),
    (256, 1, "app_icon_256.png"),
    (256, 2, "app_icon_512.png"),
    (512, 1, "app_icon_512.png"),
    (512, 2, "app_icon_1024.png"),
]

for size, scale, filename in ios_sizes:
    path = ios_appicon / filename
    path.parent.mkdir(parents=True, exist_ok=True)
    actual = int(size * scale)
    square.resize((actual, actual), Image.LANCZOS).save(path, format="PNG")
    print(f"Saved iOS icon {path} ({actual}x{actual})")

for size, scale, filename in macos_sizes:
    path = macos_appicon / filename
    path.parent.mkdir(parents=True, exist_ok=True)
    actual = int(size * scale)
    square.resize((actual, actual), Image.LANCZOS).save(path, format="PNG")
    print(f"Saved macOS icon {path} ({actual}x{actual})")

windows_icon_path = root / "mobile" / "flutter" / "windows" / "runner" / "resources" / "app_icon.ico"
windows_icon_path.parent.mkdir(parents=True, exist_ok=True)
icon_sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]
icons = [square.resize(size, Image.LANCZOS) for size in icon_sizes]
icons[0].save(windows_icon_path, format="ICO", sizes=icon_sizes)
print(f"Saved Windows icon {windows_icon_path}")
