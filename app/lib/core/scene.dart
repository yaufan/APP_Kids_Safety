import 'steps.dart';

/// A level's picture (docs/art.md): a background and the things on it.
/// Everything is placed in a 4:3 box; x and y are the centre, w and h the
/// size, all as fractions of the box (so phone and tablet look the same).
///
/// Picture names: `folder/name` is assets/art/folder/name.svg; `@hero/<pose>`
/// is the child's own squad member (hair, skin and helmet colours from the
/// save), drawn from `assets/art/hero/<pose>.svg`.
class Look {
  const Look(this.art, this.x, this.y, this.w, this.h, {this.flip = false, this.jump = false, this.exit = false});

  /// null: nothing shows (an empty place to drop onto or tap).
  final String? art;
  final double x, y, w, h;

  /// Drawn mirrored (the car facing the other way, the head turned left).
  final bool flip;

  /// Moves there at once instead of sliding (a car coming back round).
  final bool jump;

  /// Drives off: once there it vanishes and waits at its first place.
  final bool exit;

  Look copyWith({String? art, bool hide = false, double? x, double? y, double? w, double? h, bool? flip, bool? jump, bool? exit}) => Look(
        hide ? null : (art ?? this.art),
        x ?? this.x,
        y ?? this.y,
        w ?? this.w,
        h ?? this.h,
        flip: flip ?? this.flip,
        jump: jump ?? this.jump,
        exit: exit ?? this.exit,
      );

  bool contains(double px, double py, {double grow = 0}) => (px - x).abs() <= w / 2 + grow && (py - y).abs() <= h / 2 + grow;
}

/// How a thing moves on its own.
enum Anim { none, bob, swing, drift }

/// One thing in the picture. It has a state (a word); each state can show
/// another picture ([arts]: null hides it) or stand somewhere else
/// ([moves]). The first state is `start`.
class Sprite {
  const Sprite(this.id, this.zh, this.base, {this.arts = const {}, this.moves = const {}, this.anim = Anim.none, this.drag = false});

  final String id;

  /// Its name (read out when tapped or picked up).
  final String zh;
  final Look base;
  final Map<String, String?> arts;
  final Map<String, Look> moves;
  final Anim anim;

  /// Whether it can be picked up and dragged (in a step that asks).
  final bool drag;

  Look look(String state) {
    final m = moves[state];
    if (m != null) return m;
    if (arts.containsKey(state)) return base.copyWith(art: arts[state], hide: arts[state] == null);
    return base;
  }

  Iterable<String> get states => {'start', ...arts.keys, ...moves.keys};
}

/// Scene-wide states kept as pseudo things (no picture): the room shaking,
/// the power cut.
abstract final class SceneFlag {
  static const shake = '_shake';
  static const dark = '_dark';
}

class Scene {
  const Scene(this.bg, this.sprites, {this.flags = const {}});

  final String bg;
  final List<Sprite> sprites;

  /// Pseudo things' first states ([SceneFlag]).
  final Map<String, String> flags;

  Sprite? sprite(String id) {
    for (final s in sprites) {
      if (s.id == id) return s;
    }
    return null;
  }

  Map<String, String> get startStates => {for (final s in sprites) s.id: 'start', ...flags};
}

/// A level is one or more parts; each part has its own picture.
class Part {
  const Part(this.scene, this.steps);

  final Scene scene;
  final List<Step> steps;
}
