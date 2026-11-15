"""身體世界: a calm poolside for the body traffic light, a calm park for 說「不要！」, the coloured spots and
the three light cards. Plain and peaceful; the swimsuit figure itself is hero/swim_*.svg.

    python3 build.py body
"""
import sys

sys.dont_write_bytecode = True

from kit import BLK, GRN, RED, SKY, WHT, YEL, Pic, circle, ellipse, rect, rrect, union  # noqa: E402

W, H = 400, 300
BG = 390
LIGHTS = {"green": GRN, "yellow": YEL, "red": RED}


def pool():
    p = Pic(W, H, BG)
    p.shape(rect(0, 0, W, H), "#E6F4F1", dots=False, outline=False, hl=False)
    for y in range(0, 200, 40):                                                # soft tiles
        for x in range(0, W, 40):
            p.flat(rect(x + 1, y + 1, 38, 38), "#D6ECE8")
    p.shape(rect(0, 200, W, 100), "#F6E7C8", hl=False, sparse=1.7)
    p.shape(rrect(270, 214, 150, 70, 10), "#7FD0F5", hl=False)               # a bit of the pool
    for x in (300, 340, 380):
        p.stroke([(x - 14, 240), (x, 236), (x + 14, 240)], WHT, 2)
    p.shape(rrect(20, 150, 46, 52, 8), "#F9C6D5", hl=False)                    # a towel on a hook
    p.flat(circle(43, 146, 5), "#B9793F")
    return p


def park():
    p = Pic(W, H, BG)
    p.shape(rect(0, 0, W, H), SKY, dots=False, outline=False, hl=False)
    p.shape(circle(350, 46, 24), "#FFE27A", dots=False, hl=False)
    for x, r in [(40, 46), (110, 38), (300, 52)]:
        p.shape(union(circle(x, 150, r), circle(x + r * .7, 160, r * .8)), "#7CC47A", hl=False)
    p.shape(rect(0, 180, W, 120), "#A8D5A2", hl=False, sparse=1.7)
    p.shape(rrect(150, 214, 120, 14, 6), "#E4D7C4", hl=False)
    for x, c in [(30, "#F27AA0"), (190, YEL), (370, "#F27AA0")]:
        for i in range(3):
            p.shape(circle(x + i * 9, 262 + (i % 2) * 6, 4.5), c, dots=False, hl=False)
    return p


def dot(col):
    p = Pic(40, 40, 30)
    if col is None:
        p.shape(circle(20, 20, 13), WHT, hl=False)
        p.flat(circle(20, 20, 6), "#B8C4D6")
    else:
        p.shape(circle(20, 20, 15), col)
    return p


def light_card(name):
    """A small traffic light with only one lamp lit."""
    p = Pic(60, 120, 60)
    p.shape(rrect(8, 4, 44, 112, 12), BLK)
    for i, (n, c) in enumerate(LIGHTS.items()):
        lit = n == name
        p.shape(circle(30, 24 + i * 36, 13), c if lit else "#4A5361", dots=lit, hl=lit)
    return p


def build():
    files = {"body/pool": pool(), "body/park": park(), "body/dot_white": dot(None)}
    for n, c in LIGHTS.items():
        files[f"body/dot_{n}"] = dot(c)
        files[f"body/light_{n}"] = light_card(n)
    for k, p in files.items():
        p.save(k)
    print(f"body: {len(files)} files")


if __name__ == "__main__":
    build()
