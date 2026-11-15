import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:safety_team/core/content.dart';
import 'package:safety_team/core/game.dart';
import 'package:safety_team/core/levels.dart';
import 'package:safety_team/core/run.dart';
import 'package:safety_team/core/steps.dart';
import 'package:safety_team/features/parent/parent_gate.dart';

import 'helpers.dart';

/// A child (and a parent) playing 安全小隊 through every world, on a phone
/// and a tablet, with screenshots in `build/screenshots/<device>/`. The
/// phone plays 馬路 and 救災 at 小小 and 身體 and 家裡 at 大; the tablet
/// the other way round.
void main() {
  setUpAll(loadFonts);

  for (final MapEntry(key: device, value: (size, ratio)) in {'phone': (const Size(1080, 2340), 2.75), 'tablet': (const Size(1620, 2160), 2.0)}.entries) {
    testWidgets('a whole squad mission ($device)', (tester) async {
      final app = await TestApp.start(tester, game: const Game(), size: size, ratio: ratio);
      final firstAge = device == 'phone' ? Age.small : Age.big;
      final laterAge = device == 'phone' ? Age.big : Age.small;
      Future<void> shot(String name) => shoot(tester, device, name);

      /// Plays the level on screen with each step's own answer (a twin run
      /// in pure Dart says what the next step wants); [at] takes screenshots
      /// when the step with that index (counted over the whole level) starts.
      Future<void> play(Lv lv, {Map<int, String> at = const {}, Future<void> Function(int i, Step s)? before}) async {
        app.go('/level?lv=${lv.name}');
        await app.settle(900);
        expect(app.location, '/level');
        final twin = LevelRun(levelParts(lv, app.game.settings, app.game.hero));
        var i = 0;
        while (!twin.finished) {
          final step = twin.step!;
          expect(app.voice.said.last, step.say, reason: '${lv.zh} step $i starts with its line');
          await before?.call(i, step);
          if (at[i] case final name?) await shot(name);
          for (final e in step.solve()) {
            twin.play(e);
            switch (e) {
              case Tap(:final id) when id.startsWith('btn:'):
                await app.tester.tap(find.byKey(ValueKey(step is SayStep ? 'say-${twin.part}-${twin.index}' : 'btn-$id')).last);
                await app.settle(300);
              case Tap(:final id) when id.startsWith('word:'):
                await app.tester.tap(find.byKey(ValueKey('word-${id.substring(5)}')));
                await app.settle(300);
              case Tap(:final id):
                await tapSprite(app, id, ms: 300);
              case Drop(:final item, :final zone):
                await dragSprite(app, item, zone, ms: 300);
              case Hold(:final id, :final seconds):
                final f = id.startsWith('btn:') ? find.bySemanticsLabel(id.substring(4)).last : find.byKey(ValueKey('sprite-$id'));
                await hold(app, f, (seconds * 1000).round() + 400);
                await app.settle(200);
              case KeyPress(:final digit):
                await app.tester.tap(find.byKey(ValueKey('key-$digit')));
                await app.settle(150);
              case Choose(:final id):
                await app.tester.tap(find.byKey(ValueKey('opt-$id')));
                await app.settle(300);
              case Said():
                await app.settle(3400);
            }
          }
          await app.settle(2600);
          twin.next();
          i++;
        }
        await app.settle(600);
        expect(app.game.done(lv), isTrue, reason: '${lv.zh} is finished');
        expect(find.text('做得好！'), findsWidgets);
        expect(app.sounds.played, contains('badge'));
      }

      // ------------------------------------------------ the first start
      expect(app.location, '/setup');
      expect(app.voice.said.last, '你是安全小隊的小隊員！選一選你的樣子。');
      await app.tapLabel('馬尾');
      await app.tapLabel('藍色安全帽');
      await shot('01_setup');
      await app.tapLabel('出發！', ms: 900);
      expect(app.location, '/');
      expect(app.game.hero.made, isTrue);
      expect(app.game.hero.helmet, 3);
      expect(app.game.hero.hair, 1);
      await app.settle(600);
      await shot('02_base');

      // ------------------------------------------------ a parent sets the phone number
      ParentPass.grant();
      app.go('/parent');
      await app.settle(800);
      expect(app.location, '/parent');
      await tester.enterText(find.byKey(const ValueKey('name')), '小明');
      await tester.enterText(find.byKey(const ValueKey('phone')), '0912-345-678');
      await app.settle();
      expect(app.game.settings.phone, '0912345678');
      expect(app.game.hero.name, '小明');
      await tester.ensureVisible(find.byKey(const ValueKey('trust-ama')));
      await app.settle();
      await tester.tap(find.byKey(const ValueKey('trust-ama')));
      await app.settle();
      expect(app.game.settings.trusted, [Adult.mom, Adult.dad, Adult.ama]);
      await shot('03_parent');
      app.change((g) => g.copyWith(settings: g.settings.copyWith(age: firstAge)));
      app.go('/');
      await app.settle(600);

      // ------------------------------------------------ 馬路世界
      await app.tapLabel('馬路世界', ms: 900);
      expect(app.location, '/world');
      expect(app.voice.said.last, contains('汪汪警察'));
      await shot('04_world_road');
      await play(Lv.light, at: {0: '05_light'}, before: (i, s) async {
        if (i == 0) {
          await tapSprite(app, 'hero');
          expect(app.voice.said.last, '紅燈，等一下。', reason: 'red light: the squad member waits');
          expect(app.sounds.played.last, 'try');
        }
      });
      await shot('06_done');
      await play(Lv.cross, at: {4: '07_cross'}, before: (i, s) async {
        if (i == 3 && firstAge == Age.small) {
          await app.tester.tap(find.byKey(const ValueKey('word-揮')));
          await app.settle(300);
          expect(app.voice.said.last, '先「探」：慢慢探頭。');
        }
      });
      expect(app.sounds.played, contains('chirp'));
      await play(Lv.hand, at: {1: '08_hand'});
      await play(Lv.car, at: {0: '09_car'});
      await play(Lv.lost, at: {2: '10_lost_phone'});
      expect(app.voice.said, contains('我媽媽的電話是零、九、一、二、三、四、五、六、七、八。'));
      expect(app.game.crests, [World.road]);
      await shot('11_road_crest');

      // ------------------------------------------------ 救災世界
      await play(Lv.quake, at: {0: '12_quake', 2: '13_quake_hold'});
      await play(Lv.fire, at: {2: '14_fire_crawl'}, before: (i, s) async {
        if (s is DragStep && s.item == 'hero') {
          // Standing up into the smoke: 「蹲低低」 and back down.
          final from = spriteAt(tester, 'hero');
          await dragFinger(app, from, Offset(from.dx + 40, spriteAt(tester, 'smoke').dy));
          await app.settle(300);
          expect(app.voice.said.last, '蹲低低，煙在上面喔。');
        }
        if (s is KeypadStep) await shot('15_fire_119');
      });
      await play(Lv.typhoon, at: {4: '16_typhoon_dark'});

      // ------------------------------------------------ 身體世界, with the parent's note first
      app.change((g) => g.copyWith(settings: g.settings.copyWith(age: laterAge)));
      app.go('/');
      await app.settle(500);
      await app.tapLabel('身體世界', ms: 900);
      await app.tapLabel('身體紅綠燈', ms: 900);
      expect(app.location, '/intro');
      await shot('17_body_intro');
      await app.tapLabel('我看過了，開始', ms: 900);
      expect(app.game.settings.bodyIntroSeen, isTrue);
      expect(app.location, '/level');
      await play(Lv.bodyLights, at: {0: '18_body_lights'}, before: (i, s) async {
        if (i == 0 && s is TapStep) {
          await tapSprite(app, 'swim');
          expect(app.voice.said.last, contains('泳衣遮住的地方是我自己的'));
          await shot('19_body_red');
        }
      });
      await play(Lv.sayNo, at: {0: '20_say_no'});
      expect(app.voice.said.where((l) => l.contains('阿嬤')), isNotEmpty, reason: 'the trusted grown-ups the parent chose');

      // ------------------------------------------------ 家裡世界
      await play(Lv.kitchen, at: {0: '21_kitchen'});
      await play(Lv.living);
      await play(Lv.bath, at: {0: '22_bath'});
      await play(Lv.balcony);
      expect(app.game.badges.length, 14);
      expect(app.game.crests, World.values);

      // ------------------------------------------------ the helmet, with a gold badge
      app.change((g) => g.tick(RealLife.cross, true));
      app.go('/helmet');
      await app.settle(900);
      expect(find.byKey(const ValueKey('gold-cross')), findsOneWidget);
      await shot('23_helmet');

      // ------------------------------------------------ the time runs out
      app.go('/');
      await app.settle(500);
      app.now = app.now.add(const Duration(minutes: 16));
      await app.settle(2600);
      expect(app.location, '/rest');
      expect(app.voice.said.last, contains('換你去真的地方做做看'));
      await shot('24_rest');
      await app.end();
    });
  }
}
