import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/content.dart';
import '../../core/providers.dart';

/// The page for the parent before 身體世界 (docs/design.md 「身體世界」):
/// what it teaches, how to play it together, and that it can be turned off.
/// 「我看過了」 opens the world.
class BodyIntroScreen extends ConsumerWidget {
  const BodyIntroScreen({super.key, this.lv});

  /// The level the child was going to (opened after 「我看過了」).
  final Lv? lv;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Theme(
        data: Theme.of(context).copyWith(scaffoldBackgroundColor: Comic.parentBg),
        child: Scaffold(
          body: SafeArea(
            child: LayoutBuilder(builder: (context, box) {
              final w = math.min(box.maxWidth, 620.0);
              return Center(
                child: SizedBox(
                  width: w,
                  child: ListView(padding: const EdgeInsets.all(20), children: [
                    Row(children: [
                      const SizedBox(width: 70, height: 90, child: Art('helpers/bunny_stand')),
                      const SizedBox(width: 10),
                      const Expanded(child: Text(Strings.introTitle, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Comic.parentInk))),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        for (final p in Strings.introParas) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(p, style: const TextStyle(fontSize: 16, height: 1.6, color: Comic.parentInk))),
                      ]),
                    ),
                    const SizedBox(height: 18),
                    ComicButton(
                      label: Strings.introOk,
                      color: Comic.green,
                      expand: true,
                      onTap: () {
                        ref.read(gameProvider.notifier).settings((s) => s.copyWith(bodyIntroSeen: true));
                        context.go(lv == null ? '/world?w=body' : '/level?lv=${lv!.name}');
                      },
                    ),
                    const SizedBox(height: 12),
                    ComicButton(label: Strings.introLater, color: Colors.white, expand: true, onTap: () => context.go('/')),
                  ]),
                ),
              );
            }),
          ),
        ),
      );
}
