import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/version.dart';
import '../../app/widgets.dart';
import '../../core/content.dart';
import '../../core/game.dart';
import '../../core/providers.dart';

/// Parent mode (docs/design.md 「家長模式」), only through the parent gate:
/// the squad member, the phone number and what the child calls the parent
/// (no address, no full name, kept on this phone only), the trusted
/// grown-ups, the worlds, the time, the progress, the real-life checklist
/// (gold badges), the cheat sheet, the sounds, and the full version.
class ParentScreen extends ConsumerStatefulWidget {
  const ParentScreen({super.key});

  @override
  ConsumerState<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends ConsumerState<ParentScreen> {
  late final _name = TextEditingController(text: ref.read(gameProvider).hero.name);
  late final _phone = TextEditingController(text: ref.read(gameProvider).settings.phone);
  String? _phoneNote;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  GameNotifier get _game => ref.read(gameProvider.notifier);

  void _savePhone(String typed) {
    final clean = Settings.cleanPhone(typed);
    if (typed.trim().isNotEmpty && clean.isEmpty) {
      setState(() => _phoneNote = Strings.phoneBad);
      return;
    }
    _game.settings((s) => s.copyWith(phone: clean));
    setState(() => _phoneNote = clean.isEmpty ? null : Strings.phoneSaved);
  }

  Widget _section(String title, List<Widget> kids, {String? note}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Comic.parentInk)),
              if (note != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(note, style: const TextStyle(fontSize: 13, color: Comic.parentSoft))),
              const SizedBox(height: 8),
              ...kids,
            ]),
          ),
        ),
      );

  Widget _chip(String label, bool on, VoidCallback? tap, {String? art, Key? key}) => Semantics(
        key: key,
        container: true,
        button: true,
        selected: on,
        label: label,
        excludeSemantics: true,
        onTap: tap,
        child: Pressable(
          onTap: tap,
          child: Container(
            padding: EdgeInsets.fromLTRB(art != null ? 4 : 14, 6, 14, 6),
            decoration: BoxDecoration(
              color: on ? Comic.blue : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: on ? Comic.blue : const Color(0xFFD5DBE0), width: 2),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (art != null) ...[SizedBox(width: 32, height: 32, child: Art(art)), const SizedBox(width: 6)],
              Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: on ? Colors.white : Comic.parentInk)),
            ]),
          ),
        ),
      );

  Widget _switch(String label, bool on, ValueChanged<bool>? change, {String? note, Key? key}) => SwitchListTile(
        key: key,
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(label, style: const TextStyle(fontSize: 16, color: Comic.parentInk)),
        subtitle: note == null ? null : Text(note, style: const TextStyle(fontSize: 12, color: Comic.parentSoft)),
        value: on,
        onChanged: change,
      );

  @override
  Widget build(BuildContext context) {
    final g = ref.watch(gameProvider);
    final s = g.settings;
    return Theme(
      data: Theme.of(context).copyWith(scaffoldBackgroundColor: Comic.parentBg),
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            TopBar(title: Strings.parentTitle, color: const Color(0xFF8E97A4), onBack: () => context.go('/'), homeIcon: true),
            Expanded(
              child: LayoutBuilder(builder: (context, box) {
                final w = math.min(box.maxWidth, 640.0);
                return Center(
                  child: SizedBox(
                    width: w,
                    child: ListView(padding: const EdgeInsets.all(16), children: [
                      _section(Strings.sMember, [
                        TextField(
                          key: const ValueKey('name'),
                          controller: _name,
                          maxLength: HeroLook.maxName,
                          decoration: const InputDecoration(labelText: Strings.name, counterText: ''),
                          onChanged: (v) => _game.change((g) => g.copyWith(hero: g.hero.copyWith(name: v))),
                        ),
                        const SizedBox(height: 8),
                        Align(alignment: Alignment.centerLeft, child: _chip(Strings.changeLook, false, () => context.go('/setup'))),
                        const SizedBox(height: 12),
                        const Text(Strings.age, style: TextStyle(fontSize: 15, color: Comic.parentSoft)),
                        const SizedBox(height: 6),
                        Wrap(spacing: 8, children: [
                          for (final a in Age.values) _chip('${a.zh}（${a.years}）', s.age == a, () => _game.settings((x) => x.copyWith(age: a)), key: ValueKey('age-${a.name}')),
                        ]),
                        const SizedBox(height: 12),
                        const Text(Strings.minutes, style: TextStyle(fontSize: 15, color: Comic.parentSoft)),
                        const SizedBox(height: 6),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final m in Settings.minuteChoices) _chip('$m 分鐘', s.minutes == m, () => _game.settings((x) => x.copyWith(minutes: m)), key: ValueKey('min-$m')),
                        ]),
                      ]),
                      _section(Strings.sLost, note: Strings.phoneNote, [
                        TextField(
                          key: const ValueKey('phone'),
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 \-()]')), LengthLimitingTextInputFormatter(16)],
                          decoration: InputDecoration(labelText: Strings.phone, helperText: _phoneNote),
                          onChanged: _savePhone,
                        ),
                        const SizedBox(height: 10),
                        const Text(Strings.calls, style: TextStyle(fontSize: 15, color: Comic.parentSoft)),
                        const SizedBox(height: 6),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final a in Adult.callable) _chip(a.zh, s.call == a, () => _game.settings((x) => x.copyWith(call: a)), key: ValueKey('call-${a.name}')),
                        ]),
                      ]),
                      _section(Strings.sTrusted, note: Strings.trustedNote, [
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final a in Adult.values)
                            _chip(
                              a.zh,
                              s.trusted.contains(a),
                              () {
                                final on = s.trusted.contains(a);
                                if (on && s.trusted.length <= Settings.minTrusted) return;
                                if (!on && s.trusted.length >= Settings.maxTrusted) return;
                                _game.settings((x) => x.copyWith(trusted: on ? [for (final t in x.trusted) if (t != a) t] : [...x.trusted, a]));
                              },
                              art: a.art,
                              key: ValueKey('trust-${a.name}'),
                            ),
                        ]),
                      ]),
                      _section(Strings.sWorlds, [
                        for (final wd in World.values)
                          _switch(
                            wd.zh,
                            s.shows(wd),
                            (on) => _game.settings((x) => x.copyWith(off: on ? ({...x.off}..remove(wd)) : {...x.off, wd})),
                            note: wd == World.body ? Strings.bodyNote : null,
                            key: ValueKey('world-${wd.name}'),
                          ),
                        if (s.bodyIntroSeen) Align(alignment: Alignment.centerLeft, child: _chip(Strings.bodyIntroAgain, false, () => _game.settings((x) => x.copyWith(bodyIntroSeen: false)))),
                      ]),
                      _section(Strings.sReal, [
                        for (final r in RealLife.values)
                          CheckboxListTile(
                            key: ValueKey('real-${r.name}'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(r.zh, style: const TextStyle(fontSize: 16, color: Comic.parentInk)),
                            value: g.real.contains(r),
                            onChanged: (on) => _game.change((g) => g.tick(r, on ?? false)),
                          ),
                      ]),
                      _section(Strings.sProgress, [
                        for (final wd in World.values) ...[
                          Text(wd.zh, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(wd.color))),
                          for (final lv in wd.levels)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(children: [
                                Icon(g.done(lv) ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 18, color: g.done(lv) ? Comic.green : Comic.parentSoft),
                                const SizedBox(width: 6),
                                Expanded(child: Text(lv.zh, style: const TextStyle(fontSize: 15, color: Comic.parentInk))),
                                Text(Strings.plays(g.plays[lv] ?? 0), style: const TextStyle(fontSize: 13, color: Comic.parentSoft)),
                              ]),
                            ),
                          const SizedBox(height: 6),
                        ],
                      ]),
                      _section(Strings.sCheat, [
                        for (final lv in Lv.values)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text.rich(TextSpan(children: [
                              TextSpan(text: '${lv.zh}：', style: const TextStyle(fontWeight: FontWeight.w700)),
                              TextSpan(text: '${lv.learn}。${lv.ask}'),
                            ]), style: const TextStyle(fontSize: 14, height: 1.5, color: Comic.parentInk)),
                          ),
                      ]),
                      _section(Strings.sSound, [
                        _switch(Strings.music, s.music, (v) => _game.settings((x) => x.copyWith(music: v))),
                        _switch(Strings.sounds, s.sounds, (v) => _game.settings((x) => x.copyWith(sounds: v))),
                        _switch(Strings.voice, s.voice, (v) => _game.settings((x) => x.copyWith(voice: v))),
                      ]),
                      _section(Strings.full, note: Strings.freeNote, [
                        _switch(Strings.full, s.full, (v) => _game.settings((x) => x.copyWith(full: v)), key: const ValueKey('full')),
                      ]),
                      Center(child: Text(Strings.version(appVersion), style: const TextStyle(fontSize: 13, color: Comic.parentSoft))),
                    ]),
                  ),
                );
              }),
            ),
          ]),
        ),
      ),
    );
  }
}
