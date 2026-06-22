from pathlib import Path
from PIL import Image
root = Path(__file__).resolve().parent
src = root / 'App_icon.png'
img = Image.open(src).convert('RGBA')
width, height = img.size
print('size', width, height)
pixels = img.load()
threshold = 230

from colorsys import rgb_to_hsv

def is_bg(px, lum_thresh=240, sat_thresh=0.12):
    r, g, b, a = px
    if a == 0:
        return True
    lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
    if lum >= lum_thresh:
        h, s, v = rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
        if s < sat_thresh:
            return True
    return False

left = width
right = 0
top = height
bottom = 0
for y in range(height):
    for x in range(width):
        if not is_bg(pixels[x, y]):
            left = min(left, x)
            top = min(top, y)
            right = max(right, x)
            bottom = max(bottom, y)
print('bounds', left, top, right, bottom, 'size', right-left+1, bottom-top+1)

border = []
if threshold is None:
    threshold = 230
for y in range(height):
    for x in range(width):
        if x < 40 or x >= width-40 or y < 40 or y >= height-40:
            r,g,b,a = pixels[x,y]
            if a != 0:
                border.append((r,g,b,a))
print('border pixels', len(border))
if border:
    print('border min', min(p[0] for p in border), min(p[1] for p in border), min(p[2] for p in border))
    print('border max', max(p[0] for p in border), max(p[1] for p in border), max(p[2] for p in border))
    print('border avg rgb', sum(p[0] for p in border)/len(border), sum(p[1] for p in border)/len(border), sum(p[2] for p in border)/len(border))
    print('border avg lum', sum((p[0]+p[1]+p[2])/3 for p in border)/len(border))

print('corner samples:')
corners = [(0,0),(width-1,0),(0,height-1),(width-1,height-1)]
for x,y in corners:
    print((x,y), pixels[x,y])

edge_non_bg = []
for y in range(height):
    for x in range(width):
        if x < 5 or x >= width-5 or y < 5 or y >= height-5:
            if not is_bg(pixels[x,y]):
                edge_non_bg.append((x,y,pixels[x,y]))
print('edge non-bg count', len(edge_non_bg))
for i, item in enumerate(edge_non_bg[:20]):
    print('edge non-bg', item)
print('mode', img.mode)
