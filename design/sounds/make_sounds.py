"""安全小隊 (Safety Squad): every sound in the app, made here from sine waves and noise: nothing
recorded, nothing downloaded, every tune written for this app.

- Music (WAV, 16,000 Hz, seamless loops of 16 to 24 s): a cheerful squad theme for the base, one tune per
  world (馬路 brisk xylophone, 救災 steady and calm, 身體 gentle kalimba, 家裡 a homely piano), and a calm,
  slow one for the rest.
- Short sounds (WAV, 22,050 Hz): Taiwan's crossing chirp (the 「布穀」 of the walking green man), a soft car
  passing, a gentle brake and a friendly beep, 汪汪's whistle, a far-away soft siren and fire bell, a very
  soft earthquake rumble, the seat-belt and helmet clicks, keypad tones 0-9 and the ring of a call, the
  badge chime, right / try-again, and the UI sounds.
- Nothing frightening: sirens are short, soft and far away; the rumble is low and quiet.
- Every random choice uses a fixed seed (from the sound's name), so each run writes the same files.

    python3 design/sounds/make_sounds.py              # writes app/assets/sounds/*.wav
    python3 design/sounds/make_sounds.py tap pop      # only these
    python3 design/sounds/make_sounds.py preview OUT.m4a   # all of them in a row (needs ffmpeg)
"""
import pathlib
import subprocess
import sys
import tempfile
import wave
import zlib

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "app" / "assets" / "sounds"
SR = 22050
LOOP_SR = 16000
LIMIT = 9_000_000       # bytes, the whole folder

NOTE = {f"{n}{o}": 440 * 2 ** ((k - 9) / 12 + o - 4) for o in range(1, 9) for k, n in enumerate("C C# D D# E F F# G G# A A# B".split())}
for _o in range(1, 9):
    for _f, _s in (("Db", "C#"), ("Eb", "D#"), ("Gb", "F#"), ("Ab", "G#"), ("Bb", "A#")):
        NOTE[f"{_f}{_o}"] = NOTE[f"{_s}{_o}"]


# ---------------------------------------------------------------- helpers
def rng(name):
    return np.random.default_rng(zlib.crc32(name.encode()))


def t_of(dur, sr=SR):
    return np.arange(int(dur * sr)) / sr


def env(n, attack=.005, release=.05, sr=SR):
    e = np.ones(n)
    a, r = max(1, min(n, int(attack * sr))), max(1, min(n, int(release * sr)))
    e[:a] = np.linspace(0, 1, a) ** 2
    e[-r:] *= np.linspace(1, 0, r) ** 2
    return e


def decay(n, tau, attack=.004, sr=SR):
    t = np.arange(n) / sr
    e = np.exp(-t / tau)
    a = max(1, int(attack * sr))
    e[:a] *= np.linspace(0, 1, a)
    e[-max(1, int(.01 * sr)):] *= np.linspace(1, 0, max(1, int(.01 * sr)))
    return e


def lowpass(x, cutoff, sr=SR):
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / sr)
    spec *= 1 / (1 + (f / cutoff) ** 4)
    return np.fft.irfft(spec, len(x))


def bandpass(x, lo, hi, sr=SR):
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / sr)
    spec *= 1 / (1 + (lo / np.maximum(f, 1)) ** 4) / (1 + (f / hi) ** 4)
    return np.fft.irfft(spec, len(x))


def noise(name, dur, sr=SR):
    return rng(name).standard_normal(int(dur * sr))


def tone(freq, dur, kind="sine", sr=SR, vib=0.0):
    t = t_of(dur, sr)
    f = freq * (1 + vib * np.sin(2 * np.pi * 5.5 * t)) if vib else freq
    ph = 2 * np.pi * np.cumsum(np.broadcast_to(f, t.shape)) / sr
    if kind == "sine":
        return np.sin(ph)
    if kind == "bell":
        return np.sin(ph) + .35 * np.sin(2.76 * ph) + .18 * np.sin(5.4 * ph)
    if kind == "xylo":
        return np.sin(ph) + .25 * np.sin(4 * ph) + .1 * np.sin(9.9 * ph)
    if kind == "soft_square":
        return np.tanh(2.2 * np.sin(ph)) * .8
    if kind == "kalimba":
        return np.sin(ph) + .2 * np.sin(3.1 * ph)
    if kind == "piano":
        return np.sin(ph) + .45 * np.sin(2 * ph) + .2 * np.sin(3 * ph) + .08 * np.sin(4 * ph)
    if kind == "horn":
        return np.sin(ph) + .5 * np.sin(2 * ph) + .3 * np.sin(3 * ph) + .15 * np.sin(4 * ph)
    raise ValueError(kind)


def sweep(f0, f1, dur, sr=SR, kind="sine"):
    t = t_of(dur, sr)
    f = f0 * (f1 / f0) ** (t / dur)
    ph = 2 * np.pi * np.cumsum(f) / sr
    return np.sin(ph) if kind == "sine" else np.sin(ph) + .3 * np.sin(2 * ph)


def at(total, pieces, sr=SR):
    out = np.zeros(int(total * sr))
    for start, x in pieces:
        i = int(start * sr)
        n = min(len(x), len(out) - i)
        if n > 0:
            out[i:i + n] += x[:n]
    return out


def norm(x, peak=.8):
    m = np.abs(x).max()
    return x * (peak / m) if m > 0 else x


def note(freq, dur, kind="bell", tau=.25, sr=SR):
    n = int(dur * sr)
    return tone(freq, dur, kind, sr) * decay(n, tau, sr=sr)


# ---------------------------------------------------------------- short sounds
def s_tap():
    return norm(note(NOTE["A5"], .09, "sine", .03), .45)


def s_pop():
    x = sweep(500, 1100, .09) * decay(int(.09 * SR), .03)
    return norm(x, .55)


def s_right():
    return norm(at(.5, [(0, note(NOTE["E5"], .3, "bell", .15)), (.11, note(NOTE["A5"], .38, "bell", .18))]), .6)


def s_try():
    # a gentle "hmm?": two soft notes, the second a little lower (not a buzzer)
    return norm(at(.42, [(0, note(NOTE["E5"], .2, "sine", .1)), (.14, note(NOTE["C#5"], .28, "sine", .12))]), .42)


def s_cheer():
    notes = ["C5", "E5", "G5", "C6"]
    return norm(at(.9, [(i * .09, note(NOTE[n], .5, "bell", .22)) for i, n in enumerate(notes)]), .7)


def s_found():
    return norm(at(.55, [(0, note(NOTE["G5"], .25, "xylo", .1)), (.08, note(NOTE["B5"], .25, "xylo", .1)), (.16, note(NOTE["D6"], .35, "xylo", .15))]), .62)


def s_chirp():
    """Taiwan's crossing sound: a little bird's 「布穀、布穀」 when the green man walks."""
    one = lambda: at(.36, [(0, sweep(2350, 1950, .11) * env(int(.11 * SR), .004, .03)), (.15, sweep(1950, 1650, .13) * env(int(.13 * SR), .004, .04))])  # noqa: E731
    return norm(at(1.3, [(0, one()), (.62, one())]), .5)


def s_car_pass():
    n = noise("car_pass", 1.4)
    x = lowpass(n, 380)
    e = np.exp(-((t_of(1.4) - .7) / .32) ** 2)
    hum = np.sin(2 * np.pi * np.cumsum(np.linspace(130, 105, len(e))) / SR) * .3
    return norm((x + hum) * e, .45)


def s_car_hum():
    n = lowpass(noise("car_hum", 1.2), 300)
    hum = np.sin(2 * np.pi * 110 * t_of(1.2)) * .4
    return norm((n + hum) * env(int(1.2 * SR), .25, .35), .35)


def s_brake():
    # a soft, short "psss" (no screech)
    x = bandpass(noise("brake", .5), 1500, 4000) * decay(int(.5 * SR), .15, .02)
    return norm(x, .25)


def s_horn():
    # a friendly little "beep beep"
    b = lambda: tone(NOTE["A4"], .12, "horn") * env(int(.12 * SR), .01, .03)  # noqa: E731
    return norm(lowpass(at(.4, [(0, b()), (.17, b())]), 1800), .4)


def s_steps():
    pieces = []
    for i in range(4):
        x = lowpass(noise(f"step{i}", .07), 700) * decay(int(.07 * SR), .02)
        pieces.append((i * .2, x))
    return norm(at(.9, pieces), .5)


def s_whistle():
    t = t_of(.45)
    f = 2300 * (1 + .03 * np.sign(np.sin(2 * np.pi * 26 * t)))
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) + .25 * bandpass(noise("whistle", .45), 1800, 3000)
    return norm(x * env(len(t), .02, .1), .35)


def s_click():
    x = bandpass(noise("click", .04), 1500, 7000) * decay(int(.04 * SR), .006)
    y = bandpass(noise("click2", .04), 900, 4000) * decay(int(.04 * SR), .008)
    return norm(at(.12, [(0, x), (.035, y)]), .7)


def s_buckle():
    x = bandpass(noise("buckle", .05), 2000, 8000) * decay(int(.05 * SR), .005)
    return norm(at(.2, [(0, x), (.06, x * .8), (.09, note(NOTE["E6"], .1, "sine", .03) * .3)]), .6)


def s_rumble():
    # very soft and low: the earthquake's 「隆隆」 with a few small knocks
    n = lowpass(noise("rumble", 2.0), 90)
    knocks = [(t, bandpass(noise(f"knock{t}", .05), 300, 1200) * decay(int(.05 * SR), .012) * .25) for t in (.4, .9, 1.3)]
    x = n * env(int(2.0 * SR), .5, .7) + at(2.0, knocks)
    return norm(x, .32)


def s_water():
    x = bandpass(noise("water", 1.0), 900, 5000)
    x *= .6 + .4 * np.sin(2 * np.pi * 7 * t_of(1.0)) ** 2
    return norm(x * env(len(x), .08, .3), .35)


def s_window():
    x = lowpass(noise("window", .12), 1500) * decay(int(.12 * SR), .03)
    return norm(at(.3, [(0, sweep(300, 180, .2) * decay(int(.2 * SR), .08) * .5), (.15, x)]), .55)


def s_wind():
    n = noise("wind", 2.2)
    x = bandpass(n, 300, 1400)
    x *= .5 + .5 * np.sin(2 * np.pi * .7 * t_of(2.2)) ** 2
    return norm(x * env(len(x), .5, .7), .3)


def s_switch():
    return norm(at(.25, [(0, bandpass(noise("switch", .03), 1500, 6000) * decay(int(.03 * SR), .006)), (.03, note(NOTE["C6"], .2, "bell", .08) * .5)]), .55)


def s_siren():
    # far away and soft: a short, low "wee-woo" twice, heavily filtered
    t = t_of(1.4)
    f = np.where((t * 2.2) % 1 < .5, 660, 550)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR)
    return norm(lowpass(x, 900) * env(len(t), .2, .4), .22)


def s_bell():
    # a soft fire-station bell, a few rings, far away
    return norm(lowpass(at(1.0, [(i * .14, note(NOTE["G6"], .3, "bell", .08)) for i in range(5)]), 2600), .25)


def s_ring():
    # a phone being answered: two soft rings and a click
    r = lambda: tone(440, .35) * .5 + tone(480, .35) * .5  # noqa: E731
    ring = lambda: r() * env(int(.35 * SR), .02, .05)  # noqa: E731
    return norm(at(1.2, [(0, ring()), (.5, ring()), (1.0, s_click()[: int(.1 * SR)])]), .35)


KEYPAD = {"1": (697, 1209), "2": (697, 1336), "3": (697, 1477), "4": (770, 1209), "5": (770, 1336), "6": (770, 1477),
          "7": (852, 1209), "8": (852, 1336), "9": (852, 1477), "0": (941, 1336)}


def s_key(d):
    a, b = KEYPAD[d]
    x = tone(a, .16) + tone(b, .16)
    return norm(x * env(len(x), .005, .04), .3)


def s_no():
    # 「不要！」: a firm, friendly two-beat drum and a short bright note (not a scold)
    drum = lowpass(noise("nodrum", .15), 220) * decay(int(.15 * SR), .05)
    return norm(at(.5, [(0, drum), (.12, drum * .8), (.12, note(NOTE["D5"], .3, "horn", .1) * .25)]), .65)


def s_fill():
    # a rising soft tone while a button is held (loops)
    return norm(sweep(330, 660, 1.0) * env(int(SR * 1.0), .05, .1), .25)


def s_badge():
    return norm(at(1.0, [(0, note(NOTE["E6"], .6, "bell", .3)), (.12, note(NOTE["B6"], .7, "bell", .35))]), .55)


def s_whoosh():
    x = bandpass(noise("whoosh", .4), 600, 3000)
    return norm(x * np.exp(-((t_of(.4) - .18) / .09) ** 2), .4)


def s_page():
    return norm(bandpass(noise("page", .25), 2000, 7000) * env(int(.25 * SR), .03, .15), .25)


def s_night():
    return norm(at(1.4, [(i * .3, note(NOTE[n], .8, "bell", .4)) for i, n in enumerate(["G5", "E5", "C5"])]), .4)


SFX = {
    "tap": s_tap, "pop": s_pop, "right": s_right, "try": s_try, "cheer": s_cheer, "found": s_found, "chirp": s_chirp,
    "car_pass": s_car_pass, "car_hum": s_car_hum, "brake": s_brake, "horn": s_horn, "steps": s_steps, "whistle": s_whistle,
    "click": s_click, "buckle": s_buckle, "rumble": s_rumble, "water": s_water, "window": s_window, "wind": s_wind,
    "switch": s_switch, "siren": s_siren, "bell": s_bell, "ring": s_ring, "no": s_no, "fill": s_fill, "badge": s_badge,
    "whoosh": s_whoosh, "page": s_page, "night": s_night,
    **{f"key_{d}": (lambda d=d: s_key(d)) for d in KEYPAD},
}


# ---------------------------------------------------------------- music
SCALES = {"C": ["C", "D", "E", "F", "G", "A", "B"], "G": ["G", "A", "B", "C", "D", "E", "F#"], "F": ["F", "G", "A", "Bb", "C", "D", "E"], "D": ["D", "E", "F#", "G", "A", "B", "C#"]}


def chord_tones(key, degree, octave):
    sc = SCALES[key]
    out = []
    for k in (0, 2, 4):
        i = degree + k
        name = sc[i % 7]
        # notes below the key's root in the scale list wrap to the next octave
        base = "C D E F G A B".split().index(name[0])
        root_base = "C D E F G A B".split().index(sc[0][0])
        o = octave + (i // 7) + (1 if base < root_base else 0)
        out.append(NOTE[f"{name}{o}"])
    return out


def tune(name, key, bpm, prog, lead, bass="sine", beats=4, bars=8, swing=0.0, melody_oct=5, density=.7, vol=.6, drums=False):
    sr = LOOP_SR
    beat = 60 / bpm
    total = bars * beats * beat
    n = int(total * sr)
    out = np.zeros(n)
    r = rng(name)

    def add(start, x):
        i = int(start * sr) % n
        k = min(len(x), n - i)
        out[i:i + k] += x[:k]
        if k < len(x):                       # wrap the tail round to the start: a seamless loop
            out[:len(x) - k] += x[k:]
    sc = SCALES[key]
    for bar in range(bars):
        deg = prog[bar % len(prog)]
        ch = chord_tones(key, deg, 3)
        t0 = bar * beats * beat
        # bass on beats 1 and 3
        for b in range(0, beats, 2):
            add(t0 + b * beat, note(ch[0] / 2, beat * 1.8, bass, .5, sr) * .5)
        # soft chord on each beat
        for b in range(beats):
            for f in ch:
                add(t0 + b * beat, note(f, beat * .9, "sine", .25, sr) * .08)
        # melody: chord tones and steps, eighth notes, with rests
        for e in range(beats * 2):
            if r.random() > density and e % 2:
                continue
            if e % 2 == 0:
                pick = ch[r.integers(0, 3)] * 2 ** (melody_oct - 3)
            else:
                idx = (sc.index(sc[deg]) + int(r.integers(-1, 3))) % 7
                o = melody_oct + (1 if "C D E F G A B".split().index(sc[idx][0]) < "C D E F G A B".split().index(sc[0][0]) else 0)
                pick = NOTE[f"{sc[idx]}{o}"]
            st = t0 + e * beat / 2 + (swing * beat / 2 if e % 2 else 0)
            add(st, note(pick, beat * .9, lead, .18 if lead != "kalimba" else .3, sr) * .32)
        if drums:
            for b in range(beats):
                k = lowpass(rng(f"{name}k{bar}{b}").standard_normal(int(.08 * sr)), 160, sr) * decay(int(.08 * sr), .03, sr=sr)
                add(t0 + b * beat, k * (.5 if b % 2 == 0 else .25))
                hh = bandpass(rng(f"{name}h{bar}{b}").standard_normal(int(.03 * sr)), 4000, 7000, sr) * decay(int(.03 * sr), .008, sr=sr)
                add(t0 + (b + .5) * beat, hh * .12)
    return norm(lowpass(out, 5000, sr), vol)


MUSIC = {
    "music_base": lambda: tune("music_base", "C", 112, [0, 5, 3, 4], "bell", bars=8, drums=True, density=.8, vol=.6),
    "music_road": lambda: tune("music_road", "G", 120, [0, 3, 4, 0, 5, 3, 4, 4], "xylo", bars=8, drums=True, density=.75, vol=.58),
    "music_rescue": lambda: tune("music_rescue", "F", 92, [0, 4, 5, 3], "horn", bars=8, density=.5, vol=.5),
    "music_body": lambda: tune("music_body", "D", 76, [0, 3, 0, 4], "kalimba", bars=6, density=.55, vol=.5),
    "music_home": lambda: tune("music_home", "C", 96, [0, 3, 1, 4], "piano", bars=8, swing=.15, density=.65, vol=.52),
    "music_rest": lambda: tune("music_rest", "F", 60, [0, 3, 5, 4], "bell", bars=4, density=.35, vol=.4),
}


# ---------------------------------------------------------------- writing
def write(name, x, sr):
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())


def check():
    names = set(SFX) | set(MUSIC)
    files = {p.stem for p in OUT.glob("*.wav")}
    extra = files - names
    if extra:
        raise SystemExit(f"not made here: {sorted(extra)}")
    total = sum(p.stat().st_size for p in OUT.glob("*.wav"))
    if total > LIMIT:
        raise SystemExit(f"the sounds take {total / 1e6:.1f} MB (keep under {LIMIT / 1e6:.0f} MB)")
    for p in OUT.glob("*.wav"):
        with wave.open(str(p)) as w:
            d = w.getnframes() / w.getframerate()
            data = np.frombuffer(w.readframes(w.getnframes()), np.int16) / 32768
        if p.stem.startswith("music_"):
            if not 12 <= d <= 30:
                raise SystemExit(f"{p.stem}: {d:.1f} s")
        elif d > 2.5:
            raise SystemExit(f"{p.stem}: {d:.1f} s is long for a sound")
        if np.abs(data).max() > .9:
            raise SystemExit(f"{p.stem}: too loud")
    print(f"sounds: {len(files)} files, {total / 1e6:.1f} MB")


def main(argv):
    OUT.mkdir(parents=True, exist_ok=True)
    if argv[:1] == ["preview"]:
        with tempfile.TemporaryDirectory() as tmp:
            lst = pathlib.Path(tmp) / "list.txt"
            lst.write_text("".join(f"file '{p}'\n" for p in sorted(OUT.glob("*.wav"))))
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", str(lst), "-ar", "22050", argv[1]], check=True)
        return
    want = set(argv) or (set(SFX) | set(MUSIC))
    for k, f in SFX.items():
        if k in want:
            write(k, f(), SR)
    for k, f in MUSIC.items():
        if k in want:
            write(k, f(), LOOP_SR)
    check()


if __name__ == "__main__":
    main(sys.argv[1:])
