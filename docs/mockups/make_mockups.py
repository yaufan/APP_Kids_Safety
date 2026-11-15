"""Design-stage sketches for 「安全小隊」 (safety education for 3-6 year olds in Taiwan).

    python3 make_mockups.py          # writes docs/mockups/*.png (needs Node.js + Playwright)
    python3 make_mockups.py 3        # only one page: 0 = style page, 1..7 = a screen, c = contact sheet

Every picture is drawn here as SVG by code (no outside pictures, no emoji). render.js turns each page
into a PNG with Playwright's Chromium at 390x844, deviceScaleFactor 2. The font is jf open-huninn from a
sibling app's checkout.

    0_畫風選擇.png     the same crossing in the three second-round styles: A 瓦楞紙箱手作風, B 絨毛布偶風,
                       C 漫畫網點風 (chosen 2026-11-15, framed in green)
    1_小隊基地.png     home: the child with the helmet, four world signs, badge count, parent button
    2_過馬路.png       crossing: the five steps 集轉探避揮 as five big buttons, the third one glowing
    3_地震躲桌下.png   earthquake: the room wobbles gently, a finger drags the child under the table
    4_火災打119.png    fire: outside, three big keys 1 1 9
    5_身體紅綠燈.png   body traffic light: green / yellow / red spots on the child in a swimsuit
    6_家裡找危險.png   kitchen: find the dangers and fix them (turn the pot handle in)
    7_家長模式.png     parents' settings: phone number, safe grown-ups, worlds on/off, real-life checklist
    contact_sheet.png  screens 1-7 small, with titles

Screens 1-7 are drawn in the chosen style C 「漫畫網點風」 (STYLE = "comic"): flat colour, thin dark-blue
(#1E3A6E) outlines, halftone dots on the shadow side (darker shade of the fill; none on white, very light
shapes or skin), white highlights, speed lines, sound-word bursts, white speech balloons.
The mockups draw the dots with <pattern> + <mask> for speed; the app cannot (flutter_svg has no pattern,
mask or filter) and draws real circles clipped to the shape instead, see docs/design.md 「畫風」.
Other styles kept for the comparison page: "card" (瓦楞紙箱), "plush" (絨毛布偶); first round: "icon",
"cloth", "tile".
"""
import hashlib
import math
import os
import pathlib
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
FONT = None
for _c in ("app_kids_falsecharge", "app_kids_maze", "app_kids_brainstorming", "app_kids_live_circ", "app_kids_card_game", "app_kids_cook"):
    for _base in (HERE.parents[3], HERE.parents[2]):
        _p = _base / _c / "app" / "assets" / "fonts" / "jf-openhuninn-2.1.ttf"
        if _p.exists():
            FONT = _p
            break
    if FONT:
        break
SCRATCH = pathlib.Path(os.environ.get("SCRATCH", "/dev/shm")) if pathlib.Path("/dev/shm").is_dir() else pathlib.Path(tempfile.gettempdir())
W, H = 390, 844

# ---------------------------------------------------------------- signal colours
YEL = "#FFC400"
BLK = "#22262A"
RED = "#E8392F"
GRN = "#1FA64A"
BLU = "#1F6FD6"
WHT = "#FFFFFF"
ORA = "#FF8A1E"
GREY = "#8E979F"
LGREY = "#D5DBE0"
ROAD = "#4B525B"
SKY = "#DCEBF7"
PAGE = "#EEF3F7"
INK = "#1E3A6E"
SOFT = "#5F6E8A"
NAVY = "#2B3F7A"
SKIN = ["#F6D3B3", "#E8B88E", "#C98C5C", "#8F5A3A"]
HAIR = ["#3A2A22", "#7A4A2A", "#E9B64B", "#C7664A"]
GROUT = "#C6CDD3"


class Defs:
    def __init__(self):
        self.d = {}

    def add(self, key, svg):
        self.d.setdefault(key, svg)
        return key

    def svg(self):
        return "<defs>" + "".join(self.d.values()) + "</defs>"


D = Defs()
STYLE = "comic"     # chosen 2026-11-15. Candidates kept: "card", "plush"; first round: "icon", "cloth", "tile"


def _h(*parts):
    return hashlib.md5("|".join(map(str, parts)).encode()).hexdigest()[:8]


def _rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mixc(a, b, t):
    ra, rb = _rgb(a), _rgb(b)
    return "#" + "".join(f"{round(ra[i] + (rb[i] - ra[i]) * t):02X}" for i in range(3))


def darker(c, t=.25):
    return mixc(c, "#000000", t)


def lighter(c, t=.35):
    return mixc(c, "#FFFFFF", t)


# ---------------------------------------------------------------- the three styles
def cloth_f():
    k = "cloth"
    D.add(k, '<filter id="cloth" x="-.05" y="-.05" width="1.1" height="1.1" color-interpolation-filters="sRGB">'
             '<feTurbulence type="fractalNoise" baseFrequency="0.9 0.9" numOctaves="2" seed="4" result="n"/>'
             '<feColorMatrix in="n" type="matrix" values="1 0 0 0 0  1 0 0 0 0  1 0 0 0 0  0 0 0 0 1" result="g"/>'
             '<feComposite in="SourceGraphic" in2="g" operator="arithmetic" k1="0.22" k2="0.9" result="m"/>'
             '<feComposite in="m" in2="SourceGraphic" operator="in"/></filter>')
    return "url(#cloth)"


def tile_pat(col):
    k = "tp" + _h(col)
    shades = [col, lighter(col, .14), darker(col, .12), mixc(col, "#FFFFFF", .06)]
    cells = "".join(f'<rect x="{x + .6}" y="{y + .6}" width="6.8" height="6.8" rx="1" fill="{s}"/>'
                    for (x, y), s in zip(((0, 0), (8, 0), (0, 8), (8, 8)), shades))
    D.add(k, f'<pattern id="{k}" width="16" height="16" patternUnits="userSpaceOnUse">{cells}</pattern>')
    return f"url(#{k})"


KRAFT = "#B98A55"
COMIC = "#1E3A6E"


def card_f():
    """Uneven paint on hand-cut cardboard: blotchy colour and a slightly wobbly edge."""
    D.add("cardf", '<filter id="cardf" x="-.08" y="-.08" width="1.16" height="1.16" color-interpolation-filters="sRGB">'
                   '<feTurbulence type="fractalNoise" baseFrequency="0.035" numOctaves="2" seed="11" result="n"/>'
                   '<feDisplacementMap in="SourceGraphic" in2="n" scale="2.2" xChannelSelector="R" yChannelSelector="G" result="d"/>'
                   '<feTurbulence type="fractalNoise" baseFrequency="0.05" numOctaves="3" seed="2" result="p"/>'
                   '<feColorMatrix in="p" type="matrix" values="1 0 0 0 0  1 0 0 0 0  1 0 0 0 0  0 0 0 0 1" result="pg"/>'
                   '<feComposite in="d" in2="pg" operator="arithmetic" k1="0.3" k2="0.87" result="m"/>'
                   '<feComposite in="m" in2="d" operator="in"/></filter>')
    return "url(#cardf)"


def card_edge_f():
    D.add("cardef", '<filter id="cardef" x="-.08" y="-.08" width="1.16" height="1.16">'
                    '<feTurbulence type="fractalNoise" baseFrequency="0.035" numOctaves="2" seed="11" result="n"/>'
                    '<feDisplacementMap in="SourceGraphic" in2="n" scale="2.2" xChannelSelector="R" yChannelSelector="G"/></filter>')
    return "url(#cardef)"


def plush_f():
    """Fuzzy edge (noise displacement) and soft puffy lighting from the blurred shape."""
    D.add("plushf", '<filter id="plushf" x="-.15" y="-.15" width="1.3" height="1.3" color-interpolation-filters="sRGB">'
                    '<feTurbulence type="fractalNoise" baseFrequency="0.16" numOctaves="3" seed="6" result="n"/>'
                    '<feDisplacementMap in="SourceGraphic" in2="n" scale="5" xChannelSelector="R" yChannelSelector="G" result="dz"/>'
                    '<feGaussianBlur in="dz" stdDeviation="3" result="b"/>'
                    '<feDiffuseLighting in="b" surfaceScale="7" diffuseConstant="1" lighting-color="#ffffff" result="l">'
                    '<feDistantLight azimuth="230" elevation="55"/></feDiffuseLighting>'
                    '<feComposite in="dz" in2="l" operator="arithmetic" k1="0.78" k2="0.3" result="lit"/>'
                    '<feComposite in="lit" in2="dz" operator="in"/></filter>')
    return "url(#plushf)"


def fur_f():
    D.add("furf", '<filter id="furf" x="-.15" y="-.15" width="1.3" height="1.3">'
                  '<feTurbulence type="fractalNoise" baseFrequency="0.3" numOctaves="2" seed="8" result="n"/>'
                  '<feDisplacementMap in="SourceGraphic" in2="n" scale="4" xChannelSelector="R" yChannelSelector="G"/></filter>')
    return "url(#furf)"


def light(col):
    """No dots on white, very light shapes or skin (dots on a face read as dirt)."""
    if col.upper() in [c.upper() for c in SKIN] + ["#F6D3B3"]:
        return True
    r, g, b = _rgb(col)
    return (.299 * r + .587 * g + .114 * b) / 255 > .9


def halftone(col=COMIC):
    """Mockup only: a <pattern> of dots, faded in by a <mask>. The app draws real circles instead (see design.md)."""
    k = "ht" + _h(col)
    D.add(k, f'<pattern id="{k}" width="5" height="5" patternUnits="userSpaceOnUse" patternTransform="rotate(30)">'
             f'<circle cx="2.5" cy="2.5" r="1.25" fill="{col}"/></pattern>')
    D.add("htg", '<linearGradient id="htg" x1="0" y1="0" x2="1" y2="1"><stop offset=".3" stop-color="#000"/><stop offset="1" stop-color="#fff"/></linearGradient>')
    D.add("htm", '<mask id="htm" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#htg)"/></mask>')
    return f"url(#{k})"


def S(elem, col, op=None):
    """One solid shape in the current style. elem is an SVG element without fill, ending in '/>'."""
    o = f' opacity="{op}"' if op is not None else ""
    if STYLE == "card":
        return (f'<g transform="translate(2 3.5)" opacity=".28" filter="{card_edge_f()}">{elem.replace("/>", f" fill=\"{darker(KRAFT, .6)}\"/>")}</g>'
                + elem.replace("/>", f' fill="{col}" filter="{card_f()}"{o}/>')
                + f'<g filter="{card_edge_f()}">'
                + elem.replace("/>", f' fill="none" stroke="{KRAFT}" stroke-width="3.6" stroke-linejoin="round"/>')
                + elem.replace("/>", f' fill="none" stroke="{lighter(KRAFT, .45)}" stroke-width="3.6" stroke-dasharray="1.6 1.9" stroke-linejoin="round"/>')
                + "</g>")
    if STYLE == "plush":
        return (f'<g filter="{fur_f()}">' + elem.replace("/>", f' fill="none" stroke="{lighter(col, .25)}" stroke-width="5" stroke-dasharray="1 2.4" stroke-linecap="round" opacity=".9"/>') + "</g>"
                + elem.replace("/>", f' fill="{col}" filter="{plush_f()}"{o}/>')
                + elem.replace("/>", f' fill="none" stroke="{darker(col, .35)}" stroke-width="1" stroke-dasharray="2.5 3" transform="scale(.96)" opacity="0"/>'))
    if STYLE == "comic":
        return (elem.replace("/>", f' fill="{col}"{o}/>')
                + ("" if light(col) else elem.replace("/>", f' fill="{halftone(darker(col, .45))}" mask="url(#htm)" opacity=".55"/>'))
                + elem.replace("/>", f' fill="none" stroke="{COMIC}" stroke-width="1.8" stroke-linejoin="round"/>'))
    if STYLE == "cloth":
        return (f'<g transform="translate(1.5 2.5)" opacity=".25">{elem.replace("/>", f" fill=\"{darker(col, .6)}\"/>")}</g>'
                + elem.replace("/>", f' fill="{col}" filter="{cloth_f()}"{o}/>')
                + elem.replace("/>", f' fill="none" stroke="{darker(col, .5)}" stroke-width="1.3" stroke-dasharray="3.5 2.6" stroke-linecap="round" opacity=".75"/>'))
    if STYLE == "tile":
        return elem.replace("/>", f' fill="{GROUT}"{o}/>') + elem.replace("/>", f' fill="{tile_pat(col)}"{o}/>')
    return elem.replace("/>", f' fill="{col}"{o}/>')


def rect(x, y, w, h, r, col, op=None):
    return S(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{r:.1f}"/>', col, op)


def circ(cx, cy, r, col, op=None):
    return S(f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r:.1f}"/>', col, op)


def ell(cx, cy, rx, ry, col, rot=0.0, op=None):
    t = f' transform="rotate({rot} {cx:.1f} {cy:.1f})"' if rot else ""
    return S(f'<ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{rx:.1f}" ry="{ry:.1f}"{t}/>', col, op)


def path(d, col, op=None):
    return S(f'<path d="{d}"/>', col, op)


def poly(pts, col, op=None):
    return path("M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + "Z", col, op)


def line(d, col, w, cap="round"):
    """A thick rounded line (limbs, poles). Style-aware like S()."""
    base = f'<path d="{d}" fill="none" stroke-width="{w}" stroke-linecap="{cap}" stroke-linejoin="round"'
    if STYLE == "card":
        return (f'<g transform="translate(2 3.5)" opacity=".28">{base} stroke="{darker(KRAFT, .6)}"/></g>'
                f'{base.replace(f"stroke-width=\"{w}\"", f"stroke-width=\"{w + 4}\"")} stroke="{KRAFT}"/>'
                f'{base} stroke="{col}" filter="{card_f()}"/>')
    if STYLE == "plush":
        return (f'<g filter="{fur_f()}">{base.replace(f"stroke-width=\"{w}\"", f"stroke-width=\"{w + 5}\"")} stroke="{lighter(col, .25)}" stroke-dasharray="1 2.4" opacity=".9"/></g>'
                f'{base} stroke="{col}" filter="{plush_f()}"/>')
    if STYLE == "comic":
        return (f'{base.replace(f"stroke-width=\"{w}\"", f"stroke-width=\"{w + 3.6}\"")} stroke="{COMIC}"/>'
                f'{base} stroke="{col}"/>')
    if STYLE == "cloth":
        return (f'<g transform="translate(1.5 2.5)" opacity=".25">{base} stroke="{darker(col, .6)}"/></g>'
                f'{base} stroke="{col}" filter="{cloth_f()}"/>'
                f'{base.replace(f"stroke-width=\"{w}\"", f"stroke-width=\"{max(w - 3, 1)}\"")} stroke="{darker(col, .5)}" stroke-dasharray="3.5 2.6" opacity=".55"/>')
    if STYLE == "tile":
        return f'{base} stroke="{GROUT}"/>{base} stroke="{tile_pat(col)}"/>'
    return f'{base} stroke="{col}"/>'


def flat(elem, col, op=None):
    """Always a plain flat shape, whatever the style (eyes, mouths, small marks)."""
    o = f' opacity="{op}"' if op is not None else ""
    return elem.replace("/>", f' fill="{col}"{o}/>')


def stroke(d, col, w, op=1.0, dash=None, cap="round"):
    da = f' stroke-dasharray="{dash}"' if dash else ""
    return f'<path d="{d}" fill="none" stroke="{col}" stroke-width="{w}" stroke-opacity="{op}" stroke-linecap="{cap}" stroke-linejoin="round"{da}/>'


def hi(x, y, w, h, op=.55):
    """The one white highlight that style A puts on every thing."""
    if STYLE not in ("icon", "comic"):
        return ""
    return f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{min(w, h) / 2:.1f}" fill="#FFFFFF" opacity="{op}"/>'


def tx(x, y, s, size=16, col=INK, anchor="middle", weight=None, op=1.0, extra=""):
    wt = f' font-weight="{weight}"' if weight else ""
    return f'<text x="{x}" y="{y}" font-family="Huninn, sans-serif" font-size="{size}" fill="{col}" text-anchor="{anchor}"{wt} opacity="{op}"{extra}>{s}</text>'


def place(x, y, s, inner, rot=0.0):
    r = f" rotate({rot:.1f})" if rot else ""
    return f'<g transform="translate({x:.1f} {y:.1f}){r} scale({s:.4f})">{inner}</g>'


def glow(cx, cy, r):
    """The 'tap here' ring: a soft yellow halo and a dashed ring."""
    k = "glow"
    D.add(k, f'<radialGradient id="glow"><stop offset=".55" stop-color="{YEL}" stop-opacity=".55"/><stop offset="1" stop-color="{YEL}" stop-opacity="0"/></radialGradient>')
    return (f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r * 1.35:.1f}" fill="url(#glow)"/>'
            f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r:.1f}" fill="none" stroke="{YEL}" stroke-width="4" stroke-dasharray="9 7" stroke-linecap="round"/>')


def burst(cx, cy, rx, ry, text, size=14, fill=WHT, col=None, n=16):
    """A comic sound-word burst: a spiky star with the word inside."""
    col = col or COMIC
    pts = [(cx + (rx if i % 2 == 0 else rx * .68) * math.cos(math.radians(-90 + i * 360 / n)),
            cy + (ry if i % 2 == 0 else ry * .66) * math.sin(math.radians(-90 + i * 360 / n))) for i in range(n)]
    d = "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + "Z"
    return (f'<path d="{d}" fill="{fill}" stroke="{COMIC}" stroke-width="2" stroke-linejoin="round"/>'
            + tx(cx, cy + size * .36, text, size, col, weight="bold"))


def speed(x, y, n=3, length=34, gap=10, dx=1, col=None):
    """Parallel speed lines (dx=1: lines trail to the left of x)."""
    col = col or COMIC
    d = "".join(f"M{x:.1f},{y + i * gap:.1f} h{-dx * (length - (i % 2) * 10):.1f} " for i in range(n))
    return stroke(d, col, 2.4)


def finger(x, y, s=1.0):
    """A pointing hand (the child's finger on the screen)."""
    o = [f'<g transform="translate({x} {y}) scale({s})">']
    o.append(f'<path d="M0,-30 Q0,-40 8,-40 Q16,-40 16,-30 V-6 Q22,-6 26,-2 Q34,0 36,10 L34,30 Q32,40 20,40 H4 Q-8,40 -10,28 L-18,8 Q-20,0 -12,-2 Q-6,-2 0,6 Z" fill="#F6D3B3" stroke="{COMIC}" stroke-width="2.4" stroke-linejoin="round"/>')
    o.append(stroke("M-12,-2 Q-6,-2 0,6 M16,-6 V8 M26,-2 V10", "#D9A985", 2.2))
    o.append(flat('<rect x="-8" y="26" width="40" height="22" rx="6"/>', BLU))
    return "".join(o) + "</g>"


def check(cx, cy, s=1.0, col=WHT):
    return stroke(f"M{cx - 8 * s},{cy} L{cx - 2 * s},{cy + 6 * s} L{cx + 9 * s},{cy - 7 * s}", col, 4 * s)


def arrow(d, col=BLK, w=5):
    return stroke(d, col, w, dash="1 9")


# ================================================================ FACES
def eyes(cx, cy, dx, r=2.6, col=BLK):
    o = []
    for x in (cx - dx, cx + dx):
        if STYLE == "card":      # white paper eyes glued on
            o.append(flat(f'<circle cx="{x:.1f}" cy="{cy:.1f}" r="{r * 2.1:.1f}"/>', WHT) + flat(f'<circle cx="{x + r * .3:.1f}" cy="{cy + r * .3:.1f}" r="{r * 1.05:.1f}"/>', col))
        elif STYLE == "plush":   # button eyes with two holes
            o.append(flat(f'<circle cx="{x:.1f}" cy="{cy:.1f}" r="{r * 1.7:.1f}"/>', "#3A3A44") + f'<circle cx="{x:.1f}" cy="{cy:.1f}" r="{r * 1.25:.1f}" fill="none" stroke="#6A6A78" stroke-width=".8"/>'
                     + flat(f'<circle cx="{x - r * .5:.1f}" cy="{cy:.1f}" r="{r * .3:.1f}"/>', WHT) + flat(f'<circle cx="{x + r * .5:.1f}" cy="{cy:.1f}" r="{r * .3:.1f}"/>', WHT))
        elif STYLE == "comic":
            o.append(flat(f'<circle cx="{x:.1f}" cy="{cy:.1f}" r="{r * 1.15:.1f}"/>', COMIC) + flat(f'<circle cx="{x - r * .35:.1f}" cy="{cy - r * .35:.1f}" r="{r * .4:.1f}"/>', WHT))
        else:
            o.append(flat(f'<circle cx="{x:.1f}" cy="{cy:.1f}" r="{r}"/>', col))
    return "".join(o)


def smile(cx, cy, w, col=BLK, t=2.4):
    if STYLE == "comic":
        col = COMIC
    elif STYLE == "plush":
        col, t = "#6A4A3A", t * 1.2
    return stroke(f"M{cx - w:.1f},{cy:.1f} Q{cx:.1f},{cy + w * .9:.1f} {cx + w:.1f},{cy:.1f}", col, t)


def cheeks(cx, cy, dx, r, col="#FF8C9C"):
    return flat(f'<circle cx="{cx - dx:.1f}" cy="{cy:.1f}" r="{r}"/>', col, .7) + flat(f'<circle cx="{cx + dx:.1f}" cy="{cy:.1f}" r="{r}"/>', col, .7)


# ================================================================ CHARACTERS (feet at (0,0), about 110 units tall)
def hero(helmet=YEL, skin=0, hair=0, pose="stand", look=0, swimsuit=False, vest=ORA):
    """The child as a squad member: yellow helmet, orange vest with a silver stripe.
    pose: stand / wave / crouch / point / arms_out / hold (right arm forward)."""
    sc, hc = SKIN[skin % 4], HAIR[hair % 4]
    o = []
    if pose == "crouch":
        o.append(line("M-14,-24 L-26,-4 M14,-24 L26,-4", NAVY, 13))
        o.append(ell(-28, -3, 9, 5, BLK) + ell(28, -3, 9, 5, BLK))
        o.append(line("M-22,-30 L-40,-6 M22,-30 L40,-6", sc, 10))
        o.append(circ(-42, -4, 7, sc) + circ(42, -4, 7, sc))
        o.append(rect(-26, -48, 52, 30, 13, vest))
        o.append(rect(-26, -36, 52, 6, 2, LGREY))
        o.append(hi(-20, -44, 7, 10))
        hy = -64
    else:
        o.append(line("M-9,-32 L-11,-4 M9,-32 L11,-4", NAVY, 13))
        o.append(ell(-12, -3, 9, 5, BLK) + ell(12, -3, 9, 5, BLK))
        if swimsuit:
            o.append(rect(-19, -66, 38, 40, 12, "#2EA6E6"))
            o.append(hi(-13, -60, 8, 20))
        else:
            o.append(rect(-20, -66, 40, 38, 12, vest))
            o.append(rect(-20, -52, 40, 7, 2, LGREY))
            o.append(hi(-14, -62, 7, 14))
        arm_c = sc
        if pose == "wave":
            o.append(line("M-16,-58 L-30,-34", arm_c, 10) + circ(-31, -32, 7, sc))
            o.append(line("M16,-58 L34,-84", arm_c, 10) + circ(36, -87, 7.5, sc))
        elif pose == "arms_out":
            o.append(line("M-16,-56 L-42,-50", arm_c, 10) + circ(-45, -49, 7.5, sc))
            o.append(line("M16,-56 L42,-50", arm_c, 10) + circ(45, -49, 7.5, sc))
        elif pose == "point":
            o.append(line("M-16,-58 L-30,-34", arm_c, 10) + circ(-31, -32, 7, sc))
            o.append(line("M16,-58 L40,-62", arm_c, 10) + circ(43, -62, 7.5, sc))
        elif pose == "hold":
            o.append(line("M-16,-58 L-30,-34", arm_c, 10) + circ(-31, -32, 7, sc))
            o.append(line("M16,-58 L22,-80", arm_c, 10) + circ(22, -84, 7.5, sc))
        else:
            o.append(line("M-16,-58 L-30,-34", arm_c, 10) + circ(-31, -32, 7, sc))
            o.append(line("M16,-58 L30,-34", arm_c, 10) + circ(31, -32, 7, sc))
        hy = -86
    o.append(circ(0, hy, 21, sc))
    # hair peeking under the helmet
    o.append(path(f"M-20,{hy - 6} Q0,{hy - 2} 20,{hy - 6} L20,{hy - 12} L-20,{hy - 12}Z", hc))
    if swimsuit:
        o.append(path(f"M-21,{hy - 2} Q-22,{hy - 30} 0,{hy - 28} Q22,{hy - 30} 21,{hy - 2} Q10,{hy - 16} 0,{hy - 14} Q-10,{hy - 16} -21,{hy - 2}Z", hc))
    else:
        o.append(path(f"M-24,{hy - 6} A24,24 0 0 1 24,{hy - 6}Z", helmet))
        o.append(rect(-28, hy - 9, 56, 8, 4, helmet))
        o.append(hi(-14, hy - 24, 9, 9))
        o.append(flat(f'<rect x="-3" y="{hy - 30}" width="6" height="20" rx="3"/>', WHT, .6))
    o.append(eyes(look, hy + 2, 8))
    o.append(smile(look, hy + 10, 5))
    o.append(cheeks(look, hy + 8, 14, 3.2))
    return "".join(o)


def dog_police(pose="stand"):
    """汪汪警察: a brown dog in a navy uniform and cap, white gloves."""
    fur, ear = "#C98E5A", "#8A5A33"
    o = [line("M-9,-32 L-11,-4 M9,-32 L11,-4", NAVY, 13)]
    o.append(ell(-12, -3, 9, 5, BLK) + ell(12, -3, 9, 5, BLK))
    o.append(rect(-21, -68, 42, 40, 12, NAVY))
    o.append(rect(-21, -50, 42, 5, 2, "#5A6FB0"))
    o.append(hi(-15, -64, 7, 14))
    o.append(flat('<circle cx="0" cy="-60" r="2.6"/>', YEL) + flat('<circle cx="0" cy="-48" r="2.6"/>', YEL))
    if pose == "stop":
        o.append(line("M-16,-60 L-30,-36", NAVY, 10) + circ(-31, -33, 7.5, WHT))
        o.append(line("M16,-60 L34,-80", NAVY, 10) + circ(36, -84, 9, WHT))
        o.append(stroke("M33,-90 V-80 M37,-91 V-80 M41,-88 V-80", LGREY, 1.6))
    else:
        o.append(line("M-16,-60 L-30,-36", NAVY, 10) + circ(-31, -33, 7.5, WHT))
        o.append(line("M16,-60 L30,-36", NAVY, 10) + circ(31, -33, 7.5, WHT))
    hy = -90
    o.append(ell(-24, hy + 4, 8, 15, ear, rot=10) + ell(24, hy + 4, 8, 15, ear, rot=-10))
    o.append(circ(0, hy, 22, fur))
    o.append(ell(0, hy + 9, 11, 8, lighter(fur, .5)))
    o.append(flat(f'<ellipse cx="0" cy="{hy + 6}" rx="4.5" ry="3.4"/>', BLK))
    o.append(eyes(0, hy - 3, 9, 2.8))
    o.append(smile(0, hy + 11, 4))
    o.append(path(f"M-24,{hy - 10} Q0,{hy - 36} 24,{hy - 10}Z", NAVY))
    o.append(rect(-26, hy - 13, 52, 7, 3.5, BLK))
    o.append(flat(f'<circle cx="0" cy="{hy - 20}" r="5"/>', YEL))
    o.append(flat('<circle cx="24" cy="-55" r="5"/>', LGREY) + stroke("M24,-60 V-68", LGREY, 2.2))
    return "".join(o)


def cat_fire():
    """喵喵消防員: an orange cat in a red fire coat with yellow stripes and a yellow helmet."""
    fur = "#F0A040"
    o = [line("M-9,-32 L-11,-4 M9,-32 L11,-4", BLK, 13)]
    o.append(ell(-12, -3, 9, 5, BLK) + ell(12, -3, 9, 5, BLK))
    o.append(rect(-21, -68, 42, 40, 12, RED))
    o.append(rect(-21, -56, 42, 5, 2, YEL) + rect(-21, -42, 42, 5, 2, YEL))
    o.append(hi(-15, -64, 7, 10))
    o.append(line("M-16,-60 L-30,-36", RED, 10) + circ(-31, -33, 7.5, fur))
    o.append(line("M16,-60 L30,-36", RED, 10) + circ(31, -33, 7.5, fur))
    hy = -90
    o.append(circ(0, hy, 22, fur))
    o.append(poly([(-20, hy - 8), (-18, hy - 30), (-4, hy - 18)], fur) + poly([(20, hy - 8), (18, hy - 30), (4, hy - 18)], fur))
    o.append(stroke(f"M-10,{hy - 14} q3,4 0,8 M10,{hy - 14} q-3,4 0,8", darker(fur, .3), 2.4))
    o.append(eyes(0, hy - 2, 9, 2.8))
    o.append(flat(f'<path d="M-3,{hy + 5} L3,{hy + 5} L0,{hy + 8}Z"/>', "#E07080"))
    o.append(stroke(f"M0,{hy + 8} q-4,5 -7,2 M0,{hy + 8} q4,5 7,2", BLK, 2))
    o.append(stroke(f"M-28,{hy + 2} H-14 M-28,{hy + 7} H-14 M28,{hy + 2} H14 M28,{hy + 7} H14", BLK, 1.5, .6))
    o.append(path(f"M-25,{hy - 10} Q0,{hy - 38} 25,{hy - 10}Z", YEL))
    o.append(rect(-28, hy - 13, 56, 7, 3.5, YEL))
    o.append(flat(f'<rect x="-6" y="{hy - 29}" width="12" height="13" rx="3"/>', RED))
    o.append(hi(-16, hy - 22, 7, 7))
    return "".join(o)


def bunny_nurse():
    """兔兔護士: a white rabbit in a white dress with a pink cross and a pink cap."""
    fur, pink = "#FBFBFB", "#F27AA0"
    o = [line("M-9,-32 L-11,-4 M9,-32 L11,-4", fur, 13)]
    o.append(ell(-12, -3, 9, 5, pink) + ell(12, -3, 9, 5, pink))
    o.append(path("M-21,-66 H21 L26,-28 H-26Z", "#F3F6F8"))
    o.append(flat('<path d="M-3,-56 H3 V-50 H9 V-44 H3 V-38 H-3 V-44 H-9 V-50 H-3Z"/>', pink))
    o.append(line("M-16,-60 L-30,-36", "#F3F6F8", 10) + circ(-31, -33, 7.5, fur))
    o.append(line("M16,-60 L30,-36", "#F3F6F8", 10) + circ(31, -33, 7.5, fur))
    hy = -90
    o.append(ell(-11, hy - 30, 7.5, 20, fur, rot=-8) + ell(11, hy - 30, 7.5, 20, fur, rot=8))
    o.append(flat(f'<ellipse cx="-11" cy="{hy - 30}" rx="3.5" ry="13" transform="rotate(-8 -11 {hy - 30})"/>', "#F9C6D5"))
    o.append(flat(f'<ellipse cx="11" cy="{hy - 30}" rx="3.5" ry="13" transform="rotate(8 11 {hy - 30})"/>', "#F9C6D5"))
    o.append(circ(0, hy, 22, fur))
    o.append(eyes(0, hy - 2, 9, 2.8))
    o.append(flat(f'<ellipse cx="0" cy="{hy + 5}" rx="3" ry="2.2"/>', "#E07080"))
    o.append(stroke(f"M0,{hy + 7} q-4,5 -7,2 M0,{hy + 7} q4,5 7,2", BLK, 2))
    o.append(cheeks(0, hy + 6, 13, 3.2))
    o.append(rect(-16, hy - 20, 32, 12, 4, "#F3F6F8"))
    o.append(flat(f'<path d="M-2,{hy - 19} H2 V-16 H5 V-12 H2 V-9 H-2 V-12 H-5 V-16 H-2Z"/>'.replace("V-16", f"V{hy - 16}").replace("V-12", f"V{hy - 12}").replace("V-9", f"V{hy - 9}"), pink))
    return "".join(o)


HELPERS = {"dog": dog_police, "cat": cat_fire, "bunny": bunny_nurse}


# ================================================================ THINGS
def ped_light(x, y, s=1.0, green=True, count="12"):
    """Taiwan's pedestrian signal: the countdown on top, the walking green man (or the standing red man) below."""
    o = [f'<g transform="translate({x} {y}) scale({s})">']
    o.append(line("M0,96 V190", GREY, 8))
    o.append(rect(-24, -2, 48, 100, 8, BLK))
    o.append(rect(-18, 4, 36, 38, 5, "#30363B"))
    o.append(rect(-18, 48, 36, 44, 5, "#30363B"))
    col = GRN if green else RED
    o.append(tx(0, 32, count, 24, col, weight="bold"))
    cy = 70
    if green:
        o.append(flat(f'<circle cx="-2" cy="{cy - 14}" r="4.5"/>', GRN))
        o.append(stroke(f"M-2,{cy - 9} L1,{cy + 2} L-6,{cy + 14} M1,{cy + 2} L9,{cy + 13} M-2,{cy - 7} L-10,{cy} M-1,{cy - 7} L8,{cy - 2}", GRN, 3.6))
    else:
        o.append(flat(f'<circle cx="0" cy="{cy - 14}" r="4.5"/>', RED))
        o.append(stroke(f"M0,{cy - 9} V{cy + 3} M-4,{cy + 3} V{cy + 15} M4,{cy + 3} V{cy + 15} M0,{cy - 7} L-7,{cy + 2} M0,{cy - 7} L7,{cy + 2}", RED, 3.6))
    o.append(hi(-20, 2, 5, 90, .18))
    return "".join(o) + "</g>"


def car(x, y, s=1.0, col=BLU, flip=False):
    """A side-view car facing left (flip = facing right)."""
    f = f" scale(-1 1)" if flip else ""
    o = [f'<g transform="translate({x} {y}){f} scale({s})">']
    o.append(path("M-60,10 V-14 Q-60,-22 -50,-22 H-30 L-16,-44 H30 Q40,-44 44,-36 L52,-22 Q62,-20 62,-10 V10 Q62,16 54,16 H-52 Q-60,16 -60,10Z", col))
    o.append(path("M-26,-20 L-14,-38 H2 V-20Z", "#CFE7F7") + path("M10,-20 V-38 H28 Q34,-38 36,-32 L42,-20Z", "#CFE7F7"))
    o.append(circ(-36, 16, 13, BLK) + circ(36, 16, 13, BLK) + circ(-36, 16, 5.5, LGREY) + circ(36, 16, 5.5, LGREY))
    o.append(flat('<rect x="-62" y="-8" width="8" height="10" rx="3"/>', YEL))
    o.append(hi(-50, -16, 60, 6, .5))
    return "".join(o) + "</g>"


def table(x, y, s=1.0, col="#B9793F"):
    o = [f'<g transform="translate({x} {y}) scale({s})">']
    o.append(line("M-60,0 V62 M60,0 V62", darker(col, .2), 12))
    o.append(rect(-80, -12, 160, 20, 8, col))
    o.append(hi(-70, -8, 50, 5))
    return "".join(o) + "</g>"


def building(x, y, w, h, col, windows=True):
    o = [rect(x, y, w, h, 6, col)]
    if windows:
        for r in range(int(h // 34)):
            for c in range(int(w // 30)):
                o.append(flat(f'<rect x="{x + 10 + c * 30}" y="{y + 12 + r * 34}" width="14" height="16" rx="2"/>', "#FFFFFF", .55))
    return "".join(o)


def sign(x, y, r, kind, col, inner=""):
    """A road-sign shape: circle, square, diamond or triangle, with something inside."""
    if kind == "circle":
        o = circ(x, y, r, col) + circ(x, y, r - 8, lighter(col, .1)) if False else circ(x, y, r, col)
    elif kind == "diamond":
        o = poly([(x, y - r), (x + r, y), (x, y + r), (x - r, y)], col)
    elif kind == "triangle":
        o = path(f"M{x},{y - r} L{x + r * 1.05},{y + r * .8} Q{x + r * 1.1},{y + r * .95} {x + r * .9},{y + r * .95} H{x - r * .9} Q{x - r * 1.1},{y + r * .95} {x - r * 1.05},{y + r * .8}Z", col)
    else:
        o = rect(x - r, y - r, 2 * r, 2 * r, r * .28, col)
    return o + hi(x - r * .7, y - r * .75, r * .3, r * .3) + inner


def cross_scene(x, y, w=330, h=240, hero_pose="stand", look=0, show_dog=True, green=True, finger_at=None):
    """The crossing: sky, two buildings, the road with a zebra, the pedestrian light, a stopped car,
    the child at the kerb and the dog police officer. Drawn at 330x240, scaled to w x h."""
    k = w / 330
    o = [f'<g transform="translate({x} {y}) scale({k:.4f})">']
    D.add("cs" + _h(x, y, w), f'<clipPath id="cs{_h(x, y, w)}"><rect x="0" y="0" width="330" height="240" rx="14"/></clipPath>')
    o.append(f'<g clip-path="url(#cs{_h(x, y, w)})">')
    o.append(rect(0, 0, 330, 240, 0, SKY) if STYLE in ("card", "plush", "comic") else flat('<rect x="0" y="0" width="330" height="240"/>', SKY))
    o.append(circ(282, 36, 20, YEL) + hi(272, 24, 9, 9))
    o.append(building(10, 44, 86, 80, "#9CC7E8") + building(112, 30, 70, 94, "#F2B2A0") + building(200, 56, 60, 68, "#A9D9B5"))
    o.append(rect(0, 120, 330, 12, 0, LGREY))
    o.append(rect(0, 130, 330, 110, 0, ROAD))
    for i in range(7):
        o.append(flat(f'<rect x="{150 + i * 24}" y="138" width="14" height="96" rx="3"/>', WHT))
    o.append(rect(0, 226, 330, 14, 0, LGREY))
    if STYLE == "comic":      # speed lines behind the car that just stopped, and the cuckoo's sound burst
        o.append(stroke("M8,150 H40 M2,162 H46 M10,174 H38", COMIC, 2.2))
        pts = [(240 + (30 if i % 2 == 0 else 19) * math.cos(math.radians(-90 + i * 22.5)), 90 + (19 if i % 2 == 0 else 12) * math.sin(math.radians(-90 + i * 22.5))) for i in range(16)]
        o.append(flat("<path d=\"M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + "Z\"/>", WHT) + stroke("M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + "Z", COMIC, 1.6))
        o.append(tx(240, 95, "布穀！", 12, COMIC, weight="bold"))
    o.append(car(70, 172, .72, BLU))
    o.append(flat('<rect x="118" y="150" width="4" height="44" rx="2"/>', RED, .0))
    o.append(ped_light(292, 70, .62, green))
    if show_dog:
        o.append(place(250, 232, .72, dog_police("stop" if not green else "stand")))
    hx = 188
    if finger_at:
        o.append(glow(hx, 180, 36))
    o.append(place(hx, 234, .78, hero(pose=hero_pose, look=look)))
    o.append("</g></g>")
    return "".join(o)


# ================================================================ PHONE CHROME
def page(body, bg=PAGE, w=W, h=H):
    css = (f"@font-face {{ font-family: Huninn; src: url('file://{FONT}'); }}"
           f"* {{ margin: 0; padding: 0; }} body {{ width: {w}px; height: {h}px; overflow: hidden; background: {bg}; }}")
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{D.svg()}{body}</svg>'
    return f'<!doctype html><html><head><meta charset="utf-8"><style>{css}</style></head><body>{svg}</body></html>'


def render(html, out, w, h, scale):
    with tempfile.TemporaryDirectory(dir=SCRATCH) as tmp:
        p = pathlib.Path(tmp) / "page.html"
        p.write_text(html)
        env = dict(os.environ)
        env.setdefault("NODE_PATH", "/opt/node22/lib/node_modules")
        subprocess.run(["node", str(HERE / "render.js"), str(p), str(out), str(w), str(h), str(scale)], check=True, env=env)
    if pathlib.Path(out).stat().st_size > 450_000:
        from PIL import Image
        im = Image.open(out).convert("RGB")
        im.quantize(colors=256, method=Image.Quantize.MEDIANCUT, kmeans=2, dither=Image.Dither.FLOYDSTEINBERG).save(out, optimize=True)


def top_bar(title, col, back=True):
    o = [flat(f'<rect x="0" y="0" width="{W}" height="92"/>', col)]
    o.append(flat(f'<rect x="0" y="88" width="{W}" height="4"/>', COMIC))
    o.append(speed(W - 20, 30, 3, 40, 12))
    if back:
        o.append(f'<circle cx="40" cy="52" r="22" fill="{WHT}" stroke="{COMIC}" stroke-width="2.4"/>')
        o.append(stroke("M48,52 H32 M38,44 L30,52 L38,60", COMIC, 4.5))
    o.append(tx(W / 2 + (10 if back else 0), 61, title, 26, WHT, weight="bold",
                extra=f' stroke="{COMIC}" stroke-width="5" stroke-linejoin="round" paint-order="stroke"'))
    return "".join(o)


def bubble(helper, lines, col, y=690, big=False):
    """The helper on a coloured panel at the bottom, talking in a white comic balloon (read aloud)."""
    o = [f'<rect x="14" y="{y}" width="362" height="136" rx="10" fill="{lighter(col, .82)}" stroke="{COMIC}" stroke-width="2.4"/>']
    o.append(place(70, y + 128, .9, HELPERS[helper]()))
    d = (f"M132,{y + 16} H354 Q366,{y + 16} 366,{y + 28} V{y + 106} Q366,{y + 118} 354,{y + 118} H150 "
         f"Q138,{y + 118} 138,{y + 106} V{y + 76} L118,{y + 84} L138,{y + 58} V{y + 28} Q138,{y + 16} 150,{y + 16}Z").replace("M132", "M150")
    o.append(f'<path d="{d}" fill="{WHT}" stroke="{COMIC}" stroke-width="2.6" stroke-linejoin="round"/>')
    fs = 21 if big else 19
    ty = y + 16 + (102 - fs * len(lines) * 1.25) / 2 + fs * .95
    for i, t in enumerate(lines):
        o.append(tx(250, ty + i * fs * 1.25, t, fs, COMIC, weight="bold"))
    o.append(f'<circle cx="350" cy="{y + 104}" r="11" fill="{col}" stroke="{COMIC}" stroke-width="1.8"/>'
             + flat(f'<path d="M345,{y + 99} L349,{y + 99} L355,{y + 94} V{y + 114} L349,{y + 109} H345Z"/>', WHT))
    return "".join(o)


def step_chip(x, y, w, h, label, state, col):
    """One step button: done (filled, tick), now (glowing), later (outlined)."""
    o = []
    if state == "done":
        o.append(rect(x, y, w, h, 14, col))
        o.append(check(x + w / 2, y + h - 16, .9))
        o.append(tx(x + w / 2, y + 40, label, 30, WHT, weight="bold"))
    elif state == "now":
        o.append(glow(x + w / 2, y + h / 2, w / 2 + 2))
        o.append(rect(x, y, w, h, 14, WHT))
        o.append(tx(x + w / 2, y + 40, label, 30, col, weight="bold"))
        o.append(tx(x + w / 2, y + h - 12, "現在", 13, col))
    else:
        o.append(flat(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14"/>', WHT, .7))
        o.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="none" stroke="{LGREY}" stroke-width="3"/>')
        o.append(tx(x + w / 2, y + 40, label, 30, GREY, weight="bold"))
    return "".join(o)


def badge_icon(cx, cy, kind, s=1.0):
    """Small badges that end up on the helmet."""
    o = [f'<g transform="translate({cx} {cy}) scale({s})">']
    if kind == "light":
        o.append(rect(-9, -14, 18, 28, 5, BLK) + flat('<circle cx="0" cy="-6" r="4"/>', RED) + flat('<circle cx="0" cy="6" r="4"/>', GRN))
    elif kind == "table":
        o.append(rect(-14, -8, 28, 6, 2, "#B9793F") + line("M-10,-3 V10 M10,-3 V10", "#8A5A2E", 4))
    elif kind == "119":
        o.append(circ(0, 0, 15, RED) + tx(0, 5, "119", 12, WHT, weight="bold"))
    elif kind == "heart":
        o.append(path("M0,12 L-12,0 Q-16,-10 -6,-12 Q0,-12 0,-6 Q0,-12 6,-12 Q16,-10 12,0Z", GRN))
    elif kind == "house":
        o.append(path("M-14,0 L0,-13 L14,0 V12 H-14Z", YEL))
    elif kind == "star":
        pts = [(15 * math.cos(math.radians(-90 + 36 * i)) * (1 if i % 2 == 0 else .48), 15 * math.sin(math.radians(-90 + 36 * i)) * (1 if i % 2 == 0 else .48)) for i in range(10)]
        o.append(poly(pts, YEL))
    return "".join(o) + "</g>"


# ================================================================ SCREENS
def screen_home():
    o = [flat(f'<rect width="{W}" height="{H}"/>', PAGE)]
    o.append(rect(0, 0, W, 300, 0, "#FFE27A"))
    o.append(flat('<rect x="0" y="292" width="390" height="10"/>', "#E9B800"))
    for i in range(10):
        o.append(flat(f'<rect x="{i * 40 + 2}" y="296" width="20" height="6"/>', BLK))
    o.append(tx(195, 54, "安全小隊", 36, BLK, weight="bold"))
    o.append(tx(195, 84, "小隊員：小明", 18, SOFT))
    o.append(place(195, 272, 1.5, hero(pose="wave")))
    o.append(badge_icon(240, 110, "light", .8) + badge_icon(275, 128, "table", .8))
    o.append(place(60, 278, .85, dog_police()))
    o.append(place(325, 278, .85, bunny_nurse()))
    worlds = [("馬路世界", "circle", BLU, 90, 420, "dog"), ("救災世界", "square", RED, 300, 420, "cat"),
              ("身體世界", "circle", GRN, 90, 620, "bunny"), ("家裡世界", "diamond", YEL, 300, 620, "bunny")]
    for name, kind, col, cx, cy, helper in worlds:
        o.append(rect(cx - 88, cy - 86, 176, 184, 24, WHT))
        if kind == "circle" and col == BLU:
            inner = rect(cx - 12, cy - 36, 24, 44, 6, BLK) + flat(f'<circle cx="{cx}" cy="{cy - 25}" r="7"/>', RED) + flat(f'<circle cx="{cx}" cy="{cy - 3}" r="7"/>', GRN)
        elif kind == "square":
            inner = tx(cx, cy - 2, "119", 30, WHT, weight="bold") + rect(cx - 30, cy + 8, 60, 6, 3, WHT)
        elif kind == "circle":
            inner = path(f"M{cx},{cy + 6} L{cx - 20},{cy - 14} Q{cx - 26},{cy - 30} {cx - 10},{cy - 32} Q{cx},{cy - 32} {cx},{cy - 22} Q{cx},{cy - 32} {cx + 10},{cy - 32} Q{cx + 26},{cy - 30} {cx + 20},{cy - 14}Z", WHT)
        else:
            inner = path(f"M{cx - 24},{cy - 10} L{cx},{cy - 32} L{cx + 24},{cy - 10} V{cy + 12} H{cx - 24}Z", BLK) + flat(f'<rect x="{cx - 7}" y="{cy - 6}" width="14" height="18" rx="3"/>', YEL)
        o.append(sign(cx, cy - 12, 52, kind, col, inner))
        o.append(tx(cx, cy + 74, name, 22, INK, weight="bold"))
        o.append(f'<g transform="translate({cx + 52} {cy + 52}) scale(.36)">{HELPERS[helper]()}</g>')
    o.append(burst(86, 140, 44, 26, "出發！", 16, YEL))
    o.append(rect(14, 740, 250, 70, 20, WHT))
    o.append(place(52, 775, .9, badge_icon(0, 0, "star")) if False else badge_icon(52, 775, "star", 1.1))
    o.append(tx(90, 770, "安全帽", 18, INK, "start", weight="bold") + tx(90, 795, "徽章 2 ／ 14", 15, SOFT, "start"))
    o.append(rect(284, 740, 92, 70, 20, LGREY))
    o.append(stroke("M322,772 V764 A8,8 0 0 1 338,764 V772", GREY, 4) + flat('<rect x="317" y="771" width="26" height="20" rx="4"/>', GREY))
    o.append(tx(330, 806, "家長", 13, GREY))
    return page("".join(o))


def screen_cross():
    o = [flat(f'<rect width="{W}" height="{H}"/>', PAGE)]
    o.append(top_bar("過馬路五步", BLU))
    o.append(cross_scene(10, 104, 370, 269, hero_pose="stand", look=-5, finger_at=True))
    o.append(finger(230, 330, .75))
    o.append(burst(98, 160, 40, 24, "停～", 15, YEL))
    o.append(tx(195, 408, "第三步：慢慢探頭，看看有沒有車", 18, INK))
    labels = ["集", "轉", "探", "避", "揮"]
    states = ["done", "done", "now", "later", "later"]
    x0, bw, gap = 20, 62, 10
    for i, (lb, st) in enumerate(zip(labels, states)):
        o.append(step_chip(x0 + i * (bw + gap), 430, bw, 86, lb, st, BLU))
    plain = ["停在路邊", "左看右看", "慢慢探頭", "讓車先過", "揮揮手"]
    for i, s in enumerate(plain):
        o.append(tx(x0 + i * (bw + gap) + bw / 2, 540, s, 12, SOFT))
    o.append(rect(20, 566, 350, 100, 18, WHT))
    o.append(tx(40, 598, "小綠人在走，可以過。", 18, INK, "start"))
    o.append(tx(40, 628, "小綠人跑很快的時候，就等下一次。", 15, SOFT, "start"))
    o.append(flat('<rect x="326" y="582" width="30" height="66" rx="6"/>', BLK) + flat('<circle cx="341" cy="600" r="7"/>', "#30363B") + flat('<circle cx="341" cy="630" r="7"/>', GRN))
    o.append(bubble("dog", ["慢慢探頭，", "看看有沒有車來"], BLU))
    return page("".join(o))


def room_wobble(x, y, w, h, tilt=1.6):
    """A living room that wobbles gently: the lamp swings, a book slides, nothing falls."""
    o = [f'<g transform="rotate({tilt} {x + w / 2} {y + h / 2})">']
    o.append(rect(x, y, w, h, 14, "#FBF1DC"))
    o.append(rect(x, y + h - 70, w, 70, 0, "#E6C79A"))
    o.append(rect(x + 26, y + 30, 90, 76, 8, "#BFE0F5") + stroke(f"M{x + 71},{y + 30} V{y + 106} M{x + 26},{y + 68} H{x + 116}", WHT, 5))
    o.append(rect(x + w - 112, y + 22, 84, 150, 8, "#C8955E"))
    for r in range(3):
        o.append(flat(f'<rect x="{x + w - 104}" y="{y + 32 + r * 46}" width="68" height="6" rx="2"/>', "#8A5A2E"))
        for c, col in enumerate((RED, BLU, GRN, YEL)):
            o.append(flat(f'<rect x="{x + w - 102 + c * 16}" y="{y + 40 + r * 46}" width="12" height="28" rx="2" transform="rotate({(-6 if (r + c) % 2 else 4)} {x + w - 96 + c * 16} {y + 54 + r * 46})"/>', col))
    o.append(line(f"M{x + w / 2 + 10},{y} L{x + w / 2 + 24},{y + 56}", GREY, 3))
    o.append(path(f"M{x + w / 2 + 4},{y + 56} L{x + w / 2 + 44},{y + 56} L{x + w / 2 + 52},{y + 84} H{x + w / 2 - 4}Z", YEL))
    return "".join(o) + "</g>"


def screen_quake():
    o = [flat(f'<rect width="{W}" height="{H}"/>', PAGE)]
    o.append(top_bar("地震：趴、掩、穩", RED))
    o.append(room_wobble(14, 108, 362, 380))
    o.append(glow(150, 378, 110))
    o.append(table(150, 352, 1.2))
    o.append(stroke("M22,150 q-6,10 0,20 M30,142 q-8,18 0,36 M368,150 q6,10 0,20 M360,142 q8,18 0,36", COMIC, 2.6))
    o.append(burst(296, 322, 44, 24, "晃晃～", 14, WHT))
    o.append(arrow("M300,440 Q240,470 180,448", BLK, 5))
    o.append(place(302, 470, .95, hero(pose="crouch")))
    o.append(finger(318, 470, .7))
    o.append(tx(195, 523, "把小隊員拖到桌子下面", 18, INK))
    for i, (lb, st, sub) in enumerate((("趴", "now", "躲桌下"), ("掩", "later", "蓋住頭"), ("穩", "later", "抓桌腳"))):
        x = 36 + i * 112
        o.append(step_chip(x, 548, 94, 86, lb, st, RED))
        o.append(tx(x + 47, 656, sub, 13, SOFT))
    o.append(bubble("cat", ["地震！不要跑，", "先趴到桌子下面"], RED))
    return page("".join(o))


def key(x, y, w, h, label, state, col=RED):
    o = []
    if state == "done":
        o.append(rect(x, y, w, h, 20, darker(col, .15)))
        o.append(tx(x + w / 2, y + h / 2 + 22, label, 64, WHT, weight="bold"))
        o.append(check(x + w - 22, y + 22, 1.0))
    elif state == "now":
        o.append(glow(x + w / 2, y + h / 2, w / 2 + 6))
        o.append(rect(x, y, w, h, 20, WHT))
        o.append(tx(x + w / 2, y + h / 2 + 22, label, 64, col, weight="bold"))
    else:
        o.append(rect(x, y, w, h, 20, WHT))
        o.append(tx(x + w / 2, y + h / 2 + 22, label, 64, LGREY, weight="bold"))
    return "".join(o)


def screen_fire():
    o = [flat(f'<rect width="{W}" height="{H}"/>', PAGE)]
    o.append(top_bar("到外面，打 119", RED))
    o.append(rect(14, 108, 362, 230, 14, SKY))
    o.append(rect(14, 290, 362, 48, 0, "#A9D9B5"))
    o.append(rect(40, 150, 150, 150, 10, "#F2D7B0") + path("M30,156 L115,100 L200,156Z", RED))
    o.append(rect(100, 230, 34, 70, 4, "#8A5A2E") + flat('<rect x="60" y="180" width="30" height="30" rx="4"/>', "#CFE7F7") + flat('<rect x="140" y="180" width="30" height="30" rx="4"/>', "#9AA3AB"))
    for cx, cy, r in ((160, 162, 16), (178, 146, 20), (200, 134, 16), (214, 150, 12)):
        o.append(flat(f'<circle cx="{cx}" cy="{cy}" r="{r}"/>', "#C9D1D8", .9))
    o.append(place(258, 304, .78, cat_fire()))
    o.append(place(322, 306, .82, hero(pose="hold")))
    o.append(rect(322, 222, 20, 32, 6, BLK) + hi(326, 226, 4, 20, .5))
    o.append(stroke("M348,214 q6,6 0,12 M354,206 q12,12 0,24", BLK, 2.4))
    o.append(burst(300, 140, 44, 26, "嘟嘟～", 14, YEL))
    o.append(tx(195, 372, "照順序按：1、1、9", 18, INK))
    o.append(rect(30, 390, 330, 60, 16, BLK))
    o.append(tx(70, 432, "1", 36, GRN, weight="bold") + tx(130, 432, "1", 36, GRN, weight="bold") + tx(190, 432, "_", 36, GREY, weight="bold"))
    for i, (lb, st) in enumerate((("1", "done"), ("1", "done"), ("9", "now"))):
        o.append(key(24 + i * 118, 468, 106, 120, lb, st))
    o.append(tx(195, 630, "119 是消防隊，會來幫忙", 15, SOFT))
    o.append(bubble("cat", ["到外面了，", "拿電話按 1、1、9"], RED))
    return page("".join(o))


def light_dot(cx, cy, col, r=15):
    return circ(cx, cy, r, col) + f'<circle cx="{cx}" cy="{cy}" r="{r + 3}" fill="none" stroke="{WHT}" stroke-width="3"/>' + hi(cx - r * .5, cy - r * .6, r * .4, r * .4)


def screen_body():
    o = [flat(f'<rect width="{W}" height="{H}"/>', PAGE)]
    o.append(top_bar("身體紅綠燈", GRN))
    o.append(rect(14, 108, 362, 520, 20, WHT))
    o.append(rect(26, 120, 150, 36, 18, "#FFF0C2") + tx(101, 144, "和爸媽一起玩", 15, "#9A6A00"))
    cx, base = 150, 540
    s = 2.3
    o.append(place(cx, base, s, hero(pose="arms_out", swimsuit=True)))
    hy = base - 86 * s
    # spots: green on hands, head, shoulders; yellow on face/tummy; red on the swimsuit
    o.append(light_dot(cx - 45 * s, base - 49 * s, GRN) + light_dot(cx + 45 * s, base - 49 * s, GRN))
    o.append(light_dot(cx, hy - 26 * s, GRN))
    o.append(light_dot(cx - 22 * s, base - 62 * s, GRN) + light_dot(cx + 22 * s, base - 62 * s, GRN))
    o.append(light_dot(cx + 17 * s, hy + 11 * s, YEL) + light_dot(cx, base - 36 * s, YEL))
    o.append(light_dot(cx, base - 54 * s, RED) + light_dot(cx, base - 24 * s, RED))
    o.append(glow(cx - 45 * s, base - 49 * s, 26))
    o.append(finger(cx - 45 * s + 10, base - 49 * s + 30, .7))
    # legend
    lx = 296
    o.append(rect(lx - 26, 176, 94, 196, 16, "#F3F6F8"))
    for i, (col, a, b) in enumerate(((GRN, "綠燈", "可以"), (YEL, "黃燈", "先問我"), (RED, "紅燈", "不可以"))):
        y = 206 + i * 60
        o.append(light_dot(lx, y, col, 13))
        o.append(tx(lx + 20, y - 2, a, 14, INK, "start", weight="bold") + tx(lx + 20, y + 15, b, 12, SOFT, "start"))
    o.append(rect(26, 548, 338, 72, 16, lighter(GRN, .8)))
    o.append(tx(44, 578, "綠燈：握手、擊掌都可以", 17, darker(GRN, .3), "start", weight="bold"))
    o.append(tx(44, 604, "泳衣遮住的地方是紅燈，是你自己的", 14, SOFT, "start"))
    o.append(rect(14, 640, 362, 36, 12, "#F3F6F8") + tx(195, 664, "點點看身體的每個地方，聽兔兔說", 14, SOFT))
    o.append(bubble("bunny", ["泳衣遮住的地方", "是你自己的"], GRN))
    return page("".join(o))


def kitchen(x, y, w, h):
    o = [rect(x, y, w, h, 14, "#FFF6E3")]
    o.append(rect(x, y + h - 110, w, 110, 0, "#F0DDBE"))
    # cupboards and counter
    o.append(rect(x + 16, y + 20, 150, 60, 6, "#9FD0C8") + rect(x + 190, y + 20, 150, 60, 6, "#9FD0C8"))
    o.append(stroke(f"M{x + 91},{y + 24} V{y + 76} M{x + 265},{y + 24} V{y + 76}", WHT, 3))
    o.append(rect(x + 12, y + 160, w - 24, 22, 6, LGREY))
    o.append(rect(x + 12, y + 180, w - 24, 90, 4, "#B9D7E6"))
    for i in range(4):
        o.append(flat(f'<rect x="{x + 22 + i * 86}" y="{y + 190}" width="74" height="70" rx="4"/>', "#D4E8F1"))
    # stove with the pot, handle sticking out (the danger being fixed)
    o.append(rect(x + 40, y + 134, 110, 28, 8, "#3A4046"))
    o.append(circ(x + 70, y + 148, 12, "#5A6168") + circ(x + 120, y + 148, 12, "#5A6168"))
    o.append(rect(x + 44, y + 104, 54, 34, 8, "#C94A3F"))
    o.append(rect(x + 40, y + 100, 62, 8, 4, "#A43A31"))
    o.append(line(f"M{x + 98},{y + 112} L{x + 138},{y + 100}", "#A43A31", 9))
    o.append(hi(x + 50, y + 112, 10, 16))
    # socket with a cord in reach
    o.append(rect(x + 300, y + 112, 34, 34, 6, WHT) + flat(f'<rect x="{x + 310}" y="{y + 122}" width="4" height="10" rx="1"/>', BLK) + flat(f'<rect x="{x + 320}" y="{y + 122}" width="4" height="10" rx="1"/>', BLK))
    # knife on the table edge
    o.append(path(f"M{x + 170},{y + 150} L{x + 226},{y + 142} L{x + 228},{y + 150}Z", LGREY) + rect(x + 226, y + 141, 26, 10, 4, BLK))
    # medicine bottle on the counter
    o.append(rect(x + 262, y + 128, 22, 32, 5, "#FFB13B") + rect(x + 262, y + 122, 22, 10, 4, WHT) + flat(f'<circle cx="{x + 273}" cy="{y + 146}" r="5"/>', WHT))
    # a plastic bag on the floor
    o.append(path(f"M{x + 230},{y + h - 20} Q{x + 236},{y + h - 70} {x + 270},{y + h - 62} Q{x + 300},{y + h - 50} {x + 292},{y + h - 16}Z", "#EAF0F3"))
    return "".join(o)


def screen_kitchen():
    o = [flat(f'<rect width="{W}" height="{H}"/>', PAGE)]
    o.append(top_bar("廚房：找找看", "#E9B800"))
    o.append(kitchen(14, 108, 362, 300))
    # the pot handle glows and a finger turns it in
    o.append(glow(14 + 118, 108 + 108, 34))
    o.append(stroke("M156,196 A34,34 0 0 1 122,176", BLK, 4, dash="1 8"))
    o.append(flat('<path d="M116,170 L130,172 L120,184Z"/>', BLK))
    o.append(finger(150, 232, .7))
    # found marks on the knife and the socket
    o.append(burst(118, 330, 50, 26, "找到了！", 14, YEL))
    for cx, cy in ((14 + 240, 108 + 130), (14 + 317, 108 + 100)):
        o.append(flat(f'<circle cx="{cx}" cy="{cy}" r="14"/>', GRN) + check(cx, cy, .8))
    o.append(tx(195, 440, "把手轉進去，才不會撞到", 18, INK))
    o.append(rect(20, 460, 350, 110, 18, WHT))
    o.append(tx(40, 490, "找到 2 ／ 4", 18, INK, "start", weight="bold"))
    items = [("菜刀", True), ("插座", True), ("鍋子", False), ("藥罐", False)]
    for i, (n, done) in enumerate(items):
        x = 40 + i * 82
        o.append(rect(x, 504, 68, 50, 12, GRN if done else "#F3F6F8"))
        if done:
            o.append(check(x + 34, 522, .9))
            o.append(tx(x + 34, 548, n, 12, WHT))
        else:
            o.append(f'<rect x="{x}" y="504" width="68" height="50" rx="12" fill="none" stroke="{LGREY}" stroke-width="3"/>')
            o.append(tx(x + 34, 534, n, 14, GREY))
    o.append(rect(20, 586, 350, 84, 18, "#FFF0C2"))
    o.append(tx(40, 616, "問問爸爸媽媽：", 15, "#9A6A00", "start", weight="bold"))
    o.append(tx(40, 646, "我們家的鍋子把手，都朝哪裡？", 16, INK, "start"))
    o.append(bubble("bunny", ["鍋子的把手轉進去，", "才不會被撞到"], "#E9B800"))
    return page("".join(o))


def toggle(x, y, on):
    return (rect(x, y, 46, 24, 12, GRN if on else LGREY) + flat(f'<circle cx="{x + (34 if on else 12)}" cy="{y + 12}" r="9"/>', WHT))


def section(y, h, title=None):
    o = [rect(14, y, 362, h, 18, WHT)]
    if title:
        o.append(tx(32, y + 30, title, 17, INK, "start", weight="bold"))
    return "".join(o)


def row(y, label, value, col=INK):
    return tx(32, y, label, 15, SOFT, "start") + tx(358, y, value, 15, col, "end", weight="bold")


def screen_parents():
    o = [flat(f'<rect width="{W}" height="{H}"/>', PAGE)]
    o.append(top_bar("家長模式", GREY))
    o.append(section(104, 146, "小隊員"))
    o.append(row(164, "名字", "小明") + row(192, "年齡", "3～4 歲（小小）") + row(220, "每次玩多久", "15 分鐘"))
    o.append(stroke("M32,176 H358 M32,204 H358", "#EEF1F3", 1.5))
    o.append(section(262, 140, "走失的時候要說的"))
    o.append(tx(32, 318, "爸媽的電話（只存在手機裡）", 13, SOFT, "start"))
    o.append(rect(32, 330, 326, 44, 12, "#F3F6F8") + tx(48, 360, "0912-345-678", 22, INK, "start", weight="bold"))
    o.append(tx(32, 394, "小朋友叫你「媽媽」，練習背這個號碼（不存地址）", 12, SOFT, "start"))
    o.append(section(414, 104, "安全大人（不舒服的事可以跟誰說）"))
    for i, (n, col, on) in enumerate((("媽媽", GRN, True), ("爸爸", GRN, True), ("阿嬤", GRN, True), ("老師", LGREY, False), ("＋", LGREY, False))):
        x = 32 + i * 66
        o.append(rect(x, 460, 56, 44, 14, col if on else "#F3F6F8"))
        o.append(tx(x + 28, 489, n, 16, WHT if on else GREY, weight="bold"))
    o.append(section(530, 164, "要開哪些世界"))
    for i, (n, on, note) in enumerate((("馬路世界", True, ""), ("救災世界", True, ""), ("身體世界", True, "可以關掉，第一次會先給你看說明"), ("家裡世界", True, ""))):
        y = 582 + i * 28
        o.append(tx(32, y + 6, n, 15, INK, "start"))
        if note:
            o.append(tx(112, y + 6, note, 11, SOFT, "start"))
        o.append(toggle(312, y - 10, on))
    o.append(section(704, 128, "真實生活清單（打勾就給金徽章）"))
    for i, (n, done) in enumerate((("在真的路口做過五步", True), ("家裡演練過一次地震", False), ("看過家裡的插座蓋", False))):
        y = 760 + i * 26
        o.append(rect(32, y - 12, 22, 22, 6, GRN if done else "#F3F6F8") + (check(43, y - 1, .6) if done else f'<rect x="32" y="{y - 12}" width="22" height="22" rx="6" fill="none" stroke="{LGREY}" stroke-width="2"/>'))
        o.append(tx(66, y + 4, n, 14, INK, "start"))
    return page("".join(o))


# ================================================================ STYLE PAGE, CONTACT SHEET, MAIN
def style_sheet():
    global STYLE
    ph = 1210
    o = [flat(f'<rect width="{W}" height="{ph}"/>', "#F4F6F8")]
    o.append(tx(195, 56, "畫風：決定用 C", 30, INK, weight="bold"))
    o.append(tx(195, 86, "同一個路口，三種畫法（2026-11-15 決定）", 16, SOFT))
    bands = [("A 瓦楞紙箱手作風", "像幼兒園的勞作：紙箱剪下來塗顏色，貼上白紙眼睛。", "card"),
             ("B 絨毛布偶風", "像絨毛玩偶：毛毛的邊、鈕扣眼睛，軟軟的、胖胖的。", "plush"),
             ("C 漫畫網點風（決定）", "像漫畫書：平塗、深藍細線、網點陰影、速度線。", "comic")]
    y = 110
    for title, desc, st in bands:
        h = 344
        if st == "comic":
            o.append(f'<rect x="12" y="{y - 4}" width="366" height="{h + 8}" rx="28" fill="{GRN}"/>')
            o.append(f'<rect x="16" y="{y}" width="358" height="{h}" rx="24" fill="#FFFFFF"/>')
            o.append(f'<rect x="262" y="{y - 14}" width="100" height="30" rx="15" fill="{GRN}"/>' + tx(312, y + 7, "決定用這個", 14, WHT, weight="bold"))
        else:
            o.append(f'<rect x="16" y="{y + 4}" width="358" height="{h}" rx="24" fill="#DDE3E8"/><rect x="16" y="{y}" width="358" height="{h}" rx="24" fill="#FFFFFF"/>')
        o.append(tx(34, y + 40, title, 22, INK, "start", weight="bold"))
        o.append(tx(34, y + 66, desc, 13, SOFT, "start"))
        STYLE = st
        px, py = 30, y + 86
        if st == "card":          # the scene sits on a sheet of raw corrugated cardboard
            D.add("flute", f'<pattern id="flute" width="6" height="6" patternUnits="userSpaceOnUse"><rect width="6" height="6" fill="{KRAFT}"/><rect width="6" height="2.4" fill="{darker(KRAFT, .14)}"/></pattern>')
            o.append(f'<rect x="{px - 6}" y="{py - 6}" width="342" height="252" rx="16" fill="url(#flute)"/>')
        elif st == "plush":
            o.append(f'<rect x="{px - 6}" y="{py - 6}" width="342" height="252" rx="16" fill="#F4E3E8"/>')
        elif st == "comic":
            o.append(f'<rect x="{px - 6}" y="{py - 6}" width="342" height="252" rx="6" fill="{COMIC}"/>')
        o.append(cross_scene(px, py, 330, 240))
        STYLE = "comic"
        y += h + 22
    return page("".join(o), "#F4F6F8", W, ph), ph


def contact_sheet(names):
    cw_, ch_, gap, m = 232, 502, 24, 30
    per = 4
    rows = (len(names) + per - 1) // per
    w = per * cw_ + (per - 1) * gap + 2 * m
    rowh = ch_ + 64
    h = rows * rowh + 40
    items = []
    for i, n in enumerate(names):
        r, c = divmod(i, per)
        k = min(per, len(names) - r * per)
        x = m + c * (cw_ + gap) + (per - k) * (cw_ + gap) / 2
        y = 28 + r * rowh
        items.append(f'<div style="position:absolute;left:{x}px;top:{y}px;width:{cw_}px;text-align:center">'
                     f'<img src="file://{HERE / (n + ".png")}" style="width:{cw_}px;height:{ch_}px;border-radius:18px;box-shadow:0 6px 16px rgba(40,50,60,.2)">'
                     f'<div style="font:19px Huninn, sans-serif;color:{INK};margin-top:10px">{n.replace("_", " ")}</div></div>')
    css = f"@font-face {{ font-family: Huninn; src: url('file://{FONT}'); }} * {{ margin:0; padding:0 }} body {{ width:{w}px; height:{h}px; background:#F4F6F8; position:relative }}"
    return f'<!doctype html><html><head><meta charset="utf-8"><style>{css}</style></head><body>{"".join(items)}</body></html>', w, h


SCREENS = {"1_小隊基地": screen_home, "2_過馬路": screen_cross, "3_地震躲桌下": screen_quake, "4_火災打119": screen_fire,
           "5_身體紅綠燈": screen_body, "6_家裡找危險": screen_kitchen, "7_家長模式": screen_parents}


def main(only=None):
    global D
    if only in (None, "0"):
        D = Defs()
        html, ph = style_sheet()
        render(html, HERE / "0_畫風選擇.png", W, ph, 2)
        print("0_畫風選擇")
    for name, make in SCREENS.items():
        if only not in (None, name.split("_")[0]):
            continue
        D = Defs()
        render(make(), HERE / f"{name}.png", W, H, 2)
        print(name)
    if only in (None, "c"):
        html, w, h = contact_sheet(list(SCREENS))
        render(html, HERE / "contact_sheet.png", w, h, 1.25)
        print("contact_sheet")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
