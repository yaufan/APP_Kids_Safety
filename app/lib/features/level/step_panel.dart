import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/content.dart';
import '../../core/levels.dart';
import '../../core/providers.dart';
import '../../core/run.dart';
import '../../core/steps.dart';
import 'scene_view.dart';

/// Under the picture: what this step needs besides the picture itself (the
/// five crossing words, big buttons, answer cards, the keypad, the big
/// 「不要！」 button, the trusted grown-ups, the lights' legend).
class StepPanel extends ConsumerWidget {
  const StepPanel({super.key, required this.run, required this.glow, required this.onTap, required this.onChoose, required this.onKey, required this.onHold, required this.onSaid, this.wiggle = 0});

  final LevelRun run;
  final Set<String> glow;
  final void Function(String id) onTap;
  final void Function(String id) onChoose;
  final void Function(String digit) onKey;
  final void Function(String id, double seconds) onHold;
  final VoidCallback onSaid;
  final int wiggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = run.step;
    if (s == null) return const SizedBox.shrink();
    final kids = <Widget>[];
    final hint = run.asking != null ? run.question?.hint : s.hint;
    if (hint != null) kids.add(Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(hint, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Comic.inkSoft, fontWeight: FontWeight.w700))));
    if (s.extra == Extra.words) kids.add(_Words(run: run, glow: glow, onTap: onTap));
    if (s.extra == Extra.lights) kids.add(const _Legend());
    if (s.extra == Extra.trusted) kids.add(_Trusted(adults: ref.watch(gameProvider.select((g) => g.settings.trusted))));
    final q = run.question;
    if (q != null) kids.add(Wiggle(trigger: wiggle, amount: .03, child: _Cards(q: q, onChoose: onChoose)));
    switch (s) {
      case TapStep():
        final buttons = [for (final t in s.targets) if (t.startsWith('btn:')) t];
        if (buttons.isNotEmpty && !run.waiting) {
          kids.add(Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 10, children: [
            for (final b in buttons) ComicButton(key: ValueKey('btn-$b'), label: b.substring(4), height: 60, color: Comic.yellow, glow: glow.contains(b), onTap: () => onTap(b)),
          ]));
        }
      case HoldStep():
        if (s.target.startsWith('btn:') && !run.waiting) kids.add(HoldButton(key: ValueKey('hold-${run.part}'), label: s.target.substring(4), seconds: s.seconds, loopSfx: s.loopSfx, onHold: (secs) => onHold(s.target, secs)));
      case KeypadStep():
        kids.add(_Keypad(step: s, typed: run.typed, glow: glow, onKey: onKey));
      case SayStep():
        if (!run.waiting) kids.add(_SayButton(key: ValueKey('say-${run.part}-${run.index}'), step: s, started: run.tapped.isNotEmpty, onTap: () => onTap('btn:${s.label}'), onSaid: onSaid));
      default:
        break;
    }
    return Column(mainAxisSize: MainAxisSize.min, children: kids);
  }
}

class _Words extends StatelessWidget {
  const _Words({required this.run, required this.glow, required this.onTap});

  final LevelRun run;
  final Set<String> glow;
  final void Function(String id) onTap;

  @override
  Widget build(BuildContext context) {
    // A word is done once the step that taps it is behind.
    final steps = run.parts[run.part].steps;
    final done = <String>{};
    for (var i = 0; i < steps.length; i++) {
      final st = steps[i];
      if (st is TapStep && (i < run.index || (i == run.index && run.waiting))) {
        for (final t in st.targets) {
          if (t.startsWith('word:')) done.add(t.substring(5));
        }
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        for (final (w, plain) in crossWords)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Semantics(
                key: ValueKey('word-$w'),
                container: true,
                button: true,
                label: w,
                excludeSemantics: true,
                onTap: () => onTap('word:$w'),
                child: Pressable(
                  onTap: () => onTap('word:$w'),
                  sound: null,
                  child: Column(children: [
                    AspectRatio(
                      aspectRatio: .9,
                      child: _maybeGlow(
                        glow.contains('word:$w'),
                        Container(
                          alignment: Alignment.center,
                          decoration: comicBox(done.contains(w) ? Comic.blue : Colors.white, radius: 14, shadow: !done.contains(w)),
                          child: Stack(alignment: Alignment.center, children: [
                            FittedBox(child: Padding(padding: const EdgeInsets.all(6), child: ComicText(w, size: 34, color: done.contains(w) ? Colors.white : Comic.blue, edge: done.contains(w) ? Comic.ink : Colors.white))),
                            if (done.contains(w)) const Positioned(bottom: 2, right: 2, child: Icon(Icons.check_rounded, color: Colors.white, size: 18)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(child: Text(plain, style: const TextStyle(fontSize: 12, color: Comic.inkSoft))),
                  ]),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

Widget _maybeGlow(bool on, Widget child) => on ? GlowRing(child: child) : child;

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final (c, zh, say) in [(Comic.green, '綠燈', '可以'), (Comic.yellow, '黃燈', '先問我'), (Comic.red, '紅燈', '不可以')])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                Container(width: 22, height: 22, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Comic.ink, width: 2))),
                const SizedBox(width: 5),
                Text('$zh $say', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ]),
            ),
        ]),
      );
}

class _Trusted extends StatelessWidget {
  const _Trusted({required this.adults});

  final List<Adult> adults;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 8, children: [
          for (final a in adults)
            Container(
              key: ValueKey('trusted-${a.name}'),
              padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
              decoration: comicBox(Colors.white, radius: 30, shadow: false),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: 40, height: 40, child: Art(a.art)),
                const SizedBox(width: 6),
                Text(a.zh, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ]),
            ),
        ]),
      );
}

class _Cards extends StatelessWidget {
  const _Cards({required this.q, required this.onChoose});

  final ChooseStep q;
  final void Function(String id) onChoose;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final n = q.options.length;
        final w = math.min((box.maxWidth - (n - 1) * 10) / n, 200.0);
        return Wrap(alignment: WrapAlignment.center, spacing: 10, children: [
          for (final o in q.options)
            Semantics(
              key: ValueKey('opt-${o.id}'),
              container: true,
              button: true,
              label: o.zh,
              excludeSemantics: true,
              onTap: () => onChoose(o.id),
              child: Pressable(
                onTap: () => onChoose(o.id),
                sound: null,
                child: Container(
                  width: w,
                  padding: const EdgeInsets.all(8),
                  decoration: comicBox(Colors.white),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (o.art != null) SizedBox(height: math.min(w * .55, 80), child: o.art!.startsWith('@') ? const SizedBox() : Art(o.art!)),
                    if (o.art != null) const SizedBox(height: 4),
                    Text(o.zh, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.25)),
                  ]),
                ),
              ),
            ),
        ]);
      });
}

/// The keypad (119, the parent's number): the number so far on top. At
/// 小小 the whole number shows faintly and the next key lights up.
class _Keypad extends StatelessWidget {
  const _Keypad({required this.step, required this.typed, required this.glow, required this.onKey});

  final KeypadStep step;
  final int typed;
  final Set<String> glow;
  final void Function(String d) onKey;

  @override
  Widget build(BuildContext context) {
    final d = step.digits;
    Widget key(String k) => Semantics(
          key: ValueKey('key-$k'),
          container: true,
          button: true,
          label: k,
          excludeSemantics: true,
          onTap: () => onKey(k),
          child: Pressable(
            onTap: () => onKey(k),
            sound: null,
            child: _maybeGlow(
              glow.contains('key:$k'),
              Container(alignment: Alignment.center, decoration: comicBox(k == '1' || k == '9' ? const Color(0xFFFFF4DC) : Colors.white, radius: 14), child: Text(k, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700))),
            ),
          ),
        );
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: comicBox(const Color(0xFF26324A), radius: 14, shadow: false),
        child: FittedBox(
          child: Text.rich(TextSpan(children: [
            for (var i = 0; i < d.length; i++)
              TextSpan(
                text: i < typed ? d[i] : (step.glow ? d[i] : '_'),
                style: TextStyle(fontSize: 30, letterSpacing: 4, fontWeight: FontWeight.w700, color: i < typed ? const Color(0xFF7CF29A) : Colors.white.withValues(alpha: .3)),
              ),
          ])),
        ),
      ),
      const SizedBox(height: 10),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.9,
          children: [for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9']) key(k), const SizedBox(), key('0'), const SizedBox()],
        ),
      ),
    ]);
  }
}

/// A big round button to press and hold (「不要！」): a ring fills; let go
/// early and it says hold on.
class HoldButton extends ConsumerStatefulWidget {
  const HoldButton({super.key, required this.label, required this.seconds, required this.onHold, this.loopSfx});

  final String label;
  final double seconds;
  final String? loopSfx;
  final void Function(double seconds) onHold;

  @override
  ConsumerState<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends ConsumerState<HoldButton> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Duration(milliseconds: (widget.seconds * 1000).round()))
    ..addListener(() => setState(() {}))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && _on) {
        _on = false;
        widget.onHold(widget.seconds);
      }
    });
  var _on = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down() {
    _on = true;
    final l = widget.loopSfx;
    if (l != null) sfx(ref, l);
    _c.forward(from: 0);
  }

  void _up() {
    if (!_on) return;
    _on = false;
    final secs = _c.value * widget.seconds;
    _c.stop();
    _c.value = 0;
    widget.onHold(secs);
  }

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: true,
        label: widget.label,
        excludeSemantics: true,
        child: Listener(
          onPointerDown: (_) => _down(),
          onPointerUp: (_) => _up(),
          onPointerCancel: (_) => _up(),
          child: SizedBox(
            width: 150,
            height: 150,
            child: CustomPaint(
              foregroundPainter: HoldRing(_c.value, glow: true),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AnimatedScale(
                  scale: _on ? .94 : 1,
                  duration: const Duration(milliseconds: 90),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Comic.red, shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: Comic.ink, width: 3))),
                    child: ComicText(widget.label, size: 32),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// 「大聲說一次」: tap, then a few seconds to say it to the phone (nothing
/// is recorded; the app has no microphone).
class _SayButton extends StatefulWidget {
  const _SayButton({super.key, required this.step, required this.started, required this.onTap, required this.onSaid});

  final SayStep step;
  final bool started;
  final VoidCallback onTap;
  final VoidCallback onSaid;

  @override
  State<_SayButton> createState() => _SayButtonState();
}

class _SayButtonState extends State<_SayButton> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Duration(milliseconds: (widget.step.seconds * 1000).round()))
    ..addListener(() => setState(() {}))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onSaid();
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _tap() {
    if (_c.isAnimating || widget.started) return;
    widget.onTap();
    unawaited(_c.forward(from: 0));
  }

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: true,
        label: widget.step.label,
        excludeSemantics: true,
        onTap: _tap,
        child: Pressable(
          onTap: _tap,
          sound: null,
          child: SizedBox(
            width: 170,
            height: 150,
            child: CustomPaint(
              foregroundPainter: HoldRing(_c.value),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Container(
                  alignment: Alignment.center,
                  decoration: comicBox(Comic.yellow, radius: 60),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_c.isAnimating ? Icons.record_voice_over_rounded : Icons.campaign_rounded, size: 40, color: Comic.ink),
                    Text(_c.isAnimating ? '說說看⋯⋯' : widget.step.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}
