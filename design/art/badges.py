"""The badges stuck on the helmet: one per level in its world's road-sign shape (blue circle 馬路, red
square 救災, green circle 身體, yellow diamond 家裡) with a small white picture; a crest per world
(汪汪's police star, 喵喵's fire shield, 兔兔's cross) and the gold real-life badge.

    python3 build.py badges
"""
import sys

sys.dont_write_bytecode = True

import math  # noqa: E402

from kit import (BLU, GRN, INK, RED, WHT, YEL, Pic, circle, ellipse, limb, poly, rect, rpoly, rrect, star,  # noqa: E402
                 union)

SHAPES = {"road": ("circle", BLU), "rescue": ("square", RED), "body": ("circle", GRN), "home": ("diamond", "#F2B600")}
LEVELS = {
    "light": "road", "cross": "road", "hand": "road", "car": "road", "lost": "road",
    "quake": "rescue", "fire": "rescue", "typhoon": "rescue",
    "bodyLights": "body", "sayNo": "body",
    "kitchen": "home", "living": "home", "bath": "home", "balcony": "home",
}
DARK = "#2A3140"


def plate(p, world):
    kind, col = SHAPES[world]
    if kind == "circle":
        p.shape(circle(50, 50, 46), col)
    elif kind == "square":
        p.shape(rrect(5, 5, 90, 90, 18), col)
    else:
        p.shape(rpoly([(50, 2), (98, 50), (50, 98), (2, 50)], 8), col)


def glyph(p, lv):
    W = WHT
    if lv == "light":
        p.shape(rrect(38, 22, 24, 56, 8), DARK, hl=False)
        for i, c in enumerate([RED, YEL, GRN]):
            p.flat(circle(50, 33 + i * 17, 6), c)
    elif lv == "cross":
        for i in range(4):
            p.flat(rrect(26, 26 + i * 13, 48, 7, 2), W)
    elif lv == "hand":
        p.shape(union(circle(40, 52, 13), circle(60, 52, 13)), W, hl=False)
        p.stroke([(40, 52), (60, 52)], INK, 1.6)
    elif lv == "car":
        p.shape(union(rrect(22, 46, 56, 18, 8), rrect(32, 34, 34, 18, 7)), W, hl=False)
        p.shape(limb([(30, 28), (70, 70)], 6), DARK, hl=False)
    elif lv == "lost":
        p.shape(rpoly([(34, 30), (44, 26), (50, 38), (44, 44), (54, 56), (62, 50), (72, 58), (66, 70), (54, 70), (34, 48)], 4), W, hl=False)
    elif lv == "quake":
        p.shape(rrect(22, 36, 56, 10, 4), W, hl=False)
        for x in (30, 70):
            p.shape(limb([(x, 44), (x, 72)], 6), W, hl=False)
    elif lv == "fire":
        for i, x in enumerate((28, 46, 64)):
            if i < 2:
                p.flat(limb([(x + 4, 32), (x + 4, 68)], 6), W)
            else:
                p.flat(union(limb([(x, 32), (x + 10, 32), (x + 10, 68)], 6), limb([(x, 32), (x, 50), (x + 10, 50)], 6)), W)
    elif lv == "typhoon":
        pts = [(50 + r * math.cos(a), 50 + r * math.sin(a)) for r, a in zip(range(4, 30), [i * .5 for i in range(26)])]
        p.stroke(pts, W, 4.5)
    elif lv == "bodyLights":
        for i, c in enumerate([GRN, YEL, RED]):
            p.shape(circle(30 + i * 20, 50, 8), c if c != GRN else "#9BE3A8", dots=False, hl=False)
    elif lv == "sayNo":
        p.shape(union(rrect(36, 44, 28, 26, 9), *[rrect(36 + i * 7.3, 26 + abs(i - 1.5) * 3, 6.5, 24, 3.2) for i in range(4)]), W, hl=False)
    elif lv == "kitchen":
        p.shape(rrect(28, 42, 40, 26, 8), W, hl=False)
        p.shape(limb([(68, 50), (80, 44)], 6), W, hl=False)
    elif lv == "living":
        p.shape(rrect(32, 32, 36, 36, 8), W, hl=False)
        for x in (44, 56):
            p.flat(rrect(x - 2, 40, 4, 10, 2), DARK)
    elif lv == "bath":
        p.shape(union(rrect(24, 48, 52, 20, 9)), W, hl=False)
        p.shape(poly([(50, 24), (58, 38), (50, 42), (42, 38)]).buffer(2), "#9FD3F0", dots=False, hl=False)
    elif lv == "balcony":
        p.shape(rect(24, 40, 52, 6), W, hl=False)
        for x in range(28, 76, 10):
            p.flat(rect(x, 46, 4, 26), W)


def badge(lv):
    p = Pic(100, 100, 56)
    plate(p, LEVELS[lv])
    glyph(p, lv)
    return p


def crest(world):
    p = Pic(100, 110, 64)
    if world == "road":                    # 汪汪's police star
        p.shape(star(50, 56, 48, 26, 6), "#E9B64B")
        p.shape(circle(50, 56, 20), BLU, hl=False)
        p.flat(star(50, 56, 11, 5), WHT)
    elif world == "rescue":                # 喵喵's fire shield
        p.shape(poly([(10, 14), (90, 14), (90, 56), (50, 104), (10, 56)]).buffer(4).buffer(-4), RED)
        p.shape(poly([(24, 26), (76, 26), (76, 54), (50, 86), (24, 54)]), YEL, hl=False)
        p.shape(rrect(44, 34, 12, 34, 3), RED, dots=False, hl=False)
        p.shape(rrect(33, 45, 34, 12, 3), RED, dots=False, hl=False)
    elif world == "body":                  # 兔兔's cross, in green for 身體
        p.shape(circle(50, 56, 46), WHT)
        p.shape(union(rrect(40, 22, 20, 68, 4), rrect(16, 46, 68, 20, 4)), GRN, hl=False)
    else:                                  # 兔兔's cross, pink, for 家裡
        p.shape(circle(50, 56, 46), WHT)
        p.shape(union(rrect(40, 22, 20, 68, 4), rrect(16, 46, 68, 20, 4)), "#F27AA0", hl=False)
    return p


def gold():
    p = Pic(100, 100, 56)
    for a in (-30, 30):
        p.shape(poly([(50, 56), (50 + 30 * math.sin(math.radians(a)) - 9, 98), (50 + 30 * math.sin(math.radians(a)) + 9, 98)]), RED, hl=False)
    p.shape(circle(50, 44, 40), "#E9B64B")
    p.shape(circle(50, 44, 30), "#FFD54A", hl=False)
    p.flat(star(50, 45, 20, 9), WHT)
    return p


def build():
    files = {f"badges/{lv}": badge(lv) for lv in LEVELS}
    files.update({f"badges/crest_{w}": crest(w) for w in SHAPES})
    files["badges/gold"] = gold()
    for k, p in files.items():
        p.save(k)
    print(f"badges: {len(files)} files")


if __name__ == "__main__":
    build()
