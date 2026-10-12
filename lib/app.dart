import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'state/settings_controller.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/shell/app_shell.dart';
import 'screens/lock/lock_screen.dart';

class GranaApp extends StatelessWidget {
  const GranaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();

    return MaterialApp(
      title: 'Grana',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(settings.settings, Brightness.light),
      darkTheme: AppTheme.build(settings.settings, Brightness.dark),
      themeMode: settings.themeMode,
      home: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    if (!settings.settings.onboardingDone) {
      return const OnboardingScreen();
    }
    if (settings.settings.pinEnabled && settings.settings.pin.isNotEmpty) {
      return const LockScreen();
    }
    return const AppShell();
  }
}
