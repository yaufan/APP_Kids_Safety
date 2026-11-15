import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:safety_team/core/content.dart';
import 'package:safety_team/core/game.dart';
import 'package:safety_team/core/levels.dart';
import 'package:safety_team/core/run.dart';
import 'package:safety_team/core/scene.dart';
import 'package:safety_team/core/steps.dart';
import 'package:safety_team/core/store.dart';

/// The rules of the levels and the save file (docs/design.md).
void main() {
  const hero = HeroLook(name: '小明', made: true);
  Settings at(Age a, {String phone = '0912345678'}) => Settings(age: a, phone: phone);

  /// Plays [lv] through with each step's own answer; returns what was said.
  List<String> playThrough(Lv lv, Settings s) {
    final run = LevelRun(levelParts(lv, s, hero));
    final said = <String>[];
    var guard = 0;
    while (!run.finished) {
      final step = run.step!;
      said.add(step.say);
      final evs = step.solve();
      for (var i = 0; i < evs.length; i++) {
        final r = run.play(evs[i]);
        expect(r.res, isNot(Res.none), reason: '$lv ${run.part}/${run.index}: ${evs[i]} did nothing');
        expect(r.res, isNot(Res.wrong), reason: '$lv ${run.part}/${run.index}: ${evs[i]} was wrong (${r.say})');
        if (i == evs.length - 1) expect(r.res, Res.done, reason: '$lv ${run.part}/${run.index}: the last move finishes the step');
      }
      expect(run.waiting, isTrue);
      run.next();
      expect(++guard, lessThan(60));
    }
    expect(run.behind, run.total);
    return said;
  }

  group('every level', () {
    for (final lv in Lv.values) {
      for (final a in Age.values) {
        test('${lv.zh} can be played through at ${a.zh}', () => playThrough(lv, at(a)));
      }
    }

    test('everything a step points at is in its picture, and every state is known', () {
      for (final lv in Lv.values) {
        for (final a in Age.values) {
          for (final p in levelParts(lv, at(a), hero)) {
            final ids = {for (final s in p.scene.sprites) s.id};
            bool known(String id) => id.startsWith('btn:') || id.startsWith('word:') || ids.contains(id);
            void states(Map<String, String> m) {
              for (final e in m.entries) {
                if (e.key.startsWith('_')) {
                  expect(p.scene.flags.containsKey(e.key), isTrue, reason: '$lv ${e.key}');
                  continue;
                }
                expect(ids, contains(e.key), reason: '$lv: ${e.key}');
                expect(p.scene.sprite(e.key)!.states, contains(e.value), reason: '$lv: ${e.key} has no state ${e.value}');
              }
            }

            for (final st in p.steps) {
              states(st.before);
              states(st.after);
              switch (st) {
                case TapStep():
                  for (final t in [...st.targets, ...st.wrong.keys]) {
                    expect(known(t), isTrue, reason: '$lv: $t');
                  }
                  st.tapStates.values.forEach(states);
                case DragStep():
                  expect(ids, containsAll([st.item, st.to, ...st.wrong.keys]), reason: '$lv');
                  expect(p.scene.sprite(st.item)!.drag, isTrue, reason: '$lv: ${st.item} must be draggable');
                case HoldStep():
                  expect(known(st.target), isTrue, reason: '$lv: ${st.target}');
                case FindStep():
                  for (final h in st.hazards) {
                    expect(ids, contains(h.id), reason: '$lv');
                    expect(ids, containsAll(h.taps), reason: '$lv');
                    if (h.dragTo != null) {
                      expect(ids, contains(h.dragTo), reason: '$lv');
                      expect(p.scene.sprite(h.id)!.drag, isTrue, reason: '$lv: ${h.id} must be draggable');
                    }
                    states(h.safe);
                  }
                case ChooseStep():
                  expect(st.options.where((o) => o.ok), isNotEmpty, reason: '$lv: a right answer');
                  for (final o in st.options.where((o) => !o.ok)) {
                    expect(o.reply, isNotNull, reason: '$lv: a wrong card says why');
                  }
                case KeypadStep() || SayStep():
                  break;
              }
            }
          }
        }
      }
    });

    test('大 gets more 「為什麼」 questions than 小小 in every level', () {
      int questions(Lv lv, Age a) => levelParts(lv, at(a), hero).expand((p) => p.steps).where((s) => s is ChooseStep || (s is FindStep && s.askWhy)).length;
      for (final lv in Lv.values) {
        expect(questions(lv, Age.big), greaterThan(questions(lv, Age.small)), reason: '${lv.zh}: 大 asks why');
      }
    });

    test('there are 14 levels: 馬路 5, 救災 3, 身體 2, 家裡 4', () {
      expect(Lv.values.length, 14);
      expect([for (final w in World.values) w.levels.length], [5, 3, 2, 4]);
    });

    test('every level ends with a question for the parent and a real-life line', () {
      for (final lv in Lv.values) {
        expect(lv.ask, startsWith('問問小朋友'), reason: lv.zh);
        expect(lv.real, isNotEmpty);
      }
    });
  });

  group('過馬路五步', () {
    test('the five words come in the order 集轉探避揮, and a word out of order says which comes first', () {
      expect(crossWords.map((w) => w.$1).join(), '集轉探避揮');
      final run = LevelRun(levelParts(Lv.cross, at(Age.big), hero));
      expect(run.tap('word:探').res, Res.wrong);
      expect(run.tap('word:揮').say, '先「集」：停在路邊。');
      expect(run.tap('word:集').res, Res.done);
      run.next();
      expect(run.tap('word:避').say, '先「轉」：左看右看。');
      expect(run.tap('word:轉').res, Res.done);
    });

    test('the words are tapped in the order of the steps', () {
      final order = levelParts(Lv.cross, at(Age.small), hero).expand((p) => p.steps).whereType<TapStep>().expand((s) => s.targets).where((t) => t.startsWith('word:')).map((t) => t.substring(5)).join();
      expect(order, '集轉探避揮');
    });
  });

  group('the 119 keypad', () {
    LevelRun at119(Age a) {
      final run = LevelRun(levelParts(Lv.fire, at(a), hero));
      while (run.step is! KeypadStep) {
        for (final e in run.step!.solve()) {
          run.play(e);
        }
        run.next();
      }
      return run;
    }

    test('only 1, 1, 9 in that order calls', () {
      final run = at119(Age.small);
      expect((run.step as KeypadStep).digits, '119');
      for (final d in ['9', '0', '2']) {
        expect(run.key(d).res, Res.wrong);
      }
      expect(run.typed, 0, reason: 'a wrong key is not typed');
      expect(run.key('1').res, Res.progress);
      expect(run.key('9').res, Res.wrong);
      expect(run.key('1').res, Res.progress);
      expect(run.key('1').res, Res.wrong);
      expect(run.key('9').res, Res.done);
      expect(run.key('1').res, Res.none, reason: 'done');
    });

    test('小小 sees the next key light up, 大 does not', () {
      expect(at119(Age.small).hints, {'key:1'});
      expect(at119(Age.big).hints, isEmpty);
    });
  });

  group('走失了', () {
    test('the parent\'s number is practised digit by digit, and said with what the child calls them', () {
      final s = at(Age.small).copyWith(call: Adult.ama);
      final parts = levelParts(Lv.lost, s, hero);
      final pad = parts.expand((p) => p.steps).whereType<KeypadStep>().single;
      expect(pad.digits, '0912345678');
      expect(pad.lead, '我阿嬤的電話是');
      expect(pad.done, '我阿嬤的電話是零、九、一、二、三、四、五、六、七、八。');
      expect(pad.glow, isTrue);
      expect(levelParts(Lv.lost, at(Age.big), hero).expand((p) => p.steps).whereType<KeypadStep>().single.glow, isFalse);
    });

    test('without a number the keypad waits for a parent', () {
      final steps = levelParts(Lv.lost, at(Age.small, phone: ''), hero).expand((p) => p.steps).toList();
      expect(steps.whereType<KeypadStep>(), isEmpty);
      expect(steps.whereType<TapStep>().any((t) => t.say.contains('家長模式')), isTrue);
      playThrough(Lv.lost, at(Age.big, phone: ''));
    });

    test('a passer-by is not the one to ask; a uniform, a shop clerk or a mother with a child is', () {
      for (final who in ['dog', 'clerk', 'momkid']) {
        final run = LevelRun(levelParts(Lv.lost, at(Age.small), hero));
        run.tap('hero');
        run.next();
        expect(run.tap('passer').res, Res.wrong);
        expect(run.tap(who).res, Res.done, reason: who);
      }
    });

    test('「大聲說一次」 records nothing: it only waits after the tap', () {
      final say = levelParts(Lv.lost, at(Age.small), hero).last.steps.last as SayStep;
      expect(say.label, '大聲說一次');
      expect(say.solve(), [isA<Tap>(), isA<Said>()]);
    });
  });

  group('the other worlds', () {
    test('地震: dropping under the window or the shelf gets a word and no move; holding too short says hold on', () {
      final run = LevelRun(levelParts(Lv.quake, at(Age.small), hero));
      expect(run.state(SceneFlag.shake), 'on');
      expect(run.canDrag('hero'), isTrue);
      expect(run.drop('hero', 'window').say, contains('窗戶'));
      expect(run.state('hero'), 'start');
      expect(run.drop('hero', 'under').res, Res.done);
      run.next();
      run.tap('hero');
      run.next();
      expect(run.hold('leg', 1).res, Res.wrong);
      expect(run.hold('leg', 4).res, Res.done);
      expect(run.state(SceneFlag.shake), 'off', reason: 'the shaking stops');
    });

    test('火災: the finger must stay low, and the lift is not taken', () {
      final crawl = levelParts(Lv.fire, at(Age.small), hero).first.steps.whereType<DragStep>().firstWhere((d) => d.item == 'hero');
      expect(crawl.allowed(.3), isFalse);
      expect(crawl.allowed(.8), isTrue);
      final stairs = levelParts(Lv.fire, at(Age.small), hero)[1].steps.single as TapStep;
      expect(stairs.wrong['lift'], contains('不搭電梯'));
    });

    test('身體紅綠燈: swimsuit-covered is red, face and tummy yellow, hands, head and shoulders green', () {
      final lights = {for (final b in bodySpots) b.$1: b.$3};
      expect(lights, {'head': 'green', 'shoulder': 'green', 'hand': 'green', 'face': 'yellow', 'tummy': 'yellow', 'swim': 'red'});
      expect(bodySpots.firstWhere((b) => b.$1 == 'swim').$6, contains('不可以看、不可以摸'));
    });

    test('說「不要！」 is held, ends with the trusted grown-ups the parent chose, and respects the puppy\'s 不要', () {
      final s = at(Age.small).copyWith(trusted: [Adult.ama, Adult.teacher, Adult.dad]);
      final steps = levelParts(Lv.sayNo, s, hero).expand((p) => p.steps).toList();
      expect(steps.whereType<HoldStep>().length, 3);
      expect(steps.whereType<HoldStep>().every((h) => h.target == 'btn:不要！'), isTrue);
      final last = steps.last as TapStep;
      expect(last.extra, Extra.trusted);
      expect(last.say, contains('阿嬤、老師、爸爸'));
      final puppy = steps.whereType<ChooseStep>().first;
      expect(puppy.options.firstWhere((o) => o.ok).zh, '停下來');
    });

    test('家裡: 小小 finds one danger at a time (the others wait), 大 finds all in any order', () {
      final small = LevelRun(levelParts(Lv.kitchen, at(Age.small), hero));
      final f = small.step as FindStep;
      expect(f.hazards.length, 3);
      expect(small.hints, {'pot'});
      expect(small.tap('knife').res, Res.none);
      expect(small.tap('pot').res, Res.progress);
      expect(small.tap('pot').res, Res.progress, reason: 'turned in');
      expect(small.state('pot'), 'safe');
      expect(small.hints, {'knife'});
      final big = LevelRun(levelParts(Lv.kitchen, at(Age.big), hero));
      expect((big.step as FindStep).hazards.length, 4);
      expect(big.hints, isEmpty);
      expect(big.tap('knife').res, Res.progress);
      expect(big.guides, {'drawer'}, reason: 'where it goes is shown');
      expect(big.drop('knife', 'drawer').res, Res.progress);
      expect(big.question, isNotNull, reason: '大 asks why');
      expect(big.choose('wrong').res, Res.wrong);
      expect(big.choose('right').res, Res.progress);
    });

    test('浴室: cold water first, then hot', () {
      final run = LevelRun(levelParts(Lv.bath, at(Age.big), hero));
      run.tap('taps');
      expect(run.tap('hot').say, '先點冷水喔。');
      expect(run.tap('cold').res, Res.progress);
      expect(run.tap('hot').res, Res.progress);
      expect(run.state('taps'), 'safe');
    });
  });

  group('the free version and the worlds', () {
    test('free: all of 馬路世界 and the earthquake level', () {
      const s = Settings(full: false);
      expect([for (final l in Lv.values) if (s.open(l)) l], [Lv.light, Lv.cross, Lv.hand, Lv.car, Lv.lost, Lv.quake]);
      expect([for (final l in Lv.values) if (const Settings().open(l)) l], Lv.values);
    });

    test('身體世界 is on by default and a parent can turn it off; never every world off', () {
      expect(const Settings().shows(World.body), isTrue);
      expect(const Settings().bodyIntroSeen, isFalse);
      final off = const Settings().copyWith(off: {World.body});
      expect(off.open(Lv.sayNo), isFalse);
      expect(const Settings().copyWith(off: World.values.toSet()).shows(World.road), isTrue);
    });

    test('2 to 4 trusted grown-ups, no repeats', () {
      expect(const Settings().copyWith(trusted: [Adult.ama]).trusted, [Adult.ama, Adult.mom]);
      expect(const Settings().copyWith(trusted: [Adult.mom, Adult.mom, Adult.dad, Adult.ama, Adult.agong, Adult.teacher]).trusted, [Adult.mom, Adult.dad, Adult.ama, Adult.agong]);
    });

    test('the phone number keeps digits only, at a sensible length', () {
      expect(Settings.cleanPhone('0912-345-678'), '0912345678');
      expect(Settings.cleanPhone('(02) 2345 6789'), '0223456789');
      expect(Settings.cleanPhone('123'), '');
      expect(Settings.cleanPhone('1234567890123'), '');
    });

    test('a level is finished once for a badge; a world\'s crest when all are done', () {
      var g = const Game();
      for (final l in World.body.levels) {
        g = g.finished(l);
      }
      g = g.finished(Lv.light).finished(Lv.light);
      expect(g.plays[Lv.light], 2);
      expect(g.badges, [Lv.light, Lv.bodyLights, Lv.sayNo]);
      expect(g.crests, [World.body]);
      expect(g.nextIn(World.road), Lv.cross);
      expect(g.nextIn(World.body), isNull);
    });
  });

  group('the save file', () {
    final full = const Game(
      settings: Settings(age: Age.big, minutes: 10, off: {World.home}, bodyIntroSeen: true, phone: '0912345678', call: Adult.dad, trusted: [Adult.dad, Adult.teacher, Adult.ama], music: false, full: false),
      hero: HeroLook(hair: 2, skin: 3, helmet: 5, name: '小明', made: true),
      plays: {Lv.light: 3, Lv.quake: 1},
      real: {RealLife.cross, RealLife.quake},
    ).rest(DateTime(2026, 11, 15, 10));

    test('everything comes back the same', () {
      final back = Game.fromJson(jsonDecode(jsonEncode(full.toJson())) as Map<String, dynamic>);
      expect(back.toJson(), full.toJson());
      expect(back.settings.phone, '0912345678');
      expect(back.hero.name, '小明');
    });

    test('the phone number is only in the save file, and never in a log', () {
      final json = jsonEncode(full.toJson());
      expect('0912345678'.allMatches(json).length, 1);
      expect((full.toJson()['settings'] as Map)['phone'], '0912345678');
      expect(full.settings.toString(), isNot(contains('0912')));
      final logs = RegExp(r'\b(print|debugPrint|log|developer\.log)\(');
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
        expect(logs.hasMatch(f.readAsStringSync()), isFalse, reason: '${f.path} writes a log');
      }
      expect(full.toJson().toString().contains('address'), isFalse);
    });

    test('a broken or strange file gives a fresh, safe game', () {
      expect(Game.fromJson(null).toJson(), const Game().toJson());
      final odd = Game.fromJson({
        'settings': {'age': 'giant', 'minutes': 999, 'off': ['road', 'rescue', 'body', 'home', 'moon'], 'phone': 'call me', 'call': 'teacher', 'trusted': 'all', 'music': 'yes'},
        'hero': {'hair': 99, 'skin': -1, 'helmet': 'red', 'name': 42},
        'plays': {'light': 'many', 'nothing': 3, 'quake': -2, 'fire': 1},
        'real': ['cross', 'flying'],
        'restSince': 'yesterday',
      });
      expect(odd.settings.age, Age.small);
      expect(odd.settings.minutes, 15);
      expect(odd.settings.shows(World.road), isTrue, reason: 'never all worlds off');
      expect(odd.settings.phone, '');
      expect(odd.settings.call, Adult.mom);
      expect(odd.settings.trusted, [Adult.mom, Adult.dad]);
      expect(odd.settings.music, isTrue);
      expect(odd.hero.toJson(), const HeroLook().toJson());
      expect(odd.plays, {Lv.fire: 1});
      expect(odd.real, {RealLife.cross});
      expect(odd.restSince, isNull);
    });

    test('a file cut in half falls back to the save before', () async {
      final dir = Directory.systemTemp.createTempSync('safety_store');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = FileStore(dir);
      store.write(const Game().toJson());
      await store.flush();
      store.write(full.toJson());
      await store.flush();
      File('${dir.path}/safety_team.json').writeAsStringSync('{"settings": {"age": "bi');
      final back = await store.read();
      expect(back, isNotNull);
      expect(Game.fromJson(back).toJson(), const Game().toJson(), reason: 'the copy from the save before');
      File('${dir.path}/safety_team.json.bak').writeAsStringSync('not json');
      expect(await store.read(), isNull);
    });

    test('a name stays short and on one line', () {
      expect(HeroLook.cleanName('  小明\n小華小美小英小強  '), '小明 小華小美小');
      expect(const HeroLook().callName, '小隊員');
    });
  });

  group('the rest', () {
    final since = DateTime(2026, 11, 15, 10);
    final g = const Game().rest(since);

    test('an hour of rest after the time runs out', () {
      expect(g.resting(since.add(const Duration(minutes: 59))), isTrue);
      expect(g.resting(since.add(const Duration(hours: 1))), isFalse);
      expect(g.playOn().resting(since), isFalse);
    });

    test('a clock moved back ends the rest', () {
      expect(g.resting(since.subtract(const Duration(minutes: 1))), isFalse);
      expect(g.resting(DateTime(2020)), isFalse);
    });

    test('the minutes a parent can choose, 15 by default', () {
      expect(Settings.minuteChoices, [5, 10, 15, 20, 30]);
      expect(const Settings().minutes, 15);
    });
  });
}
