import 'package:flutter_tts/flutter_tts.dart';

/// Reads out what the helpers say, the questions and the answers, for
/// children who cannot read yet: the phone's own speech in Taiwanese
/// Mandarin, calm and not fast. Parents can turn it off; every line is also
/// on screen.
abstract interface class Voice {
  /// Says [text] (stopping whatever was being said); completes when it has
  /// been said, or was stopped.
  Future<void> say(String text);
  Future<void> stop();
}

class SystemVoice implements Voice {
  FlutterTts? _tts;
  Future<FlutterTts>? _setUp;
  var _said = 0;

  /// The engine, set up once. Every line waits for the whole set-up, so a
  /// second line asked for while the first is still setting up is neither
  /// said too fast nor stopped by the first one's late stop().
  Future<FlutterTts> _engine() => _setUp ??= () async {
        final tts = _tts = FlutterTts();
        await tts.awaitSpeakCompletion(true);
        await tts.setLanguage('zh-TW');
        await tts.setSpeechRate(0.45);
        await tts.setPitch(1.1);
        return tts;
      }();

  @override
  Future<void> say(String text) async {
    final turn = ++_said;
    try {
      final tts = await _engine();
      await tts.stop();
      if (turn != _said || text.trim().isEmpty) return;
      await tts.speak(text);
    } catch (_) {
      // No speech engine (tests, or a phone without one): the words on
      // screen and the pictures are enough.
    }
  }

  @override
  Future<void> stop() async {
    _said++;
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}

class SilentVoice implements Voice {
  const SilentVoice();

  @override
  Future<void> say(String text) async {}

  @override
  Future<void> stop() async {}
}

/// Remembers what was said (tests).
class RecordingVoice implements Voice {
  final said = <String>[];

  @override
  Future<void> say(String text) async => said.add(text);

  @override
  Future<void> stop() async {}
}
