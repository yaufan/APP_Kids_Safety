"""安全小隊's app icon, in the comic halftone look of the rest of the art (kit.py): the squad member's
face in the yellow helmet, big, on a blue road-sign circle with a white comic burst behind it.

    python3 icon.py preview OUT.png      # the icon big (512), as a phone cuts it (round, rounded square)
                                         # at 96 and 48 px, and at 48 px on a light and a dark home screen
                                         # next to the sibling apps' icons
    python3 icon.py export               # writes the Android and iOS icons into app/

export writes (the same files as the sibling apps' icon.py)
- Android, full square art: app/android/app/src/main/res/mipmap-{mdpi..xxxhdpi}/ic_launcher.png.
- Android adaptive icon (API 26+): mipmap-anydpi-v26/ic_launcher.xml, with
  drawable-{mdpi..xxxhdpi}/ic_launcher_foreground.png and ic_launcher_background.png (108 dp canvas;
  the subject stays inside the central 66 dp circle).
- iOS: every PNG listed in app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json, opaque.

Drawn in 200 x 200 units with kit.Pic, rendered at 1024 px by Chromium (Node.js with Playwright) and scaled
down with Pillow. `python3 build.py icon` writes the same two layers as SVG for the contact sheet.
"""
import sys

sys.dont_write_bytecode = True      # no __pycache__ in design/art

import json  # noqa: E402
import math  # noqa: E402
import pathlib  # noqa: E402
import subprocess  # noqa: E402
import tempfile  # noqa: E402

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

import hero  # noqa: E402
import kit  # noqa: E402

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
APP = ROOT / "app"
RES = APP / "android" / "app" / "src" / "main" / "res"
IOS = APP / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
FONT = APP / "assets" / "fonts" / "jf-openhuninn-2.1.ttf"

U = 200                              # drawing units across the icon
C = 1024                             # rendered size, scaled down from here
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
VIEW = 72 / 108                      # how much of the adaptive canvas a launcher shows
SAFE_R = .44 * U                     # the subject stays within this radius of the middle
HS = 2.55                            # the head's scale (radius 21 units at 1)
HX, HY = 100, 112


# ================================================================ the picture
def background(view):
    p = kit.Pic(U, U, 120, zoom=view)
    p.shape(kit.rect(-200, -200, 600, 600), "#FFC400", dots=False, outline=False, hl=False)
    for i in range(16):
        a0, a1 = math.radians(i * 22.5), math.radians(i * 22.5 + 10)
        p.flat(kit.poly([(100, 100), (100 + 400 * math.cos(a0), 100 + 400 * math.sin(a0)), (100 + 400 * math.cos(a1), 100 + 400 * math.sin(a1))]), "#FFD54A")
    p.shape(kit.circle(100, 100, 80), kit.BLU, sparse=1.3)
    return p


def subject(view):
    p = kit.Pic(U, U, 120, zoom=view)
    hero.head(p, HX, HY, 0, HS)
    return p


def check_safe():
    far = [(HX - 28 * HS, HY - 6 * HS), (HX + 28 * HS, HY - 6 * HS), (HX, HY - 31 * HS), (HX, HY + 21 * HS)]
    worst = max(math.hypot(x - U / 2, y - U / 2) for x, y in far)
    if worst > SAFE_R * 1.02:
        sys.exit(f"icon: the subject reaches {worst:.1f} units from the middle (keep within {SAFE_R:.1f})")


def doc(p, px):
    text = p.svg()
    return text.replace(f'width="{U}" height="{U}"', f'width="{px}" height="{px}"', 1)


def subject_svg(adaptive):
    return doc(subject(VIEW if adaptive else 1.0), C)


def background_svg(adaptive):
    return doc(background(VIEW if adaptive else 1.0), C)


def build():
    """The two layers as SVG (for the contact sheets only; the app does not use them)."""
    print("icon: the app icon is exported with `python3 icon.py export`")


# ================================================================ rendering
RENDER_JS = """
const { chromium } = require('playwright');
const fs = require('fs');
(async () => {
  const jobs = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  const browser = await chromium.launch();
  for (const [inp, out, px] of jobs) {
    for (let tries = 1; ; tries++) {          // a screenshot now and then fails while the machine is busy
      const page = await browser.newPage({ viewport: { width: px, height: px }, deviceScaleFactor: 1 });
      try {
        await page.goto('file://' + inp);
        await page.screenshot({ path: out, omitBackground: true });
        break;
      } catch (e) {
        if (tries >= 3) throw e;
      } finally {
        await page.close();
      }
    }
  }
  await browser.close();
})();
"""


def render_all(svgs):
    """{key: svg text} -> {key: RGBA image}, all drawn by one Chromium."""
    shm = "/dev/shm" if pathlib.Path("/dev/shm").is_dir() else None
    with tempfile.TemporaryDirectory(dir=shm, prefix="safety_icon_") as tmp:
        tmp = pathlib.Path(tmp)
        jobs = []
        for i, (key, text) in enumerate(svgs.items()):
            src, out = tmp / f"{i}.svg", tmp / f"{i}.png"
            src.write_text(text)
            jobs.append([str(src), str(out), C])
        (tmp / "jobs.json").write_text(json.dumps(jobs))
        (tmp / "r.js").write_text(RENDER_JS)
        subprocess.run(["node", str(tmp / "r.js"), str(tmp / "jobs.json")], check=True, cwd=HERE)
        return {key: Image.open(tmp / f"{i}.png").convert("RGBA").copy() for i, key in enumerate(svgs)}


def art():
    """(full square art RGB, adaptive background RGB, adaptive foreground RGBA)."""
    check_safe()
    for key, text in (("fg", subject_svg(False)), ("afg", subject_svg(True)), ("bg", background_svg(False)),
                      ("abg", background_svg(True))):
        kit.check_svg(f"icon/{key}", text)
    im = render_all({"bg": background_svg(False), "fg": subject_svg(False),
                     "abg": background_svg(True), "afg": subject_svg(True)})
    full = Image.alpha_composite(im["bg"], im["fg"]).convert("RGB")
    return full, im["abg"].convert("RGB"), im["afg"]


def launcher_view(bg, fg):
    """The adaptive icon as a launcher shows it: both layers, the middle 72 dp of 108."""
    whole = Image.alpha_composite(bg.convert("RGBA"), fg).convert("RGB")
    k = C * 18 / 108
    return whole.crop((round(k), round(k), round(C - k), round(C - k)))


def resized(img, px):
    return img.resize((px, px), Image.LANCZOS)


def mask(kind, px):
    s = px * 4
    m = Image.new("L", (s, s), 0)
    dr = ImageDraw.Draw(m)
    if kind == "round":
        dr.ellipse((0, 0, s - 1, s - 1), fill=255)
    elif kind == "squircle":
        pts = []
        for i in range(720):
            t = 2 * math.pi * i / 720
            c, si = math.cos(t), math.sin(t)
            pts.append((s / 2 + s / 2 * math.copysign(abs(c) ** (2 / 5), c), s / 2 + s / 2 * math.copysign(abs(si) ** (2 / 5), si)))
        dr.polygon(pts, fill=255)
    else:                                       # iOS-like rounded square
        dr.rounded_rectangle((0, 0, s - 1, s - 1), radius=s * .225, fill=255)
    return m.resize((px, px), Image.LANCZOS)


# ================================================================ preview
SIBLINGS = (("畫畫小鎮", "APP_Kids_Paint"), ("字母寵物", "app_kids_paint_for_learning_writing"), ("動物小餐廳", "app_kids_cook"),
            ("小卡認天下", "app_kids_card_game"), ("想一想樂園", "app_kids_brainstorming"), ("眼尖尖", "app_kids_falsecharge"),
            ("迷宮小冒險", "app_kids_maze"), ("小小生活家", "app_kids_live_circ"), ("心情小屋", "app_kids_feelings"), ("晚安小鎮", "app_kids_goodnight"))


def font(size):
    try:
        return ImageFont.truetype(str(FONT), size)
    except OSError:
        return ImageFont.load_default()


def siblings():
    out = []
    for zh, repo in SIBLINGS:
        for base in (ROOT.parent, ROOT.parent.parent):      # the siblings sit next to this repo or one level up
            p = base / repo / "app" / "android" / "app" / "src" / "main" / "res" / "mipmap-xxxhdpi" / "ic_launcher.png"
            if p.is_file():
                out.append((zh, Image.open(p).convert("RGB")))
                break
    return out


def home_screen(icons, dark, W):
    """A strip of a phone's home screen: icons (label, image) at 48 px, round, with their names."""
    H = 104
    top, bottom = ("#3A3550", "#1E1B2B") if dark else ("#F6EFE6", "#E3EEF8")
    strip = Image.new("RGB", (W, H))
    dr = ImageDraw.Draw(strip)
    for y in range(H):
        dr.line([(0, y), (W, y)], fill=kit.mix(top, bottom, y / (H - 1)))
    step = W / len(icons)
    f = font(13)
    for i, (label, im) in enumerate(icons):
        x = round(step * i + step / 2 - 24)
        strip.paste(resized(im, 48), (x, 18), mask("round", 48))
        tw = dr.textlength(label, font=f)
        dr.text((x + 24 - tw / 2, 74), label, font=f, fill="#FFFFFF" if dark else "#1E3A6E")
    return strip


def preview(out):
    full, abg, afg = art()
    view = launcher_view(abg, afg)
    pad, big = 24, 512
    W = pad * 2 + big + 40 + 420
    H = pad + big + pad + 104 * 2 + pad
    sheet = Image.new("RGB", (W, H), "#FFFFFF")
    dr = ImageDraw.Draw(sheet)
    sheet.paste(resized(full, big), (pad, pad))                                  # the full square art, big
    x, y = pad + big + 40, pad
    f = font(22)
    dr.text((x, y), "adaptive (round, squircle), full art: 96 / 48 px", font=f, fill="#1E3A6E")
    y += 40
    for kind, im, s in (("round", view, 96), ("squircle", view, 96), ("square", full, 96)):
        sheet.paste(resized(im, s), (x, y), mask(kind, s))
        x += s + 24
    x, y = pad + big + 40, pad + 40 + 96 + 24
    for kind, im, s in (("round", view, 48), ("squircle", view, 48), ("square", full, 48), ("round", view, 36)):
        sheet.paste(resized(im, s), (x, y + 48 - s), mask(kind, s))
        x += s + 24
    y = pad + big + pad
    icons = siblings() + [("安全小隊", view)]
    sheet.paste(home_screen(icons, False, W - 2 * pad), (pad, y))
    sheet.paste(home_screen(icons, True, W - 2 * pad), (pad, y + 104))
    sheet.save(out)
    print(out)


# ================================================================ export
ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
"""


def export():
    full, bg, fg = art()
    written = []
    for d, k in DENSITIES.items():
        mip = RES / f"mipmap-{d}"
        mip.mkdir(parents=True, exist_ok=True)
        resized(full, round(48 * k)).save(mip / "ic_launcher.png")
        dr = RES / f"drawable-{d}"
        dr.mkdir(parents=True, exist_ok=True)
        resized(fg, round(108 * k)).save(dr / "ic_launcher_foreground.png")
        resized(bg, round(108 * k)).save(dr / "ic_launcher_background.png")
        written += [mip / "ic_launcher.png", dr / "ic_launcher_foreground.png", dr / "ic_launcher_background.png"]
    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(ADAPTIVE_XML)
    written.append(anydpi / "ic_launcher.xml")
    contents = json.loads((IOS / "Contents.json").read_text())
    sizes = {}
    for image in contents["images"]:
        if image.get("filename"):
            px = round(float(image["size"].split("x")[0]) * float(image["scale"].rstrip("x")))
            if sizes.setdefault(image["filename"], px) != px:
                sys.exit(f"{image['filename']} is listed at two sizes in Contents.json")
    for fname, px in sizes.items():
        resized(full, px).convert("RGB").save(IOS / fname)
        written.append(IOS / fname)
    manifest = (APP / "android" / "app" / "src" / "main" / "AndroidManifest.xml").read_text()
    if 'android:icon="@mipmap/ic_launcher"' not in manifest:
        print("note: AndroidManifest.xml's android:icon is not @mipmap/ic_launcher")
    for p in written:
        print(p.relative_to(ROOT))


if __name__ == "__main__":
    if len(sys.argv) >= 2 and sys.argv[1] == "export":
        export()
    elif len(sys.argv) >= 3 and sys.argv[1] == "preview":
        preview(sys.argv[2])
    else:
        print(__doc__)
