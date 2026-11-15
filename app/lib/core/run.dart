import 'scene.dart';
import 'steps.dart';

/// What a finger move did.
enum Res {
  /// Nothing (a tap on the sky).
  none,

  /// Not that one: a gentle word, nothing lost.
  wrong,

  /// A bit of the step is done (one of several taps, a digit, a danger found).
  progress,

  /// The step is done; the screen says why, then calls [LevelRun.next].
  done,
}

class Reply {
  const Reply(this.res, {this.say, this.word, this.at, this.sfx});

  static const nothing = Reply(Res.none);

  final Res res;

  /// Said straight away (the line for this tap, or why not).
  final String? say;

  /// A comic word to burst out, and where (a sprite id).
  final String? word;
  final String? at;
  final String? sfx;
}

/// One play of a level: which part and step it is at, the things' states,
/// and what is done in the step so far. Pure Dart (no screen), so the tests
/// can play every level through.
class LevelRun {
  LevelRun(this.parts) : assert(parts.isNotEmpty) {
    states = {...parts.first.scene.startStates};
    _enter();
  }

  final List<Part> parts;
  var part = 0, index = 0;
  var states = <String, String>{};

  /// The step is done; waiting for [next].
  var waiting = false;

  final tapped = <String>{};
  var typed = 0;

  /// [FindStep]: the dangers made safe, the one found and being fixed, how
  /// many of its fixing taps are done, and whether its 「為什麼」 is asked.
  final fixed = <String>{};
  String? fixing;
  var fixTap = 0;
  Hazard? asking;

  bool get finished => part >= parts.length;
  Scene get scene => parts[finished ? parts.length - 1 : part].scene;
  Step? get step => finished ? null : parts[part].steps[index];

  /// Steps in the whole level, and how many are behind (for the dots).
  int get total => parts.fold(0, (n, p) => n + p.steps.length);
  int get behind => finished ? total : parts.take(part).fold(0, (n, p) => n + p.steps.length) + index + (waiting ? 1 : 0);

  String state(String id) => states[id] ?? 'start';

  void _enter() {
    tapped.clear();
    typed = 0;
    fixed.clear();
    fixing = null;
    fixTap = 0;
    asking = null;
    waiting = false;
    final s = step;
    if (s != null) states.addAll(s.before);
  }

  /// On to the next step (the next part's picture when this part is done).
  void next() {
    if (finished) return;
    index++;
    if (index >= parts[part].steps.length) {
      part++;
      index = 0;
      if (!finished) states = {...parts[part].scene.startStates};
    }
    _enter();
  }

  Reply _done(Step s, {String? say, String? word, String? at}) {
    waiting = true;
    states.addAll(s.after);
    return Reply(Res.done, say: say, word: word ?? s.word, at: at ?? s.wordAt, sfx: s.sfx);
  }

  String _zh(String id) => scene.sprite(id)?.zh ?? id.replaceFirst('btn:', '');

  Reply tap(String id) {
    final s = step;
    if (s == null || waiting) return Reply.nothing;
    switch (s) {
      case TapStep():
        if (s.targets.contains(id) && !tapped.contains(id)) {
          tapped.add(id);
          states.addAll(s.tapStates[id] ?? const {});
          if (s.any || tapped.containsAll(s.targets)) return _done(s, say: s.lines[id], at: s.wordAt ?? (id.startsWith('btn:') ? null : id));
          return Reply(Res.progress, say: s.lines[id], sfx: 'pop', at: id);
        }
        final w = s.wrong[id];
        if (w != null) return Reply(Res.wrong, say: w, sfx: 'try', at: id);
        return Reply.nothing;
      case SayStep():
        if (id == 'btn:${s.label}' && tapped.isEmpty) {
          tapped.add(id);
          return const Reply(Res.progress, sfx: 'pop');
        }
        return Reply.nothing;
      case FindStep():
        if (asking != null) return Reply.nothing;
        final f = fixing;
        if (f == null) {
          final h = _hazard(s, id);
          if (h == null || fixed.contains(id)) return Reply.nothing;
          if (s.oneAtATime && _nextHazard(s)?.id != id) return Reply.nothing;
          fixing = id;
          fixTap = 0;
          return Reply(Res.progress, say: '${h.found}${h.fix}', word: h.word, at: id, sfx: 'found');
        }
        final h = _hazard(s, f)!;
        final taps = h.taps;
        if (taps.isEmpty) return Reply.nothing;
        if (id == taps[fixTap]) {
          fixTap++;
          if (fixTap < taps.length) return Reply(Res.progress, sfx: 'pop', at: id);
          return _fixed(s, h);
        }
        if (taps.contains(id)) return Reply(Res.wrong, say: '先點${_zh(taps[fixTap])}喔。', sfx: 'try', at: id);
        return Reply.nothing;
      default:
        return Reply.nothing;
    }
  }

  Hazard? _hazard(FindStep s, String id) {
    for (final h in s.hazards) {
      if (h.id == id) return h;
    }
    return null;
  }

  Hazard? _nextHazard(FindStep s) {
    for (final h in s.hazards) {
      if (!fixed.contains(h.id)) return h;
    }
    return null;
  }

  Reply _fixed(FindStep s, Hazard h) {
    fixed.add(h.id);
    fixing = null;
    states.addAll(h.safe);
    if (s.askWhy && h.why != null) {
      asking = h;
      return Reply(Res.progress, say: h.why!.say, sfx: 'right', at: h.id, word: '安全了！');
    }
    if (fixed.length == s.hazards.length) return _done(s, word: '全部安全！');
    return Reply(Res.progress, sfx: 'right', at: h.id, word: '安全了！');
  }

  /// Whether [id] may be picked up now.
  bool canDrag(String id) {
    final s = step;
    if (s == null || waiting) return false;
    return switch (s) {
      DragStep() => s.item == id,
      FindStep() => fixing == id && _hazard(s, id)?.dragTo != null,
      _ => false,
    };
  }

  Reply drop(String item, String zone) {
    final s = step;
    if (s == null || waiting || !canDrag(item)) return Reply.nothing;
    switch (s) {
      case DragStep():
        if (zone == s.to) return _done(s, at: zone);
        final w = s.wrong[zone];
        if (w != null) return Reply(Res.wrong, say: w, sfx: 'try', at: zone);
        return Reply.nothing;
      case FindStep():
        final h = _hazard(s, item)!;
        if (zone == h.dragTo) return _fixed(s, h);
        return Reply.nothing;
      default:
        return Reply.nothing;
    }
  }

  Reply hold(String id, double seconds) {
    final s = step;
    if (s is! HoldStep || waiting || id != s.target) return Reply.nothing;
    if (seconds + 1e-6 >= s.seconds) return _done(s, at: id.startsWith('btn:') ? null : id);
    return Reply(Res.wrong, say: s.early, sfx: 'try');
  }

  Reply key(String digit) {
    final s = step;
    if (s is! KeypadStep || waiting) return Reply.nothing;
    if (typed < s.digits.length && s.digits[typed] == digit) {
      typed++;
      if (typed == s.digits.length) return _done(s);
      return Reply(Res.progress, sfx: 'key_$digit');
    }
    return Reply(Res.wrong, say: s.wrongSay, sfx: 'try');
  }

  /// The question on screen now: the step's own, or a danger's 「為什麼」.
  ChooseStep? get question {
    final s = step;
    if (waiting) return null;
    if (s is ChooseStep) return s;
    return asking?.why;
  }

  Reply choose(String id) {
    final s = step;
    final q = question;
    if (s == null || q == null) return Reply.nothing;
    final o = q.options.where((o) => o.id == id).firstOrNull;
    if (o == null) return Reply.nothing;
    if (!o.ok) return Reply(Res.wrong, say: o.reply, sfx: 'try');
    if (s is FindStep) {
      asking = null;
      if (fixed.length == s.hazards.length) return _done(s, say: o.reply ?? q.done, word: '全部安全！');
      return Reply(Res.progress, say: o.reply ?? q.done, sfx: 'right', word: q.word);
    }
    return _done(s, say: o.reply);
  }

  Reply said() {
    final s = step;
    if (s is! SayStep || waiting || tapped.isEmpty) return Reply.nothing;
    return _done(s);
  }

  /// Plays one finger move (tests and the demo).
  Reply play(Ev e) => switch (e) {
        Tap(:final id) => tap(id),
        Drop(:final item, :final zone) => drop(item, zone),
        Hold(:final id, :final seconds) => hold(id, seconds),
        KeyPress(:final digit) => key(digit),
        Choose(:final id) => choose(id),
        Said() => said(),
      };

  /// What glows for 小小: everything to tap, drag or hold next.
  Set<String> get hints {
    final s = step;
    if (s == null || waiting) return const {};
    return switch (s) {
      TapStep() => {for (final t in s.targets) if (!tapped.contains(t)) t},
      DragStep() => {s.item, s.to},
      HoldStep() => {s.target},
      KeypadStep() => {if (s.glow && typed < s.digits.length) 'key:${s.digits[typed]}'},
      SayStep() => {'btn:${s.label}'},
      FindStep() => fixing == null ? {if (s.oneAtATime && _nextHazard(s) != null) _nextHazard(s)!.id} : guides,
      ChooseStep() => const {},
    };
  }

  /// What glows at every age: where a picked-up danger goes, and its fixing
  /// taps (finding is the child's job, fixing is shown).
  Set<String> get guides {
    final s = step;
    if (s is! FindStep || waiting) {
      if (s is DragStep && !waiting) return {s.to};
      return const {};
    }
    final f = fixing;
    if (f == null) return const {};
    final h = _hazard(s, f)!;
    if (h.dragTo != null) return {h.dragTo!};
    return {h.taps[fixTap]};
  }
}
