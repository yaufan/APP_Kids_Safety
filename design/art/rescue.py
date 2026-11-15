"""救災世界: the living room for the earthquake, the stairwell, the room with light smoke, outside the
house, the typhoon room, and their things. Nothing frightening: the smoke is a light grey cloud, there is
no fire drawn on anything, the earthquake only wobbles (the app moves the picture gently).

    python3 build.py rescue
"""
import sys

sys.dont_write_bytecode = True

from kit import (BLK, BLU, BROWN, GREY, GRN, INK, LGREY, RED, SKY, WHT, WOOD, YEL, Pic, circle, ellipse, limb, lt,  # noqa: E402
                 poly, rect, rrect, union)

W, H = 400, 300
BG = 390


def room(p, wall="#F6E7C8", floor="#D9B48A", floor_y=210):
    p.shape(rect(0, 0, W, floor_y), wall, dots=False, outline=False, hl=False)
    p.shape(rect(0, floor_y, W, H - floor_y), floor, hl=False, sparse=1.7)
    for x in range(-40, W + 40, 50):
        p.stroke([(x + 20, floor_y), (x - 10, H)], lt(floor, -.0) if False else "#C49C72", 1.0)
    p.flat(rect(0, floor_y - 6, W, 6), "#E9D2A8")


def living():
    p = Pic(W, H, BG)
    room(p)
    p.shape(rrect(250, 150, 130, 50, 14), "#7FA3C9", hl=False)                   # a sofa at the back
    p.shape(rrect(262, 128, 106, 34, 12), "#8FB3D9", hl=False)
    p.flat(rect(0, 0, W, 8), "#E9D2A8")
    return p


def lamp():
    p = Pic(50, 64, 50)
    p.stroke([(25, 0), (25, 30)], INK, 1.6)
    p.shape(poly([(10, 50), (16, 30), (34, 30), (40, 50)]), YEL)
    p.shape(circle(25, 54, 5), "#FFF2B3", dots=False, hl=False)
    return p


def window_frame(open_, rain=False, wide=False):
    w, h = (130, 170) if wide else (100, 130)
    p = Pic(w, h, 120)
    p.shape(rrect(4, 4, w - 8, h - 8, 6), WHT)
    p.shape(rrect(12, 12, w - 24, h - 24, 4), SKY if not rain else "#9FB4C8", dots=False)
    if rain:
        for i in range(9):
            x = 18 + (i * 29) % (w - 30)
            y = 18 + (i * 37) % (h - 50)
            p.stroke([(x, y), (x - 5, y + 14)], WHT, 1.6)
    if open_:
        p.shape(poly([(12, 12), (w / 2 - 14, 22), (w / 2 - 14, h - 22), (12, h - 12)]), lt(SKY, .4), dots=False)
        p.shape(poly([(w - 12, 12), (w / 2 + 14, 22), (w / 2 + 14, h - 22), (w - 12, h - 12)]), lt(SKY, .4), dots=False)
        if rain:
            for i in range(3):
                p.stroke([(w / 2 - 8 + i * 6, 30 + i * 18), (w / 2 + 2 + i * 6, 34 + i * 18)], INK, 1.6)
    else:
        p.flat(rect(w / 2 - 2, 12, 4, h - 24), WHT)
        p.flat(rect(12, h / 2 - 2, w - 24, 4), WHT)
    return p


def shelf():
    p = Pic(80, 180, 80)
    p.shape(rrect(4, 4, 72, 172, 6), BROWN)
    cols = [RED, BLU, GRN, YEL, "#B45CD6"]
    for r in range(3):
        y = 14 + r * 54
        p.shape(rect(10, y, 60, 46), "#8A5A33", dots=False, hl=False)
        for i in range(5):
            p.shape(rrect(14 + i * 11, y + 10, 9, 36, 2), cols[(i + r) % 5], dots=False, hl=False)
    return p


def table():
    p = Pic(180, 100, 170)
    for x in (24, 156):
        p.shape(limb([(x, 22), (x, 96)], 12), lt(BROWN, -.0) if False else "#9A6232", hl=False)
    p.shape(rrect(4, 10, 172, 20, 8), WOOD)
    return p


def stairwell():
    p = Pic(W, H, BG)
    room(p, wall="#E3E9EF", floor="#B9C3CC", floor_y=240)
    return p


def lift():
    p = Pic(120, 210, 120)
    p.shape(rrect(4, 4, 112, 202, 6), "#B9C3CC")
    p.shape(rrect(16, 30, 40, 176, 2), "#D5DBE0", hl=False)
    p.shape(rrect(64, 30, 40, 176, 2), "#D5DBE0", hl=False)
    p.shape(rrect(44, 8, 32, 16, 4), BLK, hl=False)
    p.shape(poly([(54, 20), (60, 12), (66, 20)]), RED, dots=False, outline=False, hl=False)
    return p


def stairs():
    p = Pic(140, 210, 130)
    p.shape(rrect(4, 4, 132, 202, 6), "#A8D5A2")
    for i in range(6):
        p.shape(rect(18 + i * 16, 190 - i * 28, 118 - i * 16 - 14, 28), "#F2E3C9", hl=False)
    # the green running-man exit sign
    p.shape(rrect(30, 12, 80, 30, 4), GRN, hl=False)
    p.flat(circle(52, 21, 4), WHT)
    p.flat(limb([(52, 25), (48, 33)], 3.4), WHT)
    p.flat(limb([(48, 33), (42, 38)], 3.4), WHT)
    p.flat(limb([(48, 33), (55, 38)], 3.4), WHT)
    p.flat(limb([(66, 27), (98, 27)], 5), WHT)
    p.flat(poly([(96, 20), (106, 27), (96, 34)]), WHT)
    return p


def fire_room():
    p = Pic(W, H, BG)
    room(p, wall="#F3EAD9", floor="#CFAE86", floor_y=200)
    p.shape(rrect(150, 120, 60, 70, 4), "#E3D3B8", hl=False)                   # a small bed at the back
    return p


def smoke():
    p = Pic(420, 90, 400)
    puffs = [circle(x, 40 + (i % 3) * 8, 30 + (i * 7) % 14) for i, x in enumerate(range(0, 440, 38))]
    g = union(*puffs, rect(0, 0, 420, 40))
    p.shape(g.intersection(rect(0, 0, 420, 90)), "#E4E7EB", hl=False, op=.9)
    return p


def sink():
    p = Pic(90, 120, 90)
    p.shape(rrect(8, 50, 74, 66, 6), "#D5DBE0")
    p.shape(rrect(4, 44, 82, 14, 6), WHT)
    p.shape(limb([(45, 46), (45, 20), (62, 20)], 7), LGREY, hl=False)
    p.shape(rrect(38, 30, 14, 8, 3), BLU, hl=False)
    return p


def closet():
    p = Pic(80, 200, 80)
    p.shape(rrect(4, 4, 72, 192, 6), "#C99A6B")
    p.stroke([(40, 10), (40, 190)], INK, 1.4)
    for x in (34, 46):
        p.flat(circle(x, 100, 3), YEL)
    return p


def toys():
    p = Pic(60, 50, 50)
    p.shape(rrect(4, 22, 52, 26, 6), "#7FC8F0")
    p.shape(circle(18, 18, 10), RED)
    p.shape(rrect(32, 6, 16, 18, 3), YEL)
    return p


def exit_door():
    p = Pic(80, 200, 80)
    p.shape(rrect(4, 4, 72, 196, 4), "#E7DDCC", hl=False)
    p.shape(rrect(10, 14, 60, 186, 4), "#7FA3C9")
    p.flat(circle(60, 110, 4), YEL)
    p.shape(rrect(14, 24, 52, 18, 3), GRN, hl=False)
    p.flat(limb([(26, 33), (54, 33)], 4), WHT)
    p.flat(poly([(52, 27), (60, 33), (52, 39)]), WHT)
    return p


def towel(wet):
    p = Pic(50, 40, 40)
    c = "#5FB5E5" if wet else "#BFE3F5"
    p.shape(rrect(4, 6, 42, 30, 6), c)
    for i in range(3):
        p.stroke([(10 + i * 12, 30), (10 + i * 12, 36)], WHT, 1.4)
    if wet:
        for x, y in [(12, 4), (40, 2)]:
            p.shape(poly([(x, y - 4), (x + 3, y + 2), (x - 3, y + 2)]).buffer(1), "#7FD0F5", dots=False, hl=False)
    return p


def house_out():
    p = Pic(W, H, BG)
    p.shape(rect(0, 0, W, H), SKY, dots=False, outline=False, hl=False)
    p.shape(rect(0, 214, W, 86), "#A8D5A2", hl=False, sparse=1.7)
    p.shape(rect(30, 110, 170, 110), "#F2D9B8", hl=False)
    p.shape(poly([(16, 114), (115, 46), (214, 114)]), RED, hl=False)
    p.shape(rrect(96, 156, 36, 64, 3), "#B9793F", hl=False)
    p.shape(rrect(150, 130, 36, 32, 3), "#CFD6DD", dots=False)
    # light grey smoke from the window, drifting away (no flames)
    p.shape(union(circle(178, 112, 14), circle(196, 98, 17), circle(220, 84, 20)), "#E4E7EB", hl=False, op=.9)
    p.shape(rrect(250, 200, 140, 18, 6), "#C8B89E", hl=False)
    return p


def typhoon_room():
    p = Pic(W, H, BG)
    room(p, wall="#E8EEF2", floor="#C9B08C", floor_y=220)
    # the balcony door on the right, open to the rain
    p.shape(rrect(230, 40, 170, 180, 4), "#9FB4C8", dots=False, hl=False)
    for i in range(10):
        x = 240 + (i * 37) % 150
        y = 50 + (i * 53) % 150
        p.stroke([(x, y), (x - 6, y + 16)], WHT, 1.6)
    p.shape(rect(230, 150, 170, 10), "#8E979F", hl=False)                      # the balcony rail
    for x in range(240, 400, 18):
        p.flat(rect(x, 160, 4, 60), "#8E979F")
    p.shape(rect(222, 36, 10, 190), WHT, hl=False)
    p.stroke([(300, 64), (390, 64)], INK, 1.2)                                  # the washing line
    return p


def plant():
    p = Pic(50, 100, 50)
    p.shape(union(ellipse(25, 30, 18, 24), ellipse(14, 44, 10, 14), ellipse(36, 44, 10, 14)), GRN)
    p.shape(poly([(10, 62), (40, 62), (36, 96), (14, 96)]), "#D9733F")
    return p


def clothes():
    p = Pic(70, 70, 60)
    p.shape(poly([(10, 10), (26, 6), (35, 14), (44, 6), (60, 10), (66, 28), (54, 32), (54, 66), (16, 66), (16, 32), (4, 28)]).buffer(2).buffer(-2), "#F29E8E")
    for x in (20, 50):
        p.shape(rrect(x - 3, 0, 6, 12, 2), LGREY, hl=False)
    return p


def side_table():
    p = Pic(90, 100, 80)
    p.shape(limb([(20, 30), (20, 96)], 9), "#9A6232", hl=False)
    p.shape(limb([(70, 30), (70, 96)], 9), "#9A6232", hl=False)
    p.shape(rrect(4, 20, 82, 16, 6), WOOD)
    return p


def torch(on):
    p = Pic(70 if on else 50, 40, 50)
    if on:
        p.shape(poly([(44, 20), (70, 2), (70, 38)]), "#FFF2B3", dots=False, outline=False, hl=False, op=.9)
    p.shape(rrect(4, 12, 34, 16, 6), "#4A5A70")
    p.shape(rrect(34, 8, 10, 24, 4), YEL if on else LGREY, hl=False)
    p.flat(rrect(14, 16, 8, 8, 2), RED)
    return p


def build():
    files = {
        "rescue/living": living(), "rescue/lamp": lamp(), "rescue/window": window_frame(False), "rescue/shelf": shelf(), "rescue/table": table(),
        "rescue/stairwell": stairwell(), "rescue/lift": lift(), "rescue/stairs": stairs(),
        "rescue/fire_room": fire_room(), "rescue/smoke": smoke(), "rescue/sink": sink(), "rescue/closet": closet(), "rescue/toys": toys(),
        "rescue/door": exit_door(), "rescue/towel": towel(False), "rescue/towel_wet": towel(True), "rescue/house_out": house_out(),
        "rescue/typhoon_room": typhoon_room(), "rescue/win_open": window_frame(True, rain=True, wide=True), "rescue/win_closed": window_frame(False, rain=True, wide=True),
        "rescue/plant": plant(), "rescue/clothes": clothes(), "rescue/side_table": side_table(), "rescue/torch": torch(False), "rescue/torch_on": torch(True),
    }
    for k, p in files.items():
        p.save(k)
    print(f"rescue: {len(files)} files")


if __name__ == "__main__":
    build()
