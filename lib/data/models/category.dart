import 'package:flutter/material.dart';

import '../../core/constants.dart';

enum CategoryKind { income, expense, both }

CategoryKind categoryKindFromName(String name) {
  return CategoryKind.values.firstWhere(
    (CategoryKind k) => k.name == name,
    orElse: () => CategoryKind.both,
  );
}

class Category {
  Category({
    required this.id,
    required this.name,
    required this.kind,
    required this.colorHex,
    required this.iconCodePoint,
    this.isDefault = false,
  });

  final String id;
  String name;
  CategoryKind kind;
  String colorHex;
  int iconCodePoint;
  bool isDefault;

  Color get color => colorFromHex(colorHex);

  IconData get icon => kIconsByCodePoint[iconCodePoint] ?? Icons.help_outline;

  bool get supportsIncome =>
      kind == CategoryKind.income || kind == CategoryKind.both;
  bool get supportsExpense =>
      kind == CategoryKind.expense || kind == CategoryKind.both;

  Category copyWith({
    String? name,
    CategoryKind? kind,
    String? colorHex,
    int? iconCodePoint,
    bool? isDefault,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      colorHex: colorHex ?? this.colorHex,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'kind': kind.name,
        'colorHex': colorHex,
        'iconCodePoint': iconCodePoint,
        'isDefault': isDefault,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: categoryKindFromName(json['kind'] as String? ?? 'both'),
        colorHex: json['colorHex'] as String? ?? '6C5CE7',
        iconCodePoint: (json['iconCodePoint'] as num?)?.toInt() ?? 0xe59c,
        isDefault: json['isDefault'] as bool? ?? false,
      );
}

Color colorFromHex(String hex) {
  String value = hex.replaceAll('#', '').trim();
  if (value.length == 6) {
    value = 'FF$value';
  }
  final int parsed = int.tryParse(value, radix: 16) ?? 0xFF6C5CE7;
  return Color(parsed);
}

String colorToHex(Color color) {
  final int value = color.toARGB32();
  return value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
}
