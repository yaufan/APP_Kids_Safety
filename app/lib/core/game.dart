import 'content.dart';

/// What the squad member looks like (chosen at the first start; parent mode
/// can change it and add a name).
class HeroLook {
  const HeroLook({this.hair = 0, this.skin = 0, this.helmet = 0, this.name = '', this.made = false});

  static const hairs = 4, skins = 4, helmets = 6;

  /// Hair colours, skins and helmet colours (assets/art/hero/*.svg are drawn
  /// with stand-in colours that the app swaps for these).
  static const hairColors = [0xFF3A2A22, 0xFF7A4A2A, 0xFFE9B64B, 0xFFC7664A];
  static const skinColors = [0xFFF6D3B3, 0xFFE8B88E, 0xFFC98C5C, 0xFF8F5A3A];
  static const helmetColors = [0xFFFFC400, 0xFFFF8A1E, 0xFFE8392F, 0xFF1F6FD6, 0xFF1FA64A, 0xFFB45CD6];
  static const helmetZh = ['黃色', '橘色', '紅色', '藍色', '綠色', '紫色'];

  final int hair, skin, helmet;

  /// The child's name as a parent typed it (may be empty: 「小隊員」).
  final String name;

  /// Whether the child has chosen a look yet (the first start asks).
  final bool made;

  static const maxName = 8;

  String get callName => name.isEmpty ? '小隊員' : name;

  HeroLook copyWith({int? hair, int? skin, int? helmet, String? name, bool? made}) => HeroLook(
        hair: (hair ?? this.hair) % hairs,
        skin: (skin ?? this.skin) % skins,
        helmet: (helmet ?? this.helmet) % helmets,
        name: cleanName(name ?? this.name),
        made: made ?? this.made,
      );

  /// A name kept short and on one line.
  static String cleanName(String n) {
    final t = n.replaceAll(RegExp(r'[\r\n\t]'), ' ').trim();
    // Counted by code point, so a name in 中文 is never cut in half.
    return t.runes.length > maxName ? String.fromCharCodes(t.runes.take(maxName)) : t;
  }

  Map<String, dynamic> toJson() => {'hair': hair, 'skin': skin, 'helmet': helmet, 'name': name, 'made': made};

  factory HeroLook.fromJson(dynamic j) {
    if (j is! Map) return const HeroLook();
    int pick(String k, int n) => j[k] is int && (j[k] as int) >= 0 && (j[k] as int) < n ? j[k] as int : 0;
    return HeroLook(
      hair: pick('hair', hairs),
      skin: pick('skin', skins),
      helmet: pick('helmet', helmets),
      name: j['name'] is String ? cleanName(j['name'] as String) : '',
      made: j['made'] == true,
    );
  }
}

/// What a parent set (parent mode).
class Settings {
  const Settings({
    this.age = Age.small,
    this.minutes = 15,
    this.off = const {},
    this.bodyIntroSeen = false,
    this.phone = '',
    this.call = Adult.mom,
    this.trusted = const [Adult.mom, Adult.dad],
    this.music = true,
    this.sounds = true,
    this.voice = true,
    this.full = true,
  });

  final Age age;

  /// How long one sitting may be before a rest.
  final int minutes;

  /// Worlds a parent turned off (身體世界 may be; at least one stays on).
  final Set<World> off;

  /// The parent has read the page before 身體世界.
  final bool bodyIntroSeen;

  /// The parent's phone number, digits only, for practising in 走失了. Kept
  /// in the save file on this phone only; never written anywhere else, never
  /// in a log (and not in [toString]).
  final String phone;

  /// What the child calls that parent (「我媽媽的電話是⋯⋯」). No address and
  /// no full name are kept.
  final Adult call;

  /// The safe grown-ups (2 to 4) shown at the end of 說「不要！」.
  final List<Adult> trusted;
  final bool music;
  final bool sounds;
  final bool voice;

  /// The full version (everything); on while testing.
  final bool full;

  static const minuteChoices = [5, 10, 15, 20, 30];
  static const minTrusted = 2, maxTrusted = 4;
  static const minPhone = 6, maxPhone = 12;

  /// Digits only, and only a sensible length (else empty: not set).
  static String cleanPhone(String typed) {
    final d = typed.replaceAll(RegExp(r'[^0-9]'), '');
    return d.length >= minPhone && d.length <= maxPhone ? d : '';
  }

  /// [list] made fit: no repeats, at most four, at least two (媽媽 and 爸爸 fill up).
  static List<Adult> tidyTrusted(Iterable<Adult> list) {
    final out = <Adult>[];
    for (final a in list) {
      if (!out.contains(a) && out.length < maxTrusted) out.add(a);
    }
    for (final a in [Adult.mom, Adult.dad, Adult.teacher]) {
      if (out.length >= minTrusted) break;
      if (!out.contains(a)) out.add(a);
    }
    return out;
  }

  /// Never every world off: 馬路世界 comes back.
  static Set<World> tidyOff(Set<World> off) => off.length >= World.values.length ? ({...off}..remove(World.road)) : {...off};

  bool shows(World w) => !off.contains(w);

  /// Whether [lv] can be played: its world is on and (in the free version) it is free.
  bool open(Lv lv) => shows(lv.world) && (full || lv.free);

  Settings copyWith({Age? age, int? minutes, Set<World>? off, bool? bodyIntroSeen, String? phone, Adult? call, List<Adult>? trusted, bool? music, bool? sounds, bool? voice, bool? full}) => Settings(
        age: age ?? this.age,
        minutes: minutes ?? this.minutes,
        off: off == null ? this.off : tidyOff(off),
        bodyIntroSeen: bodyIntroSeen ?? this.bodyIntroSeen,
        phone: phone == null ? this.phone : cleanPhone(phone),
        call: call ?? this.call,
        trusted: trusted == null ? this.trusted : tidyTrusted(trusted),
        music: music ?? this.music,
        sounds: sounds ?? this.sounds,
        voice: voice ?? this.voice,
        full: full ?? this.full,
      );

  Map<String, dynamic> toJson() => {
        'age': age.name,
        'minutes': minutes,
        'off': [for (final w in off) w.name],
        'bodyIntroSeen': bodyIntroSeen,
        'phone': phone,
        'call': call.name,
        'trusted': [for (final a in trusted) a.name],
        'music': music,
        'sounds': sounds,
        'voice': voice,
        'full': full,
      };

  factory Settings.fromJson(Map<String, dynamic> j) {
    final m = j['minutes'], off = j['off'], trusted = j['trusted'];
    bool flag(String k, bool d) => j[k] is bool ? j[k] as bool : d;
    final call = Adult.values.asNameMap()[j['call']];
    return Settings(
      age: Age.values.asNameMap()[j['age']] ?? Age.small,
      minutes: m is int && minuteChoices.contains(m) ? m : 15,
      off: tidyOff({
        if (off is List)
          for (final n in off) ?World.values.asNameMap()[n],
      }),
      bodyIntroSeen: flag('bodyIntroSeen', false),
      phone: j['phone'] is String ? cleanPhone(j['phone'] as String) : '',
      call: call != null && call != Adult.teacher ? call : Adult.mom,
      trusted: trusted is List ? tidyTrusted([for (final n in trusted) ?Adult.values.asNameMap()[n]]) : const [Adult.mom, Adult.dad],
      music: flag('music', true),
      sounds: flag('sounds', true),
      voice: flag('voice', true),
      full: flag('full', true),
    );
  }

  /// Says nothing of the phone number (so it never lands in a log by accident).
  @override
  String toString() => 'Settings(${age.name}, $minutes min, phone ${phone.isEmpty ? 'not set' : 'set'})';
}

/// Everything kept on the phone: one small file (store.dart).
class Game {
  const Game({this.settings = const Settings(), this.hero = const HeroLook(), this.plays = const {}, this.real = const {}, this.restSince});

  final Settings settings;
  final HeroLook hero;

  /// How many times each level was finished (a badge from the first time).
  final Map<Lv, int> plays;

  /// The real-life checklist ticks (gold badges).
  final Set<RealLife> real;

  /// When the play time ran out (null: playing).
  final DateTime? restSince;

  static const restLength = Duration(hours: 1);

  bool done(Lv lv) => (plays[lv] ?? 0) > 0;

  /// The badges on the helmet, in level order.
  List<Lv> get badges => [for (final l in Lv.values) if (done(l)) l];

  /// Worlds with every level done (their crest).
  List<World> get crests => [for (final w in World.values) if (w.levels.every(done)) w];

  /// The next level to play in [w]: the first not done, else null.
  Lv? nextIn(World w) => w.levels.where((l) => !done(l)).firstOrNull;

  /// Resting for an hour after the time ran out. A clock moved back (now
  /// before the rest began) ends the rest.
  bool resting(DateTime now) {
    final since = restSince;
    if (since == null) return false;
    final d = now.difference(since);
    return !d.isNegative && d < restLength;
  }

  Game finished(Lv lv) => copyWith(plays: {...plays, lv: (plays[lv] ?? 0) + 1});

  Game tick(RealLife r, bool on) => copyWith(real: on ? {...real, r} : ({...real}..remove(r)));

  Game rest(DateTime now) => copyWith(restSince: now);

  Game playOn() => copyWith(clearRest: true);

  Game copyWith({Settings? settings, HeroLook? hero, Map<Lv, int>? plays, Set<RealLife>? real, DateTime? restSince, bool clearRest = false}) => Game(
        settings: settings ?? this.settings,
        hero: hero ?? this.hero,
        plays: plays ?? this.plays,
        real: real ?? this.real,
        restSince: clearRest ? null : (restSince ?? this.restSince),
      );

  Map<String, dynamic> toJson() => {
        'version': 1,
        'settings': settings.toJson(),
        'hero': hero.toJson(),
        'plays': {for (final e in plays.entries) e.key.name: e.value},
        'real': [for (final r in real) r.name],
        if (restSince != null) 'restSince': restSince!.toIso8601String(),
      };

  factory Game.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const Game();
    final p = j['plays'], r = j['real'], rest = j['restSince'];
    return Game(
      settings: Settings.fromJson(j['settings'] is Map ? (j['settings'] as Map).cast<String, dynamic>() : const {}),
      hero: HeroLook.fromJson(j['hero']),
      plays: {
        if (p is Map)
          for (final e in p.entries)
            if (Lv.values.asNameMap()[e.key] != null && e.value is int && (e.value as int) > 0) Lv.values.asNameMap()[e.key]!: e.value as int,
      },
      real: {
        if (r is List)
          for (final n in r) ?RealLife.values.asNameMap()[n],
      },
      restSince: rest is String ? DateTime.tryParse(rest) : null,
    );
  }
}
