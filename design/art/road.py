"""馬路世界: the crossing, the front door, the car park, inside the car, the scooter, the night market,
and the things on them (the Taiwan pedestrian light with its walking green man, cars, the belt...).

Backgrounds are 400 x 300 (the app's 4:3 picture box); things are placed by app/lib/core/levels.dart.

    python3 build.py road
"""
import sys

sys.dont_write_bytecode = True

from kit import (BLK, BLU, GREY, GRN, INK, LGREY, NAVY, RED, ROAD, SKY, WHT, YEL, Pic, circle, ellipse, limb, lt,  # noqa: E402
                 poly, rect, rrect, star, union)

W, H = 400, 300
BG = 390          # backgrounds are shown about 390 points wide on a phone


def sky(p, top=SKY):
    p.shape(rect(0, 0, W, H), top, dots=False, outline=False, hl=False)


def buildings(p, y0, y1, cols=("#F5C26B", "#8FC1E3", "#F29E8E", "#A8D5A2", "#C9B6E4")):
    xs = [0, 70, 150, 230, 300, 400]
    for i, (a, b) in enumerate(zip(xs, xs[1:])):
        top = y0 + (i * 17) % 28
        p.shape(rect(a + 2, top, b - a - 4, y1 - top), cols[i % len(cols)], hl=False, sparse=1.6)
        for r in range(int((y1 - top - 10) // 22)):
            for c in range(int((b - a - 10) // 24)):
                p.flat(rrect(a + 10 + c * 24, top + 8 + r * 22, 12, 12, 2), WHT, .6)


def seg_digits(p, x, y, text, h, col):
    """Seven-segment digits (no SVG text): x, y top-left, h tall."""
    segs = {"0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd", "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg"}
    w = h * .55
    t = h * .14
    for i, ch in enumerate(text):
        ox = x + i * (w + t * 1.6)
        lines = {"a": [(ox, y), (ox + w, y)], "b": [(ox + w, y), (ox + w, y + h / 2)], "c": [(ox + w, y + h / 2), (ox + w, y + h)],
                 "d": [(ox, y + h), (ox + w, y + h)], "e": [(ox, y + h / 2), (ox, y + h)], "f": [(ox, y), (ox, y + h / 2)], "g": [(ox, y + h / 2), (ox + w, y + h / 2)]}
        for sgm in segs[ch]:
            p.flat(limb(lines[sgm], t), col)


def walker(p, cx, cy, s, col, pose):
    """Taiwan's pedestrian figures: the walking green man, the running one, the standing red man."""
    p.flat(circle(cx + (2 * s if pose != "stand" else 0), cy - 15 * s, 4.6 * s), col)
    if pose == "stand":
        body = [((cx, cy - 10 * s), (cx, cy + 3 * s)), ((cx - 4 * s, cy + 3 * s), (cx - 4 * s, cy + 16 * s)), ((cx + 4 * s, cy + 3 * s), (cx + 4 * s, cy + 16 * s)),
                ((cx, cy - 8 * s), (cx - 7 * s, cy + 2 * s)), ((cx, cy - 8 * s), (cx + 7 * s, cy + 2 * s))]
    elif pose == "walk":
        body = [((cx + 2 * s, cy - 10 * s), (cx, cy + 2 * s)), ((cx, cy + 2 * s), (cx - 6 * s, cy + 15 * s)), ((cx, cy + 2 * s), (cx + 8 * s, cy + 14 * s)),
                ((cx + 1 * s, cy - 8 * s), (cx - 7 * s, cy - 1 * s)), ((cx + 1 * s, cy - 8 * s), (cx + 8 * s, cy - 3 * s))]
    else:  # run: a long stride, leaning forward
        body = [((cx + 4 * s, cy - 10 * s), (cx, cy + 2 * s)), ((cx, cy + 2 * s), (cx - 10 * s, cy + 12 * s)), ((cx, cy + 2 * s), (cx + 11 * s, cy + 10 * s)),
                ((cx + 3 * s, cy - 8 * s), (cx - 8 * s, cy - 4 * s)), ((cx + 3 * s, cy - 8 * s), (cx + 11 * s, cy - 12 * s))]
    for a, b in body:
        p.flat(limb([a, b], 3.8 * s), col)


def ped_light(state):
    p = Pic(60, 180, display=50)
    p.shape(limb([(30, 110), (30, 176)], 7), GREY, hl=False)
    p.shape(rrect(6, 4, 48, 112, 8), BLK)
    p.shape(rrect(11, 9, 38, 40, 5), "#30363B", dots=False, hl=False)
    p.shape(rrect(11, 56, 38, 54, 5), "#30363B", dots=False, hl=False)
    if state == "red":
        seg_digits(p, 15, 17, "45", 24, RED)
        p.flat(circle(30, 83, 23), RED, .16)
        walker(p, 30, 85, 1.3, RED, "stand")
    elif state == "green":
        seg_digits(p, 15, 17, "18", 24, GRN)
        p.flat(circle(30, 83, 23), GRN, .18)
        walker(p, 30, 85, 1.3, GRN, "walk")
    else:
        seg_digits(p, 23, 17, "3", 24, GRN)
        p.flat(circle(30, 83, 23), GRN, .18)
        walker(p, 30, 85, 1.3, GRN, "run")
    return p


def car(col, wave=False, facing=1, parked=False):
    """A small round car seen from the side, facing right (facing=-1: left)."""
    p = Pic(130, 80, display=110)
    f = facing

    def X(x):
        return 65 + f * x
    pts = [(-60, 18), (-60, -8), (-52, -16), (-30, -16), (-14, -36), (26, -36), (40, -18), (56, -14), (62, -4), (62, 18)]
    p.shape(poly([(X(x), 52 + y) for x, y in pts]).buffer(4).buffer(-4), col)
    for wx, wy, ww in [(-24, -32, 26), (6, -32, 20)]:
        a, b = X(wx), X(wx + ww)
        p.shape(poly([(min(a, b), 52 + wy), (max(a, b), 52 + wy), (max(a, b) + (4 if f > 0 and wx > 0 else 0), 52 - 18), (min(a, b) - (4 if f < 0 and wx > 0 else 0), 52 - 18)]).buffer(2).buffer(-2), "#CFE7F7", dots=False)
    for wx in (-36, 38):
        p.shape(circle(X(wx), 70, 11), BLK, hl=False)
        p.shape(circle(X(wx), 70, 4.5), LGREY, dots=False, hl=False)
    p.shape(rrect(min(X(58), X(64)) - 2, 40, 8, 9, 3), YEL, dots=False, hl=False)
    if not parked:
        # the driver: a round little face in the window
        p.shape(circle(X(16), 52 - 24, 7), "#F0C7A0", dots=False, hl=False)
        p.flat(circle(X(18), 52 - 25, 1.3), INK)
    if wave:
        p.shape(limb([(X(22), 52 - 20), (X(34), 52 - 44)], 6), "#F0C7A0", hl=False)
        p.shape(circle(X(35), 52 - 47, 5.5), "#F0C7A0", hl=False)
        for i in range(3):
            p.stroke([(X(42 + i * 2), 52 - 52 + i * 6), (X(48 + i * 2), 52 - 55 + i * 6)], INK, 1.6)
    return p


def street():
    p = Pic(W, H, BG)
    sky(p)
    buildings(p, 8, 74)
    p.shape(rect(0, 70, W, 26), "#D9DEE3", dots=False, hl=False)            # far pavement
    p.shape(rect(0, 95, W, 120), ROAD, hl=False, sparse=1.6)                  # the road
    for x in range(10, W, 46):
        if not 140 < x < 255:
            p.flat(rrect(x, 153, 24, 4, 2), WHT, .85)
    for i in range(6):                                                        # the zebra
        p.flat(rrect(152, 102 + i * 19, 96, 10, 2), WHT, .95)
    p.flat(rect(0, 211, W, 5), WHT)                                            # the line to stop at
    p.shape(rect(0, 216, W, 84), "#E4D7C4", hl=False, sparse=1.6)            # our pavement
    for x in range(0, W, 40):
        p.stroke([(x, 216), (x, 300)], "#CDBFA9", 1.0)
    p.stroke([(0, 258), (W, 258)], "#CDBFA9", 1.0)
    return p


def door():
    p = Pic(W, H, BG)
    sky(p)
    p.shape(rect(0, 0, 250, 236), "#F2D9B8", hl=False, sparse=1.6)            # our building
    p.shape(rrect(40, 70, 90, 166, 6), "#B9793F")                             # the front door
    p.flat(circle(118, 160, 4), YEL)
    p.shape(rrect(150, 60, 70, 60, 4), "#CFE7F7", dots=False)
    p.shape(rrect(250, 120, 150, 116, 4), "#A8D5A2", hl=False)               # a hedge
    p.shape(rect(0, 236, W, 64), "#E4D7C4", hl=False, sparse=1.6)
    for x in range(0, W, 40):
        p.stroke([(x, 236), (x, 300)], "#CDBFA9", 1.0)
    return p


def parking():
    p = Pic(W, H, BG)
    sky(p)
    buildings(p, 10, 100, ("#C9B6E4", "#F5C26B", "#8FC1E3"))
    p.shape(rect(0, 100, W, 200), "#9AA2AC", hl=False, sparse=1.6)
    for x in (200, 330):
        p.flat(rect(x, 140, 5, 120), WHT, .9)
    return p


def car_inside():
    p = Pic(W, H, BG)
    p.shape(rect(0, 0, W, H), "#5B6B85", dots=False, outline=False, hl=False)
    p.shape(rrect(250, 20, 140, 130, 18), "#CFE7F7", dots=False)                # the side window
    p.shape(rrect(10, 40, 230, 250, 26), "#3E4C66", hl=False)                 # the back seat
    p.shape(rrect(60, 70, 120, 210, 30), "#E8392F")                            # the child seat
    p.shape(rrect(80, 92, 80, 150, 20), "#F07A6E", dots=False, hl=False)
    p.shape(rrect(240, 160, 160, 140, 10), "#46546E", hl=False)               # the door
    p.flat(rrect(270, 200, 60, 10, 5), "#2E3A50")
    return p


def scooter_bg():
    p = Pic(W, H, BG)
    sky(p)
    buildings(p, 10, 180, ("#A8D5A2", "#F29E8E", "#8FC1E3"))
    p.shape(rect(0, 180, W, 120), "#E4D7C4", hl=False, sparse=1.6)
    for x in range(0, W, 40):
        p.stroke([(x, 180), (x, 300)], "#CDBFA9", 1.0)
    return p


def market():
    p = Pic(W, H, BG)
    p.shape(rect(0, 0, W, H), "#2F3D6B", dots=False, outline=False, hl=False)  # the evening sky
    for x, y in [(30, 20), (120, 36), (300, 18), (370, 40)]:
        p.flat(star(x, y, 4, 1.8), "#FFE6A6")
    stalls = [(0, "#E8392F"), (100, "#1F6FD6"), (200, "#1FA64A"), (300, "#FF8A1E")]
    for x, c in stalls:
        p.shape(rect(x + 6, 70, 88, 110), "#F2D9B8", hl=False)
        p.shape(poly([(x, 70), (x + 100, 70), (x + 94, 48), (x + 6, 48)]), c, hl=False)
        for i in range(5):
            p.flat(rect(x + 6 + i * 18, 48, 9, 22), WHT, .45)
        p.shape(rrect(x + 14, 130, 72, 22, 4), lt(c, .3), hl=False)
    for i, x in enumerate(range(10, W, 36)):                                    # lanterns on a string
        p.shape(ellipse(x, 30 + (i % 2) * 4, 7, 9), "#FF5A4A" if i % 2 else YEL, hl=False)
    p.stroke([(0, 22), (W, 26)], INK, 1.0)
    p.shape(rect(0, 180, W, 120), "#C8B89E", hl=False, sparse=1.6)
    return p


# ---------------------------------------------------------------- things
def thing(w, h, display):
    return Pic(w, h, display)


def ball():
    p = thing(40, 40, 30)
    p.shape(circle(20, 20, 17), RED)
    p.stroke([(5, 18), (20, 22), (35, 18)], WHT, 3)
    return p


def balloon():
    p = thing(50, 120, 50)
    p.stroke([(25, 62), (22, 90), (27, 118)], INK, 1.4)
    p.shape(ellipse(25, 32, 22, 28), "#F27AA0")
    p.shape(poly([(21, 60), (29, 60), (25, 66)]), "#F27AA0", hl=False)
    return p


def belt():
    p = thing(50, 60, 40)
    p.shape(rrect(17, 0, 16, 40, 3), "#5A6474", hl=False)
    p.shape(rrect(12, 36, 26, 20, 4), LGREY)
    p.flat(rrect(19, 42, 12, 8, 2), "#5A6474")
    return p


def belt_on():
    """The belt across the squad member in the seat (laid over sit_*.svg in the same box)."""
    p = Pic(120, 150, display=110, ox=60, oy=146)
    p.shape(limb([(-24, -70), (16, -36)], 9), "#5A6474", hl=False)
    p.shape(limb([(-22, -30), (22, -30)], 9), "#5A6474", hl=False)
    p.shape(rrect(14, -40, 14, 14, 3), LGREY)
    return p


def buckle():
    p = thing(40, 40, 32)
    p.shape(rrect(6, 6, 28, 28, 6), "#C8102E")
    p.flat(rrect(12, 16, 16, 8, 2), BLK)
    return p


def bear_window(out):
    p = thing(140, 140, 120)
    p.shape(rrect(4, 10, 132, 110, 16), "#7FA3C9", hl=False)                 # the next car's window
    p.shape(rrect(14, 20, 112, 90, 12), "#CFE7F7", dots=False)
    fur = "#B0784A"
    for sx in (-1, 1):
        p.shape(circle(60 + sx * 17, 48, 8), fur, hl=False)
    p.shape(circle(60, 64, 22), fur)
    p.shape(ellipse(60, 72, 10, 7), "#F1B98A", dots=False, hl=False)
    p.flat(ellipse(60, 68, 4, 3), BLK)
    for x in (52, 68):
        p.flat(circle(x, 60, 2.6), INK)
    if out:
        p.shape(limb([(80, 90), (110, 110), (136, 126)], 12), fur, hl=False)
        p.shape(circle(136, 126, 8), "#D49A6A", hl=False)
        p.stroke([(70, 74), (75, 77)], INK, 1.6)
    else:
        p.shape(limb([(40, 100), (52, 84)], 12), fur, hl=False)
        p.shape(limb([(80, 100), (68, 84)], 12), fur, hl=False)
        p.stroke([(55, 76), (60, 80), (65, 76)], INK, 1.8)
    return p


def scooter():
    p = thing(200, 150, 200)
    p.shape(circle(40, 120, 24), BLK, hl=False)
    p.shape(circle(162, 120, 24), BLK, hl=False)
    for x in (40, 162):
        p.shape(circle(x, 120, 9), LGREY, dots=False, hl=False)
    p.shape(union(rrect(30, 80, 150, 36, 18), poly([(140, 60), (178, 20), (190, 26), (160, 90)])), "#45B3E0")
    p.shape(rrect(40, 66, 80, 18, 9), BLK, hl=False)                           # the seat
    p.shape(limb([(176, 22), (196, 14)], 7), BLK, hl=False)
    p.shape(circle(186, 40, 7), YEL, hl=False)
    return p


def kid_helmet():
    p = thing(60, 50, 44)
    p.shape(poly([(4, 40), (6, 22), (18, 8), (30, 4), (42, 8), (54, 22), (56, 40)]).buffer(3).buffer(-3), "#FF8A1E")
    p.shape(rrect(2, 36, 56, 9, 4), "#FF8A1E", hl=False)
    p.flat(rrect(27, 8, 6, 26, 3), WHT, .6)
    return p


def chin_buckle():
    p = thing(30, 30, 26)
    p.shape(rrect(4, 9, 22, 12, 4), BLK)
    p.flat(rrect(11, 13, 8, 4, 2), LGREY)
    return p


def run_icon():
    """A child running off (the wrong choice on a card)."""
    p = thing(80, 80, 70)
    from kit import SKIN, ORA
    p.shape(limb([(36, 52), (22, 70)], 9), NAVY, hl=False)
    p.shape(limb([(42, 52), (60, 66)], 9), NAVY, hl=False)
    p.shape(rrect(28, 30, 22, 26, 8), ORA)
    p.shape(limb([(32, 36), (16, 44)], 7), SKIN, hl=False)
    p.shape(limb([(46, 36), (60, 26)], 7), SKIN, hl=False)
    p.shape(circle(44, 18, 12), SKIN, hl=False)
    for i in range(3):
        p.stroke([(4, 30 + i * 9), (16 - i * 3, 30 + i * 9)], INK, 2.2)
    return p


def build():
    files = {
        "road/street": street(), "road/door": door(), "road/parking": parking(), "road/car_inside": car_inside(),
        "road/scooter_bg": scooter_bg(), "road/market": market(),
        "road/ped_red": ped_light("red"), "road/ped_green": ped_light("green"), "road/ped_run": ped_light("run"),
        "road/car_blue": car(BLU), "road/car_red": car(RED), "road/car_red_wave": car(RED, wave=True), "road/car_parked": car("#7FC8A9", facing=-1, parked=True),
        "road/ball": ball(), "road/balloon": balloon(), "road/belt": belt(), "road/belt_on": belt_on(), "road/buckle": buckle(),
        "road/bear_out": bear_window(True), "road/bear_in": bear_window(False), "road/scooter": scooter(), "road/kid_helmet": kid_helmet(),
        "road/chin_buckle": chin_buckle(), "ui/run": run_icon(),
    }
    for k, p in files.items():
        p.save(k)
    print(f"road: {len(files)} files")


if __name__ == "__main__":
    build()
