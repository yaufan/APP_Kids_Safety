"""The 漫畫網點風 kit for 安全小隊 (docs/design.md 「畫風」, docs/art.md).

Every thing is a shapely shape. Pic.shape() writes it three times:
  1. the flat colour (<path fill>),
  2. halftone dots on the shadow side: real small circles, all of one shape in ONE <path>, clipped by a
     <clipPath> holding the shape itself (flutter_svg draws clipPath; it has no pattern, mask or filter),
  3. the thin dark-blue outline (#1E3A6E) on top, covering the dots' edges.
A white rounded highlight sits at the top left of bigger shapes.

The dots: the shadow area is the shape minus itself moved up-left by about 11 points; in it a grid
turned 30 degrees (5.5 points apart) puts a dot whose radius grows from 0 at the inner edge to about
1.4 points at the outer edge; dots under 0.4 are skipped. Their colour is the fill 45 % darker, with
fill-opacity. White, very light shapes and skin get no dots.

"Points" are points on a phone screen: each Pic is told how wide it is usually shown (display=), and the
outline width, dot sizes and spacing are worked out from that, so big and small pictures look alike.
Pic.save() keeps every file under 70 KB by spreading the dots out if needed.

Never run git from here.
"""
import sys

sys.dont_write_bytecode = True

import math  # noqa: E402
import pathlib  # noqa: E402
import xml.etree.ElementTree as ET  # noqa: E402

import numpy as np  # noqa: E402
import shapely  # noqa: E402
from shapely import affinity  # noqa: E402
from shapely.geometry import LineString, MultiPolygon, Point, Polygon, box  # noqa: E402
from shapely.ops import unary_union  # noqa: E402

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
ART = ROOT / "app" / "assets" / "art"
MAX_KB = 70
FORBIDDEN = ["<filter", "<mask", "<pattern", "<style", "style=", "<text", "<image", "mix-blend", "<foreignObject"]

# ---------------------------------------------------------------- colours
INK = "#1E3A6E"
YEL = "#FFC400"
BLK = "#2A3140"
RED = "#E8392F"
GRN = "#1FA64A"
BLU = "#1F6FD6"
WHT = "#FFFFFF"
ORA = "#FF8A1E"
GREY = "#8E979F"
LGREY = "#D5DBE0"
ROAD = "#5A626D"
SKY = "#DCEBF7"
NAVY = "#2B3F7A"
PINK = "#F27AA0"
BROWN = "#B9793F"
WOOD = "#D49A5E"
CREAM = "#FFF4DC"
SKINS = ["#F6D3B3", "#E8B88E", "#C98C5C", "#8F5A3A"]
CHEEK = "#FF8C9C"

# Stand-in colours in hero/*.svg: the app swaps them for the child's choice (lib/app/hero_art.dart).
HELMET, HELMET_DOT = "#FEC401", "#FEC402"
HAIR, HAIR_DOT = "#3B2A21", "#3B2A22"
SKIN = "#F6D3B1"
NO_DOTS = {c.upper() for c in SKINS + [SKIN, CHEEK, WHT]}


def _rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    ra, rb = _rgb(a), _rgb(b)
    return "#" + "".join(f"{round(ra[i] + (rb[i] - ra[i]) * t):02X}" for i in range(3))


def dk(c, t=.25):
    return mix(c, "#000000", t)


def lt(c, t=.35):
    return mix(c, "#FFFFFF", t)


def dot_color(c):
    if c.upper() == HELMET:
        return HELMET_DOT
    if c.upper() == HAIR.upper():
        return HAIR_DOT
    return dk(c, .45)


def light(c):
    if c.upper() in NO_DOTS:
        return True
    r, g, b = _rgb(c)
    return (.299 * r + .587 * g + .114 * b) / 255 > .9


# ---------------------------------------------------------------- shapes (all shapely)
def circle(cx, cy, r):
    return Point(cx, cy).buffer(r, quad_segs=12)


def ellipse(cx, cy, rx, ry, rot=0.0):
    g = affinity.scale(Point(cx, cy).buffer(1, quad_segs=12), rx, ry)
    return affinity.rotate(g, rot, origin=(cx, cy)) if rot else g


def rrect(x, y, w, h, r=4.0):
    r = max(0.01, min(r, w / 2 - .01, h / 2 - .01))
    return box(x + r, y + r, x + w - r, y + h - r).buffer(r, quad_segs=6)


def rect(x, y, w, h):
    return box(x, y, x + w, y + h)


def poly(pts):
    return Polygon(pts).buffer(0)


def rpoly(pts, r):
    """A polygon with rounded corners."""
    return Polygon(pts).buffer(-r, join_style="mitre").buffer(r, quad_segs=6) if r else Polygon(pts)


def limb(pts, w):
    """A thick round-ended line (arms, legs, poles)."""
    return LineString(pts).buffer(w / 2, quad_segs=8)


def quad(p0, c, p1, n=12):
    """Points along a quadratic curve."""
    return [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * c[0] + t * t * p1[0], (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * c[1] + t * t * p1[1]) for t in np.linspace(0, 1, n)]


def arc_pts(cx, cy, rx, ry, a0, a1, n=16):
    return [(cx + rx * math.cos(math.radians(a)), cy + ry * math.sin(math.radians(a))) for a in np.linspace(a0, a1, n)]


def star(cx, cy, R, r, n=5, rot=-90):
    return Polygon([(cx + (R if i % 2 == 0 else r) * math.cos(math.radians(rot + i * 180 / n)), cy + (R if i % 2 == 0 else r) * math.sin(math.radians(rot + i * 180 / n))) for i in range(2 * n)])


def burst_pts(cx, cy, rx, ry, n=16, inner=.7):
    return [(cx + (rx if i % 2 == 0 else rx * inner) * math.cos(math.radians(-90 + i * 360 / n)),
             cy + (ry if i % 2 == 0 else ry * inner * .97) * math.sin(math.radians(-90 + i * 360 / n))) for i in range(n)]


def union(*gs):
    return unary_union([g for g in gs if g is not None and not g.is_empty])


def move(g, dx, dy):
    return affinity.translate(g, dx, dy)


def flipx(g, x0=0.0):
    return affinity.scale(g, -1, 1, origin=(x0, 0))


def scale(g, s, origin=(0, 0)):
    return affinity.scale(g, s, s, origin=origin)


def rot(g, a, origin):
    return affinity.rotate(g, a, origin=origin)


def n1(v):
    s = f"{v:.1f}"
    s = s.rstrip("0").rstrip(".") if "." in s else s
    return "0" if s in ("-0", "") else s


def path_d(g, simplify=0.0):
    """SVG path data for a shapely (multi)polygon."""
    if g.is_empty:
        return ""
    if simplify:
        g = g.simplify(simplify, preserve_topology=True)
    polys = list(g.geoms) if hasattr(g, "geoms") else [g]
    out = []
    for p in polys:
        if p.is_empty or p.geom_type != "Polygon":
            continue
        for ring in [p.exterior, *p.interiors]:
            c = list(ring.coords)[:-1]
            if len(c) < 3:
                continue
            out.append("M" + " ".join(f"{n1(x)},{n1(y)}" for x, y in c) + "Z")
    return "".join(out)


def line_d(pts):
    return "M" + " L".join(f"{n1(x)},{n1(y)}" for x, y in pts)


# ---------------------------------------------------------------- the picture
class Pic:
    """One SVG. (ox, oy) is added to every shape, so drawings can use their own origin (a character's
    feet at 0,0). display: how many points wide it is usually shown on a phone."""

    def __init__(self, w, h, display, ox=0.0, oy=0.0, zoom=1.0):
        self.w, self.h = w, h
        self.k = w / display          # viewBox units per screen point
        self.ox, self.oy = ox, oy
        self.zoom = zoom              # everything scaled about the middle (the adaptive icon)
        self.items = []

    # sizes in screen points → units
    def u(self, pts):
        return pts * self.k

    def _g(self, g):
        g = affinity.translate(g, self.ox, self.oy) if (self.ox or self.oy) else g
        return affinity.scale(g, self.zoom, self.zoom, origin=(self.w / 2, self.h / 2)) if self.zoom != 1 else g

    def _p(self, x, y):
        x, y = x + self.ox, y + self.oy
        z = self.zoom
        return (self.w / 2 + (x - self.w / 2) * z, self.h / 2 + (y - self.h / 2) * z)

    def shape(self, g, col, dots=True, outline=True, hl=True, op=None, lw=1.0, sparse=1.0):
        """sparse: dots this many times further apart (big backgrounds)."""
        if g is None or g.is_empty:
            return
        self.items.append(("shape", self._g(g), col, dots and not light(col), outline, hl, op, lw, sparse))

    def flat(self, g, col, op=None):
        if g is None or g.is_empty:
            return
        self.items.append(("flat", self._g(g), col, op))

    def outline(self, g, lw=1.0):
        self.items.append(("outline", self._g(g), lw))

    def stroke(self, pts, col, width_pts, op=None, cap="round"):
        """A stroked line (mouths, speed lines); width in screen points."""
        pts = [self._p(x, y) for x, y in pts]
        self.items.append(("stroke", pts, col, width_pts * self.zoom, op, cap))

    # ------------------------------------------------------------ writing
    def _dots(self, g, col, spacing):
        k = self.k
        minx, miny, maxx, maxy = g.bounds
        size = min(maxx - minx, maxy - miny)
        if size < 4 * k:
            return ""
        off = min(11 * k, .38 * size)
        lit = affinity.translate(g, -off, -off)
        shadow = g.difference(lit)
        if shadow.is_empty or shadow.area < (2 * k) ** 2:
            return ""
        step = spacing * k
        a = math.radians(30)
        ca, sa = math.cos(a), math.sin(a)
        sx0, sy0, sx1, sy1 = shadow.bounds
        cx, cy = (sx0 + sx1) / 2, (sy0 + sy1) / 2
        R = math.hypot(sx1 - sx0, sy1 - sy0) / 2 + step
        n = int(R / step) + 1
        ii, jj = np.meshgrid(np.arange(-n, n + 1), np.arange(-n, n + 1))
        gx, gy = (ii * step).ravel(), (jj * step).ravel()
        gy = gy + (ii.ravel() % 2) * step / 2      # staggered rows
        x = cx + gx * ca - gy * sa
        y = cy + gx * sa + gy * ca
        inside = shapely.contains_xy(shadow.buffer(1.4 * k), x, y)
        x, y = x[inside], y[inside]
        if not len(x):
            return ""
        d = shapely.distance(lit, shapely.points(x, y))
        band = max(off * .8, 3 * k)
        r = 1.45 * k * np.clip(d / band, 0, 1)
        keep = r >= .4 * k
        out = []
        for xi, yi, ri in zip(x[keep], y[keep], r[keep]):
            out.append(f"M{n1(xi - ri)},{n1(yi)}a{n1(ri)},{n1(ri)} 0 1,0 {n1(2 * ri)},0a{n1(ri)},{n1(ri)} 0 1,0 {n1(-2 * ri)},0")
        return "".join(out)

    def _hl(self, g):
        k = self.k
        minx, miny, maxx, maxy = g.bounds
        w, h = maxx - minx, maxy - miny
        if min(w, h) < 9 * k:
            return None
        bw, bh = max(2.2 * k, min(w * .1, 5 * k)), max(4 * k, min(h * .3, 16 * k))
        bar = rrect(minx + w * .16, miny + h * .14, bw, bh, bw / 2)
        inner = g.buffer(-2.6 * k)
        hl = bar.intersection(inner)
        return hl if hl.area > bar.area * .5 else None

    def svg(self, spacing=5.5):
        k = self.k
        lw = 1.8 * k
        defs, body = [], []
        clip = 0
        simp = .12 * k
        for it in self.items:
            kind = it[0]
            if kind == "shape":
                _, g, col, dots, outline, hl, op, lwm, sparse = it
                d = path_d(g, simp)
                o = f' fill-opacity="{op}"' if op is not None else ""
                body.append(f'<path d="{d}" fill="{col}"{o}/>')
                if dots:
                    dd = self._dots(g, col, spacing * sparse)
                    if dd:
                        clip += 1
                        defs.append(f'<clipPath id="c{clip}"><path d="{d}"/></clipPath>')
                        body.append(f'<path d="{dd}" fill="{dot_color(col)}" fill-opacity=".62" clip-path="url(#c{clip})"/>')
                if hl:
                    h = self._hl(g)
                    if h is not None:
                        body.append(f'<path d="{path_d(h, simp)}" fill="#FFFFFF" fill-opacity=".55"/>')
                if outline:
                    body.append(f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="{n1(lw * lwm) if lw * lwm >= .1 else f"{lw * lwm:.2f}"}" stroke-linejoin="round"/>')
            elif kind == "flat":
                _, g, col, op = it
                o = f' fill-opacity="{op}"' if op is not None else ""
                body.append(f'<path d="{path_d(g, simp)}" fill="{col}"{o}/>')
            elif kind == "outline":
                _, g, lwm = it
                body.append(f'<path d="{path_d(g, simp)}" fill="none" stroke="{INK}" stroke-width="{n1(lw * lwm)}" stroke-linejoin="round"/>')
            elif kind == "stroke":
                _, pts, col, wp, op, cap = it
                o = f' stroke-opacity="{op}"' if op is not None else ""
                body.append(f'<path d="{line_d(pts)}" fill="none" stroke="{col}" stroke-width="{n1(wp * k)}" stroke-linecap="{cap}" stroke-linejoin="round"{o}/>')
        head = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {n1(self.w)} {n1(self.h)}" width="{n1(self.w)}" height="{n1(self.h)}">'
        return head + (f"<defs>{''.join(defs)}</defs>" if defs else "") + "".join(body) + "</svg>\n"

    def save(self, rel):
        """Writes assets/art/<rel>.svg, spreading the dots out until it is under 70 KB."""
        spacing = 5.5
        while True:
            text = self.svg(spacing)
            if len(text.encode()) <= (MAX_KB - 2) * 1024 or spacing > 30:
                break
            spacing *= 1.25
        out = ART / f"{rel}.svg"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text)
        check_svg(rel, text)
        return out


# ---------------------------------------------------------------- checks
def check_svg(name, text):
    bad = [f for f in FORBIDDEN if f in text]
    if bad:
        raise SystemExit(f"{name}: uses {bad} (flutter_svg cannot draw these)")
    kb = len(text.encode()) / 1024
    if kb > MAX_KB:
        raise SystemExit(f"{name}: {kb:.0f} KB (keep under {MAX_KB} KB)")
    if not text.rstrip().endswith("</svg>"):
        raise SystemExit(f"{name}: does not end with </svg>")
    try:
        root = ET.fromstring(text)
    except ET.ParseError as e:
        raise SystemExit(f"{name}: not well-formed XML: {e}")
    vb = [float(v) for v in root.get("viewBox", "").split()]
    if len(vb) != 4 or vb[0] or vb[1]:
        raise SystemExit(f"{name}: viewBox must be 0 0 w h")
    ids = {e.get("id") for e in root.iter() if e.get("id")}
    for e in root.iter():
        ref = e.get("clip-path")
        if ref and ref[5:-1] not in ids:
            raise SystemExit(f"{name}: clip-path {ref} has no clipPath")
    return kb


def viewbox_of(p):
    root = ET.fromstring(pathlib.Path(p).read_text())
    vb = [float(v) for v in root.get("viewBox").split()]
    return vb[2], vb[3]
