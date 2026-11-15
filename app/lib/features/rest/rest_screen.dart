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
import '../parent/parent_gate.dart';

/// The play time is up (docs/design.md 「每次玩多久」): the helpers are back at
/// the base resting, the helmet is hung up, and the child is sent to try
/// it for real. Only a parent (through the gate) or an hour's wait lets play
/// go on.
class RestScreen extends ConsumerStatefulWidget {
  const RestScreen({super.key});

  @override
  ConsumerState<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends ConsumerState<RestScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      sfx(ref, 'night');
      speak(ref, '${Strings.restTitle}${Strings.restLine}');
    });
  }

  Future<void> _parent() async {
    if (!await showParentGate(context) || !mounted) return;
    ref.read(gameProvider.notifier).change((g) => g.playOn());
    ref.read(sessionStartProvider.notifier).restart();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) => WithMusic(
        music: Music.rest,
        child: Scaffold(
          backgroundColor: const Color(0xFFE6ECF5),
          body: SafeArea(
            child: LayoutBuilder(builder: (context, box) {
              final w = math.min(box.maxWidth, 560.0);
              return Center(
                child: SizedBox(
                  width: w,
                  child: Column(children: [
                    const SizedBox(height: 18),
                    const ComicText(Strings.restTitle, size: 32, color: Comic.yellow),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: comicBox(Colors.white),
                        child: const Text(Strings.restLine, textAlign: TextAlign.center, style: TextStyle(fontSize: 21, height: 1.5, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    Expanded(
                      child: Stack(children: [
                        Positioned(left: w * .38, top: 20, width: w * .24, height: w * .24, child: const Art('ui/helmet_hook')),
                        Positioned(left: w * .04, right: w * .04, bottom: 0, height: w * .5, child: const Art('ui/base_bg', fit: BoxFit.cover)),
                        for (final (i, h) in Helper.values.indexed)
                          Positioned(left: w * (.12 + i * .27), bottom: 8, width: w * .22, height: w * .3, child: Bob(amount: 1.5, period: 3600, phase: i * .3, child: Art(h.art()))),
                      ]),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 18, 14),
                        child: ComicButton(label: Strings.parent, icon: Icons.lock_outline_rounded, color: Comic.grey, height: 48, onTap: _parent),
                      ),
                    ),
                  ]),
                ),
              );
            }),
          ),
        ),
      );
}
