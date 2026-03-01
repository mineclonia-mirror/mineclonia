import math
from PIL import Image

SIZE = 256
CENTER = SIZE / 2
INNER_RADIUS = 45.0  # from the MC JE vignette texture
MAX_ALPHA = 210      # from the MC JE vignette texture
OUTER_RADIUS = math.hypot(CENTER, CENTER)
CURVE = 2.0

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
px = img.load()

for y in range(SIZE):
    for x in range(SIZE):
        dx = x - CENTER
        dy = y - CENTER
        d = math.hypot(dx, dy)

        if d <= INNER_RADIUS:
            a = 0
        else:
            t = (d - INNER_RADIUS) / (OUTER_RADIUS - INNER_RADIUS)
            if t >= 1.0:
                a = MAX_ALPHA
            else:
                a = int(round(MAX_ALPHA * (t ** CURVE)))

        if a < 0:
            a = 0
        elif a > MAX_ALPHA:
            a = MAX_ALPHA

        px[x, y] = (0, 0, 0, a)

# corner must have the max alpha value
assert img.getpixel((0, 0)) == (0, 0, 0, MAX_ALPHA), "Corner pixel alpha mismatch"

img.save("mcl_vignette_vignette.png")
print("Saved to mcl_vignette_vignette.png")
