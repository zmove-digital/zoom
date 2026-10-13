import 'package:flutter/material.dart';

import 'gradient_background.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.leading,
    this.padding = EdgeInsets.zero,
    this.centerTitle = false,
    super.key,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? leading;
  final EdgeInsetsGeometry padding;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: title == null && actions == null
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              scrolledUnderElevation: 0,
              centerTitle: centerTitle,
              leading: leading,
              title: title == null ? null : Text(title!),
              actions: actions,
            ),
      body: GradientBackground(
        child: SafeArea(
          top: title == null && actions == null,
          bottom: false,
          child: Padding(padding: padding, child: body),
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
