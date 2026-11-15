"""The three helpers (汪汪警察, 喵喵消防員, 兔兔護士), the grown-ups of the road levels (媽媽, the shop
clerk, a mother with her child, a passer-by) and the friendly animals of 說「不要！」.

Characters stand on (0, 0); helpers are about 130 units tall like the squad member, grown-ups 175.

    python3 build.py helpers
"""
import sys

sys.dont_write_bytecode = True

from kit import (BLK, BLU, CHEEK, INK, LGREY, NAVY, RED, WHT, YEL, Pic, circle, ellipse, limb, lt, poly, rrect,  # noqa: E402
                 union)

SKIN_A = "#F0C7A0"   # the grown-ups' skin (a fixed, friendly tone)


def eyes(p, cx, cy, dx=9, r=2.9, closed=False):
    for x in (cx - dx, cx + dx):
        if closed:
            p.stroke([(x - 4, cy + 1), (x, cy - 2), (x + 4, cy + 1)], INK, 1.9)
        else:
            p.flat(circle(x, cy, r), INK)
            p.flat(circle(x - r * .35, cy - r * .35, r * .38), WHT)


def smile(p, cx, cy, w=5, open_=False):
    if open_:
        p.shape(ellipse(cx, cy + 1.5, w * .8, w * .7), "#C2404A", dots=False, hl=False)
    else:
        p.stroke([(cx - w, cy), (cx, cy + w * .8), (cx + w, cy)], INK, 1.9)


def cheeks(p, cx, cy, dx=13, r=3.2):
    p.flat(circle(cx - dx, cy, r), CHEEK, .7)
    p.flat(circle(cx + dx, cy, r), CHEEK, .7)


def body(p, coat, legs_col, arms, sleeve=None, hand=WHT, feet_col=BLK, stripes=(), cross=None, dress=False):
    """Legs, a coat and two arms: arms = [(shoulder, hand) or (shoulder, elbow, hand)] x 2."""
    sleeve = sleeve or coat
    for sx in (-1, 1):
        p.shape(limb([(sx * 9, -32), (sx * 11, -5)], 13), legs_col, hl=False)
        p.shape(ellipse(sx * 13, -3, 9, 5), feet_col, hl=False)
    if dress:
        p.shape(poly([(-20, -68), (20, -68), (27, -28), (-27, -28)]), coat)
    else:
        p.shape(rrect(-21, -68, 42, 40, 12), coat)
    for y, c in stripes:
        p.shape(rrect(-21, y, 42, 5, 2), c, hl=False)
    if cross:
        p.flat(poly([(-3, -58), (3, -58), (3, -52), (9, -52), (9, -46), (3, -46), (3, -40), (-3, -40), (-3, -46), (-9, -46), (-9, -52), (-3, -52)]), cross)
    for a in arms:
        pts = list(a)
        p.shape(limb(pts, 10), sleeve, hl=False)
        p.shape(circle(*pts[-1], 7.5), hand, hl=False)


DOWN = [((-16, -60), (-30, -36)), ((16, -60), (30, -36))]


# ---------------------------------------------------------------- the helpers
def dog(p, pose="stand"):
    fur, ear = "#C98E5A", "#8A5A33"
    arms = DOWN
    if pose == "stop":
        arms = [DOWN[0], ((16, -60), (34, -80), (34, -96))]
    elif pose == "salute":
        arms = [DOWN[0], ((16, -60), (32, -78), (14, -100))]
    body(p, NAVY, NAVY, arms, stripes=[(-50, "#5A6FB0")])
    p.flat(circle(0, -60, 2.6), YEL)
    p.flat(circle(0, -48, 2.6), YEL)
    hy = -90
    for sx in (-1, 1):
        p.shape(ellipse(sx * 24, hy + 4, 8, 15, rot=-sx * 10), ear, hl=False)
    p.shape(circle(0, hy, 22), fur)
    p.shape(ellipse(0, hy + 9, 11, 8), lt(fur, .55), dots=False, hl=False)
    p.flat(ellipse(0, hy + 5, 4.5, 3.4), BLK)
    eyes(p, 0, hy - 3)
    smile(p, 0, hy + 11, 4, open_=pose == "stop")
    p.shape(poly([(-24, hy - 10), (-18, hy - 26), (0, hy - 33), (18, hy - 26), (24, hy - 10)]), NAVY)
    p.shape(rrect(-26, hy - 13, 52, 7, 3.5), BLK, hl=False)
    p.shape(circle(0, hy - 20, 5), YEL, hl=False)
    if pose == "stop":
        # the whistle
        p.shape(rrect(8, hy + 8, 12, 6, 3), LGREY, hl=False)
        for i, (x, y) in enumerate([(26, hy + 4), (30, hy + 10), (26, hy + 16)]):
            p.stroke([(x, y), (x + 6, y + (i - 1) * 2)], INK, 1.6)


def cat(p, pose="stand"):
    fur = "#F0A040"
    arms = DOWN
    if pose == "salute":
        arms = [DOWN[0], ((16, -60), (32, -78), (14, -100))]
    elif pose == "phone":
        arms = [DOWN[0], ((16, -60), (34, -74), (22, -92))]
    body(p, RED, BLK, arms, hand=fur, stripes=[(-56, YEL), (-42, YEL)])
    hy = -90
    p.shape(circle(0, hy, 22), fur)
    for sx in (-1, 1):
        p.shape(poly([(sx * 20, hy - 8), (sx * 18, hy - 30), (sx * 4, hy - 18)]), fur, hl=False)
    p.shape(ellipse(0, hy + 8, 10, 7), lt(fur, .6), dots=False, hl=False)
    eyes(p, 0, hy - 2)
    p.flat(poly([(-3, hy + 4), (3, hy + 4), (0, hy + 7)]), "#E07080")
    p.stroke([(-6, hy + 9), (-3, hy + 11), (0, hy + 8), (3, hy + 11), (6, hy + 9)], INK, 1.7)
    for sx in (-1, 1):
        for dy in (2, 7):
            p.stroke([(sx * 14, hy + dy), (sx * 28, hy + dy - 1)], INK, 1.1, op=.5)
    p.shape(poly([(-25, hy - 10), (-20, hy - 27), (0, hy - 36), (20, hy - 27), (25, hy - 10)]), YEL)
    p.shape(rrect(-28, hy - 13, 56, 7, 3.5), YEL, hl=False)
    p.shape(rrect(-6, hy - 31, 12, 13, 3), RED, hl=False)
    if pose == "phone":
        p.shape(rrect(14, -100, 12, 22, 4), BLU, hl=False)


def bunny(p, pose="stand"):
    fur, pink, dress = "#FBFBFB", "#F27AA0", "#EEF3F7"
    arms = DOWN
    if pose == "salute":
        arms = [DOWN[0], ((16, -60), (32, -78), (14, -100))]
    for sx in (-1, 1):
        p.shape(limb([(sx * 9, -32), (sx * 11, -5)], 12), fur, hl=False)
        p.shape(ellipse(sx * 13, -3, 9, 5), pink, hl=False)
    p.shape(poly([(-20, -68), (20, -68), (27, -28), (-27, -28)]), dress)
    p.flat(poly([(-3, -60), (3, -60), (3, -54), (9, -54), (9, -48), (3, -48), (3, -42), (-3, -42), (-3, -48), (-9, -48), (-9, -54), (-3, -54)]), pink)
    for a in arms:
        p.shape(limb(list(a), 10), dress, hl=False)
        p.shape(circle(*a[-1], 7.5), fur, hl=False)
    hy = -90
    for sx in (-1, 1):
        p.shape(ellipse(sx * 11, hy - 30, 7.5, 20, rot=sx * 8), fur, hl=False)
        p.flat(ellipse(sx * 11, hy - 30, 3.5, 13, rot=sx * 8), "#F9C6D5")
    p.shape(circle(0, hy, 22), fur, hl=False)
    eyes(p, 0, hy - 2)
    p.flat(ellipse(0, hy + 5, 3, 2.2), "#E07080")
    p.stroke([(-6, hy + 9), (-3, hy + 11), (0, hy + 8), (3, hy + 11), (6, hy + 9)], INK, 1.7)
    cheeks(p, 0, hy + 6)
    p.shape(rrect(-16, hy - 20, 32, 12, 4), dress, hl=False)
    p.flat(poly([(-2, hy - 19), (2, hy - 19), (2, hy - 16), (5, hy - 16), (5, hy - 12), (2, hy - 12), (2, hy - 9), (-2, hy - 9), (-2, hy - 12), (-5, hy - 12), (-5, hy - 16), (-2, hy - 16)]), pink)


# ---------------------------------------------------------------- grown-ups (about 175 tall)
def grownup(p, top, legs_col, hair, arms, dress=False, extra=None, hair_long=True, hat=None):
    s = 1.0
    for sx in (-1, 1):
        p.shape(limb([(sx * 10, -70), (sx * 12, -5)], 15), legs_col, hl=False)
        p.shape(ellipse(sx * 14, -3, 10, 5.5), BLK, hl=False)
    if dress:
        p.shape(poly([(-24, -128), (24, -128), (34, -62), (-34, -62)]), top)
    else:
        p.shape(rrect(-24, -128, 48, 62, 14), top)
    if extra:
        extra(p)
    for a in arms:
        p.shape(limb(list(a), 11), top, hl=False)
        p.shape(limb([a[-2] if len(a) > 2 else ((a[0][0] + a[-1][0]) / 2, (a[0][1] + a[-1][1]) / 2), a[-1]], 10), SKIN_A, hl=False)
        p.shape(circle(*a[-1], 7.5), SKIN_A, hl=False)
    hy = -150
    if hair_long:
        p.shape(union(ellipse(0, hy + 4, 25, 28), rrect(-25, hy, 50, 26, 10)), hair)
    p.shape(circle(0, hy, 21 * s), SKIN_A, hl=False)
    p.shape(poly([(-22, hy - 2), (-14, hy - 8), (-4, hy - 5), (6, hy - 10), (16, hy - 6), (22, hy - 2), (22, hy - 14), (0, hy - 24), (-22, hy - 14)]), hair, hl=False)
    eyes(p, 0, hy + 2, 8, 2.6)
    smile(p, 0, hy + 10, 4.5)
    cheeks(p, 0, hy + 8, 12, 3)
    if hat:
        hat(p, hy)


ADULT_DOWN = [((-20, -120), (-30, -80)), ((20, -120), (30, -80))]


def mom(p, pose="stand"):
    arms = ADULT_DOWN if pose == "stand" else [ADULT_DOWN[0], ((20, -120), (34, -96), (44, -76))]
    if pose == "ball":
        arms = [ADULT_DOWN[0], ((20, -120), (36, -100), (40, -82))]
    grownup(p, "#E8678A", "#5A6FB0", "#5A3A2A", arms, dress=True)
    if pose == "ball":
        p.shape(circle(44, -80, 9), RED)


def clerk(p):
    def apron(q):
        q.shape(rrect(-18, -112, 36, 50, 8), "#1FA64A")
        q.flat(rrect(-12, -104, 12, 6, 2), WHT, .9)
    grownup(p, "#FFFFFF", NAVY, "#3A2A22", ADULT_DOWN, extra=apron, hair_long=False,
            hat=lambda q, hy: q.shape(union(rrect(-20, hy - 26, 40, 14, 6), rrect(-4, hy - 16, 30, 6, 3)), "#1FA64A"))


def passer(p):
    grownup(p, "#9AA4AE", "#6B5A4A", "#6B4A2A", [((-20, -120), (-28, -78)), ((20, -120), (28, -96), (14, -112))], hair_long=False)
    p.shape(rrect(8, -122, 10, 16, 3), BLK, hl=False)


def mom_kid(p):
    grownup(p, "#FFB547", "#5A6FB0", "#3A2A22", [ADULT_DOWN[0], ((20, -120), (32, -96), (40, -78))])
    # the little one holding her hand
    kx = 52
    for sx in (-1, 1):
        p.shape(limb([(kx + sx * 6, -26), (kx + sx * 7, -4)], 10), "#5A6FB0", hl=False)
        p.shape(ellipse(kx + sx * 8, -2, 7, 4), BLK, hl=False)
    p.shape(rrect(kx - 14, -54, 28, 30, 10), "#7FC8F0")
    p.shape(limb([(kx - 10, -48), (40, -76)], 8), "#7FC8F0", hl=False)
    p.shape(circle(kx, -70, 15), SKIN_A, hl=False)
    p.shape(poly([(kx - 16, -72), (kx - 8, -78), (kx + 8, -78), (kx + 16, -72), (kx + 14, -84), (kx, -88), (kx - 14, -84)]), "#3A2A22", hl=False)
    eyes(p, kx, -69, 6, 2.1)
    smile(p, kx, -63, 3)


# ---------------------------------------------------------------- the friendly animals of 說「不要！」
def animal_base(p, coat, arms, legs_col=None, feet=None):
    legs_col = legs_col or coat
    for sx in (-1, 1):
        p.shape(limb([(sx * 11, -32), (sx * 13, -5)], 15), legs_col, hl=False)
        p.shape(ellipse(sx * 14, -3, 10, 5.5), feet or lt(legs_col, .2), hl=False)
    p.shape(ellipse(0, -48, 25, 26), coat)
    for a in arms:
        p.shape(limb(list(a), 12), coat, hl=False)
        p.shape(circle(*a[-1], 7.5), lt(coat, .25), hl=False)


def bear(p, pose):
    fur = "#B0784A"
    arms = [((-18, -62), (-46, -76)), ((18, -62), (30, -86))] if pose == "ask" else [((-18, -62), (-26, -36)), ((18, -62), (26, -36))]
    animal_base(p, fur, arms)
    p.shape(ellipse(0, -44, 14, 15), "#F1B98A", dots=False, hl=False)
    hy = -92
    for sx in (-1, 1):
        p.shape(circle(sx * 17, hy - 16, 8), fur, hl=False)
    p.shape(circle(0, hy, 22), fur)
    p.shape(ellipse(0, hy + 8, 10, 7), "#F1B98A", dots=False, hl=False)
    p.flat(ellipse(0, hy + 4, 4, 3), BLK)
    eyes(p, 0, hy - 4)
    smile(p, 0, hy + 10, 4)
    cheeks(p, 0, hy + 4, 14)
    # an apron: 熊阿姨
    p.shape(poly([(-14, -66), (14, -66), (18, -30), (-18, -30)]), "#F9C6D5", hl=False)


def monkey(p, pose):
    fur = "#9A6A44"
    arms = [((-18, -62), (-46, -70)), ((18, -62), (-40, -54))] if pose == "ask" else [((-18, -62), (-26, -36)), ((18, -62), (26, -36))]
    p.shape(limb([(18, -30), (40, -40), (44, -64)], 6), fur, hl=False)
    animal_base(p, fur, arms)
    p.shape(ellipse(0, -46, 13, 15), "#E8C49A", dots=False, hl=False)
    hy = -92
    for sx in (-1, 1):
        p.shape(circle(sx * 23, hy, 8), "#E8C49A", hl=False)
    p.shape(circle(0, hy, 21), fur)
    p.shape(union(ellipse(-6, hy - 2, 9, 10), ellipse(6, hy - 2, 9, 10), ellipse(0, hy + 8, 13, 9)), "#E8C49A", dots=False, hl=False)
    eyes(p, 0, hy - 2, 6)
    smile(p, 0, hy + 9, 5, open_=pose == "ask")
    if pose == "ask":
        for x, y in [(-56, -78), (-54, -64), (-50, -48)]:
            p.stroke([(x, y), (x - 6, y - 2)], INK, 1.5)


def elephant(p, pose):
    skin = "#A9B8CC"
    arms = [((-18, -62), (-26, -36)), ((18, -62), (-30, -60))] if pose == "ask" else [((-18, -62), (-26, -36)), ((18, -62), (34, -84))]
    animal_base(p, skin, arms)
    hy = -92
    for sx in (-1, 1):
        p.shape(ellipse(sx * 24, hy, 14, 17), skin, hl=False)
        p.flat(ellipse(sx * 24, hy, 8, 11), "#E7B8C4")
    p.shape(circle(0, hy, 22), skin)
    trunk = [(0, hy + 6), (-6, hy + 20), (-16, hy + 26)] if pose == "ask" else [(0, hy + 6), (4, hy + 20), (12, hy + 22)]
    p.shape(limb(trunk, 9), skin, hl=False)
    eyes(p, 0, hy - 4, 8, 2.6, closed=pose == "ask")
    # grandpa's round glasses
    for sx in (-1, 1):
        p.stroke([(sx * 8 + 5 * x, hy - 4 + 5 * y) for x, y in [(1, 0), (.7, .7), (0, 1), (-.7, .7), (-1, 0), (-.7, -.7), (0, -1), (.7, -.7), (1, 0)]], INK, 1.2)
    if pose == "ask":
        p.flat(ellipse(-14, hy + 26, 3, 2.5), "#E07080")
        p.shape(poly([(-30, hy + 6), (-25, hy + 1), (-20, hy + 6), (-25, hy + 12)]), "#F27AA0", dots=False, hl=False)
    p.shape(rrect(-18, hy - 26, 36, 8, 4), "#6B5A4A", hl=False)


def puppy(p, pose):
    fur, ear = "#E9C27A", "#B07A3A"
    p.shape(ellipse(4, -22, 26, 16), fur)
    for x in (-14, -4, 12, 22):
        p.shape(limb([(x, -14), (x, -3)], 8), fur, hl=False)
    p.shape(limb([(28, -26), (40, -40)], 6), fur, hl=False)
    hx, hy = (-18, -40)
    p.shape(circle(hx, hy, 17), fur)
    for sx in (-1, 1):
        p.shape(ellipse(hx + sx * 15, hy + 2, 6, 11, rot=-sx * 15), ear, hl=False)
    p.shape(ellipse(hx, hy + 7, 8, 6), lt(fur, .5), dots=False, hl=False)
    p.flat(ellipse(hx, hy + 4, 3.4, 2.6), BLK)
    if pose == "no":
        eyes(p, hx, hy - 3, 6, 2.4, closed=True)
        p.stroke([(hx - 3, hy + 11), (hx + 3, hy + 11)], INK, 1.6)
        for sx in (-1, 1):
            p.stroke([(hx + sx * 24, hy - 8), (hx + sx * 30, hy - 4)], INK, 1.6)
            p.stroke([(hx + sx * 24, hy + 2), (hx + sx * 30, hy + 2)], INK, 1.6)
    else:
        eyes(p, hx, hy - 3, 6, 2.4)
        smile(p, hx, hy + 10, 3.5)
        p.shape(ellipse(hx + 2, hy + 15, 3, 4), "#F27AA0", dots=False, hl=False)


def leash_dog(p):
    puppy(p, "ok")
    p.stroke([(-14, -26), (-10, -60), (-4, -96)], RED, 2.4)
    p.shape(rrect(-26, -30, 18, 5, 2.5), RED, hl=False)


def build():
    out = []

    def save(fn, rel, vb=(120, 150), feet=(60, 142), display=90, *a):
        p = Pic(*vb, display=display, ox=feet[0], oy=feet[1])
        fn(p, *a)
        p.save(rel)
        out.append(rel)

    for h, poses in [(dog, ["stand", "stop", "salute"]), (cat, ["stand", "salute", "phone"]), (bunny, ["stand", "salute"])]:
        for ps in poses:
            save(h, f"helpers/{h.__name__}_{ps}", (120, 160), (60, 154), 90, ps)
    big = ((140, 196), (70, 190), 100)
    save(mom, "road/mom", *big, "stand")
    save(mom, "road/mom_hand", *big, "hand")
    save(mom, "road/mom_ball", *big, "ball")
    save(clerk, "road/clerk", *big)
    save(passer, "road/passer", *big)
    save(mom_kid, "road/mom_kid", (170, 196), (66, 190), 110)
    for fn in (bear, monkey, elephant):
        for ps in ("ask", "ok"):
            save(fn, f"body/{fn.__name__}_{ps}", (130, 150), (70, 144), 100, ps)
    save(puppy, "body/puppy_no", (100, 76), (54, 70), 80, "no")
    save(puppy, "body/puppy_ok", (100, 76), (54, 70), 80, "ok")
    save(leash_dog, "road/leash_dog", (100, 110), (54, 104), 70)
    print(f"helpers: {len(out)} files")


if __name__ == "__main__":
    build()
