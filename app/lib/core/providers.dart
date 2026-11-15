import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game.dart';
import 'sounds.dart';
import 'store.dart';
import 'voice.dart';

/// What time it is (tests and screenshots set it): the play-time limit uses it.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final storeProvider = Provider<GameStore>((ref) => MemoryStore());
final savedGameProvider = Provider<Game>((ref) => const Game());
final soundsProvider = Provider<Sounds>((ref) => const SilentSounds());
final voiceProvider = Provider<Voice>((ref) => const SilentVoice());

/// The game; every change is saved straight away.
final gameProvider = NotifierProvider<GameNotifier, Game>(GameNotifier.new);

class GameNotifier extends Notifier<Game> {
  @override
  Game build() => ref.read(savedGameProvider);

  void change(Game Function(Game g) f) {
    final next = f(state);
    if (identical(next, state)) return;
    state = next;
    ref.read(storeProvider).write(next.toJson());
  }

  void settings(Settings Function(Settings s) f) => change((g) => g.copyWith(settings: f(g.settings)));
}

/// When this sitting started (reset when a parent lets play go on, or after
/// ten minutes away from the app; moved on by the time spent in parent mode,
/// which is not the child's play time).
final sessionStartProvider = NotifierProvider<SessionStart, DateTime>(SessionStart.new);

class SessionStart extends Notifier<DateTime> {
  @override
  DateTime build() => ref.read(clockProvider)();

  void restart() => state = ref.read(clockProvider)();

  /// Leaves [d] out of the sitting (a parent was in parent mode).
  void skip(Duration d) {
    if (!d.isNegative) state = state.add(d);
  }
}
