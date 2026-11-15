// Records a demo video of 安全小隊 being played: a scripted child (a white
// dot where the finger is) with a caption under the phone screen; the music
// and sounds the app asked for are written down and mixed in afterwards by
// tools/demo_audio.py.
//
//   flutter test test/demo/demo_video_test.dart --dart-define=DEMO=true
//   python3 ../tools/demo_audio.py
//
// Needs ffmpeg; writes build/demo/demo.mp4, chapters.txt and sounds.txt.
// Skipped in normal test runs.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Step;
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safety_team/app/app.dart';
import 'package:safety_team/core/content.dart';
import 'package:safety_team/core/game.dart';
import 'package:safety_team/core/levels.dart';
import 'package:safety_team/core/run.dart';
import 'package:safety_team/core/steps.dart';
import 'package:safety_team/features/base/base_screen.dart';
import 'package:safety_team/features/level/level_screen.dart';
import 'package:safety_team/core/providers.dart';
import 'package:safety_team/core/sounds.dart';
import 'package:safety_team/core/store.dart';
import 'package:safety_team/core/voice.dart';

import '../helpers.dart' show loadFonts;

const _phone = Size(390, 844);
const _captionHeight = 84.0;
const _fps = 10;
const _demo = bool.fromEnvironment('DEMO');

/// The music and the sounds asked for, with the frame they were asked at.
class _Recording implements Sounds {
  _Recording(this.frame);

  final int Function() frame;
  final lines = <String>[];
  final _holders = MusicHolders();
  Music? _playing;

  @override
  set music(bool on) {}

  @override
  set effects(bool on) {}

  @override
  void play(String sfx) => lines.add('${frame()} sfx $sfx');

  @override
  void hold(Object owner, Music? music) {
    _holders.hold(owner, music);
    _changed();
  }

  @override
  void release(Object owner) {
    _holders.release(owner);
    _changed();
  }

  void _changed() {
    final now = _holders.current;
    if (now == _playing) return;
    _playing = now;
    lines.add('${frame()} music ${now?.file ?? '-'}');
  }
}

void main() {
  testWidgets('demo video', skip: !_demo, (tester) async {
    await tester.runAsync(loadFonts);
    tester.view.physicalSize = Size(_phone.width * 3, (_phone.height + _captionHeight) * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    LevelScreen.pace = .8;
    BaseScreen.welcomed = false;

    var frameCount = 0;
    var now = DateTime(2026, 11, 15, 10);
    final track = _Recording(() => frameCount);
    final finger = ValueNotifier<Offset?>(null);
    final caption = ValueNotifier<String>('');
    final key = GlobalKey();
    final store = MemoryStore();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(children: [
          SizedBox.fromSize(
            size: _phone,
            child: MediaQuery(
              data: const MediaQueryData(size: _phone, devicePixelRatio: 3, padding: EdgeInsets.only(top: 24)),
              child: Stack(children: [
                ProviderScope(
                  overrides: [
                    storeProvider.overrideWithValue(store),
                    savedGameProvider.overrideWithValue(const Game()),
                    soundsProvider.overrideWithValue(track),
                    voiceProvider.overrideWithValue(const SilentVoice()),
                    clockProvider.overrideWithValue(() => now),
                  ],
                  child: const SafetyApp(),
                ),
                IgnorePointer(child: ValueListenableBuilder(valueListenable: finger, builder: (_, at, _) => _Finger(at))),
              ]),
            ),
          ),
          SizedBox(
            width: _phone.width,
            height: _captionHeight,
            child: ColoredBox(
              color: const Color(0xFF1E3A6E),
              child: Center(
                child: ValueListenableBuilder(
                  valueListenable: caption,
                  builder: (_, text, _) => Text(text, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Huninn', color: Colors.white, fontSize: 17, height: 1.35)),
                ),
              ),
            ),
          ),
        ]),
      ),
    ));

    final rec = (await tester.runAsync(() => _Recorder.start(key)))!;
    final marks = <String>[];
    void mark(String name) => marks.add('$name $frameCount');
    Future<void> frames(int n) async {
      for (var i = 0; i < n; i++) {
        frameCount++;
        await tester.runAsync(() async {
          await rec.capture();
          await Future<void>.delayed(const Duration(milliseconds: 15));
        });
        await tester.pump(const Duration(milliseconds: 1000 ~/ _fps));
      }
    }

    Future<void> seconds(double s) => frames((s * _fps).round());
    Future<void> touch(Offset at) async {
      finger.value = at;
      await frames(2);
      await tester.tapAt(at);
      await frames(2);
      finger.value = null;
    }

    Future<void> label(String l) async {
      final f = find.bySemanticsLabel(l);
      if (f.evaluate().isEmpty || !tester.getRect(f.last).overlaps(Offset.zero & _phone)) {
        await tester.scrollUntilVisible(f, 120, scrollable: find.byType(Scrollable).first);
        await frames(3);
      }
      await touch(tester.getCenter(f.last));
    }

    Future<void> tapKey(String id) => touch(tester.getCenter(find.byKey(ValueKey(id)).last));
    ProviderContainer container() => ProviderScope.containerOf(tester.element(find.byType(SafetyApp)));
    Game game() => container().read(gameProvider);
    void change(Game Function(Game) f) => container().read(gameProvider.notifier).change(f);
    void go(String to) => container().read(routerProvider).go(to);
    Offset sprite(String id) => tester.getCenter(find.byKey(ValueKey('sprite-$id')));
    Future<void> holdAt(Offset c, double s) async {
      finger.value = c;
      final g = await tester.startGesture(c);
      await seconds(s);
      await g.up();
      finger.value = null;
    }

    Future<void> dragFrom(Offset a, Offset b) async {
      finger.value = a;
      final g = await tester.startGesture(a);
      await frames(2);
      for (var i = 1; i <= 10; i++) {
        final p = Offset.lerp(a, b, i / 10)!;
        finger.value = p;
        await g.moveTo(p);
        await frames(1);
      }
      await g.up();
      await frames(2);
      finger.value = null;
    }

    /// Plays a level with each step's own answer; [notes] are captions shown
    /// when the step with that index starts.
    Future<void> play(Lv lv, Map<int, String> notes, {Future<void> Function(int i, Step s)? before}) async {
      final twin = LevelRun(levelParts(lv, game().settings, game().hero));
      var i = 0;
      while (!twin.finished) {
        final step = twin.step!;
        if (notes[i] case final n?) caption.value = n;
        await seconds(1.6);
        await before?.call(i, step);
        for (final e in step.solve()) {
          twin.play(e);
          switch (e) {
            case Tap(:final id) when id.startsWith('btn:'):
              await tapKey(step is SayStep ? 'say-${twin.part}-${twin.index}' : 'btn-$id');
            case Tap(:final id) when id.startsWith('word:'):
              await tapKey('word-${id.substring(5)}');
            case Tap(:final id):
              await touch(sprite(id));
            case Drop(:final item, :final zone):
              await dragFrom(sprite(item), sprite(zone));
            case Hold(:final id, :final seconds):
              await holdAt(id.startsWith('btn:') ? tester.getCenter(find.bySemanticsLabel(id.substring(4)).last) : sprite(id), seconds + .4);
            case KeyPress(:final digit):
              await tapKey('key-$digit');
            case Choose(:final id):
              await tapKey('opt-$id');
            case Said():
              await seconds(3.3);
          }
          await seconds(.5);
        }
        await seconds(3.2);
        twin.next();
        i++;
      }
      await seconds(2.5);
    }

    // The first start.
    mark('start');
    caption.value = '安全小隊：3～6 歲的安全遊戲\n小朋友自己當戴安全帽的小隊員';
    await seconds(2.5);
    caption.value = '第一次打開：選髮型、膚色、安全帽的顏色';
    await label('雙辮');
    await seconds(.6);
    await label('紅色安全帽');
    await seconds(1.4);
    await label('出發！');
    await seconds(1);

    // The base.
    mark('base');
    caption.value = '小隊基地：小隊員和三位幫手\n汪汪警察、喵喵消防員、兔兔護士';
    await seconds(3);
    caption.value = '四個世界：馬路、救災、身體、家裡\n（漫畫網點風：深藍細框、網點、漫畫字）';
    await seconds(3);
    change((g) => g.copyWith(settings: g.settings.copyWith(phone: '0912345678')));

    // 馬路世界.
    mark('road');
    await label('馬路世界');
    caption.value = '馬路世界：汪汪警察帶路';
    await seconds(2.5);
    await label('紅綠燈');
    mark('light');
    await play(Lv.light, {0: '紅綠燈：紅燈的時候點小隊員\n他只會說「紅燈，等一下」', 1: '布穀布穀！小綠人走路了\n車子停下來，慢慢走過去', 2: '小綠人跑起來、數字快沒了\n就等下一次'}, before: (i, s) async {
      if (i == 0) {
        await touch(sprite('hero'));
        await seconds(1.5);
      }
    });
    caption.value = '做完一關：徽章貼到安全帽上\n給爸爸媽媽的問題卡、回真實生活做做看';
    await seconds(4);
    mark('cross');
    go('/level?lv=cross');
    await play(Lv.cross, {0: '過馬路五步「集、轉、探、避、揮」\n五個大按鈕，幫手念白話', 2: '轉：點左邊看、點右邊看', 4: '避：有車子來了，點「等一下」\n讓車子先過去', 6: '揮：對司機揮揮手，司機也揮手、車子停好'});
    mark('car');
    go('/level?lv=car');
    await play(Lv.car, {0: '坐車：把安全帶拖到扣子，「喀！」', 1: '隔壁的小熊把手伸出窗外\n點牠，請牠收回來', 2: '坐機車：戴上安全帽、扣好扣環'});
    mark('lost');
    go('/level?lv=lost');
    await play(Lv.lost, {0: '走失了：先站在原地', 1: '找穿制服的人、店員\n或帶著小孩的媽媽', 2: '背爸媽的電話：家長在家長模式輸入\n小小跟著亮亮的數字按（只存在手機裡）', 3: '「大聲說一次」：小朋友對著手機說\nAPP 不錄音，沒有麥克風'});

    // 救災世界.
    mark('quake');
    go('/level?lv=quake');
    await play(Lv.quake, {0: '地震：畫面輕輕晃（不會倒）\n趴：把小隊員拖到桌子下面', 1: '掩：用手蓋住頭', 2: '穩：按住桌腳，圈圈轉滿、搖晃停了', 3: '搖完了，走樓梯不搭電梯'});
    mark('fire');
    go('/level?lv=fire');
    await play(Lv.fire, {0: '火災：只有淡淡的灰煙，不畫火\n先把毛巾弄濕、摀住口鼻', 2: '蹲低低，沿著地板爬到門口\n站起來的話幫手說「蹲低低」', 4: '到外面了，練習按 1、1、9\n只是練習的鍵盤，不會真的打電話'}, before: (i, s) async {
      if (s is DragStep && s.item == 'hero') {
        final from = sprite('hero');
        await dragFrom(from, Offset(from.dx + 30, sprite('smoke').dy));
        await seconds(2);
      }
    });

    // 身體世界.
    mark('body');
    go('/world?w=body');
    await seconds(1.5);
    caption.value = '身體世界：預設打開，家長可以關掉\n第一次進去，先給爸爸媽媽看說明';
    await label('身體紅綠燈');
    await seconds(3.5);
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await seconds(1.5);
    await label('我看過了，開始');
    await play(Lv.bodyLights, {0: '身體紅綠燈：點身體的地方\n綠燈可以、黃燈先問我、紅燈不可以', 1: '爸媽幫忙洗澡、醫生看病而且爸媽在旁邊\n才可以'});
    mark('no');
    go('/level?lv=sayNo');
    await play(Lv.sayNo, {0: '說「不要！」：按住大大的按鈕\n對方就停下來說「好」', 3: '反過來：小狗說不要\n我們也要停下來', 4: '最後兔兔提醒：不舒服的事\n要跟爸媽選的安全大人說'});

    // 家裡世界, at 大.
    mark('home');
    change((g) => g.copyWith(settings: g.settings.copyWith(age: Age.big)));
    go('/level?lv=kitchen');
    await play(Lv.kitchen, {0: '家裡世界（大：5～6 歲）\n自己找出全部危險的東西、弄安全\n每一個還要回答「為什麼」'});

    // The helmet.
    mark('helmet');
    change((g) => g.tick(RealLife.cross, true));
    go('/helmet');
    caption.value = '安全帽頁：每一關一個徽章\n家長勾「真實生活清單」，就有金徽章';
    await seconds(4.5);

    // Parent mode.
    mark('parent');
    go('/');
    await seconds(1);
    caption.value = '家長模式要過家長關卡';
    await label('家長');
    await seconds(1.2);
    final parts = (find.textContaining('加').evaluate().first.widget as Text).data!.split(' ');
    const digits = {'三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9};
    for (final d in '${digits[parts[0]]! + digits[parts[2]]!}'.split('')) {
      await tapKey('gate-key-$d');
      await frames(3);
    }
    await seconds(1.2);
    caption.value = '家長模式：名字、年齡、玩多久\n爸媽的電話和稱呼（不存地址）、安全大人';
    await seconds(3.5);
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await seconds(3);
    caption.value = '要開哪些世界、真實生活清單、家長小抄';
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await seconds(3);

    // The rest.
    mark('rest');
    go('/');
    await seconds(1);
    now = now.add(const Duration(minutes: 16));
    caption.value = '每次玩多久由家長設定（預設 15 分鐘）\n時間到了：「換你去真的地方做做看！」';
    await seconds(5);
    caption.value = '';
    mark('end');
    await seconds(.5);
    await tester.runAsync(() async {
      await rec.finish();
      File('build/demo/chapters.txt').writeAsStringSync('${marks.join('\n')}\n');
      File('build/demo/sounds.txt').writeAsStringSync('fps $_fps\nframes $frameCount\n${track.lines.join('\n')}\n');
    });
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }, timeout: const Timeout(Duration(minutes: 40)));
}

class _Finger extends StatelessWidget {
  const _Finger(this.at);

  final Offset? at;

  @override
  Widget build(BuildContext context) {
    final p = at;
    if (p == null) return const SizedBox.expand();
    return Stack(children: [
      Positioned(
        left: p.dx - 22,
        top: p.dy - 22,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.55),
            border: Border.all(color: const Color(0xFF1E3A6E).withValues(alpha: 0.5), width: 3),
          ),
        ),
      ),
    ]);
  }
}

/// Streams frames of [key]'s boundary into ffmpeg.
class _Recorder {
  _Recorder(this._key, this._ffmpeg);

  final GlobalKey _key;
  final Process _ffmpeg;

  static Future<_Recorder> start(GlobalKey key) async {
    Directory('build/demo').createSync(recursive: true);
    final size = Size(_phone.width * 2, (_phone.height + _captionHeight) * 2);
    final ffmpeg = await Process.start('ffmpeg', [
      '-y', '-loglevel', 'error',
      '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', '${size.width.toInt()}x${size.height.toInt()}', '-r', '$_fps', '-i', '-',
      '-vf', 'fps=30', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '24', '-movflags', '+faststart', 'build/demo/demo_silent.mp4',
    ]);
    ffmpeg.stderr.listen(stderr.add);
    return _Recorder(key, ffmpeg);
  }

  Future<void> capture() async {
    final boundary = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    _ffmpeg.stdin.add(bytes!.buffer.asUint8List());
    await _ffmpeg.stdin.flush();
  }

  Future<void> finish() async {
    await _ffmpeg.stdin.flush();
    await _ffmpeg.stdin.close();
    final code = await _ffmpeg.exitCode;
    if (code != 0) throw StateError('ffmpeg failed ($code)');
  }
}
