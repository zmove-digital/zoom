import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/settings_controller.dart';
import '../core/theme/app_theme.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final ThemeData theme = Theme.of(context);
    final String? imagePath = settings.settings.backgroundImagePath;
    final bool hasImage =
        !kIsWeb && imagePath != null && imagePath.isNotEmpty;

    final Color base = theme.brightness == Brightness.dark
        ? const Color(0xFF101018)
        : theme.colorScheme.surface;
    final Color top = theme.colorScheme.primary;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ColoredBox(color: base),
        if (hasImage)
          Opacity(
            opacity: settings.settings.backgroundOpacity.clamp(0.0, 1.0),
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                withOpacity(top, 0.14),
                const Color(0x00000000),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}