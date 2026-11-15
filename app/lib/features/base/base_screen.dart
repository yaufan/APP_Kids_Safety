import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/hero_art.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/content.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';
import '../parent/parent_gate.dart';

/// 小隊基地 (docs/design.md 「畫面」 1): the squad member and the helpers at
/// the top, the four world signs, the helmet with its badges, and a small
/// parent button.
class BaseScreen extends ConsumerStatefulWidget {
  const BaseScreen({super.key});

  /// The welcome is said once per app start.
  static var welcomed = false;

  @override
  ConsumerState<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends ConsumerState<BaseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || BaseScreen.welcomed) return;
      BaseScreen.welcomed = true;
      speak(ref, Strings.hello(ref.read(gameProvider).hero.callName));
    });
  }

  void _world(World w) {
    sfx(ref, 'whoosh');
    context.go('/world?w=${w.name}');
  }

  Future<void> _parent() async {
    if (!await showParentGate(context) || !mounted) return;
    context.go('/parent');
  }

  @override
  Widget build(BuildContext context) {
    final g = ref.watch(gameProvider);
    final worlds = [for (final w in World.values) if (g.settings.shows(w)) w];
    return WithMusic(
      music: Music.base,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(builder: (context, box) {
            final w = math.min(box.maxWidth, 640.0);
            final headH = math.min(box.maxHeight * .36, w * .62);
            return Center(
              child: SizedBox(
                width: w,
                child: Column(children: [
                  SizedBox(
                    height: headH,
                    child: Stack(children: [
                      const Positioned.fill(child: Art('ui/base_bg', fit: BoxFit.cover)),
                      Positioned(left: 0, right: 0, top: 6, child: Column(children: [
                        const ComicText(Strings.appName, size: 34),
                        Text(Strings.member(g.hero.callName), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Comic.ink)),
                      ])),
                      Positioned(
                        left: w * .3,
                        width: w * .4,
                        bottom: 4,
                        height: headH * .62,
                        child: Semantics(
                          container: true,
                          button: true,
                          label: g.hero.callName,
                          excludeSemantics: true,
                          onTap: () => speak(ref, Strings.hello(g.hero.callName)),
                          child: Pressable(onTap: () => speak(ref, Strings.hello(g.hero.callName)), sound: 'pop', child: const Bob(amount: 2, child: HeroArt('wave'))),
                        ),
                      ),
                      Positioned(left: w * .03, bottom: 4, width: w * .2, height: headH * .5, child: Art(Helper.dog.art())),
                      Positioned(left: w * .2, bottom: 4, width: w * .16, height: headH * .4, child: Art(Helper.cat.art())),
                      Positioned(right: w * .03, bottom: 4, width: w * .18, height: headH * .46, child: Art(Helper.bunny.art())),
                    ]),
                  ),
                  Container(height: 6, decoration: const BoxDecoration(color: Comic.ink)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.15,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [for (final wd in worlds) _WorldCard(world: wd, onTap: () => _world(wd))],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Row(children: [
                      Expanded(
                        child: Semantics(
                          container: true,
                          button: true,
                          label: Strings.helmet,
                          excludeSemantics: true,
                          onTap: () => context.go('/helmet'),
                          child: Pressable(
                            onTap: () => context.go('/helmet'),
                            child: Container(
                              height: 64,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: comicBox(Colors.white),
                              child: Row(children: [
                                const SizedBox(width: 44, height: 40, child: Art('ui/helmet_hook')),
                                const SizedBox(width: 10),
                                Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text(Strings.helmet, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                  Text(Strings.badgeCount(g.badges.length, Lv.values.length), style: const TextStyle(fontSize: 14, color: Comic.inkSoft)),
                                ]),
                              ]),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Semantics(
                        container: true,
                        button: true,
                        label: Strings.parent,
                        excludeSemantics: true,
                        onTap: _parent,
                        child: Pressable(
                          onTap: _parent,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: comicBox(Comic.grey, shadow: false),
                            child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.lock_outline_rounded, color: Comic.inkSoft, size: 24),
                              Text(Strings.parent, style: TextStyle(fontSize: 12, color: Comic.inkSoft)),
                            ]),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _WorldCard extends ConsumerWidget {
  const _WorldCard({required this.world, required this.onTap});

  final World world;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(gameProvider);
    final done = world.levels.where(g.done).length;
    return Semantics(
      key: ValueKey('world-${world.name}'),
      container: true,
      button: true,
      label: world.zh,
      excludeSemantics: true,
      onTap: onTap,
      child: Pressable(
        onTap: onTap,
        sound: null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          decoration: comicBox(Colors.white),
          child: Column(children: [
            Expanded(
              child: Stack(children: [
                Positioned.fill(child: Art(world.sign)),
                Positioned(right: 0, bottom: 0, width: 40, height: 52, child: Art(world.helper.art())),
              ]),
            ),
            const SizedBox(height: 4),
            Text(world.zh, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            Text('$done／${world.levels.length}', style: TextStyle(fontSize: 13, color: Color(world.color))),
          ]),
        ),
      ),
    );
  }
}
