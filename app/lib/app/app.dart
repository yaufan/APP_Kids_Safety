import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/content.dart';
import '../core/providers.dart';
import '../features/base/base_screen.dart';
import '../features/helmet/helmet_screen.dart';
import '../features/intro/body_intro_screen.dart';
import '../features/level/level_screen.dart';
import '../features/parent/parent_gate.dart';
import '../features/parent/parent_screen.dart';
import '../features/rest/rest_screen.dart';
import '../features/setup/setup_screen.dart';
import '../features/world/world_screen.dart';
import 'strings.dart';
import 'theme.dart';

/// The pages: the base (`/`), the first start (`/setup`), a world
/// (`/world?w=road`), a level (`/level?lv=light`), the parent's note before
/// 身體世界 (`/intro?lv=…`), the helmet (`/helmet`), the rest and parent mode.
final routerProvider = Provider<GoRouter>((ref) {
  final resting = ref.read(gameProvider).resting(ref.read(clockProvider)());
  final router = GoRouter(
    initialLocation: resting ? '/rest' : '/',
    // Always start here, whatever page another app asks the phone to open.
    overridePlatformDefaultLocation: true,
    redirect: (_, state) {
      final at = state.matchedLocation;
      final q = state.uri.queryParameters;
      final g = ref.read(gameProvider);
      if (at == '/parent') return ParentPass.take() ? null : '/';
      if (!g.hero.made && at != '/setup' && at != '/rest') return '/setup';
      if (at == '/world') {
        final w = World.values.asNameMap()[q['w']];
        if (w == null || !g.settings.shows(w)) return '/';
      }
      if (at == '/level' || at == '/intro') {
        final lv = Lv.values.asNameMap()[q['lv']];
        if (lv == null || !g.settings.open(lv)) return '/';
        if (at == '/level' && lv.world == World.body && !g.settings.bodyIntroSeen) return '/intro?lv=${lv.name}';
      }
      return null;
    },
    onException: (_, _, router) => router.go('/'),
    routes: [
      GoRoute(path: '/', builder: (_, _) => const BaseScreen()),
      GoRoute(path: '/setup', builder: (_, _) => const SetupScreen()),
      GoRoute(path: '/world', builder: (_, s) => WorldScreen(key: ValueKey(s.uri.toString()), world: World.values.byName(s.uri.queryParameters['w']!))),
      GoRoute(path: '/level', builder: (_, s) => LevelScreen(key: ValueKey('${s.uri}#${s.pageKey.value}'), lv: Lv.values.byName(s.uri.queryParameters['lv']!))),
      GoRoute(path: '/intro', builder: (_, s) => BodyIntroScreen(lv: Lv.values.asNameMap()[s.uri.queryParameters['lv']])),
      GoRoute(path: '/helmet', builder: (_, _) => const HelmetScreen()),
      GoRoute(path: '/rest', builder: (_, _) => const RestScreen()),
      GoRoute(path: '/parent', builder: (_, _) => const ParentScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class SafetyApp extends ConsumerWidget {
  const SafetyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(gameProvider.select((g) => g.settings));
    ref.read(soundsProvider)
      ..music = settings.music
      ..effects = settings.sounds;
    return MaterialApp.router(
      title: Strings.appName,
      debugShowCheckedModeBanner: false,
      theme: ComicTheme.light(),
      locale: const Locale('zh', 'TW'),
      supportedLocales: const [Locale('zh', 'TW')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
      builder: (_, child) => RestGuard(child: child ?? const SizedBox()),
    );
  }
}

/// Keeps the parent's play time (docs/design.md 「每次玩多久」): when the
/// sitting has gone on for the minutes they set, the helpers go back to the
/// base to rest, the helmet is hung up and the child is sent to try it for
/// real; an hour later (or when a parent says so) play can go on. Away from
/// the app for ten minutes counts as a rest. Parent mode and the parent's
/// note are never stopped.
class RestGuard extends ConsumerStatefulWidget {
  const RestGuard({super.key, required this.child});

  final Widget child;

  static const check = Duration(seconds: 2);
  static const awayIsRest = Duration(minutes: 10);

  @override
  ConsumerState<RestGuard> createState() => _RestGuardState();
}

class _RestGuardState extends ConsumerState<RestGuard> {
  Timer? _timer;
  AppLifecycleListener? _life;
  DateTime? _away;

  @override
  void initState() {
    super.initState();
    ref.read(sessionStartProvider);
    _timer = Timer.periodic(RestGuard.check, (_) => _check());
    _life = AppLifecycleListener(
      onHide: () => _away = ref.read(clockProvider)(),
      onShow: () {
        final away = _away;
        _away = null;
        if (away != null && ref.read(clockProvider)().difference(away) >= RestGuard.awayIsRest) ref.read(sessionStartProvider.notifier).restart();
        _check();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _life?.dispose();
    super.dispose();
  }

  void _check() {
    if (!mounted) return;
    final now = ref.read(clockProvider)();
    final g = ref.read(gameProvider);
    final router = ref.read(routerProvider);
    final path = router.state.matchedLocation;
    if (path.startsWith('/parent') || path.startsWith('/intro')) return;
    if (g.restSince != null) {
      if (g.resting(now)) {
        if (path != '/rest') router.go('/rest');
        return;
      }
      ref.read(gameProvider.notifier).change((g) => g.playOn());
      ref.read(sessionStartProvider.notifier).restart();
      if (path == '/rest') router.go('/');
      return;
    }
    if (path == '/rest') {
      router.go('/');
      return;
    }
    if (now.difference(ref.read(sessionStartProvider)) >= Duration(minutes: g.settings.minutes)) {
      ref.read(gameProvider.notifier).change((g) => g.rest(now));
      router.go('/rest');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
