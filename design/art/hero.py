"""The squad member (the child): helmet, orange vest with a silver stripe, navy trousers.

Drawn standing on (0, 0), about 130 units tall. Four hair styles (0 short, 1 ponytail, 2 pigtails,
3 curly) are separate files, hero/<pose>_h<style>.svg; skin and helmet are stand-in colours the app
swaps (kit.SKIN, kit.HELMET, kit.HELMET_DOT; lib/app/hero_art.dart).

    python3 build.py hero
"""
import sys

sys.dont_write_bytecode = True

import math  # noqa: E402

from kit import (BLK, CHEEK, HELMET, INK, LGREY, NAVY, ORA, SKIN, WHT, Pic, arc_pts, circle, ellipse, limb, move,  # noqa: E402
                 poly, rot, rrect, union)

HAIRS = ["#3A2A22", "#7A4A2A", "#2E2420", "#9A5A32"]
SWIM = "#2EA6E6"
VB = (120, 150)          # viewBox of a pose; the feet at (60, 140)
FEET = (60, 140)


def face(p, hx, hy, s=1.0, look=0.0, mood="smile"):
    k = p.k
    ex = hx + look * s
    for dx in (-8, 8):
        p.flat(circle(ex + dx * s, hy + 2 * s, 3.1 * s), INK)
        p.flat(circle(ex + dx * s - 1.1 * s, hy + .9 * s, 1.1 * s), WHT)
    p.flat(circle(ex - 13 * s, hy + 9 * s, 3.4 * s), CHEEK, .7)
    p.flat(circle(ex + 13 * s, hy + 9 * s, 3.4 * s), CHEEK, .7)
    if mood == "open":
        p.shape(ellipse(ex, hy + 11 * s, 4.2 * s, 3.6 * s), "#C2404A", dots=False, hl=False)
    elif mood == "firm":
        p.stroke([(ex - 4 * s, hy + 11 * s), (ex + 4 * s, hy + 11 * s)], INK, 1.9)
    else:
        p.stroke([(ex - 5 * s, hy + 9 * s), (ex, hy + 13 * s), (ex + 5 * s, hy + 9 * s)], INK, 1.9)
    return k


def hair_back(p, style, hx, hy, s, helmet, look=0.0):
    """Hair that sits behind the head (drawn before the face)."""
    c = HAIRS[style]
    side = -1 if look >= 0 else 1
    if style == 1:      # ponytail
        p.shape(ellipse(hx + side * 22 * s, hy + 4 * s, 7 * s, 13 * s, rot=side * 25), c)
    elif style == 2:    # pigtails
        for sx in (-1, 1):
            p.shape(ellipse(hx + sx * 22 * s, hy + 10 * s, 6.5 * s, 10 * s, rot=-sx * 20), c)
            p.shape(circle(hx + sx * 20 * s, hy + 1 * s, 3 * s), "#F27AA0", hl=False)
    elif style == 3:    # curly
        for sx in (-1, 1):
            p.shape(union(circle(hx + sx * 20 * s, hy - 2 * s, 6.5 * s), circle(hx + sx * 21 * s, hy + 7 * s, 6 * s)), c)
    if not helmet:
        p.shape(union(circle(hx, hy - 4 * s, 22.5 * s), ellipse(hx, hy - 10 * s, 23 * s, 16 * s)), c, hl=False)


def hair_front(p, style, hx, hy, s, helmet, look=0.0):
    c = HAIRS[style]
    if helmet:
        fringe = poly([(hx - 19 * s, hy - 7 * s), *[(hx + x * s, hy + y * s) for x, y in [(-12, -3), (-6, -6), (0, -2.5), (6, -6), (12, -3)]], (hx + 19 * s, hy - 7 * s), (hx + 19 * s, hy - 11 * s), (hx - 19 * s, hy - 11 * s)])
        p.shape(fringe, c, dots=False, hl=False)
        if style == 0:
            for sx in (-1, 1):
                p.shape(poly([(hx + sx * 19 * s, hy - 9 * s), (hx + sx * 22 * s, hy + 2 * s), (hx + sx * 16 * s, hy - 2 * s)]), c, dots=False, hl=False)
    else:
        cap = union(
            poly([(hx - 21 * s, hy - 2 * s), (hx - 16 * s, hy - 6 * s), (hx - 9 * s, hy - 3 * s), (hx - 3 * s, hy - 7 * s), (hx + 4 * s, hy - 3 * s), (hx + 11 * s, hy - 7 * s), (hx + 17 * s, hy - 3 * s), (hx + 21 * s, hy - 2 * s), (hx + 22 * s, hy - 14 * s), (hx, hy - 24 * s), (hx - 22 * s, hy - 14 * s)]),
        )
        p.shape(cap, c)


def helmet(p, hx, hy, s=1.0):
    dome = poly(arc_pts(hx, hy - 6 * s, 24.5 * s, 24 * s, 180, 360, 24))
    p.shape(dome, HELMET, hl=False)
    p.flat(rrect(hx - 3 * s, hy - 29 * s, 6 * s, 22 * s, 3 * s), WHT, .55)
    p.flat(rrect(hx - 15 * s, hy - 24 * s, 6 * s, 9 * s, 3 * s), WHT, .55)
    p.shape(rrect(hx - 28 * s, hy - 10 * s, 56 * s, 8 * s, 4 * s), HELMET, hl=False)


def head(p, hx, hy, style, s=1.0, look=0.0, has_helmet=True, mood="smile", towel=False):
    hair_back(p, style, hx, hy, s, has_helmet, look)
    p.shape(circle(hx, hy, 21 * s), SKIN, hl=False)
    hair_front(p, style, hx, hy, s, has_helmet, look)
    face(p, hx, hy, s, look, mood)
    if has_helmet:
        helmet(p, hx, hy, s)
        # the chin strap
        p.stroke([(hx - 20 * s, hy - 4 * s), (hx - 13 * s, hy + 16 * s), (hx, hy + 20 * s), (hx + 13 * s, hy + 16 * s), (hx + 20 * s, hy - 4 * s)], INK, 1.2, op=.55)
    if towel:
        p.shape(rrect(hx - 8 * s + look, hy + 4 * s, 26 * s, 14 * s, 5 * s), "#BFE3F5")


def vest(p, x, y, w, h, swim=False):
    if swim:
        p.shape(rrect(x, y, w, h, 12), SWIM)
        return
    p.shape(rrect(x, y, w, h, 12), ORA)
    p.shape(rrect(x, y + h * .38, w, 7, 2), LGREY, hl=False)


def arm(p, a, b, sleeve=ORA, hand=SKIN, w=10, elbow=None):
    pts = [a, elbow, b] if elbow else [a, b]
    p.shape(limb(pts, w), SKIN, hl=False)
    m = elbow or b
    p.shape(limb([a, ((a[0] * 2 + m[0]) / 3, (a[1] * 2 + m[1]) / 3)], w + 1), sleeve, hl=False)
    p.shape(circle(b[0], b[1], 7), hand, hl=False)


def legs(p, hips, feet, col=NAVY):
    for h, f in zip(hips, feet):
        p.shape(limb([h, f], 13), col, hl=False)
    for f in feet:
        p.shape(ellipse(f[0] + (2 if f[0] >= 0 else -2), f[1] + 1, 9, 5), BLK, hl=False)


def standing(p, style, arms, look=0.0, has_helmet=True, mood="smile", swim=False, feet=((-11, -4), (11, -4)), lean=0.0):
    """A standing pose: arms = (left hand, right hand) in body units (shoulders at ±16, -58)."""
    leg_col = SKIN if swim else NAVY
    legs(p, [(-9, -32), (9, -32)], feet, leg_col)
    sleeve = SWIM if swim else ORA
    vest(p, -20, -66, 40, 38, swim)
    if swim:
        # the swimsuit's straps
        for sx in (-1, 1):
            p.shape(rrect(sx * 12 - 3, -74, 6, 12, 3), SWIM, hl=False)
    for sh, hand in zip([(-16, -58), (16, -58)], arms):
        arm(p, sh, hand, SKIN if swim else sleeve)
    head(p, lean, -88, style, 1.0, look, has_helmet, mood)


POSES = {}


def pose(fn):
    POSES[fn.__name__] = fn
    return fn


@pose
def stand(p, st):
    standing(p, st, [(-30, -34), (30, -34)])


@pose
def bare(p, st):
    standing(p, st, [(-30, -34), (30, -34)], has_helmet=False)


@pose
def walk(p, st):
    standing(p, st, [(-26, -38), (28, -44)], feet=((-16, -4), (14, -5)))


@pose
def wave(p, st):
    standing(p, st, [(-30, -34), (34, -92)], mood="open")


@pose
def look(p, st):
    standing(p, st, [(-30, -34), (30, -34)], look=7)


@pose
def hold(p, st):
    standing(p, st, [(-34, -86), (30, -34)])


@pose
def hug(p, st):
    standing(p, st, [(-40, -54), (40, -54)], mood="open")


@pose
def stop(p, st):
    # chest out, one hand forward like a stop sign
    standing(p, st, [(-30, -36), (46, -62)], mood="firm")
    p.shape(rrect(44, -76, 10, 16, 5), SKIN, hl=False)


@pose
def peek(p, st):
    legs(p, [(-9, -32), (9, -32)], [(-11, -4), (11, -4)])
    body = rot(rrect(-20, -66, 40, 38, 12), -12, (0, -30))
    p.shape(body, ORA)
    p.shape(rot(rrect(-20, -51, 40, 7, 2), -12, (0, -30)), LGREY, hl=False)
    arm(p, (-14, -58), (-28, -34))
    arm(p, (18, -54), (32, -40))
    head(p, 12, -84, st, 1.0, 7)


@pose
def crouch(p, st):
    legs(p, [(-12, -22), (12, -22)], [(-22, -4), (22, -4)])
    p.shape(rrect(-24, -50, 48, 32, 13), ORA)
    p.shape(rrect(-24, -38, 48, 6, 2), LGREY, hl=False)
    arm(p, (-18, -44), (-34, -10))
    arm(p, (18, -44), (34, -10))
    head(p, 0, -68, st)


@pose
def cover(p, st):
    legs(p, [(-12, -22), (12, -22)], [(-22, -4), (22, -4)])
    p.shape(rrect(-24, -50, 48, 32, 13), ORA)
    p.shape(rrect(-24, -38, 48, 6, 2), LGREY, hl=False)
    head(p, 0, -66, st, mood="firm")
    # both hands on the helmet, elbows out
    arm(p, (-18, -46), (-12, -92), elbow=(-36, -68))
    arm(p, (18, -46), (12, -92), elbow=(36, -68))


def _crawl(p, st, towel):
    # on hands and knees, heading right
    p.shape(limb([(-20, -16), (-34, -6)], 12), NAVY, hl=False)
    p.shape(limb([(-34, -6), (-44, -5)], 11), NAVY, hl=False)
    p.shape(ellipse(-48, -5, 6, 5), BLK, hl=False)
    p.shape(rrect(-30, -34, 46, 26, 12), ORA)
    p.shape(rrect(-30, -24, 46, 6, 2), LGREY, hl=False)
    arm(p, (8, -26), (14, -6))
    arm(p, (-8, -24), (-4, -6))
    head(p, 34, -36, st, .92, 5, towel=towel)


@pose
def crawl(p, st):
    _crawl(p, st, False)


@pose
def crawl_towel(p, st):
    _crawl(p, st, True)


@pose
def sit(p, st):
    # sitting in the car seat, seen from the front: knees forward, lower legs hanging down
    for sx in (-1, 1):
        p.shape(limb([(sx * 10, -26), (sx * 12, -6)], 12), NAVY, hl=False)
        p.shape(ellipse(sx * 13, -3, 8, 5), BLK, hl=False)
        p.shape(ellipse(sx * 10, -27, 10, 8), NAVY, hl=False)
    p.shape(rrect(-20, -62, 40, 36, 12), ORA)
    p.shape(rrect(-20, -49, 40, 7, 2), LGREY, hl=False)
    arm(p, (-16, -55), (-22, -30))
    arm(p, (16, -55), (22, -30))
    head(p, 0, -84, st)


def draw(name, style):
    p = Pic(*VB, display=90, ox=FEET[0], oy=FEET[1])
    POSES[name](p, style)
    return p


# ---------------------------------------------------------------- the swimsuit figure (身體紅綠燈)
SWIM_VB = (120, 216)
SWIM_S = 1.5
SWIM_FEET = (60, 210)


def swim_pic(style):
    """Bigger, taller and in a swimsuit, so every place on the body is easy to tap."""
    p = Pic(*SWIM_VB, display=160, ox=SWIM_FEET[0], oy=SWIM_FEET[1])
    s = SWIM_S

    def S(x, y):
        return (x * s, y * s)
    for h, f in [((-9, -32), (-12, -4)), ((9, -32), (12, -4))]:
        p.shape(limb([S(*h), S(*f)], 12 * s), SKIN, hl=False)
    for f in [(-12, -4), (12, -4)]:
        p.shape(ellipse(f[0] * s, f[1] * s + 2, 8 * s, 4.5 * s), "#F2B66B", hl=False)
    p.shape(rrect(-19 * s, -66 * s, 38 * s, 42 * s, 12 * s), SKIN, hl=False)
    # a two-piece: a top over the chest and swimming trunks, so the tummy shows between them
    suit = union(rrect(-19 * s, -63 * s, 38 * s, 13 * s, 5 * s), *[rrect((sx * 11 - 3) * s, -70 * s, 6 * s, 10 * s, 3 * s) for sx in (-1, 1)])
    p.shape(suit, SWIM)
    suit = poly([(-19 * s, -38 * s), (19 * s, -38 * s), (19 * s, -26 * s), (5 * s, -20 * s), (-5 * s, -20 * s), (-19 * s, -26 * s)])
    p.shape(suit, SWIM)
    for sh, hand in [((-16, -60), (-31, -36)), ((16, -60), (31, -36))]:
        p.shape(limb([S(*sh), S(*hand)], 10 * s), SKIN, hl=False)
        p.shape(circle(hand[0] * s, hand[1] * s, 7 * s), SKIN, hl=False)
    p.stroke([(-4 * s, -60 * s), (0, -58 * s), (4 * s, -60 * s)], INK, 1.2, op=.4)
    head(p, 0, -88 * s, style, s, 0, has_helmet=False)
    return p


def spots():
    """Where the tap spots of 身體紅綠燈 are on swim_*.svg (as fractions of the picture)."""
    s = SWIM_S
    pts = {"head": (0, -112), "face": (9, -82), "shoulder": (-14, -62), "hand": (31, -36), "tummy": (0, -44), "swim": (0, -29)}
    return {k: ((x * s + SWIM_FEET[0]) / SWIM_VB[0], (y * s + SWIM_FEET[1]) / SWIM_VB[1]) for k, (x, y) in pts.items()}


def build():
    n = 0
    for name in POSES:
        for st in range(4):
            draw(name, st).save(f"hero/{name}_h{st}")
            n += 1
    for st in range(4):
        swim_pic(st).save(f"hero/swim_h{st}")
        n += 1
    print(f"hero: {n} files; spots {', '.join(f'{k} ({x:.3f}, {y:.3f})' for k, (x, y) in spots().items())}")


if __name__ == "__main__":
    build()
