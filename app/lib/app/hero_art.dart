import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/game.dart';
import '../core/providers.dart';

/// The squad member in a pose, in the child's own look: assets/art/hero/
/// `<pose>_h<hair>.svg` is drawn with stand-in colours (design/art/kit.py:
/// helmet #FEC401, its dots #FEC402, skin #F6D3B1) that are swapped here.
class HeroArt extends ConsumerWidget {
  const HeroArt(this.pose, {super.key, this.look, this.flip = false, this.fit = BoxFit.contain});

  final String pose;

  /// Another look than the saved one (the first-start picker).
  final HeroLook? look;
  final bool flip;
  final BoxFit fit;

  static final _raw = <String, Future<String>>{};

  static String hex(int argb) => '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  /// [argb] mixed [t] of the way to black (the halftone dots' colour).
  static int darker(int argb, double t) {
    int ch(int shift) => (((argb >> shift) & 0xFF) * (1 - t)).round();
    return 0xFF000000 | ch(16) << 16 | ch(8) << 8 | ch(0);
  }

  /// The SVG text in [look]'s colours.
  static String colour(String svg, HeroLook look) {
    final helmet = HeroLook.helmetColors[look.helmet];
    return svg
        .replaceAll('#FEC401', hex(helmet))
        .replaceAll('#FEC402', hex(darker(helmet, .45)))
        .replaceAll('#F6D3B1', hex(HeroLook.skinColors[look.skin]));
  }

  static String file(String pose, HeroLook look) => 'assets/art/hero/${pose}_h${look.hair}.svg';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HeroLook l = look ?? ref.watch(gameProvider.select((g) => g.hero));
    final path = file(pose, l);
    final bundle = DefaultAssetBundle.of(context);
    final f = _raw.putIfAbsent(path, () => bundle.loadString(path));
    final child = FutureBuilder<String>(
      future: f,
      builder: (_, snap) {
        final raw = snap.data;
        if (raw == null) return const SizedBox.expand();
        return SvgPicture.string(colour(raw, l), fit: fit, excludeFromSemantics: true);
      },
    );
    return flip ? Transform.flip(flipX: true, child: child) : child;
  }
}
