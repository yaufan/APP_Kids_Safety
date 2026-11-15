import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/hero_art.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/scene.dart';

/// A comic word bursting out over the picture.
class BurstMark {
  const BurstMark(this.key, this.word, this.x, this.y);

  final int key;
  final String word;
  final double x, y;
}

/// A level's picture (core/scene.dart): the background and the things in
/// their states, in a 4:3 comic panel. Raw pointer events only: a touch
/// picks a thing up at once (no drag gesture to wait for), a tap is a
/// touch that lifts close to where it went down.
class SceneView extends StatefulWidget {
  const SceneView({
    super.key,
    required this.scene,
    required this.states,
    this.glow = const {},
    this.bursts = const [],
    this.wiggles = const {},
    required this.canDrag,
    required this.allowed,
    required this.onTap,
    required this.onDrop,
    this.onPick,
    this.onTooHigh,
    this.holdTarget,
    this.holdSeconds = 3,
    this.onHold,
  });

  final Scene scene;
  final Map<String, String> states;
  final Set<String> glow;
  final List<BurstMark> bursts;
  final Map<String, int> wiggles;
  final bool Function(String id) canDrag;

  /// Whether a held [item] may be at height y (0 top, 1 bottom).
  final bool Function(String item, double y) allowed;

  /// The things under the finger, the top one first.
  final void Function(List<String> ids) onTap;
  final void Function(String item, List<String> zones) onDrop;
  final void Function(String item)? onPick;
  final void Function(String item)? onTooHigh;

  /// A thing to press and hold (地震's table leg), and for how long.
  final String? holdTarget;
  final double holdSeconds;
  final void Function(double seconds)? onHold;

  static const aspect = 4 / 3;

  @override
  State<SceneView> createState() => _SceneViewState();
}

class _SceneViewState extends State<SceneView> with SingleTickerProviderStateMixin {
  String? _held;
  Offset _at = Offset.zero;
  Offset? _down;
  final _gone = <String>{};
  final _speed = <String, double>{};
  late final _hold = AnimationController(vsync: this);
  var _holding = false;

  @override
  void initState() {
    super.initState();
    _hold.addListener(() => setState(() {}));
    _hold.addStatusListener((s) {
      if (s == AnimationStatus.completed && _holding) {
        _holding = false;
        widget.onHold?.call(widget.holdSeconds);
        _hold.value = 0;
      }
    });
  }

  @override
  void didUpdateWidget(SceneView old) {
    super.didUpdateWidget(old);
    if (old.scene != widget.scene) {
      _gone.clear();
      _speed.clear();
      return;
    }
    for (final s in widget.scene.sprites) {
      final was = old.states[s.id] ?? 'start', now = widget.states[s.id] ?? 'start';
      if (was == now) continue;
      _gone.remove(s.id);
      final a = s.look(was), b = s.look(now);
      final dx = b.x - a.x, dy = b.y - a.y;
      if (!b.jump && (dx.abs() > .05 || dy.abs() > .05) && b.art != null && dx.abs() >= dy.abs()) {
        _speed[s.id] = dx.sign;
        Timer(const Duration(milliseconds: 750), () {
          if (mounted) setState(() => _speed.remove(s.id));
        });
      }
    }
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  Look _look(Sprite s) {
    if (_gone.contains(s.id)) return s.base.copyWith(hide: true, jump: true);
    return s.look(widget.states[s.id] ?? 'start');
  }

  Rect _rect(Look l, Size size) => Rect.fromCenter(center: Offset(l.x * size.width, l.y * size.height), width: l.w * size.width, height: l.h * size.height);

  List<String> _under(Offset p, Size size, {String? except}) {
    final out = <String>[];
    for (final s in widget.scene.sprites.reversed) {
      if (s.id == except) continue;
      final l = _look(s);
      final grow = math.min(size.width, size.height) * .03;
      if (_rect(l, size).inflate(grow).contains(p)) out.add(s.id);
    }
    return out;
  }

  Widget _pic(Look l) {
    final a = l.art;
    if (a == null) return const SizedBox.expand();
    if (a.startsWith('@hero/')) return HeroArt(a.substring(6), flip: l.flip);
    return Art(a, flip: l.flip);
  }

  void _down0(PointerDownEvent e, Size size) {
    if (_held != null) return;
    final p = e.localPosition;
    final ids = _under(p, size);
    for (final id in ids) {
      if (widget.canDrag(id)) {
        widget.onPick?.call(id);
        setState(() {
          _held = id;
          _at = p;
        });
        return;
      }
    }
    final h = widget.holdTarget;
    if (h != null && ids.contains(h)) {
      _holding = true;
      _hold.duration = Duration(milliseconds: (widget.holdSeconds * 1000).round());
      _hold.forward(from: 0);
      return;
    }
    _down = p;
  }

  void _move(PointerMoveEvent e, Size size) {
    final h = _held;
    if (h == null) return;
    final p = e.localPosition;
    if (!widget.allowed(h, p.dy / size.height)) {
      setState(() => _held = null);
      widget.onTooHigh?.call(h);
      return;
    }
    setState(() => _at = p);
  }

  void _up(Offset p, Size size) {
    if (_holding) {
      _holding = false;
      final secs = _hold.value * widget.holdSeconds;
      _hold.stop();
      _hold.value = 0;
      widget.onHold?.call(secs);
      return;
    }
    final h = _held;
    if (h != null) {
      setState(() => _held = null);
      widget.onDrop(h, _under(p, size, except: h));
      return;
    }
    final d = _down;
    _down = null;
    if (d != null && (d - p).distance < 30) widget.onTap(_under(p, size));
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: SceneView.aspect,
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Comic.ink, width: 2.5), borderRadius: BorderRadius.circular(8)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LayoutBuilder(builder: (context, box) {
              final size = Size(box.maxWidth, box.maxHeight);
              final shake = widget.states[SceneFlag.shake] == 'on';
              final dark = widget.states[SceneFlag.dark];
              final kids = <Widget>[Positioned.fill(child: Art(widget.scene.bg, fit: BoxFit.fill))];
              for (final s in widget.scene.sprites) {
                final l = _look(s);
                final r = _rect(l, size);
                Widget pic = _pic(l);
                if (s.anim != Anim.none) {
                  pic = Bob(
                    motion: switch (s.anim) { Anim.swing => Motion.swing, Anim.drift => Motion.drift, _ => Motion.bob },
                    amount: s.anim == Anim.swing ? 6 : 3,
                    period: s.anim == Anim.drift ? 5000 : 2200,
                    child: pic,
                  );
                }
                if (widget.glow.contains(s.id)) pic = GlowRing(circle: l.art == null || l.w < .12, child: pic);
                pic = Wiggle(trigger: widget.wiggles[s.id] ?? 0, child: pic);
                final speed = _speed[s.id];
                kids.add(AnimatedPositioned(
                  key: ValueKey('sprite-${s.id}'),
                  duration: l.jump ? Duration.zero : const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  left: r.left,
                  top: r.top,
                  width: r.width,
                  height: r.height,
                  onEnd: () {
                    if (l.exit && !_gone.contains(s.id) && mounted) setState(() => _gone.add(s.id));
                  },
                  child: Opacity(
                    opacity: _held == s.id ? .25 : 1,
                    child: Stack(clipBehavior: Clip.none, children: [
                      Positioned.fill(child: pic),
                      if (speed != null)
                        Positioned(
                          top: r.height * .2,
                          height: r.height * .5,
                          width: r.width * .5,
                          left: speed > 0 ? -r.width * .45 : null,
                          right: speed < 0 ? -r.width * .45 : null,
                          child: Art('fx/speed', flip: speed < 0),
                        ),
                    ]),
                  ),
                ));
              }
              final h = widget.holdTarget;
              if (h != null) {
                final sp = widget.scene.sprite(h);
                if (sp != null) {
                  final r = _rect(_look(sp), size).inflate(size.width * .03);
                  kids.add(Positioned.fromRect(rect: r, child: IgnorePointer(child: CustomPaint(painter: HoldRing(_hold.value, glow: widget.glow.contains(h) || _hold.value > 0)))));
                }
              }
              if (dark == 'on') kids.add(Positioned.fill(child: IgnorePointer(child: Container(color: const Color(0xAA0E1830)))));
              if (dark == 'lit') kids.add(Positioned.fill(child: IgnorePointer(child: Container(color: const Color(0x440E1830)))));
              final held = _held;
              if (held != null) {
                final l = widget.scene.sprite(held)!.look(widget.states[held] ?? 'start');
                final r = _rect(l, size);
                final w = math.max(r.width, size.width * .1) * 1.1, hh = math.max(r.height, size.height * .1) * 1.1;
                kids.add(Positioned(left: _at.dx - w / 2, top: _at.dy - hh * .75, width: w, height: hh, child: IgnorePointer(child: _pic(l.copyWith(art: l.art ?? 'fx/speed')))));
              }
              for (final b in widget.bursts) {
                final w = size.width * .34;
                kids.add(Positioned(
                  key: ValueKey('burst-${b.key}'),
                  left: (b.x * size.width - w / 2).clamp(0, size.width - w),
                  top: (b.y * size.height - w * .45).clamp(0, size.height - w * .6),
                  width: w,
                  height: w * .6,
                  child: Burst(word: b.word, size: w),
                ));
              }
              Widget stack = Stack(clipBehavior: Clip.hardEdge, children: kids);
              if (shake) stack = Bob(motion: Motion.wobble, amount: 3, period: 700, child: stack);
              return Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) => _down0(e, size),
                onPointerMove: (e) => _move(e, size),
                onPointerUp: (e) => _up(e.localPosition, size),
                onPointerCancel: (e) => _up(e.localPosition, size),
                child: stack,
              );
            }),
          ),
        ),
      );
}

/// The ring that fills while a finger holds something down.
class HoldRing extends CustomPainter {
  HoldRing(this.t, {this.glow = false});

  final double t;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    if (glow) {
      canvas.drawCircle(c, r, Paint()
        ..color = Colors.white.withValues(alpha: .7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8);
    }
    if (t <= 0) return;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * t, false, Paint()
      ..color = Comic.yellow
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8);
  }

  @override
  bool shouldRepaint(HoldRing old) => old.t != t || old.glow != glow;
}
