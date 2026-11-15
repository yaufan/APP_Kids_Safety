import 'content.dart';
import 'game.dart';
import 'scene.dart';
import 'steps.dart';

/// The 14 levels of 0.1 (docs/design.md 「玩法：四個世界」), as pictures and
/// steps. [age] decides the 小小 and 大 differences: 大 gets a 「為什麼」
/// card, keeps the order alone and types the phone number without lights.
///
/// Every picture named here is drawn in design/art/ (test/art_test.dart
/// checks), and test/rules_test.dart plays every level through at both ages.
List<Part> levelParts(Lv lv, Settings s, HeroLook hero) {
  final big = s.age == Age.big;
  return switch (lv) {
    Lv.light => _light(big),
    Lv.cross => _cross(big),
    Lv.hand => _hand(big),
    Lv.car => _carLevel(big),
    Lv.lost => _lost(big, s, hero),
    Lv.quake => _quake(big),
    Lv.fire => _fire(big),
    Lv.typhoon => _typhoon(big),
    Lv.bodyLights => _bodyLights(big),
    Lv.sayNo => _sayNo(big, s),
    Lv.kitchen => _kitchen(big),
    Lv.living => _living(big),
    Lv.bath => _bath(big),
    Lv.balcony => _balcony(big),
  };
}

/// The squad member in a pose (`hero/<pose>.svg` in the child's colours).
String pose(String p) => '@hero/$p';

Sprite _hero(Look base, {Map<String, String?> arts = const {}, Map<String, Look> moves = const {}, bool drag = false}) => Sprite('hero', '小隊員', base, arts: arts, moves: moves, drag: drag);

Sprite _helper(Helper h, double x, double y, {double w = .17, double h0 = .34, Map<String, String?> arts = const {}}) => Sprite(h.name, h.zh, Look(h.art(), x, y, w, h0), arts: arts, anim: Anim.bob);

/// A place to drop onto or tap that has no picture of its own.
Sprite _zone(String id, String zh, double x, double y, double w, double h) => Sprite(id, zh, Look(null, x, y, w, h));

ChooseStep _why(String ask, String right, String wrong, String wrongReply, {String? done, String? rightArt, String? wrongArt}) => ChooseStep(
      [Opt('right', right, ok: true, art: rightArt), Opt('wrong', wrong, reply: wrongReply, art: wrongArt)],
      say: ask,
      hint: '為什麼？選一個',
      done: done ?? '對！$right。',
      word: '答對了！',
    );

// ------------------------------------------------------------ 馬路世界

/// The crossing seen from our side of the road: the far pavement at the top,
/// the road across the middle, the zebra in the middle, our pavement below.
const _street = 'road/street';

Sprite _pedLight() => const Sprite('light', '紅綠燈', Look('road/ped_red', .8, .2, .12, .36), arts: {'green': 'road/ped_green', 'run': 'road/ped_run', 'red': 'road/ped_red'});

/// A car on the road: waits off to the left, drives in and stops before the
/// zebra, or drives past.
Sprite _car(String id, String art, {String? stopArt}) => Sprite(id, '車子', Look(art, -.2, .5, .3, .2, jump: true), moves: {
      'stop': Look(art, .22, .5, .3, .2),
      'wave': Look(stopArt ?? art, .22, .5, .3, .2),
      'pass': Look(art, 1.25, .5, .3, .2, exit: true),
    });

List<Part> _light(bool big) {
  Scene scene() => Scene(_street, [
        _pedLight(),
        _car('car', 'road/car_blue'),
        _hero(Look(pose('stand'), .5, .82, .15, .3), arts: {'no': pose('stop')}, moves: {'cross': Look(pose('walk'), .5, .2, .1, .2)}),
        _helper(Helper.dog, .14, .8, arts: {'stop': Helper.dog.art('stop')}),
      ]);
  return [
    Part(scene(), [
      const TapStep(['light'],
          say: '看！對面的小紅人站著，是紅燈。點點看紅綠燈。',
          hint: '點紅綠燈',
          wrong: {'hero': '紅燈，等一下。'},
          after: {'car': 'pass', 'dog': 'stop'},
          word: '紅燈停！',
          wordAt: 'light',
          sfx: 'car_pass',
          done: '紅燈的時候車子在走，我們站在路邊等一下。'),
      const TapStep(['hero'],
          say: '布穀布穀！小綠人走路了，是綠燈。點小隊員，慢慢走過去。',
          hint: '點小隊員',
          before: {'light': 'green', 'car': 'stop', 'dog': 'start'},
          startSfx: 'chirp',
          after: {'hero': 'cross'},
          word: '布穀！',
          wordAt: 'light',
          sfx: 'steps',
          done: '綠燈亮了，車子停好，我們慢慢走過去。'),
    ]),
    Part(scene(), [
      const ChooseStep([
        Opt('wait', '等下一次', ok: true, art: 'road/ped_run'),
        Opt('run', '快跑過去', reply: '小綠人在跑，表示來不及了，等下一次。', art: 'ui/run'),
      ], say: '小綠人跑得好快，數字快要沒了。現在要走嗎？', hint: '要等，還是要走？', before: {'light': 'run'}, after: {'light': 'red', 'car': 'pass'}, word: '等一下！', sfx: 'car_pass', done: '對！小綠人跑起來，就等下一次綠燈。'),
      if (big) _why('為什麼紅燈的時候要停下來？', '車子正在走', '紅色很漂亮', '紅色很漂亮，可是紅燈要停，是因為車子正在走喔。', rightArt: 'road/car_blue', wrongArt: 'road/ped_red'),
    ]),
  ];
}

/// The five big words of 過馬路五步 and what each means in plain words.
const crossWords = [('集', '停在路邊'), ('轉', '左看右看'), ('探', '慢慢探頭'), ('避', '讓車先過'), ('揮', '揮揮手')];

List<Part> _cross(bool big) {
  Map<String, String> outOfOrder(int i) => {
        for (var j = i + 1; j < crossWords.length; j++) 'word:${crossWords[j].$1}': '先「${crossWords[i].$1}」：${crossWords[i].$2}。',
      };
  final scene = Scene(_street, [
    _pedLight(),
    _car('car', 'road/car_red', stopArt: 'road/car_red_wave'),
    _hero(Look(pose('stand'), .5, .93, .15, .3), moves: {
      'curb': Look(pose('stand'), .5, .8, .15, .3),
      'look_l': Look(pose('look'), .5, .8, .15, .3, flip: true),
      'look_r': Look(pose('look'), .5, .8, .15, .3),
      'peek': Look(pose('peek'), .5, .79, .15, .3),
      'wave': Look(pose('wave'), .5, .8, .15, .3),
      'cross': Look(pose('walk'), .5, .2, .1, .2),
    }),
    const Sprite('arrow_l', '左邊', Look(null, .3, .62, .12, .16), arts: {'on': 'ui/arrow_l'}, anim: Anim.bob),
    const Sprite('arrow_r', '右邊', Look(null, .7, .62, .12, .16), arts: {'on': 'ui/arrow_r'}, anim: Anim.bob),
    _helper(Helper.dog, .14, .82),
  ]);
  return [
    Part(scene, [
      TapStep(const ['word:集'],
          say: '過馬路五步！第一步「集」：走到路邊，腳停在白線後面。',
          hint: '點「集」',
          extra: Extra.words,
          before: const {'light': 'green'},
          wrong: outOfOrder(0),
          after: const {'hero': 'curb'},
          word: '集！',
          wordAt: 'hero',
          sfx: 'steps',
          done: '停在路邊，腳在線後面。'),
      TapStep(const ['word:轉'], say: '第二步「轉」：轉頭看一看。', hint: '點「轉」', extra: Extra.words, wrong: outOfOrder(1), after: const {'arrow_l': 'on', 'arrow_r': 'on'}, sfx: 'pop'),
      const TapStep(['arrow_l', 'arrow_r'],
          say: '點左邊，看左邊；再點右邊，看右邊。',
          hint: '點左邊、點右邊',
          extra: Extra.words,
          tapStates: {
            'arrow_l': {'hero': 'look_l', 'arrow_l': 'start'},
            'arrow_r': {'hero': 'look_r', 'arrow_r': 'start'},
          },
          lines: {'arrow_l': '左邊看看。', 'arrow_r': '右邊看看。'},
          word: '轉！',
          wordAt: 'hero',
          done: '左邊看看，右邊看看。'),
      TapStep(const ['word:探'], say: '第三步「探」：慢慢探頭，看看有沒有車。', hint: '點「探」', extra: Extra.words, wrong: outOfOrder(2), after: const {'hero': 'peek'}, word: '探！', wordAt: 'hero', done: '慢慢探頭，看清楚。'),
      TapStep(const ['word:避'], say: '第四步「避」：有車子來了！', hint: '點「避」', extra: Extra.words, wrong: outOfOrder(3), after: const {'car': 'stop'}, sfx: 'car_hum', done: '有車子，我們讓它先走。'),
      const TapStep(['btn:等一下'], say: '點「等一下」，讓車子先過去。', hint: '點「等一下」', extra: Extra.words, wrong: {'hero': '車子還在，先等一下。'}, after: {'car': 'pass', 'hero': 'curb'}, word: '咻～', sfx: 'car_pass', done: '車子過去了。讓車先過，就是「避」。'),
      TapStep(const ['word:揮'],
          say: '第五步「揮」：又來一台車，對司機揮揮手。',
          hint: '點「揮」',
          extra: Extra.words,
          before: const {'car': 'stop'},
          startSfx: 'brake',
          after: const {'hero': 'wave', 'car': 'wave'},
          word: '揮揮！',
          wordAt: 'hero',
          sfx: 'horn',
          done: '司機看到你了，也揮揮手，車子停好了。'),
      const TapStep(['hero'], say: '五步都做好了！點小隊員，慢慢走過去。', hint: '點小隊員', extra: Extra.words, after: {'hero': 'cross'}, word: '過馬路！', wordAt: 'hero', sfx: 'steps', done: '集、轉、探、避、揮，安全過馬路！'),
      if (big) _why('為什麼要先停在路邊？', '才能看清楚車子', '因為腳累了', '腳累了可以休息，可是停在路邊，是為了看清楚車子喔。', rightArt: 'road/car_red'),
    ]),
  ];
}

List<Part> _hand(bool big) => [
      Part(
        Scene('road/door', [
          const Sprite('mom', '媽媽', Look('road/mom', .3, .62, .22, .62), arts: {'hand': 'road/mom_hand'}),
          const Sprite('balloon', '氣球', Look('road/balloon', .72, .4, .14, .4), anim: Anim.bob),
          const Sprite('pup', '小狗', Look('road/leash_dog', .85, .82, .18, .24)),
          _hero(Look(pose('stand'), .55, .8, .15, .3), moves: {'hand': Look(pose('hold'), .44, .8, .15, .3)}),
        ]),
        [
          const TapStep(['mom'],
              say: '要出門了！要牽誰的手呢？',
              hint: '點一個',
              wrong: {'balloon': '氣球會飛走，要牽大人的手喔。', 'pup': '小狗牽著繩子，我們要牽大人的手喔。'},
              after: {'mom': 'hand', 'hero': 'hand'},
              word: '牽好了！',
              wordAt: 'hero',
              done: '牽著媽媽的手，車子比較看得到你。'),
        ],
      ),
      Part(
        Scene('road/parking', [
          const Sprite('car', '車子', Look('road/car_parked', .74, .56, .46, .32)),
          const Sprite('ball', '球', Look('road/ball', .5, .86, .08, .1), moves: {'away': Look('road/ball', .78, .8, .08, .1), 'back': Look('road/ball', .2, .9, .08, .1)}),
          const Sprite('mom', '媽媽', Look('road/mom_hand', .2, .6, .22, .62)),
          _hero(Look(pose('hold'), .34, .8, .15, .3)),
          _helper(Helper.dog, .92, .8, arts: {'stop': Helper.dog.art('stop')}),
        ]),
        [
          ChooseStep(const [
            Opt('tell', '跟媽媽說', ok: true, art: 'road/mom'),
            Opt('run', '跑去撿', reply: '等一下！車子旁邊，司機看不到你喔。再選一次。', art: 'ui/run'),
          ], say: '哎呀，球滾到車子旁邊了。怎麼辦？', hint: '跟媽媽說，還是跑去撿？', before: const {'ball': 'away'}, after: const {'ball': 'back'}, word: '好！', wordAt: 'mom', done: '對！先跟大人說，請大人幫忙撿。'),
          if (big) _why('為什麼要牽大人的手？', '車子看不到小小的人', '因為手冷', '手冷可以戴手套。牽手是因為小小的人，車子不容易看到。', rightArt: 'road/car_parked', wrongArt: 'road/balloon'),
        ],
      ),
    ];

List<Part> _carLevel(bool big) => [
      Part(
        Scene('road/car_inside', [
          _hero(Look(pose('sit'), .4, .6, .3, .56)),
          const Sprite('strap', '安全帶', Look(null, .4, .6, .3, .56), arts: {'on': 'road/belt_on'}),
          const Sprite('belt', '安全帶', Look('road/belt', .18, .36, .1, .14), arts: {'off': null}, drag: true),
          const Sprite('buckle', '扣子', Look('road/buckle', .52, .8, .08, .1)),
          const Sprite('bear', '小熊', Look('road/bear_out', .82, .4, .3, .42), arts: {'in': 'road/bear_in'}),
        ]),
        [
          const DragStep('belt', 'buckle', say: '坐好安全座椅。把安全帶拉過來，扣進扣子裡。', hint: '把安全帶拖到扣子', after: {'belt': 'off', 'strap': 'on'}, word: '喀！', wordAt: 'buckle', sfx: 'click', done: '喀！安全帶扣好了。'),
          const TapStep(['bear'], say: '隔壁車子的小熊把手伸出窗外。點點牠，請牠把手收回來。', hint: '點小熊', after: {'bear': 'in'}, word: '收好！', wordAt: 'bear', done: '手和頭都不要伸出窗外喔。'),
        ],
      ),
      Part(
        Scene('road/scooter_bg', [
          const Sprite('scooter', '機車', Look('road/scooter', .66, .64, .56, .5)),
          _hero(Look(pose('bare'), .3, .7, .17, .36), arts: {'helmet': pose('stand')}),
          const Sprite('kidhelmet', '安全帽', Look('road/kid_helmet', .62, .26, .14, .14), arts: {'off': null}, drag: true),
          _zone('head', '頭', .3, .44, .14, .14),
          const Sprite('chin', '扣環', Look(null, .3, .56, .07, .07), arts: {'on': 'road/chin_buckle'}),
        ]),
        [
          const DragStep('kidhelmet', 'head', say: '要坐機車了。把安全帽拖到頭上。', hint: '把安全帽拖到頭上', after: {'kidhelmet': 'off', 'hero': 'helmet', 'chin': 'on'}, word: '戴好！', wordAt: 'hero', sfx: 'pop', done: '戴上安全帽。'),
          const TapStep(['chin'], say: '扣環要扣好，點一下扣環。', hint: '點扣環', after: {'chin': 'start'}, word: '喀！', wordAt: 'hero', sfx: 'buckle', done: '扣好了，才可以坐機車。'),
          if (big) _why('為什麼坐車要繫安全帶？', '車子停下來，身體不會往前衝', '安全帶很好看', '安全帶是保護身體的，車子突然停下來，身體才不會往前衝。', rightArt: 'road/belt'),
        ],
      ),
    ];

List<Part> _lost(bool big, Settings s, HeroLook hero) {
  final call = s.call.zh;
  final scene = Scene('road/market', [
    _helper(Helper.dog, .14, .74),
    const Sprite('clerk', '店員', Look('road/clerk', .38, .7, .17, .42)),
    const Sprite('momkid', '帶小孩的媽媽', Look('road/mom_kid', .64, .72, .22, .44)),
    const Sprite('passer', '路人', Look('road/passer', .88, .72, .16, .44)),
    _hero(Look(pose('stand'), .5, .88, .14, .26), arts: {'stay': pose('stand')}),
  ]);
  final phone = s.phone;
  return [
    Part(scene, [
      const TapStep(['hero'], say: '夜市人好多，媽媽不見了。先不要亂跑，點小隊員，站在原地。', hint: '點小隊員', after: {'hero': 'stay'}, word: '站好！', wordAt: 'hero', sfx: 'whistle', done: '站在原地不要跑，媽媽會回來找你。'),
      const TapStep(['dog', 'clerk', 'momkid'],
          any: true,
          say: '找一個可以幫忙的人：穿制服的警察、店員，或是帶著小孩的媽媽。',
          hint: '點一個可以幫忙的人',
          wrong: {'passer': '可以先找穿制服的人，像警察、店員。'},
          word: '找到了！',
          done: '對！請他們幫忙找爸爸媽媽。'),
    ]),
    Part(Scene('road/market', [_helper(Helper.dog, .3, .74), _hero(Look(pose('stand'), .6, .8, .16, .3))]), [
      if (phone.isEmpty)
        const TapStep(['btn:好'], say: '爸爸媽媽還沒有把電話告訴我。請他們在家長模式打進來，下次我們一起背！', hint: '點「好」', word: '好！')
      else
        KeypadStep(phone,
            say: '跟警察說$call的電話。我們一起按一次。',
            hint: big ? '自己按按看' : '照著亮亮的數字按',
            glow: !big,
            lead: '我$call的電話是',
            wrongSay: big ? '再想想看，下一個數字是什麼？' : '照著亮亮的數字按喔。',
            word: '說好了！',
            done: '我$call的電話是${spokenDigits(phone)}。'),
      SayStep('大聲說一次',
          say: '現在對著手機，大聲說一次：我叫${hero.name.isEmpty ? '⋯⋯' : hero.name}，我$call的電話是⋯⋯',
          hint: '點了就大聲說（不會錄音）',
          word: '說得好！',
          done: '說得好！走失的時候，就這樣跟警察說。'),
      if (big) _why('為什麼走失了要站在原地？', '爸爸媽媽回來才找得到你', '因為想看夜市', '夜市很好看，可是站在原地，是為了讓爸爸媽媽找得到你喔。', rightArt: 'road/mom'),
    ]),
  ];
}

/// A phone number read digit by digit (「零、九、一、二⋯⋯」).
String spokenDigits(String digits) => digits.split('').map((d) => const ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'][int.parse(d)]).join('、');

// ------------------------------------------------------------ 救災世界

/// A stairwell: the lift on the left, the stairs on the right.
Part _stairs(String why, {String say = '要從哪裡下樓呢？'}) => Part(
      Scene('rescue/stairwell', [
        const Sprite('lift', '電梯', Look('rescue/lift', .28, .52, .3, .7)),
        const Sprite('stairs', '樓梯', Look('rescue/stairs', .72, .52, .34, .7)),
        _hero(Look(pose('stand'), .5, .86, .14, .26), moves: {'down': Look(pose('walk'), .76, .78, .12, .22)}),
      ]),
      [
        TapStep(const ['stairs'], say: say, hint: '點樓梯或電梯', wrong: {'lift': why}, after: const {'hero': 'down'}, word: '走樓梯！', wordAt: 'stairs', sfx: 'steps', done: '走樓梯，跟著大人到外面。'),
      ],
    );

List<Part> _quake(bool big) => [
      Part(
        const Scene('rescue/living', [
          Sprite('lamp', '燈', Look('rescue/lamp', .5, .1, .12, .2), anim: Anim.swing),
          Sprite('window', '窗戶', Look('rescue/window', .16, .36, .24, .36)),
          Sprite('shelf', '書櫃', Look('rescue/shelf', .87, .48, .2, .58)),
          Sprite('table', '桌子', Look('rescue/table', .48, .72, .44, .3)),
          Sprite('under', '桌子下面', Look(null, .48, .8, .3, .2)),
          Sprite('leg', '桌腳', Look(null, .3, .8, .08, .18)),
          Sprite('hero', '小隊員', Look('@hero/stand', .7, .82, .14, .28), moves: {
            'under': Look('@hero/crouch', .5, .8, .16, .2),
            'cover': Look('@hero/cover', .5, .8, .16, .2),
          }, drag: true),
        ], flags: {SceneFlag.shake: 'on'}),
        [
          const DragStep('hero', 'under',
              say: '地震了！趴、掩、穩。第一步「趴」：把小隊員拖到桌子下面。',
              hint: '把小隊員拖到桌子下面',
              startSfx: 'rumble',
              wrong: {'window': '窗戶旁邊玻璃會破，躲到桌子下面。', 'shelf': '書櫃的東西會掉下來，躲到桌子下面。'},
              after: {'hero': 'under'},
              word: '趴！',
              wordAt: 'table',
              done: '趴下來，躲到桌子下面。'),
          const TapStep(['hero'], say: '第二步「掩」：點小隊員，用手蓋住頭。', hint: '點小隊員', after: {'hero': 'cover'}, word: '掩！', wordAt: 'table', done: '手蓋住頭，保護頭。'),
          const HoldStep('leg', say: '第三步「穩」：按住桌腳不要放手，等搖晃停下來。', hint: '按住桌腳，等圈圈轉滿', seconds: 4, early: '還在搖喔，再按住一下。', loopSfx: 'rumble', after: {SceneFlag.shake: 'off'}, word: '穩！', wordAt: 'table', done: '搖晃停了，可以放手了。'),
          if (big)
            const ChooseStep([
              Opt('window', '窗戶旁邊', ok: true, art: 'rescue/window', reply: '對！窗戶旁邊玻璃會破，不能躲。'),
              Opt('shelf', '書櫃旁邊', ok: true, art: 'rescue/shelf', reply: '對！書櫃的東西會掉下來，不能躲。'),
              Opt('table', '桌子下面', art: 'rescue/table', reply: '桌子下面可以躲喔！再找找哪裡不能躲。'),
            ], say: '想一想：哪裡不能躲？', hint: '選一個不能躲的地方', word: '答對了！'),
        ],
      ),
      _stairs('地震不搭電梯，電梯可能會停在半路。我們走樓梯。', say: '搖完了，跟大人到外面空曠的地方。要從哪裡下樓？'),
    ];

List<Part> _fire(bool big) => [
      Part(
        Scene('rescue/fire_room', [
          const Sprite('smoke', '煙', Look('rescue/smoke', .5, .14, 1.04, .3), anim: Anim.drift),
          const Sprite('sink', '水龍頭', Look('rescue/sink', .17, .58, .22, .3)),
          const Sprite('closet', '衣櫃', Look('rescue/closet', .44, .5, .2, .5)),
          const Sprite('toys', '玩具', Look('rescue/toys', .62, .84, .14, .14)),
          const Sprite('door', '門', Look('rescue/door', .87, .56, .2, .54)),
          const Sprite('towel', '毛巾', Look('rescue/towel', .4, .86, .1, .1), arts: {'wet': 'rescue/towel_wet', 'off': null}, moves: {'wet': Look('rescue/towel_wet', .17, .52, .1, .1)}, drag: true),
          _zone('mouth', '嘴巴', .2, .8, .14, .14),
          _hero(Look(pose('crawl'), .2, .86, .2, .18), arts: {'towel': pose('crawl_towel')}, moves: {'out': Look(pose('crawl_towel'), .84, .86, .2, .18)}, drag: true),
        ]),
        [
          const DragStep('towel', 'sink', say: '有煙！先把毛巾拖到水龍頭，弄濕。', hint: '把毛巾拖到水龍頭', after: {'towel': 'wet'}, word: '嘩～', wordAt: 'sink', sfx: 'water', done: '毛巾濕了。'),
          const DragStep('towel', 'mouth', say: '把濕毛巾拿到嘴巴，摀住口鼻。', hint: '把毛巾拖到小隊員的嘴巴', after: {'towel': 'off', 'hero': 'towel'}, word: '摀好！', wordAt: 'hero', done: '濕毛巾摀住口鼻。'),
          const DragStep('hero', 'door',
              say: '蹲低低，沿著地板爬到門口。煙在上面，不要站起來。',
              hint: '把小隊員沿著地板拖到門口',
              ceiling: .55,
              wrong: {'closet': '不要躲在衣櫃裡，要出去。', 'toys': '玩具不要拿，人先出去。'},
              after: {'hero': 'out'},
              word: '蹲低低！',
              wordAt: 'door',
              done: '煙會往上飄，低低的地方比較好呼吸。'),
          if (big) _why('玩具還在房間裡，要回去拿嗎？', '不回去，人先出去', '回去拿', '玩具可以再買，人最重要。出來了就不回去。', rightArt: 'rescue/door', wrongArt: 'rescue/toys'),
        ],
      ),
      _stairs('火災不搭電梯。走樓梯到外面。'),
      Part(
        Scene('rescue/house_out', [
          _helper(Helper.cat, .78, .8, arts: {'phone': Helper.cat.art('phone')}),
          _hero(Look(pose('stand'), .58, .82, .14, .28)),
        ]),
        [
          KeypadStep('119', say: '到外面了！請大人打 119。我們練習按：一、一、九。', hint: '照順序按 1、1、9（練習用，不會真的打）', glow: !big, wrongSay: '照順序按：一、一、九。', after: const {'cat': 'phone'}, word: '嘟嚕嚕～', done: '電話通了。'),
          const TapStep(['btn:我家'], say: '喵喵在電話那頭問：「哪裡失火了？」', hint: '點「我家」', word: '我家！', wordAt: 'hero', sfx: 'siren', done: '說清楚哪裡失火，消防員就會來幫忙。'),
        ],
      ),
    ];

List<Part> _typhoon(bool big) => [
      Part(
        Scene('rescue/typhoon_room', [
          const Sprite('window', '窗戶', Look('rescue/win_open', .24, .4, .34, .5), arts: {'closed': 'rescue/win_closed'}),
          const Sprite('plant', '盆栽', Look('rescue/plant', .7, .58, .1, .2), moves: {'in': Look('rescue/plant', .46, .82, .1, .2)}, drag: true),
          const Sprite('clothes', '衣服', Look('rescue/clothes', .86, .4, .14, .16), moves: {'in': Look('rescue/clothes', .58, .84, .12, .14)}, drag: true),
          _zone('inside', '屋子裡', .5, .84, .3, .22),
          const Sprite('table', '桌子', Look('rescue/side_table', .16, .82, .2, .22)),
          const Sprite('torch', '手電筒', Look('rescue/torch', .36, .92, .1, .08), moves: {'table': Look('rescue/torch', .16, .7, .1, .08), 'lit': Look('rescue/torch_on', .16, .7, .1, .08)}, drag: true),
          _hero(Look(pose('stand'), .5, .62, .14, .28)),
        ], flags: {SceneFlag.dark: 'off'}),
        [
          const TapStep(['window'], say: '颱風來了，風好大。點窗戶，把它關起來。', hint: '點窗戶', startSfx: 'wind', after: {'window': 'closed'}, word: '喀！', wordAt: 'window', sfx: 'window', done: '窗戶關好，雨就不會跑進來。'),
          const DragStep('plant', 'inside', say: '陽台的盆栽會被風吹倒，拖進屋子裡。', hint: '把盆栽拖進來', after: {'plant': 'in'}, word: '收好！', wordAt: 'plant', done: '盆栽收進來了。'),
          const DragStep('clothes', 'inside', say: '還有晾在外面的衣服，也拖進來。', hint: '把衣服拖進來', after: {'clothes': 'in'}, word: '收好！', wordAt: 'clothes', done: '衣服也收好了。'),
          const DragStep('torch', 'table', say: '準備手電筒，放在桌上。', hint: '把手電筒拖到桌上', after: {'torch': 'table'}, word: '準備好！', wordAt: 'table'),
          const TapStep(['torch'], say: '停電了！點手電筒。', hint: '點手電筒', before: {SceneFlag.dark: 'on'}, after: {'torch': 'lit', SceneFlag.dark: 'lit'}, word: '亮了！', wordAt: 'torch', sfx: 'switch', done: '颱風天待在家裡最安全，不去海邊看浪。'),
          if (big) _why('颱風天可以去海邊看浪嗎？', '不可以，待在家', '可以，去看看', '颱風天的浪很大，很危險。我們待在家裡。', rightArt: 'rescue/win_closed', wrongArt: 'ui/run'),
        ],
      ),
    ];

// ------------------------------------------------------------ 身體世界

/// The places on the squad member in a swimsuit, and their light.
const bodySpots = [
  ('head', '頭', 'green', .42, .23, '綠燈：頭，拍拍頭可以。'),
  ('shoulder', '肩膀', 'green', .35, .56, '綠燈：肩膀，拍拍肩膀可以。'),
  ('hand', '手', 'green', .575, .73, '綠燈：手，握手、擊掌都可以。'),
  ('face', '臉', 'yellow', .465, .43, '黃燈：臉，要先問我喔。'),
  ('tummy', '肚子', 'yellow', .42, .68, '黃燈：肚子，要先問我喔。'),
  ('swim', '泳衣遮住的地方', 'red', .42, .78, '紅燈：泳衣遮住的地方是我自己的，別人不可以看、不可以摸。'),
];

List<Part> _bodyLights(bool big) {
  final scene = Scene('body/pool', [
    _hero(Look(pose('swim'), .42, .52, .4, .96)),
    for (final (id, zh, light, x, y, _) in bodySpots) Sprite(id, zh, Look('body/dot_white', x, y, .07, .09), arts: {'lit': 'body/dot_$light'}),
    _helper(Helper.bunny, .86, .78),
  ]);
  ChooseStep ask(String id) {
    final (_, zh, light, _, _, line) = bodySpots.firstWhere((b) => b.$1 == id);
    return ChooseStep([
      for (final (l, lz) in [('green', '綠燈'), ('yellow', '黃燈'), ('red', '紅燈')]) Opt(l, lz, ok: l == light, art: 'body/light_$l', reply: l == light ? line : '再想想看，$zh是什麼燈呢？'),
    ], say: '這裡是$zh，是什麼燈？', hint: '選一個燈', before: {id: 'start'}, after: {id: 'lit'}, extra: Extra.lights, word: '答對了！', wordAt: id, sfx: 'right');
  }

  return [
    Part(scene, [
      TapStep([for (final b in bodySpots) b.$1],
          say: '小隊員穿著泳衣。點點看身體的每個地方，聽聽它是什麼燈。',
          hint: '點身體上的圓點',
          extra: Extra.lights,
          lines: {for (final b in bodySpots) b.$1: b.$6},
          tapStates: {
            for (final b in bodySpots) b.$1: {b.$1: 'lit'},
          },
          word: '紅綠燈！',
          done: '泳衣遮住的地方，是你自己的。'),
      if (big) ...[ask('hand'), ask('tummy'), ask('swim')],
      const TapStep(['btn:知道了'], say: '爸爸媽媽幫你洗澡、醫生看病而且爸爸媽媽在旁邊，才可以。', hint: '點「知道了」', extra: Extra.lights, word: '知道了！', done: '你的身體，是你自己的。'),
    ]),
  ];
}

List<Part> _sayNo(bool big, Settings s) {
  Part situation(String id, String zh, String art, String say, String ok) => Part(
        Scene('body/park', [
          _hero(Look(pose('stand'), .3, .76, .17, .36), arts: {'stop': pose('stop')}),
          Sprite(id, zh, Look('body/${art}_ask', .66, .7, .26, .5), moves: {'back': Look('body/${art}_ok', .84, .72, .22, .44)}),
          _helper(Helper.bunny, .1, .84, w: .13, h0: .26),
        ]),
        [
          HoldStep('btn:不要！', say: say, hint: '按住「不要！」', seconds: 2, early: '按久一點，大聲說「不要！」', loopSfx: 'fill', after: {'hero': 'stop', id: 'back'}, word: '不要！', wordAt: 'hero', sfx: 'no', done: ok),
        ],
      );
  final names = s.trusted.map((a) => a.zh).join('、');
  return [
    situation('bear', '熊阿姨', 'bear', '熊阿姨想抱抱你，可是你現在不想要。按住「不要！」，大聲說出來。', '熊阿姨說：「好，我知道了。」'),
    situation('monkey', '猴子哥哥', 'monkey', '猴子哥哥一直搔你癢癢，你不想玩了。按住「不要！」。', '猴子哥哥說：「好，我停下來。」'),
    situation('elephant', '象爺爺', 'elephant', '象爺爺想親你的臉，你不想要。按住「不要！」。', '象爺爺說：「好，那我們擊掌。」'),
    Part(
      Scene('body/park', [
        _hero(Look(pose('hug'), .36, .76, .17, .36), arts: {'stop': pose('stand')}),
        const Sprite('puppy', '小狗', Look('body/puppy_no', .66, .82, .2, .26), arts: {'happy': 'body/puppy_ok'}),
        _helper(Helper.bunny, .1, .84, w: .13, h0: .26),
      ]),
      [
        ChooseStep(const [
          Opt('stop', '停下來', ok: true, art: 'ui/stop_hand'),
          Opt('hug', '還是抱', reply: '小狗說不要了，我們要停下來喔。', art: 'body/puppy_no'),
        ], say: '你想抱小狗，可是小狗搖搖頭說：「不要。」怎麼辦？', hint: '停下來，還是還是抱？', after: const {'hero': 'stop', 'puppy': 'happy'}, word: '好！', wordAt: 'puppy', done: '對！別人說不要，我們也要停下來。'),
        if (big) _why('為什麼可以說「不要」？', '我的身體我決定', '因為我在生氣', '不用生氣也可以說不要。你的身體，你自己決定。'),
        TapStep(const ['btn:好'],
            say: '你的身體你決定，不管是誰，都可以說不要。不舒服的事、怪怪的事，要去跟$names說，不是你的錯。',
            hint: '點「好」',
            extra: Extra.trusted,
            word: '說好了！',
            sfx: 'cheer',
            done: '記得喔，要跟$names說。'),
      ],
    ),
  ];
}

// ------------------------------------------------------------ 家裡世界

List<Part> _room(String bg, List<Sprite> sprites, List<Hazard> all, {required int small, required bool big, required String say, required String done}) => [
      Part(Scene(bg, [...sprites, _helper(Helper.bunny, .9, .84, w: .13, h0: .26)]), [
        FindStep(big ? all : all.take(small).toList(), say: big ? '$say 全部找出來！' : say, hint: big ? '找出 ${all.length} 個危險的東西' : '點亮亮的地方', oneAtATime: !big, askWhy: big, done: done),
      ]),
    ];

ChooseStep _hazardWhy(String ask, String right, String wrong) => ChooseStep([Opt('right', right, ok: true), Opt('wrong', wrong, reply: '再想想看。')], say: ask, hint: '為什麼？', done: '對！$right。', word: '答對了！');

List<Part> _kitchen(bool big) => _room(
      'home/kitchen',
      const [
        Sprite('pot', '鍋子', Look('home/pot_out', .3, .44, .22, .16), arts: {'safe': 'home/pot_in'}),
        Sprite('drawer', '抽屜', Look('home/drawer', .56, .7, .22, .12), arts: {'shut': 'home/drawer_shut'}),
        Sprite('knife', '菜刀', Look('home/knife', .6, .5, .14, .08), moves: {'safe': Look(null, .56, .7, .14, .08)}, drag: true),
        Sprite('kettle', '熱水壺', Look('home/kettle_cord', .8, .44, .14, .32), arts: {'safe': 'home/kettle_safe'}),
        Sprite('bag', '塑膠袋', Look('home/bag', .3, .9, .14, .12), moves: {'safe': Look(null, .14, .66, .14, .12)}, drag: true),
        Sprite('bin', '櫃子', Look('home/cupboard', .14, .7, .18, .2)),
      ],
      [
        Hazard('pot', found: '熱鍋子的把手朝外，會被撞到。', fix: '點一下，把手轉進去。', safe: {'pot': 'safe'}, why: _hazardWhy('為什麼把手要轉進去？', '才不會撞到打翻', '比較好看', )),
        Hazard('knife', found: '菜刀放在桌邊，會掉下來。', fix: '把菜刀拖進抽屜。', dragTo: 'drawer', safe: {'knife': 'safe', 'drawer': 'shut'}, why: _hazardWhy('為什麼菜刀要收好？', '刀子很利，會割到手', '刀子會不見')),
        Hazard('kettle', found: '熱水壺的電線垂下來，一拉就倒。', fix: '點一下，把電線推進去。', safe: {'kettle': 'safe'}, why: _hazardWhy('為什麼電線不能垂下來？', '一拉熱水會倒下來', '電線會冷')),
        Hazard('bag', found: '地上有塑膠袋，不可以套在頭上玩。', fix: '把塑膠袋收進櫃子。', dragTo: 'bin', safe: {'bag': 'safe'}, why: _hazardWhy('為什麼塑膠袋不能套頭？', '會不能呼吸', '會看不到電視')),
      ],
      small: 3,
      big: big,
      say: '廚房裡有危險的東西，找出來，把它變安全。',
      done: '廚房變安全了！',
    );

List<Part> _living(bool big) => _room(
      'home/living',
      const [
        Sprite('socket', '插座', Look('home/socket', .2, .74, .08, .1), arts: {'safe': 'home/socket_cover'}),
        Sprite('cabinet', '高櫃子', Look('home/high_cabinet', .5, .2, .2, .18)),
        Sprite('pills', '藥', Look('home/medicine', .44, .62, .1, .1), moves: {'safe': Look('home/medicine', .5, .2, .08, .08)}, drag: true),
        Sprite('coins', '硬幣和鈕扣', Look('home/coins', .64, .88, .12, .08), moves: {'safe': Look(null, .82, .84, .1, .08)}, drag: true),
        Sprite('box', '盒子', Look('home/box_open', .84, .86, .12, .1), arts: {'shut': 'home/box_shut'}),
        Sprite('chair', '椅子', Look('home/chair', .86, .56, .14, .26), moves: {'safe': Look('home/chair', .66, .64, .14, .26)}),
      ],
      [
        Hazard('socket', found: '插座沒有蓋子，手指頭不能放進去。', fix: '點一下，蓋上插座蓋。', safe: {'socket': 'safe'}, why: _hazardWhy('為什麼插座要蓋起來？', '裡面有電，會電到', '插座會冷')),
        Hazard('pills', found: '桌上的藥看起來像糖果，可是不能自己吃。', fix: '把藥拖到高高的櫃子。', dragTo: 'cabinet', safe: {'pills': 'safe'}, why: _hazardWhy('為什麼藥要放高高？', '藥要大人給才能吃', '藥很重')),
        Hazard('coins', found: '小小的硬幣和鈕扣，放進嘴巴會卡住。', fix: '把它們拖進盒子。', dragTo: 'box', safe: {'coins': 'safe', 'box': 'shut'}, why: _hazardWhy('為什麼小東西不能放嘴巴？', '會卡在喉嚨', '會不好吃')),
        Hazard('chair', found: '窗戶旁邊有椅子，小朋友會爬上去。', fix: '點一下，把椅子移開。', safe: {'chair': 'safe'}, why: _hazardWhy('為什麼椅子不能放在窗邊？', '爬上去會掉下去', '椅子會曬太陽')),
      ],
      small: 3,
      big: big,
      say: '客廳裡有危險的東西，找出來，把它變安全。',
      done: '客廳變安全了！',
    );

List<Part> _bath(bool big) => _room(
      'home/bath',
      const [
        Sprite('tub', '浴缸', Look('home/tub_full', .32, .66, .5, .34), arts: {'safe': 'home/tub_empty'}),
        Sprite('wet', '濕濕的地板', Look('home/floor_wet', .66, .9, .26, .1), arts: {'safe': 'home/mat'}),
        Sprite('taps', '水龍頭', Look('home/shower', .78, .4, .16, .26), arts: {'safe': 'home/shower_ok'}),
        Sprite('cold', '冷水', Look('home/knob_cold', .72, .58, .07, .09)),
        Sprite('hot', '熱水', Look('home/knob_hot', .84, .58, .07, .09)),
      ],
      [
        Hazard('tub', found: '浴缸裝滿了水，小小的人會滑進去。', fix: '點一下，拔掉塞子把水放掉。', safe: {'tub': 'safe'}, why: _hazardWhy('為什麼浴缸的水要放掉？', '小朋友會滑進水裡', '水會變冷')),
        Hazard('wet', found: '地板濕濕的，會滑倒。', fix: '點一下，鋪上防滑墊。', safe: {'wet': 'safe'}, why: _hazardWhy('為什麼要鋪防滑墊？', '才不會滑倒', '墊子很漂亮')),
        Hazard('taps', found: '洗澡的熱水，直接開會太燙。', fix: '先點藍色的冷水，再點紅色的熱水。', fixTaps: ['cold', 'hot'], safe: {'taps': 'safe'}, why: _hazardWhy('為什麼要先開冷水？', '熱水太燙會燙傷', '冷水比較好聽'), word: '找到了！'),
      ],
      small: 2,
      big: big,
      say: '浴室裡有危險的地方，找出來，把它變安全。',
      done: '浴室變安全了！',
    );

List<Part> _balcony(bool big) => _room(
      'home/balcony',
      const [
        Sprite('stool', '椅子', Look('home/stool', .34, .72, .16, .24), moves: {'safe': Look(null, .12, .84, .16, .24)}, drag: true),
        Sprite('window', '窗戶', Look('home/bwin_open', .78, .4, .3, .5), arts: {'safe': 'home/bwin_closed'}),
        Sprite('boxes', '箱子', Look('home/boxes', .56, .78, .16, .2), moves: {'safe': Look(null, .12, .84, .16, .24)}, drag: true),
        Sprite('inside', '屋子裡', Look('home/indoor_mat', .12, .9, .2, .14)),
      ],
      [
        Hazard('stool', found: '欄杆旁邊有椅子，小朋友會爬上去。', fix: '把椅子拖進屋子裡。', dragTo: 'inside', safe: {'stool': 'safe'}, why: _hazardWhy('為什麼欄杆旁邊不能放椅子？', '爬上去會掉下去', '椅子會被雨淋')),
        Hazard('window', found: '窗戶打開了，風很大。', fix: '點一下，把窗戶關好。', safe: {'window': 'safe'}, why: _hazardWhy('為什麼窗戶要關好？', '小朋友不會從窗戶掉出去', '蚊子會飛進來')),
        Hazard('boxes', found: '欄杆旁邊有箱子，也會被爬上去。', fix: '把箱子拖進屋子裡。', dragTo: 'inside', safe: {'boxes': 'safe'}, why: _hazardWhy('為什麼箱子要搬走？', '踩上去會掉下去', '箱子會被吹走')),
      ],
      small: 2,
      big: big,
      say: '陽台有危險的地方，找出來，把它變安全。',
      done: '陽台變安全了！',
    );
