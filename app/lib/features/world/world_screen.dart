import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/content.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';

/// The music of each world.
Music musicOf(World w) => switch (w) {
      World.road => Music.road,
      World.rescue => Music.rescue,
      World.body => Music.body,
      World.home => Music.home,
    };

/// A world (docs/design.md 「畫面」 2): its levels as road-sign cards along a
/// road; the next one bobs; the helper says what it is about.
class WorldScreen extends ConsumerStatefulWidget {
  const WorldScreen({super.key, required this.world});

  final World world;

  @override
  ConsumerState<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends ConsumerState<WorldScreen> {
  late String _line = Strings.worldHello(widget.world.helper.zh, widget.world.zh);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) speak(ref, _line);
    });
  }

  void _open(Lv lv) {
    final s = ref.read(gameProvider).settings;
    if (!s.open(lv)) {
      sfx(ref, 'try');
      setState(() => _line = Strings.locked);
      speak(ref, Strings.locked);
      return;
    }
    sfx(ref, 'whoosh');
    context.go('/level?lv=${lv.name}');
  }

  @override
  Widget build(BuildContext context) {
    final g = ref.watch(gameProvider);
    final w = widget.world;
    final next = g.nextIn(w);
    return WithMusic(
      music: musicOf(w),
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            TopBar(title: w.zh, color: Color(w.color), onBack: () => context.go('/'), homeIcon: true, onSpeak: () => speak(ref, _line)),
            Expanded(
              child: LayoutBuilder(builder: (context, box) {
                final width = math.min(box.maxWidth, 640.0);
                return Center(
                  child: SizedBox(
                    width: width,
                    child: ListView(padding: const EdgeInsets.fromLTRB(14, 12, 14, 20), children: [
                      SpeechBubble(text: _line, helper: w.helper.art(), onTap: () => speak(ref, _line)),
                      const SizedBox(height: 10),
                      for (final (i, lv) in w.levels.indexed)
                        Padding(
                          padding: EdgeInsets.only(left: i.isEven ? 0 : width * .12, right: i.isEven ? width * .12 : 0, bottom: 12),
                          child: _LevelCard(lv: lv, done: g.done(lv), open: g.settings.open(lv), next: lv == next, onTap: () => _open(lv)),
                        ),
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

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.lv, required this.done, required this.open, required this.next, required this.onTap});

  final Lv lv;
  final bool done, open, next;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(10),
      decoration: comicBox(open ? Colors.white : const Color(0xFFE4E8EE)),
      child: Row(children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(children: [
            Positioned.fill(child: Opacity(opacity: done ? 1 : .45, child: Art(lv.badge))),
            if (done) const Positioned(right: 0, bottom: 0, child: Icon(Icons.check_circle_rounded, color: Comic.green, size: 26)),
            if (!open) const Positioned(right: 0, bottom: 0, child: Icon(Icons.lock_rounded, color: Comic.inkSoft, size: 24)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lv.zh, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(lv.learn, style: const TextStyle(fontSize: 14, color: Comic.inkSoft)),
          ]),
        ),
        Icon(Icons.play_circle_fill_rounded, color: open ? Color(lv.world.color) : Comic.grey, size: 40),
      ]),
    );
    return Semantics(
      key: ValueKey('level-${lv.name}'),
      container: true,
      button: true,
      label: lv.zh,
      excludeSemantics: true,
      onTap: onTap,
      child: Pressable(onTap: onTap, sound: null, child: next && open ? Bob(amount: 3, period: 1400, child: card) : card),
    );
  }
}
