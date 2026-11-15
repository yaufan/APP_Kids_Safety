"""Writes the pictures of 安全小隊 (kit.py: 漫畫網點風, real halftone dots clipped to each shape) and checks them.

    python3 build.py all                    # every module below, then check
    python3 build.py house                  # one module (its build())
    python3 build.py check                  # flutter_svg's rules on every SVG under app/assets/art
    python3 build.py sheet OUT.png [dir]    # a contact sheet of the files (all, or one folder: house,
                                            # calm, icons, stories), drawn by Chromium
    python3 build.py fluttercheck [dir]     # draw every file with the real flutter_svg (a throw-away
                                            # Flutter project in /dev/shm, deleted afterwards) and with
                                            # Chromium, and compare them

THE REGISTRY: MODULES lists the picture modules; each defines build().

Needs: Python 3, Node.js with Playwright (Chromium) for sheet and fluttercheck, numpy + Pillow for
fluttercheck, Flutter at /home/user/flutter/bin (or $FLUTTER). Never run git from here.
"""
import sys

sys.dont_write_bytecode = True      # no __pycache__ in design/art

import html  # noqa: E402
import importlib  # noqa: E402
import os  # noqa: E402
import pathlib  # noqa: E402
import shutil  # noqa: E402
import subprocess  # noqa: E402
import tempfile  # noqa: E402

import kit  # noqa: E402

HERE = pathlib.Path(__file__).resolve().parent
SCRATCH = pathlib.Path("/dev/shm") if pathlib.Path("/dev/shm").is_dir() else pathlib.Path(tempfile.gettempdir())
MODULES = ("hero", "helpers", "road", "rescue", "body", "home", "badges", "ui", "icon")


def check_all():
    n = 0
    for p in sorted(kit.ART.rglob("*.svg")):
        kit.check_svg(str(p.relative_to(kit.ROOT)), p.read_text())
        n += 1
    print(f"check: {n} SVG files are fine")


def _files(which):
    if "," in which:
        return [f for w in which.split(",") for f in _files(w)]
    if which == "all":
        return sorted(kit.ART.rglob("*.svg"))
    if "*" in which:
        return sorted(kit.ART.glob(which + ("" if which.endswith(".svg") else ".svg")))
    d = kit.ART / which
    if d.is_dir():
        return sorted(d.rglob("*.svg"))
    raise SystemExit(f"nothing to show for {which!r}")


def sheet(out, which="all", cell=170):
    files = _files(which)
    cells = "".join(
        f'<div style="display:inline-block;width:{cell}px;margin:4px;vertical-align:top;text-align:center;font:12px sans-serif;color:#1E3A6E">'
        f'<div style="width:{cell}px;height:{cell}px;display:flex;align-items:center;justify-content:center;background:#F4F7FB;border-radius:12px">'
        f'<img style="max-width:{cell - 10}px;max-height:{cell - 10}px" src="file://{f}"></div>{html.escape(f.stem)}</div>'
        for f in files)
    per_row = 6
    rows = (len(files) + per_row - 1) // per_row
    width = per_row * (cell + 8) + 20
    page = f'<html><body style="margin:10px;background:#DDE6F0;width:{width - 20}px">{cells}</body></html>'
    with tempfile.TemporaryDirectory(dir=SCRATCH) as tmp:
        p = pathlib.Path(tmp) / "sheet.html"
        p.write_text(page)
        subprocess.run(["node", str(kit.ROOT / "docs" / "mockups" / "render.js"), str(p), str(out), str(width), str(rows * (cell + 26) + 24), "1"], check=True)
    print(out)


# ---------------------------------------------------------------- flutter_svg against Chromium
DART_TEST = r"""
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('render svgs', (tester) async {
    final lines = File('list.txt').readAsLinesSync().where((l) => l.trim().isNotEmpty);
    final failed = <String>[];
    for (final line in lines) {
      final p = line.split('|');
      final w = int.parse(p[2]), h = int.parse(p[3]);
      await tester.runAsync(() async {
        try {
          final info = await vg.loadPicture(SvgStringLoader(File(p[0]).readAsStringSync()), null);
          final rec = ui.PictureRecorder();
          final c = Canvas(rec);
          c.scale(w / info.size.width, h / info.size.height);
          c.drawPicture(info.picture);
          final img = await rec.endRecording().toImage(w, h);
          final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
          File(p[1]).writeAsBytesSync(bytes!.buffer.asUint8List());
          info.picture.dispose();
        } catch (e) {
          failed.add('${p[0]}: $e');
        }
      });
    }
    File('failed.txt').writeAsStringSync(failed.join('\n'));
  });
}
"""

CHROME_JS = r"""
const { chromium } = require('playwright');
const fs = require('fs');
(async () => {
  const lines = fs.readFileSync(process.argv[2], 'utf8').split('\n').filter(l => l.trim());
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 400, height: 400 }, deviceScaleFactor: 1 });
  for (const line of lines) {
    const [inp, out, w, h] = line.split('|');
    const svg = fs.readFileSync(inp);
    await page.setViewportSize({ width: +w, height: +h });
    await page.setContent(`<html><body style="margin:0;background:transparent"><img style="display:block;width:${w}px;height:${h}px" src="data:image/svg+xml;base64,${svg.toString('base64')}"></body></html>`);
    await page.waitForFunction(() => document.images[0].complete);
    await page.screenshot({ path: out, omitBackground: true });
  }
  await browser.close();
})();
"""


def fluttercheck(which="all", keep=False, px=300):
    import numpy as np
    from PIL import Image
    files = _files(which)
    flutter = pathlib.Path(os.environ.get("FLUTTER", "/home/user/flutter/bin")) / "flutter"
    work = pathlib.Path(tempfile.mkdtemp(prefix="safety_svgcheck_", dir=SCRATCH))
    try:
        for sub in ("lib", "test", "out", "src"):
            (work / sub).mkdir()
        (work / "pubspec.yaml").write_text("name: svgcheck\npublish_to: 'none'\nversion: 0.0.1\nenvironment:\n  sdk: ^3.13.7\n"
                                           "dependencies:\n  flutter:\n    sdk: flutter\n  flutter_svg: ^2.3.0\n"
                                           "dev_dependencies:\n  flutter_test:\n    sdk: flutter\n")
        (work / "lib" / "main.dart").write_text("void main() {}\n")
        (work / "test" / "render_test.dart").write_text(DART_TEST)
        (work / "shot.js").write_text(CHROME_JS)
        fl, cr = [], []
        for i, f in enumerate(files):
            src = work / "src" / f"{i}.svg"
            src.write_text(f.read_text())
            vw, vh = kit.viewbox_of(f)
            s = px / max(vw, vh)
            w, h = max(8, round(vw * s)), max(8, round(vh * s))
            fl.append(f"{src}|{work / 'out' / f'{i}_f.png'}|{w}|{h}")
            cr.append(f"{src}|{work / 'out' / f'{i}_c.png'}|{w}|{h}")
        (work / "list.txt").write_text("\n".join(fl))
        (work / "crlist.txt").write_text("\n".join(cr))
        r = subprocess.run([str(flutter), "pub", "get", "--offline"], cwd=work, capture_output=True, text=True)
        if r.returncode:
            print(r.stdout[-2000:], r.stderr[-2000:])
            raise SystemExit("flutter pub get --offline failed")
        r = subprocess.run([str(flutter), "test", "test/render_test.dart"], cwd=work, capture_output=True, text=True)
        if r.returncode:
            print(r.stdout[-3000:], r.stderr[-3000:])
            raise SystemExit("flutter test failed")
        failed = (work / "failed.txt").read_text().strip()
        if failed:
            print("flutter_svg could not draw:\n" + failed)
        subprocess.run(["node", str(work / "shot.js"), str(work / "crlist.txt")], cwd=work, check=True, env={**os.environ})
        rows = []
        for i, f in enumerate(files):
            a, b = work / "out" / f"{i}_f.png", work / "out" / f"{i}_c.png"
            if not a.exists():
                rows.append((1.0, 1.0, f))
                continue
            A = np.asarray(Image.open(a).convert("RGBA")).astype(float)
            B = np.asarray(Image.open(b).convert("RGBA")).astype(float)

            def flat(X):
                al = X[..., 3:4] / 255
                return X[..., :3] * al + 255 * (1 - al)
            D = np.abs(flat(A) - flat(B)).max(axis=2)
            big = D > 60
            core = big[1:-1, 1:-1] & big[:-2, 1:-1] & big[2:, 1:-1] & big[1:-1, :-2] & big[1:-1, 2:]
            rows.append((core.mean(), D.mean() / 255, f))
        rows.sort(key=lambda r: (-r[0], -r[1]))
        bad = [r for r in rows if r[0] > .004]
        print(f"fluttercheck: {len(files)} files; worst:")
        for frac, mean, f in rows[:6]:
            print(f"  {frac * 100:6.2f}% solid differences, mean {mean * 100:.2f}%  {f.relative_to(kit.ROOT)}")
        if keep:
            print("kept", work)
        if bad or failed:
            raise SystemExit(f"{len(bad)} files draw differently in flutter_svg")
        print("fluttercheck: flutter_svg draws every file like Chromium")
    finally:
        if not keep:
            shutil.rmtree(work, ignore_errors=True)


def main(argv):
    if not argv:
        print(__doc__)
        return
    cmd, rest = argv[0], argv[1:]
    if cmd == "all":
        for m in MODULES:
            importlib.import_module(m).build()
        check_all()
    elif cmd == "check":
        check_all()
    elif cmd == "sheet":
        sheet(rest[0], rest[1] if len(rest) > 1 else "all")
    elif cmd == "fluttercheck":
        fluttercheck(rest[0] if rest and not rest[0].startswith("--") else "all", keep="--keep" in rest)
    elif cmd in MODULES:
        importlib.import_module(cmd).build()
    else:
        raise SystemExit(f"unknown: {cmd} (modules: {', '.join(MODULES)})")


if __name__ == "__main__":
    main(sys.argv[1:])
