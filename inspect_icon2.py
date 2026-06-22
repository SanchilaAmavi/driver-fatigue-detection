from pathlib import Path
from PIL import Image
root = Path(__file__).resolve().parent
src = root / 'App_icon.png'
img = Image.open(src).convert('RGBA')
width, height = img.size
pixels = img.load()

corner_coords = [(0,0),(width-1,0),(0,height-1),(width-1,height-1)]
corner_colors = [pixels[x,y][:3] for x,y in corner_coords]
avg_corner = tuple(sum(c[i] for c in corner_colors)/4 for i in range(3))
print('avg_corner', avg_corner)
print('corner_colors', corner_colors)

# compute boundary where pixels diverge from corner background by delta
for thresh in [10, 15, 20, 25, 30, 35, 40, 45, 50]:
    left = width
    right = 0
    top = height
    bottom = 0
    for y in range(height):
        for x in range(width):
            r,g,b,a = pixels[x,y]
            if a == 0:
                continue
            dr = r - avg_corner[0]
            dg = g - avg_corner[1]
            db = b - avg_corner[2]
            if dr*dr + dg*dg + db*db > thresh*thresh:
                left = min(left, x)
                top = min(top, y)
                right = max(right, x)
                bottom = max(bottom, y)
    if right < left:
        print('thresh', thresh, 'no visible pixels')
    else:
        print('thresh', thresh, 'bounds', left, top, right, bottom, 'size', right-left+1, bottom-top+1)

# inspect edge stripes for actual values
for y in range(0, height, 85):
    print('row', y, [pixels[x,y] for x in range(0, 60, 10)])
for x in range(0, width, 140):
    print('col', x, [pixels[x,y] for y in range(0, 60, 10)])

# determine rightmost column deviations
for x in range(width-80, width):
    sample = [pixels[x,y][:3] for y in range(0, height, 128)]
    if any(sum((c[i]-avg_corner[i])**2 for i in range(3)) > 25*25 for c in sample):
        print('non-bg near right edge at x', x, sample)
        break
