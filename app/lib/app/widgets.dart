import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/providers.dart';
import '../core/sounds.dart';
import 'strings.dart';
import 'theme.dart';

/// A drawing from assets/art/ (nothing at all if it is missing).
class Art extends StatelessWidget {
  const Art(this.path, {super.key, this.fit = BoxFit.contain, this.alignment = Alignment.center, this.flip = false});

  /// Under assets/art/, without ".svg" (road/street).
  final String path;
  final BoxFit fit;
  final Alignment alignment;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    final svg = SvgPicture.asset('assets/art/$path.svg', fit: fit, alignment: alignment, excludeFromSemantics: true, errorBuilder: (_, _, _) => const SizedBox.expand());
    return flip ? Transform.flip(flipX: true, child: svg) : svg;
  }
}

/// Says a line out loud (if the parent left the voice on).
void speak(WidgetRef ref, String text) {
  if (!ref.read(gameProvider).settings.voice) return;
  ref.read(voiceProvider).say(text);
}

void sfx(WidgetRef ref, String name) => ref.read(soundsProvider).play(name);

/// Shrinks a little while pressed and fires when the finger lifts on it
/// (raw pointer events: a touch counts at once, no gesture to wait for).
class Pressable extends ConsumerStatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.sound = 'tap'});

  final Widget child;
  final VoidCallback? onTap;
  final String? sound;

  @override
  ConsumerState<Pressable> createState() => _PressableState();
}

class _PressableState extends ConsumerState<Pressable> {
  int? _pointer;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: enabled && _pointer == null ? (e) => setState(() => _pointer = e.pointer) : null,
      onPointerCancel: (e) {
        if (e.pointer == _pointer) setState(() => _pointer = null);
      },
      onPointerUp: (e) {
        if (e.pointer != _pointer) return;
        setState(() => _pointer = null);
        final box = context.findRenderObject() as RenderBox?;
        if (!enabled || box == null || !(Offset.zero & box.size).inflate(12).contains(e.localPosition)) return;
        final s = widget.sound;
        if (s != null) ref.read(soundsProvider).play(s);
        widget.onTap!();
      },
      child: AnimatedScale(scale: _pointer != null ? 0.93 : 1, duration: const Duration(milliseconds: 90), child: widget.child),
    );
  }
}

/// A flat comic panel: a colour, a thin dark-blue outline and a hard offset
/// shadow (no soft blur: it is a comic).
BoxDecoration comicBox(Color color, {double radius = 18, double border = 2.2, bool shadow = true, Color? ring}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: ring ?? Comic.ink, width: ring != null ? border + 1.6 : border),
      boxShadow: shadow ? const [BoxShadow(color: Color(0x331E3A6E), offset: Offset(3, 4))] : null,
    );

/// Words with a dark-blue edge (titles, comic words), drawn with the font.
class ComicText extends StatelessWidget {
  const ComicText(this.text, {super.key, this.size = 24, this.color = Colors.white, this.edge = Comic.ink, this.width, this.align = TextAlign.center});

  final String text;
  final double size;
  final Color color, edge;
  final double? width;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final w = width ?? size * .16;
    final style = TextStyle(fontFamily: 'Huninn', fontSize: size, fontWeight: FontWeight.w700, height: 1.2);
    return Stack(children: [
      Text(text, textAlign: align, style: style.copyWith(foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeJoin = StrokeJoin.round
        ..color = edge)),
      Text(text, textAlign: align, style: style.copyWith(color: color)),
    ]);
  }
}

/// A round button with an icon.
class RoundButton extends StatelessWidget {
  const RoundButton({super.key, required this.label, required this.icon, this.onTap, this.size = 50, this.color = Colors.white, this.sound = 'tap'});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color color;
  final String? sound;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: Pressable(
          onTap: onTap,
          sound: sound,
          child: Container(
            width: size,
            height: size,
            decoration: comicBox(color, radius: size / 2, shadow: false),
            child: Icon(icon, size: size * 0.55, color: color == Colors.white ? Comic.ink : Colors.white),
          ),
        ),
      );
}

/// A wide comic button with a word (and an icon or a picture).
class ComicButton extends StatelessWidget {
  const ComicButton({super.key, required this.label, this.onTap, this.color = Comic.yellow, this.icon, this.art, this.height = 58, this.sound = 'tap', this.expand = false, this.glow = false, this.semantics});

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  final String? art;
  final double height;
  final String? sound;
  final bool expand;
  final bool glow;
  final String? semantics;

  @override
  Widget build(BuildContext context) {
    final light = color.computeLuminance() > .5;
    final fg = light ? Comic.ink : Colors.white;
    final button = Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: height * 0.36),
      decoration: comicBox(color, radius: height / 2),
      child: Row(mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        if (art != null) ...[SizedBox(width: height * .6, height: height * .6, child: Art(art!)), const SizedBox(width: 6)],
        if (icon != null) ...[Icon(icon, size: height * 0.44, color: fg), const SizedBox(width: 6)],
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: height * 0.36, fontWeight: FontWeight.w700, color: fg))),
      ]),
    );
    return Semantics(
      container: true,
      button: true,
      label: semantics ?? label,
      excludeSemantics: true,
      onTap: onTap,
      child: Pressable(onTap: onTap, sound: sound, child: glow ? GlowRing(child: button) : button),
    );
  }
}

/// The 「tap here」 light for 小小: a pulsing dashed yellow ring around [child].
class GlowRing extends StatefulWidget {
  const GlowRing({super.key, required this.child, this.circle = false});

  final Widget child;
  final bool circle;

  @override
  State<GlowRing> createState() => _GlowRingState();
}

class _GlowRingState extends State<GlowRing> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) => CustomPaint(foregroundPainter: _Ring(_c.value, widget.circle), child: child),
        child: widget.child,
      );
}

class _Ring extends CustomPainter {
  _Ring(this.t, this.circle);

  final double t;
  final bool circle;

  @override
  void paint(Canvas canvas, Size size) {
    final grow = 4 + t * 5;
    final r = (Offset.zero & size).inflate(grow);
    final rr = circle ? RRect.fromRectAndRadius(r, Radius.circular(r.shortestSide / 2)) : RRect.fromRectAndRadius(r, Radius.circular(math.min(24, r.shortestSide / 2)));
    canvas.drawRRect(rr, Paint()
      ..color = Comic.yellow.withValues(alpha: .28 + .2 * t)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10);
    canvas.drawRRect(rr, Paint()
      ..color = Comic.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5);
  }

  @override
  bool shouldRepaint(_Ring old) => old.t != t;
}

/// The helper and a white speech balloon whose tail points at them (tap to
/// hear it again).
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text, required this.helper, this.onTap, this.size = 19});

  final String text;

  /// The helper's picture (helpers/dog_stand).
  final String helper;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: onTap != null,
        label: text,
        excludeSemantics: true,
        onTap: onTap,
        child: Pressable(
          onTap: onTap,
          sound: null,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            SizedBox(width: size * 3.6, height: size * 4.8, child: Bob(amount: 2, child: Art(helper))),
            Expanded(
              child: CustomPaint(
                painter: _BalloonPainter(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(size * 1.2, size * .6, size * .7, size * .6),
                  child: Row(children: [
                    Expanded(child: Text(text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: Comic.ink, height: 1.35))),
                    const SizedBox(width: 6),
                    Icon(Icons.volume_up_rounded, color: Comic.blue, size: size * 1.2),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      );
}

class _BalloonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tail = 14.0;
    final body = RRect.fromLTRBR(tail, 0, size.width, size.height, const Radius.circular(18));
    final p = Path.combine(PathOperation.union, Path()..addRRect(body), Path()
      ..moveTo(tail + 2, size.height * .58)
      ..lineTo(0, size.height * .84)
      ..lineTo(tail + 2, size.height * .8)
      ..close());
    canvas.drawPath(p.shift(const Offset(3, 4)), Paint()..color = const Color(0x331E3A6E));
    canvas.drawPath(p, Paint()..color = Colors.white);
    canvas.drawPath(p, Paint()
      ..color = Comic.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_BalloonPainter old) => false;
}

/// A comic word in a burst bubble that pops in and fades (布穀！喀！).
class Burst extends StatefulWidget {
  const Burst({super.key, required this.word, this.size = 120, this.yellow = true, this.onDone});

  final String word;
  final double size;
  final bool yellow;
  final VoidCallback? onDone;

  static const length = Duration(milliseconds: 1300);

  @override
  State<Burst> createState() => _BurstState();
}

class _BurstState extends State<Burst> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Burst.length)
    ..forward().whenComplete(() {
      if (mounted) widget.onDone?.call();
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) {
            final t = _c.value;
            final s = t < .18 ? Curves.easeOutBack.transform(t / .18) : 1.0;
            final o = t > .75 ? 1 - (t - .75) / .25 : 1.0;
            return Opacity(opacity: o.clamp(0, 1), child: Transform.scale(scale: s, child: Transform.rotate(angle: -.08, child: child)));
          },
          child: SizedBox(
            width: widget.size,
            height: widget.size * .6,
            child: Stack(alignment: Alignment.center, children: [
              Positioned.fill(child: Art(widget.yellow ? 'fx/burst_yellow' : 'fx/burst', fit: BoxFit.fill)),
              FittedBox(child: Padding(padding: EdgeInsets.all(widget.size * .12), child: ComicText(widget.word, size: widget.size * .2, color: Comic.red, edge: Colors.white, width: widget.size * .04))),
            ]),
          ),
        ),
      );
}

/// Plays [music] while this is on screen.
class WithMusic extends ConsumerStatefulWidget {
  const WithMusic({super.key, required this.music, required this.child});

  final Music music;
  final Widget child;

  @override
  ConsumerState<WithMusic> createState() => _WithMusicState();
}

class _WithMusicState extends ConsumerState<WithMusic> {
  late final Sounds _sounds = ref.read(soundsProvider);

  @override
  void initState() {
    super.initState();
    _sounds.hold(this, widget.music);
  }

  @override
  void didUpdateWidget(WithMusic old) {
    super.didUpdateWidget(old);
    if (old.music != widget.music) _sounds.hold(this, widget.music);
  }

  @override
  void dispose() {
    _sounds.release(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Shakes its child side to side once each time [trigger] changes.
class Wiggle extends StatefulWidget {
  const Wiggle({super.key, required this.trigger, required this.child, this.amount = 0.08});

  final int trigger;
  final Widget child;
  final double amount;

  @override
  State<Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<Wiggle> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void didUpdateWidget(Wiggle old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = _c.value;
          return Transform.rotate(angle: math.sin(t * math.pi * 4) * (1 - t) * widget.amount, child: child);
        },
        child: widget.child,
      );
}

/// A gentle repeating movement: up and down (bob), a lamp swinging, smoke
/// drifting, or the room's soft earthquake wobble.
enum Motion { bob, swing, drift, wobble }

class Bob extends StatefulWidget {
  const Bob({super.key, required this.child, this.phase = 0, this.amount = 4, this.period = 2400, this.motion = Motion.bob, this.on = true});

  final Widget child;
  final double phase;
  final double amount;
  final int period;
  final Motion motion;
  final bool on;

  @override
  State<Bob> createState() => _BobState();
}

class _BobState extends State<Bob> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.period));

  @override
  void initState() {
    super.initState();
    if (widget.on) _c.repeat();
  }

  @override
  void didUpdateWidget(Bob old) {
    super.didUpdateWidget(old);
    if (widget.on && !_c.isAnimating) _c.repeat();
    if (!widget.on && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final s = math.sin((_c.value + widget.phase) * 2 * math.pi);
          return switch (widget.motion) {
            Motion.bob => Transform.translate(offset: Offset(0, s * widget.amount), child: child),
            Motion.swing => Transform.rotate(angle: s * widget.amount * .03, alignment: Alignment.topCenter, child: child),
            Motion.drift => Transform.translate(offset: Offset(s * widget.amount, 0), child: child),
            Motion.wobble => Transform.rotate(angle: s * widget.amount * .004, child: Transform.translate(offset: Offset(math.sin((_c.value * 2 + widget.phase) * 2 * math.pi) * widget.amount * .6, 0), child: child)),
          };
        },
        child: widget.child,
      );
}

/// The bar at the top of a page: back, the title in the world's colour, the speaker.
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title, this.color = Comic.blue, this.onBack, this.onSpeak, this.homeIcon = false});

  final String title;
  final Color color;
  final VoidCallback? onBack;
  final VoidCallback? onSpeak;
  final bool homeIcon;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: color, border: const Border(bottom: BorderSide(color: Comic.ink, width: 2.5))),
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        child: Row(children: [
          if (onBack == null) const SizedBox(width: 46) else RoundButton(label: homeIcon ? Strings.home : Strings.back, icon: homeIcon ? Icons.home_rounded : Icons.arrow_back_rounded, onTap: onBack, size: 46),
          Expanded(child: Center(child: ComicText(title, size: 24))),
          if (onSpeak != null) RoundButton(label: Strings.again, icon: Icons.volume_up_rounded, onTap: onSpeak, size: 46, sound: null) else const SizedBox(width: 46),
        ]),
      );
}
