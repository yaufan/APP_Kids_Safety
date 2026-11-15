"""The squad base, the four world signs (blue circle 馬路, red square 救災, green circle 身體, yellow
diamond 家裡), arrows, the grown-ups' faces for parent mode, the stop hand, the helmet board and the
helmet on its hook, and the comic effects the app moves about: the burst bubble (the word inside is
drawn by Flutter with the font) and the speed lines.

    python3 build.py ui
"""
import sys

sys.dont_write_bytecode = True

import math  # noqa: E402

from kit import (BLU, CHEEK, GRN, INK, LGREY, NAVY, ORA, RED, SKY, WHT, YEL, Pic, burst_pts, circle, ellipse, limb,  # noqa: E402
                 poly, rect, rpoly, rrect, star, union)

SKIN_A = "#F0C7A0"


def sign(world):
    p = Pic(120, 120, 110)
    if world == "road":
        p.shape(circle(60, 60, 54), BLU)
        p.shape(rrect(44, 22, 32, 76, 10), "#2A3140", hl=False)
        for i, c in enumerate([RED, YEL, GRN]):
            p.shape(circle(60, 38 + i * 22, 8), c, dots=False, hl=False)
    elif world == "rescue":
        p.shape(rrect(8, 8, 104, 104, 22), RED)
        # a fire engine's ladder and bell, simply
        p.shape(rrect(26, 58, 68, 30, 8), WHT, hl=False)
        p.shape(circle(42, 90, 8), "#2A3140", hl=False)
        p.shape(circle(80, 90, 8), "#2A3140", hl=False)
        p.shape(rrect(30, 40, 60, 8, 3), YEL, hl=False)
        p.shape(rrect(70, 46, 16, 14, 3), "#9FD3F0", dots=False, hl=False)
    elif world == "body":
        p.shape(circle(60, 60, 54), GRN)
        h = union(circle(46, 50, 16), circle(74, 50, 16), poly([(32, 58), (88, 58), (60, 92)]))
        p.shape(h, WHT, hl=False)
    else:
        p.shape(rpoly([(60, 4), (116, 60), (60, 116), (4, 60)], 10), "#F2B600")
        p.shape(poly([(36, 64), (60, 40), (84, 64), (84, 86), (36, 86)]), "#2A3140", hl=False)
        p.shape(rrect(54, 68, 12, 18, 2), "#F2B600", dots=False, hl=False)
    return p


def arrow(left):
    p = Pic(80, 80, 60)
    pts = [(10, 40), (40, 10), (40, 26), (70, 26), (70, 54), (40, 54), (40, 70)]
    if not left:
        pts = [(80 - x, y) for x, y in pts]
    p.shape(rpoly(pts, 3), YEL)
    return p


def adult(kind):
    p = Pic(80, 80, 60)
    p.shape(circle(40, 40, 38), {"mom": "#F9C6D5", "dad": "#BFE3F5", "grandma": "#E7D7F5", "grandpa": "#D7EBD2", "teacher": "#FFE6A6", "aunt": "#FFD8C2", "uncle": "#D5DBE0"}[kind], dots=False, hl=False)
    hair = {"mom": "#5A3A2A", "dad": "#3A2A22", "grandma": "#C9CDD3", "grandpa": "#B9BEC6", "teacher": "#7A4A2A", "aunt": "#9A5A32", "uncle": "#2E2420"}[kind]
    if kind in ("mom", "aunt", "grandma", "teacher"):
        p.shape(union(ellipse(40, 44, 22, 24), rrect(18, 40, 44, 22, 8)), hair, hl=False)
    p.shape(rrect(18, 62, 44, 18, 9), {"teacher": GRN, "dad": BLU, "uncle": NAVY}.get(kind, "#E8678A"), hl=False)
    p.shape(circle(40, 42, 17), SKIN_A, hl=False)
    p.shape(poly([(22, 40), (28, 30), (40, 26), (52, 30), (58, 40), (52, 34), (40, 32), (28, 34)]).buffer(2), hair, hl=False)
    if kind == "grandma":
        p.shape(circle(40, 22, 7), hair, hl=False)
    for x in (34, 46):
        p.flat(circle(x, 43, 2.2), INK)
    if kind in ("grandma", "grandpa", "teacher"):
        for x in (34, 46):
            p.stroke([(x + 4.5 * math.cos(a), 43 + 4.5 * math.sin(a)) for a in [i * math.pi / 6 for i in range(13)]], INK, 1.1)
    if kind in ("dad", "uncle", "grandpa"):
        p.stroke([(35, 52), (45, 52)], INK, 1.6) if kind == "grandpa" else None
    p.stroke([(36, 50), (40, 53), (44, 50)], INK, 1.5)
    p.flat(circle(29, 49, 2.6), CHEEK, .7)
    p.flat(circle(51, 49, 2.6), CHEEK, .7)
    return p


def stop_hand():
    p = Pic(80, 80, 60)
    p.shape(circle(40, 40, 36), RED, hl=False)
    palm = union(rrect(24, 34, 32, 30, 10), *[rrect(24 + i * 8.5, 14 + (abs(i - 1.5) * 4), 7.5, 26, 3.7) for i in range(4)], rot_thumb())
    p.shape(palm, WHT, hl=False)
    return p


def rot_thumb():
    from kit import rot
    return rot(rrect(14, 40, 18, 8, 4), -35, (28, 44))


def burst(col):
    p = Pic(200, 120, 130)
    p.shape(poly(burst_pts(100, 60, 94, 55, 16, .74)), col, dots=False)
    return p


def speed():
    """Speed lines: drawn behind something moving to the right (the app mirrors them)."""
    p = Pic(80, 60, 50)
    for i, (y, l) in enumerate([(10, 70), (24, 50), (38, 64), (52, 40)]):
        p.stroke([(76 - l, y), (76, y)], INK, 2.2)
    return p


def base_bg():
    """The squad base on the home page: a yellow comic sky with dots, the base building and a flag."""
    p = Pic(400, 220, 390)
    p.shape(rect(0, 0, 400, 220), "#FFD54A", dots=False, outline=False, hl=False)
    for i in range(18):                                                         # comic rays
        a0, a1 = math.radians(i * 20), math.radians(i * 20 + 9)
        p.flat(poly([(200, 230), (200 + 520 * math.cos(a0), 230 - 520 * math.sin(a0)), (200 + 520 * math.cos(a1), 230 - 520 * math.sin(a1))]).intersection(rect(0, 0, 400, 220)), "#FFE27A")
    p.shape(rrect(250, 92, 130, 110, 6), "#F2F2F2", hl=False)                 # the base
    p.shape(rrect(244, 80, 142, 18, 6), BLU, hl=False)
    for x in (264, 300, 336):
        p.shape(rrect(x, 112, 26, 26, 4), SKY, dots=False, hl=False)
    p.shape(rrect(290, 152, 48, 50, 4), RED, hl=False)
    p.shape(limb([(372, 80), (372, 24)], 4), LGREY, hl=False)
    p.shape(poly([(374, 26), (398, 34), (374, 44)]), ORA, hl=False)
    p.shape(rect(0, 196, 400, 24), "#7F8A96", hl=False)
    for x in range(10, 400, 46):
        p.flat(rrect(x, 206, 24, 4, 2), WHT, .8)
    return p


def helmet_board():
    """The big helmet the badges are stuck on (安全帽頁)."""
    p = Pic(300, 210, 300, ox=150, oy=200)
    p.shape(poly([(-140, 0), *[(140 * math.cos(math.radians(a)), -190 * math.sin(math.radians(a))) for a in range(0, 181, 6)]]).buffer(4).buffer(-4), YEL)
    p.shape(rrect(-150, -16, 300, 22, 10), YEL, hl=False)
    p.flat(rrect(-12, -182, 24, 160, 12), WHT, .45)
    return p


def helmet_hook():
    """The helmet hung up on its hook (the rest page)."""
    p = Pic(120, 120, 100)
    p.shape(rrect(52, 4, 16, 10, 3), LGREY, hl=False)
    p.stroke([(60, 14), (60, 30)], INK, 2)
    p.shape(poly([(14, 96), *[(60 + 46 * math.cos(math.radians(a)), 96 - 62 * math.sin(math.radians(a))) for a in range(0, 181, 10)]]), YEL)
    p.shape(rrect(8, 90, 104, 12, 6), YEL, hl=False)
    p.flat(rrect(56, 38, 8, 50, 4), WHT, .5)
    return p


def star_badge():
    p = Pic(80, 80, 50)
    p.shape(star(40, 42, 36, 16), YEL)
    return p


def build():
    files = {f"ui/sign_{w}": sign(w) for w in ("road", "rescue", "body", "home")}
    files.update({"ui/arrow_l": arrow(True), "ui/arrow_r": arrow(False), "ui/stop_hand": stop_hand(), "ui/base_bg": base_bg(),
                  "ui/helmet_board": helmet_board(), "ui/helmet_hook": helmet_hook(), "ui/star": star_badge(),
                  "fx/burst": burst(WHT), "fx/burst_yellow": burst("#FFE27A"), "fx/speed": speed()})
    for k in ("mom", "dad", "grandma", "grandpa", "teacher", "aunt", "uncle"):
        files[f"ui/adult_{k}"] = adult(k)
    for k, p in files.items():
        p.save(k)
    print(f"ui: {len(files)} files")


if __name__ == "__main__":
    build()
