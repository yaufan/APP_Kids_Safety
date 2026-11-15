import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:safety_team/core/content.dart';
import 'package:safety_team/core/game.dart';
import 'package:safety_team/core/levels.dart';
import 'package:safety_team/core/sounds.dart';
import 'package:safety_team/core/steps.dart';

/// Every picture and sound the program asks for exists (docs/art.md,
/// design/sounds/README.md), and no picture uses what flutter_svg cannot draw.
void main() {
  bool has(String path) => File('assets/art/$path.svg').existsSync();
  final parts = [
    for (final lv in Lv.values)
      for (final a in Age.values)
        for (final phone in ['', '0912345678']) ...levelParts(lv, Settings(age: a, phone: phone), const HeroLook()),
  ];

  /// assets/art paths for a picture name (`@hero/x` is four files, one per hair style).
  List<String> files(String art) => art.startsWith('@hero/') ? [for (var h = 0; h < HeroLook.hairs; h++) 'hero/${art.substring(6)}_h$h'] : [art];

  test('every picture in every level is drawn', () {
    final wanted = <String>{};
    for (final p in parts) {
      wanted.add(p.scene.bg);
      for (final s in p.scene.sprites) {
        for (final st in s.states) {
          final a = s.look(st).art;
          if (a != null) wanted.addAll(files(a));
        }
      }
      for (final st in p.steps) {
        final qs = [if (st is ChooseStep) st, if (st is FindStep) ...[for (final h in st.hazards) ?h.why]];
        for (final q in qs) {
          for (final o in q.options) {
            if (o.art != null) wanted.addAll(files(o.art!));
          }
        }
      }
    }
    expect([for (final p in wanted) if (!has(p)) p], isEmpty, reason: 'draw these in design/art/');
  });

  test('every picture the screens ask for is drawn', () {
    final wanted = [
      for (final w in World.values) ...[w.sign, w.crest, w.helper.art(), w.helper.art('salute')],
      for (final lv in Lv.values) lv.badge,
      for (final a in Adult.values) a.art,
      'helpers/dog_stop', 'helpers/cat_phone', 'badges/gold', 'ui/base_bg', 'ui/helmet_board', 'ui/helmet_hook', 'ui/arrow_l', 'ui/arrow_r',
      'fx/burst', 'fx/burst_yellow', 'fx/speed', 'body/light_green', 'body/light_yellow', 'body/light_red',
      for (final p in ['stand', 'wave', 'bare']) ...files('@hero/$p'),
    ];
    expect([for (final p in wanted) if (!has(p)) p], isEmpty);
  });

  test('the squad member is drawn with the stand-in colours the app swaps', () {
    for (final f in Directory('assets/art/hero').listSync().whereType<File>()) {
      final t = f.readAsStringSync();
      expect(t, contains('#F6D3B1'), reason: '${f.path}: the skin');
      if (!f.path.contains('swim') && !f.path.contains('bare')) expect(t, contains('#FEC401'), reason: '${f.path}: the helmet');
    }
  });

  test('every thing in a picture stays mostly inside it', () {
    for (final p in parts) {
      for (final s in p.scene.sprites) {
        for (final st in s.states) {
          final l = s.look(st);
          if (l.exit || l.jump) continue;
          expect(l.x, inInclusiveRange(-.05, 1.05), reason: '${p.scene.bg} ${s.id} $st');
          expect(l.y, inInclusiveRange(0, 1), reason: '${p.scene.bg} ${s.id} $st');
          expect(l.w * l.h, greaterThan(0), reason: '${s.id}: big enough to tap');
          expect(l.w, greaterThanOrEqualTo(.06), reason: '${p.scene.bg} ${s.id}: big enough for a small finger');
        }
      }
    }
  });

  test('no picture uses what flutter_svg cannot draw, and none is too big', () {
    final bad = <String>[];
    var n = 0;
    for (final f in Directory('assets/art').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.svg')) continue;
      n++;
      final text = f.readAsStringSync();
      if (f.lengthSync() > 70 * 1024) bad.add('${f.path} too big');
      for (final no in ['<filter', '<mask', '<style', 'style=', '<text', '<image', '<pattern', 'mix-blend']) {
        if (text.contains(no)) bad.add('${f.path} uses $no');
      }
      for (final m in RegExp(r'clip-path="url\(#(\w+)\)"').allMatches(text)) {
        if (!text.contains('<clipPath id="${m[1]}">')) bad.add('${f.path}: no clipPath ${m[1]}');
      }
      if (!text.trimRight().endsWith('</svg>')) bad.add('${f.path} is cut off');
    }
    expect(n, greaterThan(200));
    expect(bad, isEmpty);
  });

  test('every sound the app plays is there', () {
    final names = <String>{
      'tap', 'pop', 'right', 'try', 'cheer', 'found', 'badge', 'whoosh', 'night', 'ring', 'fill',
      for (var d = 0; d <= 9; d++) 'key_$d',
      for (final m in Music.values) m.file,
    };
    for (final p in parts) {
      for (final s in p.steps) {
        names.add(s.sfx);
        if (s.startSfx != null) names.add(s.startSfx!);
        if (s is HoldStep && s.loopSfx != null) names.add(s.loopSfx!);
        if (s is DragStep) names.add(s.dropSfx);
      }
    }
    expect([for (final s in names) if (!File('assets/sounds/$s.wav').existsSync()) s], isEmpty);
  });
}
