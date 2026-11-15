/// The names of everything in 安全小隊 (docs/design.md): the two ages, the
/// three helpers, the four worlds and their 14 levels, the grown-ups a child
/// can call, and the real-life checklist.
library;

/// 小小 (3～4): the helper shows the way, one thing at a time, what to tap
/// glows. 大 (5～6): the whole chain alone, order matters, a 「為什麼」
/// question, the phone number without help.
enum Age {
  small('小小', '3～4 歲'),
  big('大', '5～6 歲');

  const Age(this.zh, this.years);

  final String zh;
  final String years;
}

/// The three helpers. They show and talk; the child does.
enum Helper {
  dog('汪汪警察'),
  cat('喵喵消防員'),
  bunny('兔兔護士');

  const Helper(this.zh);

  final String zh;

  /// `assets/art/helpers/<name>_<pose>.svg` (stand, salute; the dog also stop).
  String art([String pose = 'stand']) => 'helpers/${name}_$pose';
}

/// The four worlds, each with its road-sign shape and colour.
enum World {
  road('馬路世界', Helper.dog, 0xFF1F6FD6, '藍色圓形的路牌'),
  rescue('救災世界', Helper.cat, 0xFFE8392F, '紅色方形的路牌'),
  body('身體世界', Helper.bunny, 0xFF1FA64A, '綠色圓形的路牌'),
  home('家裡世界', Helper.bunny, 0xFFF2B600, '黃色菱形的路牌');

  const World(this.zh, this.helper, this.color, this.signZh);

  final String zh;
  final Helper helper;
  final int color;
  final String signZh;

  String get sign => 'ui/sign_$name';
  String get crest => 'badges/crest_$name';

  List<Lv> get levels => [for (final l in Lv.values) if (l.world == this) l];
}

/// The 14 levels of 0.1, in the order they are played in each world.
enum Lv {
  light(World.road, '紅綠燈', '紅燈停、綠燈行、小綠人跑就等下一次',
      ask: '問問小朋友：我們家附近的路口，紅綠燈在哪裡？小綠人在做什麼？', real: '下次過馬路，一起看小綠人：走路才走，跑起來就等下一次。'),
  cross(World.road, '過馬路五步', '集、轉、探、避、揮',
      ask: '問問小朋友：過馬路的五步是哪五個字？你最喜歡哪一步？', real: '下次出門，在真的路口一起做一次「集、轉、探、避、揮」。'),
  hand(World.road, '牽手走', '牽大人的手、不在車子旁邊跑',
      ask: '問問小朋友：球滾到車子旁邊，你會怎麼做？', real: '下次出門，從家門口就牽好手；東西掉了，先跟大人說。'),
  car(World.road, '坐車', '安全帶、安全座椅、安全帽',
      ask: '問問小朋友：坐車第一件事要做什麼？坐機車呢？', real: '下次坐車，讓小朋友自己聽聽看安全帶「喀」的聲音。'),
  lost(World.road, '走失了', '站在原地、找穿制服的人、說電話',
      ask: '問問小朋友：如果找不到爸爸媽媽，要先做什麼？可以找誰幫忙？', real: '下次去夜市或賣場，先約好：走散了就站在原地，找穿制服的人。'),
  quake(World.rescue, '地震', '趴、掩、穩，不搭電梯',
      ask: '問問小朋友：家裡哪一張桌子可以躲？哪裡不能躲？', real: '在家裡找一張桌子，一起做一次「趴、掩、穩」。'),
  fire(World.rescue, '火災', '低姿勢、濕毛巾、走樓梯、打 119',
      ask: '問問小朋友：有煙的時候，要站著走還是蹲低低？要搭電梯嗎？', real: '一起在家裡走一次：從房間到大門，再到樓梯。'),
  typhoon(World.rescue, '颱風', '待在家、關窗、收陽台、手電筒',
      ask: '問問小朋友：颱風天可以去海邊看浪嗎？停電了要用什麼？', real: '一起找找家裡的手電筒放在哪裡，放到小朋友知道的地方。'),
  bodyLights(World.body, '身體紅綠燈', '泳衣遮住的地方是自己的',
      ask: '問問小朋友：身體的紅燈在哪裡？誰可以幫你洗澡？', real: '洗澡的時候，用「紅綠燈」的說法，輕鬆地再說一次。'),
  sayNo(World.body, '說「不要！」', '說不要、也尊重別人的不要',
      ask: '問問小朋友：不想被抱的時候，可以怎麼說？別人說不要，我們要怎麼做？', real: '在家裡練習：小朋友說「不要」的時候，大人說「好」，停下來。'),
  kitchen(World.home, '廚房', '熱鍋把手轉進去、菜刀收好',
      ask: '問問小朋友：我們家的鍋子把手，都朝哪裡？', real: '一起去廚房看看：鍋子把手、菜刀、熱水壺放在哪裡。'),
  living(World.home, '客廳', '插座蓋、藥放高高、小東西不放嘴巴',
      ask: '問問小朋友：藥看起來像糖果，可以自己吃嗎？', real: '一起去看看家裡的插座有沒有蓋子，藥有沒有放在高高的地方。'),
  bath(World.home, '浴室', '浴缸放水、防滑墊、先冷水再熱水',
      ask: '問問小朋友：洗澡的時候，要先開冷水還是熱水？', real: '下次洗澡，讓小朋友先摸摸水，說說看是冷還是熱。'),
  balcony(World.home, '陽台', '欄杆旁不放椅子、窗戶關好',
      ask: '問問小朋友：陽台的欄杆旁邊，可以放椅子嗎？為什麼？', real: '一起去陽台看看：欄杆旁邊有沒有可以爬的東西。');

  const Lv(this.world, this.zh, this.learn, {required this.ask, required this.real});

  final World world;
  final String zh;

  /// What it teaches (the world page and the parent's cheat sheet).
  final String learn;

  /// The question card for the parent at the end.
  final String ask;

  /// 「回真實生活做做看」.
  final String real;

  /// The free version: all of 馬路世界 and the earthquake level.
  bool get free => world == World.road || this == Lv.quake;

  String get badge => 'badges/$name';
}

/// Grown-ups a child can call or trust (parent mode picks them).
enum Adult {
  mom('媽媽', 'mom'),
  dad('爸爸', 'dad'),
  ama('阿嬤', 'grandma'),
  agong('阿公', 'grandpa'),
  nainai('奶奶', 'grandma'),
  yeye('爺爺', 'grandpa'),
  waipo('外婆', 'grandma'),
  waigong('外公', 'grandpa'),
  teacher('老師', 'teacher'),
  ayi('阿姨', 'aunt'),
  shushu('叔叔', 'uncle');

  const Adult(this.zh, this.icon);

  final String zh;
  final String icon;

  String get art => 'ui/adult_$icon';

  /// Who a child calls on the phone (not the teacher).
  static List<Adult> get callable => [for (final a in values) if (a != teacher) a];
}

/// The real-life checklist (parent mode): each tick is a gold badge.
enum RealLife {
  cross('在真的路口做過「集轉探避揮」'),
  hand('出門都牽著大人的手'),
  belt('坐車都繫安全帶、坐安全座椅'),
  phone('背得出爸爸媽媽的電話'),
  quake('家裡演練過一次地震'),
  fire('一起看過家裡怎麼走到外面'),
  body('一起聊過身體紅綠燈'),
  socket('看過家裡的插座和藥');

  const RealLife(this.zh);

  final String zh;
}
