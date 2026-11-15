/// The kinds of steps a level is made of (docs/design.md 「玩法」: the helper
/// says one line → the squad member does it → the picture answers → why).
/// One screen knows how to show each kind (features/level/step_panel.dart);
/// run.dart keeps the score of what is done. Nothing can be failed: a wrong
/// tap or drop gets a calm word and another go.
///
/// Targets are sprite ids, or a big button under the picture written
/// `btn:<label>`, or one of the five crossing words written `word:<字>`.
library;

/// Something extra shown under the picture.
enum Extra { none, words, trusted, lights }

sealed class Step {
  const Step({
    required this.say,
    this.hint,
    this.before = const {},
    this.after = const {},
    this.done,
    this.word,
    this.wordAt,
    this.sfx = 'right',
    this.startSfx,
    this.extra = Extra.none,
  });

  /// What the helper says when the step starts (spoken and shown).
  final String say;

  /// A short line under the picture (「把小隊員拖到桌子下面」).
  final String? hint;

  /// Things' states when the step starts.
  final Map<String, String> before;

  /// Things' states once it is done (the picture answers).
  final Map<String, String> after;

  /// Said when it is done (why it is done so).
  final String? done;

  /// The comic word that bursts out when it is done (布穀！喀！).
  final String? word;

  /// Where the word bursts (a sprite id; null: the middle).
  final String? wordAt;

  /// Played when it is done, and when it starts.
  final String sfx;
  final String? startSfx;
  final Extra extra;

  /// The finger moves that do this step (the tests play every level so).
  List<Ev> solve();
}

/// Tap each target once ([any]: one of them is enough). [lines] are said at
/// each tap, [tapStates] change the picture at each tap; [wrong] are things
/// that get a gentle word instead.
class TapStep extends Step {
  const TapStep(this.targets,
      {required super.say,
      this.any = false,
      this.lines = const {},
      this.tapStates = const {},
      this.wrong = const {},
      super.hint,
      super.before,
      super.after,
      super.done,
      super.word,
      super.wordAt,
      super.sfx,
      super.startSfx,
      super.extra});

  final List<String> targets;
  final bool any;
  final Map<String, String> lines;
  final Map<String, Map<String, String>> tapStates;
  final Map<String, String> wrong;

  @override
  List<Ev> solve() => [for (final t in any ? targets.take(1) : targets) Tap(t)];
}

/// Drag [item] onto [to]. Dropped on one of [wrong]: a gentle word and it
/// goes back. With [ceiling], the finger must stay below that height (the
/// smoke: 「蹲低低」).
class DragStep extends Step {
  const DragStep(this.item, this.to,
      {required super.say,
      this.wrong = const {},
      this.ceiling,
      this.ceilingSay = '蹲低低，煙在上面喔。',
      this.dropSfx = 'pop',
      super.hint,
      super.before,
      super.after,
      super.done,
      super.word,
      super.wordAt,
      super.sfx,
      super.startSfx,
      super.extra});

  final String item;
  final String to;
  final Map<String, String> wrong;
  final double? ceiling;
  final String ceilingSay;
  final String dropSfx;

  /// Whether the finger may be at height [y] (0 top, 1 bottom of the picture).
  bool allowed(double y) => ceiling == null || y >= ceiling!;

  @override
  List<Ev> solve() => [Drop(item, to)];
}

/// One answer card.
class Opt {
  const Opt(this.id, this.zh, {this.ok = false, this.reply, this.art});

  final String id;
  final String zh;
  final bool ok;

  /// Said when picked (a wrong one: why not; a right one: overrides done).
  final String? reply;

  /// A picture on the card.
  final String? art;
}

/// Pick a card (「為什麼？」, 「要走嗎？」). Any card with [Opt.ok] is right.
class ChooseStep extends Step {
  const ChooseStep(this.options, {required super.say, super.hint, super.before, super.after, super.done, super.word, super.wordAt, super.sfx, super.startSfx, super.extra});

  final List<Opt> options;

  @override
  List<Ev> solve() => [Choose(options.firstWhere((o) => o.ok).id)];
}

/// Press and hold [target] until the ring is full ([seconds]).
class HoldStep extends Step {
  const HoldStep(this.target,
      {required super.say, this.seconds = 3, this.early = '再按住一下下。', this.loopSfx, super.hint, super.before, super.after, super.done, super.word, super.wordAt, super.sfx, super.startSfx, super.extra});

  final String target;
  final double seconds;

  /// Said when let go too soon.
  final String early;
  final String? loopSfx;

  @override
  List<Ev> solve() => [Hold(target, seconds)];
}

/// Press [digits] in order on a keypad (119, the parent's phone number). A
/// wrong key is not typed. [glow]: the next key lights up (小小). [lead] is
/// said before the whole number at the end (「我媽媽的電話是」).
class KeypadStep extends Step {
  const KeypadStep(this.digits, {required super.say, this.glow = true, this.lead = '', this.wrongSay = '再看看喔。', super.hint, super.before, super.after, super.done, super.word, super.wordAt, super.sfx = 'ring', super.startSfx, super.extra});

  final String digits;
  final bool glow;
  final String lead;
  final String wrongSay;

  @override
  List<Ev> solve() => [for (final d in digits.split('')) KeyPress(d)];
}

/// A big button 「大聲說一次」: the child speaks to the phone for a few
/// seconds; nothing is recorded (the app has no microphone).
class SayStep extends Step {
  const SayStep(this.label, {required super.say, this.seconds = 3, super.hint, super.before, super.after, super.done, super.word, super.wordAt, super.sfx = 'cheer', super.startSfx, super.extra});

  final String label;
  final double seconds;

  @override
  List<Ev> solve() => [Tap('btn:$label'), const Said()];
}

/// One danger in a room and how to make it safe: tap it again ([fixTaps]
/// empty), tap other things in order ([fixTaps]), or drag it onto
/// [dragTo]. [why] is asked at 大 once it is safe.
class Hazard {
  const Hazard(this.id, {required this.found, required this.fix, this.fixTaps = const [], this.dragTo, required this.safe, this.why, this.word = '找到了！'});

  final String id;

  /// Said when found: what is dangerous.
  final String found;

  /// Said next: how to make it safe.
  final String fix;
  final List<String> fixTaps;
  final String? dragTo;

  /// States once safe.
  final Map<String, String> safe;
  final ChooseStep? why;
  final String word;

  List<String> get taps => dragTo != null ? const [] : (fixTaps.isEmpty ? [id] : fixTaps);
}

/// Find the dangers in a room and make each safe. [oneAtATime] (小小): only
/// the next one counts and glows.
class FindStep extends Step {
  const FindStep(this.hazards, {required super.say, this.oneAtATime = true, this.askWhy = false, super.hint, super.before, super.after, super.done, super.word, super.wordAt, super.sfx = 'cheer', super.startSfx, super.extra});

  final List<Hazard> hazards;
  final bool oneAtATime;
  final bool askWhy;

  @override
  List<Ev> solve() => [
        for (final h in hazards) ...[
          Tap(h.id),
          if (h.dragTo != null) Drop(h.id, h.dragTo!) else for (final t in h.taps) Tap(t),
          if (askWhy && h.why != null) ...h.why!.solve(),
        ],
      ];
}

/// A finger move (what the screen tells the run, and what the tests send).
sealed class Ev {
  const Ev();
}

class Tap extends Ev {
  const Tap(this.id);
  final String id;
  @override
  String toString() => 'Tap($id)';
}

class Drop extends Ev {
  const Drop(this.item, this.zone);
  final String item, zone;
  @override
  String toString() => 'Drop($item→$zone)';
}

class Hold extends Ev {
  const Hold(this.id, this.seconds);
  final String id;
  final double seconds;
  @override
  String toString() => 'Hold($id, $seconds)';
}

class KeyPress extends Ev {
  const KeyPress(this.digit);
  final String digit;
  @override
  String toString() => 'KeyPress($digit)';
}

class Choose extends Ev {
  const Choose(this.id);
  final String id;
  @override
  String toString() => 'Choose($id)';
}

class Said extends Ev {
  const Said();
}
