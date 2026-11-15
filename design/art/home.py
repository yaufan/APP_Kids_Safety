"""家裡世界: the kitchen, the living room, the bathroom and the balcony, and each danger with its safe
version (the pot handle turned in, the socket cover, the medicine up high, the water let out...).

    python3 build.py home
"""
import sys

sys.dont_write_bytecode = True

from kit import (BLK, BLU, BROWN, GREY, GRN, INK, LGREY, RED, SKY, WHT, WOOD, YEL, Pic, circle, ellipse, limb, lt,  # noqa: E402
                 poly, quad, rect, rrect, union)

W, H = 400, 300
BG = 390


def walls(p, wall, floor, floor_y):
    p.shape(rect(0, 0, W, floor_y), wall, dots=False, outline=False, hl=False)
    p.shape(rect(0, floor_y, W, H - floor_y), floor, hl=False, sparse=1.7)
    p.flat(rect(0, floor_y - 5, W, 5), lt(floor, .3))


def kitchen():
    p = Pic(W, H, BG)
    walls(p, "#FFF4DC", "#D9C3A0", 262)
    for x in range(0, W, 26):                                                   # tiles behind the counter
        for y in range(60, 140, 26):
            p.flat(rect(x + 1, y + 1, 24, 24), "#F3E6C8")
    p.shape(rrect(30, 8, 140, 50, 6), "#CFE7F7", dots=False)                   # windows
    p.shape(rrect(230, 8, 140, 50, 6), "#CFE7F7", dots=False)
    p.shape(rect(0, 150, W, 112), "#8FC1E3", hl=False)                         # the counter
    p.shape(rect(0, 140, W, 12), "#E9EEF2", hl=False)
    p.shape(rrect(70, 128, 100, 14, 3), "#4A5361", hl=False)                   # the stove
    for x in (95, 145):
        p.flat(ellipse(x, 135, 14, 4), "#2E3540")
    return p


def pot(out):
    p = Pic(110, 70, 90)
    p.shape(rrect(20, 20, 64, 40, 10), RED)
    p.shape(rrect(14, 14, 76, 10, 5), "#C8102E", hl=False)
    if out:
        p.shape(limb([(86, 30), (108, 44)], 8), BLK, hl=False)              # the handle sticking out
    else:
        p.shape(limb([(70, 22), (50, 10)], 8), BLK, hl=False)               # turned in, over the stove
    for x in (36, 52, 68):
        p.stroke([(x, 10), (x + 3, 2), (x, -4)], "#C8D2DC", 1.6, op=.8)
    return p


def drawer(shut):
    p = Pic(100, 50, 90)
    p.shape(rrect(4, 4, 92, 42, 6), "#6FA9D6")
    p.shape(rrect(36, 20, 28, 8, 4), WHT, hl=False)
    if not shut:
        p.shape(rrect(10, 0, 80, 10, 3), "#5A8FBF", hl=False)
    return p


def knife():
    p = Pic(80, 40, 60)
    p.shape(poly([(4, 22), (50, 10), (54, 30), (8, 30)]).buffer(1), "#D5DBE0")
    p.shape(rrect(52, 16, 26, 12, 5), BLK, hl=False)
    return p


def kettle(cord_down):
    p = Pic(70, 160, 60)
    p.shape(rrect(10, 10, 50, 56, 14), "#F5F7F9")
    p.shape(limb([(14, 20), (2, 34)], 6), "#F5F7F9", hl=False)
    p.shape(rrect(14, 62, 42, 10, 4), BLK, hl=False)
    if cord_down:
        p.stroke(quad((52, 68), (66, 100), (56, 156)), BLK, 2.2)
        p.shape(rrect(50, 146, 12, 12, 3), LGREY, hl=False)
    else:
        p.stroke(quad((52, 68), (62, 72), (66, 66)), BLK, 2.2)
    p.flat(circle(48, 30, 3), RED)
    return p


def bag():
    p = Pic(70, 60, 60)
    p.shape(poly([(8, 56), (4, 20), (18, 18), (20, 4), (28, 18), (42, 18), (50, 4), (52, 18), (66, 20), (62, 56)]).buffer(2).buffer(-2), "#F2F6F9")
    p.stroke([(12, 30), (58, 30)], "#C9D4DF", 1.4)
    return p


def cupboard():
    p = Pic(80, 90, 70)
    p.shape(rrect(4, 4, 72, 82, 6), "#6FA9D6")
    p.flat(circle(64, 44, 3.5), WHT)
    return p


def living():
    p = Pic(W, H, BG)
    walls(p, "#F2F0E6", "#C9A57C", 236)
    p.shape(rrect(318, 50, 76, 110, 4), WHT)                                    # the window
    p.shape(rrect(324, 56, 64, 98, 3), SKY, dots=False)
    p.shape(rrect(70, 196, 160, 12, 4), WOOD)                                   # a low table
    for x in (86, 214):
        p.shape(limb([(x, 206), (x, 236)], 8), "#9A6232", hl=False)
    p.shape(rrect(240, 150, 70, 80, 12), "#E8678A", hl=False)                  # an armchair
    p.flat(rect(0, 228, W, 8), "#EAE2CF")                                       # the skirting
    return p


def socket(cover):
    p = Pic(40, 40, 32)
    p.shape(rrect(4, 4, 32, 32, 6), WHT)
    if cover:
        p.shape(rrect(8, 8, 24, 24, 5), "#7FC8F0", hl=False)
    else:
        for x in (14, 26):
            p.flat(rrect(x - 2, 13, 4, 10, 2), BLK)
        p.flat(circle(20, 28, 2.4), BLK)
    return p


def high_cabinet():
    p = Pic(110, 90, 80)
    p.shape(rrect(4, 4, 102, 82, 6), BROWN)
    p.stroke([(55, 8), (55, 82)], INK, 1.4)
    for x in (48, 62):
        p.flat(circle(x, 46, 3), YEL)
    return p


def medicine():
    p = Pic(50, 50, 40)
    p.shape(rrect(8, 14, 34, 32, 6), "#FFFFFF")
    p.shape(rrect(12, 4, 26, 12, 3), RED, hl=False)
    for x, y, c in [(18, 30, "#F27AA0"), (30, 34, YEL), (24, 40, "#7FC8F0")]:
        p.shape(ellipse(x, y, 5, 3.5), c, dots=False, hl=False)
    return p


def coins():
    p = Pic(60, 40, 50)
    for x, y, c in [(14, 26, "#E9B64B"), (30, 20, LGREY), (46, 28, "#E9B64B")]:
        p.shape(circle(x, y, 8), c, hl=False)
    p.shape(circle(28, 32, 5), RED, hl=False)
    p.flat(circle(26.5, 32, 1), WHT)
    p.flat(circle(29.5, 32, 1), WHT)
    return p


def box(shut):
    p = Pic(60, 50, 50)
    p.shape(rrect(6, 18, 48, 28, 4), "#B45CD6")
    if shut:
        p.shape(rrect(2, 12, 56, 10, 4), "#9A44BC", hl=False)
    else:
        p.shape(poly([(6, 18), (54, 18), (58, 2), (10, 2)]), "#9A44BC", hl=False)
    return p


def chair():
    p = Pic(70, 130, 60)
    for x in (12, 58):
        p.shape(limb([(x, 70), (x, 126)], 7), "#9A6232", hl=False)
    p.shape(rrect(6, 4, 58, 60, 8), WOOD)
    p.shape(rrect(4, 60, 62, 14, 6), WOOD)
    return p


def bath():
    p = Pic(W, H, BG)
    walls(p, "#E6F4F7", "#CFE3EA", 250)
    for x in range(0, W, 30):
        for y in range(0, 250, 30):
            p.flat(rect(x + 1, y + 1, 28, 28), "#D8EDF2")
    return p


def tub(full):
    p = Pic(200, 110, 200)
    p.shape(rrect(4, 20, 192, 86, 30), WHT)
    if full:
        p.shape(rrect(14, 24, 172, 18, 9), "#7FD0F5", dots=False, hl=False)
        for x in (50, 110, 160):
            p.stroke([(x - 10, 33), (x, 30), (x + 10, 33)], WHT, 1.6)
    else:
        p.shape(rrect(14, 24, 172, 18, 9), "#EEF6F9", dots=False, hl=False)
    p.shape(circle(170, 70, 6), "#8E979F", hl=False)                            # the plug
    if not full:
        p.stroke([(170, 64), (176, 48)], INK, 1.4)
    for x in (30, 170):
        p.shape(rrect(x - 8, 96, 16, 12, 4), LGREY, hl=False)
    return p


def floor_wet(safe):
    p = Pic(110, 40, 100)
    if safe:
        p.shape(rrect(4, 6, 102, 30, 8), "#6FBF73")
        for x in range(14, 100, 12):
            for y in (14, 26):
                p.flat(circle(x, y, 2.4), "#4E9A52")
    else:
        for x, y, rx in [(24, 18, 20), (66, 22, 26), (92, 14, 12)]:
            p.shape(ellipse(x, y, rx, 8), "#AEE3F7", dots=False, hl=False)
        for x in (30, 70):
            p.stroke([(x - 6, 16), (x + 6, 14)], WHT, 1.6)
    return p


def shower(ok):
    p = Pic(70, 110, 60)
    p.shape(limb([(35, 104), (35, 30), (20, 18)], 7), LGREY, hl=False)
    p.shape(ellipse(16, 16, 14, 8), LGREY)
    for i in range(4):
        x = 8 + i * 6
        p.stroke([(x, 26), (x - 2, 40 + (4 if ok else 0))], "#7FD0F5" if ok else "#F29E8E", 1.8)
    if not ok:
        for x in (44, 54):
            p.stroke([(x, 30), (x + 3, 20), (x, 12)], "#F29E8E", 1.6)
    return p


def knob(col):
    p = Pic(36, 36, 30)
    p.shape(circle(18, 18, 14), col)
    p.flat(rrect(10, 16, 16, 4, 2), WHT)
    return p


def balcony():
    p = Pic(W, H, BG)
    p.shape(rect(0, 0, W, H), SKY, dots=False, outline=False, hl=False)
    for x, r in [(60, 30), (180, 22)]:
        p.shape(union(circle(x, 50, r), circle(x + r, 56, r * .8)), WHT, dots=False, hl=False)
    p.shape(rect(260, 0, 140, 236), "#F2D9B8", hl=False)                       # the house wall
    p.shape(rect(0, 0, 60, 236), "#F2D9B8", hl=False)
    p.shape(rrect(8, 120, 46, 116, 4), "#B9793F", hl=False)                    # the door back in
    p.shape(rect(0, 236, W, 64), "#CDBFA9", hl=False, sparse=1.7)
    p.shape(rect(60, 150, 200, 8), GREY, hl=False)                              # the railing
    for x in range(66, 260, 16):
        p.flat(rect(x, 158, 4, 78), GREY)
    return p


def bwin(open_):
    p = Pic(120, 150, 110)
    p.shape(rrect(4, 4, 112, 142, 6), WHT)
    p.shape(rrect(12, 12, 96, 126, 3), SKY, dots=False)
    if open_:
        p.shape(poly([(108, 12), (150 - 40, 16), (130 - 10, 140), (108, 138)]), lt(SKY, .5), dots=False)
        p.shape(poly([(12, 12), (48, 22), (48, 128), (12, 138)]), lt(SKY, .45), dots=False)
        for i in range(3):
            p.stroke([(60 + i * 10, 40 + i * 20), (78 + i * 10, 36 + i * 20)], INK, 1.6)
    else:
        p.flat(rect(58, 12, 4, 126), WHT)
    return p


def stool():
    p = Pic(70, 100, 60)
    for x in (14, 56):
        p.shape(limb([(x, 30), (x + (-4 if x < 30 else 4), 96)], 7), "#E8392F", hl=False)
    p.shape(rrect(4, 20, 62, 14, 6), "#F25C4F")
    return p


def boxes():
    p = Pic(80, 90, 70)
    p.shape(rrect(6, 44, 68, 42, 3), "#D49A5E")
    p.shape(rrect(16, 8, 50, 38, 3), "#C9894C")
    for y in (8, 44):
        p.flat(rect(36, y, 8, 10), "#E9C08A")
    return p


def indoor_mat():
    p = Pic(90, 50, 80)
    p.shape(rrect(4, 10, 82, 30, 8), "#A8D5A2")
    p.stroke([(14, 25), (76, 25)], WHT, 2)
    return p


def build():
    files = {
        "home/kitchen": kitchen(), "home/pot_out": pot(True), "home/pot_in": pot(False), "home/drawer": drawer(False), "home/drawer_shut": drawer(True),
        "home/knife": knife(), "home/kettle_cord": kettle(True), "home/kettle_safe": kettle(False), "home/bag": bag(), "home/cupboard": cupboard(),
        "home/living": living(), "home/socket": socket(False), "home/socket_cover": socket(True), "home/high_cabinet": high_cabinet(),
        "home/medicine": medicine(), "home/coins": coins(), "home/box_open": box(False), "home/box_shut": box(True), "home/chair": chair(),
        "home/bath": bath(), "home/tub_full": tub(True), "home/tub_empty": tub(False), "home/floor_wet": floor_wet(False), "home/mat": floor_wet(True),
        "home/shower": shower(False), "home/shower_ok": shower(True), "home/knob_cold": knob(BLU), "home/knob_hot": knob(RED),
        "home/balcony": balcony(), "home/bwin_open": bwin(True), "home/bwin_closed": bwin(False), "home/stool": stool(), "home/boxes": boxes(),
        "home/indoor_mat": indoor_mat(),
    }
    for k, p in files.items():
        p.save(k)
    print(f"home: {len(files)} files")


if __name__ == "__main__":
    build()
