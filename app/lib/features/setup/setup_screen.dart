import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/hero_art.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/game.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';

/// The first start (and 「換樣子」 in parent mode): the child picks a hair
/// style, a skin and a helmet colour for their squad member.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  late HeroLook _look = ref.read(gameProvider).hero;

  static const hairZh = ['短髮', '馬尾', '雙辮', '捲髮'];
  static const skinZh = ['膚色一', '膚色二', '膚色三', '膚色四'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) speak(ref, Strings.setupSay);
    });
  }

  void _pick(HeroLook l) {
    sfx(ref, 'pop');
    setState(() => _look = l);
  }

  void _go() {
    sfx(ref, 'cheer');
    ref.read(gameProvider.notifier).change((g) => g.copyWith(hero: _look.copyWith(made: true)));
    context.go('/');
  }

  Widget _row(String title, List<Widget> items) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 10, children: items),
        ]),
      );

  Widget _choice(String label, bool on, VoidCallback tap, Widget child) => Semantics(
        key: ValueKey('setup-$label'),
        container: true,
        button: true,
        selected: on,
        label: label,
        excludeSemantics: true,
        onTap: tap,
        child: Pressable(
          onTap: tap,
          sound: null,
          child: Container(width: 66, height: 66, padding: const EdgeInsets.all(5), decoration: comicBox(Colors.white, radius: 16, ring: on ? Comic.blue : null, shadow: false), child: child),
        ),
      );

  @override
  Widget build(BuildContext context) => WithMusic(
        music: Music.base,
        child: Scaffold(
          body: SafeArea(
            child: LayoutBuilder(builder: (context, box) {
              final w = math.min(box.maxWidth, 620.0);
              return Center(
                child: SizedBox(
                  width: w,
                  child: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 24), children: [
                    const Center(child: ComicText(Strings.setupTitle, size: 30, color: Comic.yellow)),
                    SizedBox(height: math.min(box.maxHeight * .3, 260), child: Bob(amount: 3, child: HeroArt('wave', look: _look))),
                    _row(Strings.hair, [
                      for (var i = 0; i < HeroLook.hairs; i++)
                        _choice(hairZh[i], _look.hair == i, () => _pick(_look.copyWith(hair: i)), ClipRect(child: Align(alignment: Alignment.topCenter, heightFactor: .62, child: HeroArt('bare', look: _look.copyWith(hair: i))))),
                    ]),
                    _row(Strings.skin, [
                      for (var i = 0; i < HeroLook.skins; i++)
                        _choice(skinZh[i], _look.skin == i, () => _pick(_look.copyWith(skin: i)), Container(decoration: BoxDecoration(color: Color(HeroLook.skinColors[i]), shape: BoxShape.circle, border: Border.all(color: Comic.ink, width: 2)))),
                    ]),
                    _row(Strings.helmetColor, [
                      for (var i = 0; i < HeroLook.helmets; i++)
                        _choice('${HeroLook.helmetZh[i]}安全帽', _look.helmet == i, () => _pick(_look.copyWith(helmet: i)), ClipRect(child: Align(alignment: Alignment.topCenter, heightFactor: .5, child: HeroArt('stand', look: _look.copyWith(helmet: i))))),
                    ]),
                    const SizedBox(height: 22),
                    Center(child: ComicButton(label: Strings.go, onTap: _go, icon: Icons.flag_rounded, height: 64, glow: true, sound: null)),
                  ]),
                ),
              );
            }),
          ),
        ),
      );
}
