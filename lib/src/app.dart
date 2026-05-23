import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'extensions/registry/source_registry.dart';
import 'features/extensions/presentation/extensions_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/search/presentation/search_page.dart';
import 'features/settings/presentation/settings_page.dart';

class OtakuStreamApp extends StatefulWidget {
  const OtakuStreamApp({super.key});

  @override
  State<OtakuStreamApp> createState() => _OtakuStreamAppState();
}

class _OtakuStreamAppState extends State<OtakuStreamApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      dark: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      initial: AdaptiveThemeMode.system,
      builder: (theme, darkTheme) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'OtakuStream',
        theme: theme,
        darkTheme: darkTheme,
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: const [
            Breakpoint(start: 0, end: 600, name: MOBILE),
            Breakpoint(start: 601, end: 1200, name: TABLET),
            Breakpoint(start: 1201, end: double.infinity, name: DESKTOP),
          ],
        ),
        home: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _showSplash ? const _SplashScreen() : const _Shell(),
        ),
      ),
    );
  }
}

// ── Main shell with bottom nav ─────────────────────────────────────────────────

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 0;
  final _registry = SourceRegistry.instance;

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded, label: 'Home'),
    _TabItem(icon: Icons.search_rounded, label: 'Search'),
    _TabItem(icon: Icons.extension_rounded, label: 'Sources'),
    _TabItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  static const _pages = [
    HomePage(),
    SearchPage(),
    ExtensionsPage(),
    SettingsPage(),
  ];

  static const _titles = ['Home', 'Search', 'Sources', 'Settings'];

  @override
  void initState() {
    super.initState();
    _registry.addListener(_onSourceChanged);
  }

  @override
  void dispose() {
    _registry.removeListener(_onSourceChanged);
    super.dispose();
  }

  void _onSourceChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final source = _registry.active;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _titles[_index],
              style: Theme.of(context).textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
            if (_index < 2)
              Text(
                source.name,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  label: t.label,
                ))
            .toList(growable: false),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

// ── Splash screen ──────────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.95),
              colorScheme.tertiary.withValues(alpha: 0.92),
              colorScheme.secondary.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: colorScheme.surface.withValues(alpha: 0.25)),
                ),
                child: Icon(Icons.auto_stories,
                    size: 48, color: colorScheme.onPrimary),
              ),
              const SizedBox(height: 20),
              Text(
                'OtakuStream',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Novels. Manga. Anime.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.85),
                    ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 220,
                child: LinearProgressIndicator(
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor:
                      colorScheme.onPrimary.withValues(alpha: 0.14),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
