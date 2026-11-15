import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:safety_team/core/content.dart';
import 'package:safety_team/core/game.dart';
import 'package:safety_team/features/parent/parent_gate.dart';

import 'helpers.dart';

/// Privacy and safety (docs/design.md 「技術」): no permissions, no links
/// from other apps, no real phone calls, parent mode only through the gate,
/// the free version and 身體世界's note.
void main() {
  test('the app asks for no permissions and takes no links from other apps', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, isNot(contains('uses-permission')), reason: 'no internet, microphone, location, phone…');
    expect(manifest, contains('android:name="flutter_deeplinking_enabled" android:value="false"'));
    expect(manifest, contains('android:label="安全小隊"'));
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<key>FlutterDeepLinkingEnabled</key>\n\t<false/>'));
    expect(plist, isNot(contains('UsageDescription')), reason: 'no camera, microphone, contacts… prompts');
    expect(plist, contains('<string>安全小隊</string>'));
    expect(File('android/app/build.gradle.kts').readAsStringSync(), allOf(contains('applicationId = "com.yaufan.safetyteam"'), contains('SAFETY_TEAM_KEYSTORE')));
  });

  test('「打 119」 is a pretend keypad: nothing can dial or open a link', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final p in ['url_launcher', 'flutter_phone_direct_caller', 'android_intent', 'http', 'record', 'geolocator']) {
      expect(pubspec, isNot(contains('$p:')), reason: 'no $p');
    }
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final t = f.readAsStringSync();
      expect(t, isNot(contains('tel:')), reason: f.path);
      expect(t, isNot(contains('ACTION_DIAL')), reason: f.path);
      expect(t, isNot(contains('dart:io\' show HttpClient')), reason: f.path);
    }
  });

  testWidgets('parent mode and unknown pages cannot be opened without the gate', (tester) async {
    final app = await TestApp.start(tester);
    app.go('/parent');
    await app.settle();
    expect(app.location, '/', reason: 'no pass from the gate');
    ParentPass.grant();
    app.go('/parent');
    await app.settle();
    expect(app.location, '/parent', reason: 'right after the gate');
    app.go('/');
    await app.settle();
    app.go('/parent');
    await app.settle();
    expect(app.location, '/', reason: 'the pass is used up');
    for (final bad in ['/level?lv=nothing', '/world?w=moon', '/level', '/nowhere']) {
      app.go(bad);
      await app.settle();
      expect(app.location, '/', reason: bad);
    }
    await app.end();
  });

  testWidgets('the gate asks a sum written in characters, and a wrong answer keeps it shut', (tester) async {
    final c = ParentGateChallenge(4, 5);
    expect(c.question, '四 加 五 等於多少？');
    expect(c.check('9'), isTrue);
    expect(c.check('8'), isFalse);
    final app = await TestApp.start(tester);
    await app.tapLabel('家長', ms: 600);
    expect(find.byType(ParentGatePage), findsOneWidget);
    await app.tapLabel('取消', ms: 600);
    expect(app.location, '/');
    await app.end();
  });

  testWidgets('the free version: 馬路世界 and the earthquake only', (tester) async {
    final app = await TestApp.start(tester, game: ready.copyWith(settings: const Settings(full: false)));
    app.go('/level?lv=fire');
    await app.settle();
    expect(app.location, '/');
    app.go('/world?w=rescue');
    await app.settle(700);
    await app.tapLabel('火災');
    expect(app.location, '/world');
    expect(app.voice.said.last, '完整版才有喔，請爸爸媽媽看看。');
    await app.tapLabel('地震', ms: 900);
    expect(app.location, '/level');
    await app.end();
  });

  testWidgets('身體世界 shows the parent\'s note first, and a parent can turn it off', (tester) async {
    final app = await TestApp.start(tester);
    app.go('/level?lv=sayNo');
    await app.settle(700);
    expect(app.location, '/intro');
    expect(find.textContaining('泳衣遮住的地方是紅燈'), findsOneWidget);
    await app.tapLabel('先回基地', ms: 700);
    expect(app.location, '/');
    expect(app.game.settings.bodyIntroSeen, isFalse);
    app.change((g) => g.copyWith(settings: g.settings.copyWith(off: {World.body})));
    await app.settle();
    expect(find.bySemanticsLabel('身體世界'), findsNothing);
    app.go('/world?w=body');
    await app.settle();
    expect(app.location, '/');
    await app.end();
  });

  testWidgets('the first start asks for a look; the rest locks play for an hour and a clock moved back ends it', (tester) async {
    final app = await TestApp.start(tester, game: const Game());
    expect(app.location, '/setup');
    app.go('/world?w=road');
    await app.settle();
    expect(app.location, '/setup', reason: 'no squad member yet');
    await app.tapLabel('出發！', ms: 700);
    app.change((g) => g.rest(app.now));
    await app.settle(2600);
    expect(app.location, '/rest');
    app.go('/world?w=road');
    await app.settle(2600);
    expect(app.location, '/rest', reason: 'still resting');
    app.now = app.now.subtract(const Duration(hours: 3));
    await app.settle(2600);
    expect(app.location, '/', reason: 'a clock moved back counts as rested');
    expect(app.game.restSince, isNull);
    await app.end();
  });
}
