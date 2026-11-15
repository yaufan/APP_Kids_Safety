import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/hero_art.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/content.dart';
import '../../core/levels.dart';
import '../../core/providers.dart';
import '../../core/run.dart';
import '../../core/steps.dart';
import '../world/world_screen.dart';
import 'scene_view.dart';
import 'step_panel.dart';

/// One level (docs/design.md 「畫面」 3 and 4): the picture on top, what the
/// step needs below it, and the helper's balloon at the bottom. The helper
/// says one line, the child does it, the picture answers (the car stops,
/// the table covers the squad member) with a comic word, the helper says
/// why, and on to the next step. At the end: 「做得好」, a question card for
/// the parent, a 「回真實生活」 line, and the badge goes on the helmet.
class LevelScreen extends ConsumerStatefulWidget {
  const LevelScreen({super.key, required this.lv});

  final Lv lv;

  /// How long the helper waits after a done step, as a share of the normal
  /// time (the tests run quicker).
  static var pace = 1.0;

  @override
  ConsumerState<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends ConsumerState<LevelScreen> {
  late LevelRun _run;
  late String _line;
  final _bursts = <BurstMark>[];
  final _wiggles = <String, int>{};
  var _panelWiggle = 0;
  var _burstKey = 0;
  var _finished = false;
  var _crest = false;
  Timer? _next;

  Lv get lv => widget.lv;

  @override
  void initState() {
    super.initState();
    _begin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startStep();
    });
  }

  void _begin() {
    final g = ref.read(gameProvider);
    _run = LevelRun(levelParts(lv, g.settings, g.hero));
    _line = _run.step!.say;
    _finished = false;
    _crest = false;
    _bursts.clear();
  }

  @override
  void dispose() {
    _next?.cancel();
    super.dispose();
  }

  void _say(String text) {
    setState(() => _line = text);
    speak(ref, text);
  }

  void _startStep() {
    final s = _run.step;
    if (s == null) return;
    _say(s.say);
    final st = s.startSfx;
    if (st != null) sfx(ref, st);
  }

  void _burst(String word, String? at) {
    final sp = at == null ? null : _run.scene.sprite(at);
    final look = sp?.look(_run.state(at!));
    final key = ++_burstKey;
    _bursts.add(BurstMark(key, word, look?.x ?? .5, look == null ? .4 : (look.y - look.h * .3).clamp(.15, .85)));
    Timer(Burst.length, () {
      if (mounted) setState(() => _bursts.removeWhere((b) => b.key == key));
    });
  }

  void _handle(Reply r) {
    if (r.res == Res.none || _finished) return;
    final s = _run.step;
    final snd = r.sfx;
    if (snd != null) sfx(ref, snd);
    final w = r.word;
    if (w != null) _burst(w, r.at);
    switch (r.res) {
      case Res.wrong:
        final at = r.at;
        if (at != null) _wiggles[at] = (_wiggles[at] ?? 0) + 1;
        _panelWiggle++;
        if (r.say != null) _say(r.say!);
      case Res.progress:
        if (r.say != null) _say(r.say!);
      case Res.done:
        final parts = s is ChooseStep ? [r.say ?? s.done] : [r.say, s?.done];
        final text = parts.whereType<String>().join(' ');
        if (text.isNotEmpty) _say(text);
        final ms = (900 + 170 * text.length).clamp(1500, 6500) * LevelScreen.pace;
        _next = Timer(Duration(milliseconds: ms.round()), _advance);
      case Res.none:
        break;
    }
    setState(() {});
  }

  void _advance() {
    if (!mounted) return;
    _run.next();
    if (_run.finished) {
      _finish();
      return;
    }
    setState(() {});
    _startStep();
  }

  void _finish() {
    final before = ref.read(gameProvider).crests.contains(lv.world);
    ref.read(gameProvider.notifier).change((g) => g.finished(lv));
    _crest = !before && ref.read(gameProvider).crests.contains(lv.world);
    sfx(ref, 'badge');
    setState(() => _finished = true);
    final line = [Strings.wellDone, Strings.gotBadge(lv.zh), if (_crest) Strings.gotCrest(lv.world.helper.zh), lv.real].join(' ');
    speak(ref, line);
  }

  void _again() {
    _next?.cancel();
    setState(_begin);
    _startStep();
  }

  Lv? get _nextLevel {
    final s = ref.read(gameProvider).settings;
    final list = lv.world.levels;
    for (var i = list.indexOf(lv) + 1; i < list.length; i++) {
      if (s.open(list[i])) return list[i];
    }
    return null;
  }

  // -------------------------------------------------- finger moves
  void _tapIds(List<String> ids) {
    for (final id in ids) {
      final r = _run.tap(id);
      if (r.res != Res.none) {
        _handle(r);
        return;
      }
    }
  }

  void _drop(String item, List<String> zones) {
    for (final z in zones) {
      final r = _run.drop(item, z);
      if (r.res != Res.none) {
        _handle(r);
        return;
      }
    }
    sfx(ref, 'pop');
    setState(() {});
  }

  void _tooHigh(String item) {
    final s = _run.step;
    if (s is DragStep) _handle(Reply(Res.wrong, say: s.ceilingSay, sfx: 'try', at: item));
  }

  @override
  Widget build(BuildContext context) {
    final w = lv.world;
    final g = ref.watch(gameProvider);
    final small = g.settings.age == Age.small;
    final glow = {..._run.guides, if (small) ..._run.hints};
    final s = _run.step;
    return WithMusic(
      music: musicOf(w),
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            TopBar(title: lv.zh, color: Color(w.color), onBack: () => context.go('/world?w=${w.name}'), onSpeak: () => speak(ref, _line)),
            Expanded(
              child: LayoutBuilder(builder: (context, box) {
                final width = math.min(box.maxWidth, 720.0);
                if (_finished) return Center(child: SizedBox(width: width, child: _Done(lv: lv, crest: _crest, next: _nextLevel, onAgain: _again)));
                return Center(
                  child: SizedBox(
                    width: width,
                    child: ListView(padding: const EdgeInsets.fromLTRB(12, 10, 12, 12), children: [
                      _Dots(done: _run.behind, total: _run.total, color: Color(w.color)),
                      const SizedBox(height: 6),
                      SceneView(
                        scene: _run.scene,
                        states: _run.states,
                        glow: glow,
                        bursts: _bursts,
                        wiggles: _wiggles,
                        canDrag: _run.canDrag,
                        allowed: (item, y) => s is! DragStep || s.item != item || s.allowed(y),
                        onTap: _tapIds,
                        onDrop: _drop,
                        onPick: (id) {
                          sfx(ref, 'pop');
                          final zh = _run.scene.sprite(id)?.zh;
                          if (zh != null && id != 'hero') speak(ref, zh);
                        },
                        onTooHigh: _tooHigh,
                        holdTarget: s is HoldStep && !s.target.startsWith('btn:') && !_run.waiting ? s.target : null,
                        holdSeconds: s is HoldStep ? s.seconds : 3,
                        onHold: (secs) {
                          if (s is HoldStep) _handle(_run.hold(s.target, secs));
                        },
                      ),
                      const SizedBox(height: 10),
                      StepPanel(
                        run: _run,
                        glow: glow,
                        wiggle: _panelWiggle,
                        onTap: (id) => _handle(_run.tap(id)),
                        onChoose: (id) => _handle(_run.choose(id)),
                        onKey: (d) {
                          final r = _run.key(d);
                          if (r.res == Res.progress) speak(ref, spokenDigits(d));
                          _handle(r);
                        },
                        onHold: (id, secs) => _handle(_run.hold(id, secs)),
                        onSaid: () => _handle(_run.said()),
                      ),
                      const SizedBox(height: 10),
                      SpeechBubble(key: const ValueKey('bubble'), text: _line, helper: w.helper.art(), onTap: () => speak(ref, _line)),
                    ]),
                  ),
                );
              }),
            ),
          ]),
        ),
      ),
    );
  }
}

/// How far along the level is: a dot per step.
class _Dots extends StatelessWidget {
  const _Dots({required this.done, required this.total, required this.color});

  final int done, total;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(color: i < done ? color : Colors.white, shape: BoxShape.circle, border: Border.all(color: Comic.ink, width: 2)),
          ),
      ]);
}

/// The end of a level: 做得好, the badge onto the helmet, the parent's
/// question card and the real-life line.
class _Done extends ConsumerStatefulWidget {
  const _Done({required this.lv, required this.crest, required this.next, required this.onAgain});

  final Lv lv;
  final bool crest;
  final Lv? next;
  final VoidCallback onAgain;

  @override
  ConsumerState<_Done> createState() => _DoneState();
}

class _DoneState extends ConsumerState<_Done> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _card(String title, String body, Color color, IconData icon) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: comicBox(color),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, color: Comic.ink, size: 20), const SizedBox(width: 6), Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Comic.inkSoft))]),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.4)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final lv = widget.lv;
    final helper = lv.world.helper;
    return ListView(padding: const EdgeInsets.fromLTRB(14, 10, 14, 20), children: [
      const Center(child: ComicText(Strings.wellDone, size: 40, color: Comic.yellow)),
      SizedBox(
        height: 190,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 110, child: Art(helper.art('salute'))),
          SizedBox(
            width: 170,
            height: 190,
            child: Stack(alignment: Alignment.center, children: [
              const Positioned.fill(child: HeroArt('wave')),
              AnimatedBuilder(
                animation: _c,
                builder: (_, child) {
                  final t = Curves.easeInOutBack.transform(_c.value);
                  return Transform.translate(offset: Offset(90 * (1 - t), -60 + 60 * (1 - t) - 26 * t), child: Transform.scale(scale: 1.8 - .9 * t, child: child));
                },
                child: SizedBox(key: const ValueKey('done-badge'), width: 54, height: 54, child: Art(widget.crest ? lv.world.crest : lv.badge)),
              ),
            ]),
          ),
        ]),
      ),
      Center(child: Text(widget.crest ? Strings.gotCrest(helper.zh) : Strings.gotBadge(lv.zh), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
      const SizedBox(height: 12),
      _card(Strings.forParent, lv.ask, const Color(0xFFFFF4DC), Icons.chat_bubble_outline_rounded),
      const SizedBox(height: 10),
      _card(Strings.realLife, lv.real, const Color(0xFFE3F4E6), Icons.directions_walk_rounded),
      const SizedBox(height: 16),
      Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 10, children: [
        ComicButton(label: Strings.playAgain, icon: Icons.replay_rounded, color: Colors.white, onTap: widget.onAgain),
        if (widget.next != null) ComicButton(label: Strings.nextLevel, icon: Icons.arrow_forward_rounded, onTap: () => context.go('/level?lv=${widget.next!.name}')),
        ComicButton(label: Strings.toWorld, icon: Icons.map_rounded, color: Color(lv.world.color), onTap: () => context.go('/world?w=${lv.world.name}')),
      ]),
    ]);
  }
}
