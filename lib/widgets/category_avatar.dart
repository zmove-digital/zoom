import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/models/category.dart';

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    required this.category,
    this.size = 42,
    super.key,
  });

  final Category? category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color color = category?.color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: withOpacity(color, 0.18),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        category?.icon ?? Icons.help_outline,
        color: color,
        size: size * 0.52,
      ),
    );
  }
}
