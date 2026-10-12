import 'package:flutter/material.dart';

import 'category.dart';

class Goal {
  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0,
    this.deadline,
    this.colorHex = '06D6A0',
    this.iconCodePoint = 0xe8f7,
  });

  final String id;
  String name;
  double targetAmount;
  double savedAmount;
  DateTime? deadline;
  String colorHex;
  int iconCodePoint;

  Color get color => colorFromHex(colorHex);

  double get progress => targetAmount <= 0
      ? 0.0
      : (savedAmount / targetAmount).clamp(0.0, 1.0).toDouble();
  bool get isDone => savedAmount >= targetAmount && targetAmount > 0;

  Goal copyWith({
    String? name,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
    String? colorHex,
    int? iconCodePoint,
  }) {
    return Goal(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: deadline ?? this.deadline,
      colorHex: colorHex ?? this.colorHex,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        'deadline': deadline?.toIso8601String(),
        'colorHex': colorHex,
        'iconCodePoint': iconCodePoint,
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0,
        savedAmount: (json['savedAmount'] as num?)?.toDouble() ?? 0,
        deadline: json['deadline'] == null
            ? null
            : DateTime.parse(json['deadline'] as String),
        colorHex: json['colorHex'] as String? ?? '06D6A0',
        iconCodePoint: (json['iconCodePoint'] as num?)?.toInt() ?? 0xe8f7,
      );
}
