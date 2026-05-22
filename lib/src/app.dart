import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'features/home/presentation/home_page.dart';

class WtrApp extends StatefulWidget {
  const WtrApp({super.key});

  @override
  State<WtrApp> createState() => _WtrAppState();
}

class _WtrAppState extends State<WtrApp> {
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
        title: 'WTR Android',
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
          child: _showSplash ? const SplashScreen() : const HomePage(),
        ),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
              colorScheme.primary.withOpacity(0.95),
              colorScheme.tertiary.withOpacity(0.92),
              colorScheme.secondary.withOpacity(0.95),
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
                  color: colorScheme.surface.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: colorScheme.surface.withOpacity(0.25)),
                ),
                child: Icon(Icons.auto_stories, size: 48, color: colorScheme.onPrimary),
              ),
              const SizedBox(height: 20),
              Text(
                'WTR Android',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Read. Discover. Continue.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary.withOpacity(0.85),
                    ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 220,
                child: LinearProgressIndicator(
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: colorScheme.onPrimary.withOpacity(0.14),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
