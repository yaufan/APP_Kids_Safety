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

/// 安全小勇士 (docs/design.md 「畫面」 5): the helmet with a badge for every
/// level done, the worlds' crests, and the gold real-life badges.
class HelmetScreen extends ConsumerStatefulWidget {
  const HelmetScreen({super.key});

  @override
  ConsumerState<HelmetScreen> createState() => _HelmetScreenState();
}

class _HelmetScreenState extends ConsumerState<HelmetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) speak(ref, Strings.helmetSay);
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = ref.watch(gameProvider);
    return WithMusic(
      music: Music.base,
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            TopBar(title: Strings.helmetTitle, color: Comic.yellow, onBack: () => context.go('/'), homeIcon: true, onSpeak: () => speak(ref, Strings.helmetSay)),
            Expanded(
              child: LayoutBuilder(builder: (context, box) {
                final w = math.min(box.maxWidth, 620.0);
                final hw = w - 40;
                return Center(
                  child: SizedBox(
                    width: w,
                    child: ListView(padding: const EdgeInsets.all(20), children: [
                      SizedBox(
                        width: hw,
                        height: hw * .7,
                        child: Stack(children: [
                          const Positioned.fill(child: Art('ui/helmet_board')),
                          // the badges, in rows on the dome
                          for (final (i, lv) in Lv.values.indexed)
                            if (g.done(lv))
                              Positioned(
                                key: ValueKey('helmet-${lv.name}'),
                                left: hw * (.5 + _spot(i).$1) - hw * .055,
                                top: hw * .7 * _spot(i).$2 - hw * .055,
                                width: hw * .11,
                                height: hw * .11,
                                child: Art(lv.badge),
                              ),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      Text(Strings.badgeCount(g.badges.length, Lv.values.length), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      const Text(Strings.crests, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                        for (final wd in World.values)
                          Column(children: [
                            SizedBox(width: 62, height: 68, child: Opacity(opacity: g.crests.contains(wd) ? 1 : .2, child: Art(wd.crest))),
                            Text(wd.zh, style: const TextStyle(fontSize: 13, color: Comic.inkSoft)),
                          ]),
                      ]),
                      const SizedBox(height: 18),
                      const Text(Strings.gold, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      const Text(Strings.goldNote, style: TextStyle(fontSize: 14, color: Comic.inkSoft)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        for (final r in RealLife.values)
                          if (g.real.contains(r))
                            Container(
                              key: ValueKey('gold-${r.name}'),
                              width: 170,
                              padding: const EdgeInsets.all(8),
                              decoration: comicBox(const Color(0xFFFFF4DC), radius: 14, shadow: false),
                              child: Row(children: [
                                const SizedBox(width: 40, height: 40, child: Art('badges/gold')),
                                const SizedBox(width: 6),
                                Expanded(child: Text(r.zh, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                              ]),
                            ),
                      ]),
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

  /// Where the i-th badge sits on the helmet: x from the middle, y from the
  /// top, as shares of the helmet picture (rows of 3, 4, 4, 3).
  static (double, double) _spot(int i) {
    const rows = [3, 4, 4, 3];
    const ys = [.26, .44, .62, .8];
    var r = 0, k = i;
    while (k >= rows[r]) {
      k -= rows[r];
      r++;
    }
    return ((k - (rows[r] - 1) / 2) * [.18, .17, .17, .17][r], ys[r]);
  }
}
