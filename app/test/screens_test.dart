import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safety_team/core/content.dart';
import 'package:safety_team/core/game.dart';
import 'package:safety_team/core/scene.dart';
import 'package:safety_team/core/voice.dart';
import 'package:safety_team/features/level/scene_view.dart';
import 'package:safety_team/features/level/step_panel.dart';
import 'package:safety_team/features/parent/parent_gate.dart';

import 'helpers.dart';

/// A voice that is still talking until the test says it is done.
class SlowVoice extends RecordingVoice {
  Completer<void>? talking;

  @override
  Future<void> say(String text) {
    said.add(text);
    final c = talking = Completer<void>();
    return c.future;
  }
}

/// The screens' rules that the 0.1.1 review fixed: play time, the helper's
/// lines, fingers, and parent mode.
void main() {
  testWidgets('time in parent mode is not the child\'s play time', (tester) async {
    final app = await TestApp.start(tester);
    ParentPass.grant();
    app.go('/parent');
    await app.settle(2600);
    expect(app.location, '/parent');
    app.now = app.now.add(const Duration(minutes: 20));
    await app.settle(2600);
    app.go('/');
    await app.settle(2600);
    expect(app.location, '/', reason: '20 minutes setting things up are the parent\'s, not 15 minutes of play');
    app.now = app.now.add(const Duration(minutes: 13));
    await app.settle(2600);
    expect(app.location, '/');
    app.now = app.now.add(const Duration(minutes: 3));
    await app.settle(2600);
    expect(app.location, '/rest', reason: 'the child\'s own 15 minutes are up');
    await app.end();
  });

  testWidgets('a clock moved back does not stretch the play time', (tester) async {
    final app = await TestApp.start(tester);
    app.now = app.now.subtract(const Duration(hours: 2));
    await app.settle(2600);
    app.now = app.now.add(const Duration(minutes: 16));
    await app.settle(2600);
    expect(app.location, '/rest');
    await app.end();
  });

  testWidgets('the next step waits until the helper has said why', (tester) async {
    final voice = SlowVoice();
    final app = await TestApp.start(tester, voice: voice);
    app.go('/level?lv=light');
    await app.settle(900);
    expect(voice.said.last, startsWith('看！對面的小紅人站著'));
    await tapSprite(app, 'light', ms: 300);
    const why = '紅燈的時候車子在走，我們站在路邊等一下。';
    expect(voice.said.last, why);
    await app.settle(2600);
    expect(voice.said.last, why, reason: 'still saying it: not cut off by the next line');
    voice.talking!.complete();
    await app.settle(300);
    expect(voice.said.last, startsWith('布穀布穀！'));

    // A speech engine that never says it is done does not stop the level.
    await tapSprite(app, 'hero', ms: 300);
    expect(voice.said.last, '綠燈亮了，車子停好，我們慢慢走過去。');
    await app.settle(5200);
    expect(voice.said.last, startsWith('小綠人跑得好快'));
    await app.end();
  });

  group('one finger at a time in the picture', () {
    const scene = Scene('road/street', [
      Sprite('leg', '桌腳', Look(null, .3, .8, .1, .2)),
      Sprite('item', '毛巾', Look(null, .2, .3, .1, .1), drag: true),
      Sprite('zone', '水龍頭', Look(null, .8, .3, .15, .15)),
      Sprite('other', '書櫃', Look(null, .8, .8, .1, .1)),
    ]);

    Future<Map<String, List<Object>>> pump(WidgetTester tester, {String? holdTarget}) async {
      final got = <String, List<Object>>{'tap': [], 'drop': [], 'hold': []};
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SceneView(
                scene: scene,
                states: const {},
                canDrag: (id) => id == 'item',
                allowed: (_, _) => true,
                onTap: (ids) => got['tap']!.add(ids),
                onDrop: (item, zones) => got['drop']!.add('$item→${zones.join(',')}'),
                holdTarget: holdTarget,
                holdSeconds: 1,
                onHold: (s) => got['hold']!.add(s),
              ),
            ),
          ),
        ),
      ));
      return got;
    }

    Offset at(WidgetTester tester, String id) => tester.getCenter(find.byKey(ValueKey('sprite-$id')));

    testWidgets('another finger does not let go of the table leg', (tester) async {
      final got = await pump(tester, holdTarget: 'leg');
      final a = await tester.startGesture(at(tester, 'leg'), pointer: 1);
      await tester.pump(const Duration(milliseconds: 300));
      final b = await tester.startGesture(at(tester, 'other'), pointer: 2);
      await tester.pump(const Duration(milliseconds: 50));
      await b.up();
      await tester.pump(const Duration(milliseconds: 50));
      expect(got['hold'], isEmpty, reason: 'the first finger is still holding');
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 300));
      expect(got['hold'], [1.0]);
      await a.up();
      await tester.pump();
      expect(got['hold'], [1.0]);
      expect(got['tap'], isEmpty);
    });

    testWidgets('another finger does not drop or move what is held', (tester) async {
      final got = await pump(tester);
      final a = await tester.startGesture(at(tester, 'item'), pointer: 1);
      await tester.pump();
      final b = await tester.startGesture(at(tester, 'other'), pointer: 2);
      await b.moveBy(const Offset(-30, -10));
      await b.up();
      await tester.pump();
      expect(got['drop'], isEmpty, reason: 'still in the first finger');
      final to = at(tester, 'zone');
      await a.moveTo(to);
      await tester.pump();
      await a.up();
      await tester.pump();
      expect(got['drop'], ['item→zone']);
    });

    testWidgets('a touch the phone takes away is not a tap or a drop', (tester) async {
      final got = await pump(tester);
      final a = await tester.startGesture(at(tester, 'other'), pointer: 1);
      await a.cancel();
      final b = await tester.startGesture(at(tester, 'item'), pointer: 2);
      await b.moveTo(at(tester, 'zone'));
      await b.cancel();
      await tester.pump();
      expect(got['tap'], isEmpty);
      expect(got['drop'], isEmpty);
      final c = await tester.startGesture(at(tester, 'other'), pointer: 3);
      await c.up();
      await tester.pump();
      expect(got['tap'], [
        ['other'],
      ], reason: 'the next touch works');
    });
  });

  testWidgets('a second finger on 「不要！」 does not end the hold', (tester) async {
    final held = <double>[];
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: Scaffold(body: Center(child: HoldButton(label: '不要！', seconds: 1, onHold: held.add)))),
    ));
    final c = tester.getCenter(find.byType(HoldButton));
    final a = await tester.startGesture(c, pointer: 1);
    await tester.pump(const Duration(milliseconds: 400));
    final b = await tester.startGesture(c + const Offset(30, 20), pointer: 2);
    await tester.pump(const Duration(milliseconds: 50));
    await b.up();
    await tester.pump(const Duration(milliseconds: 50));
    expect(held, isEmpty);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 300));
    expect(held, [1.0]);
    await a.up();
    await tester.pump();
    expect(held, [1.0]);
  });

  testWidgets('the last world on cannot be turned off (else a world the parent turned off comes back)', (tester) async {
    final app = await TestApp.start(tester, game: ready.copyWith(settings: const Settings(off: {World.road, World.rescue, World.body})));
    ParentPass.grant();
    app.go('/parent');
    await app.settle(600);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('world-home')), 200, scrollable: find.byType(Scrollable).first);
    await app.settle();
    SwitchListTile tile(World w) => tester.widget<SwitchListTile>(find.byKey(ValueKey('world-${w.name}')));
    expect(tile(World.home).value, isTrue);
    expect(tile(World.home).onChanged, isNull);
    expect(tile(World.road).onChanged, isNotNull);
    await app.end();
  });

  test('the speech engine is set up once, and a line asked for during the set-up is said', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('flutter_tts');
    final calls = <String>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'awaitSpeakCompletion') await Future<void>.delayed(const Duration(milliseconds: 30));
      final arg = call.arguments;
      calls.add(call.method == 'speak' ? 'speak ${arg is Map ? arg['text'] : arg}' : call.method);
      return 1;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final voice = SystemVoice();
    await Future.wait([voice.say('歡迎'), voice.say('你好')]);
    expect(calls.where((c) => c == 'awaitSpeakCompletion'), hasLength(1), reason: 'set up once');
    expect(calls.last, 'speak 你好', reason: 'the newest line is said and nothing stops it: $calls');
    expect(calls.indexOf('setSpeechRate'), lessThan(calls.indexOf('speak 你好')), reason: 'said at the calm speed');
  });
}
