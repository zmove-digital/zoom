import 'package:flutter/material.dart';

import 'category.dart';

class GoalContribution {
  GoalContribution({
    required this.id,
    required this.accountId,
    required this.amount,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  final String id;
  final String accountId;
  final double amount;
  final DateTime date;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'accountId': accountId,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory GoalContribution.fromJson(Map<String, dynamic> json) =>
      GoalContribution(
        id: json['id'] as String,
        accountId: json['accountId'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        date: json['date'] == null
            ? null
            : DateTime.parse(json['date'] as String),
      );
}

class Goal {
  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    List<GoalContribution>? contributions,
    this.deadline,
    this.colorHex = '06D6A0',
    this.iconCodePoint = 0xe8f7,
  }) : contributions = contributions ?? <GoalContribution>[];

  final String id;
  String name;
  double targetAmount;
  List<GoalContribution> contributions;
  DateTime? deadline;
  String colorHex;
  int iconCodePoint;

  Color get color => colorFromHex(colorHex);

  double get savedAmount {
    double total = 0;
    for (final GoalContribution c in contributions) {
      total += c.amount;
    }
    return total;
  }

  double get progress => targetAmount <= 0
      ? 0.0
      : (savedAmount / targetAmount).clamp(0.0, 1.0).toDouble();
  bool get isDone => savedAmount >= targetAmount && targetAmount > 0;

  /// Soma das contribuições de todas as metas dentro do período informado.
  /// Usado para descontar, no saldo do extrato, o dinheiro que saiu para a meta.
  static double contributionsBetween(
    Iterable<Goal> goals,
    DateTime from,
    DateTime to,
  ) {
    final DateTime start = DateTime(from.year, from.month, from.day);
    final DateTime end = DateTime(to.year, to.month, to.day, 23, 59, 59);
    double total = 0;
    for (final Goal g in goals) {
      for (final GoalContribution c in g.contributions) {
        if (c.date.isBefore(start) || c.date.isAfter(end)) continue;
        total += c.amount;
      }
    }
    return total;
  }

  Goal copyWith({
    String? name,
    double? targetAmount,
    List<GoalContribution>? contributions,
    DateTime? deadline,
    String? colorHex,
    int? iconCodePoint,
  }) {
    return Goal(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      contributions: contributions ?? this.contributions,
      deadline: deadline ?? this.deadline,
      colorHex: colorHex ?? this.colorHex,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'contributions':
            contributions.map((GoalContribution c) => c.toJson()).toList(),
        'deadline': deadline?.toIso8601String(),
        'colorHex': colorHex,
        'iconCodePoint': iconCodePoint,
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0,
        contributions: (json['contributions'] is List)
            ? (json['contributions'] as List<dynamic>)
                .whereType<Map<dynamic, dynamic>>()
                .map((Map<dynamic, dynamic> e) =>
                    GoalContribution.fromJson(e.cast<String, dynamic>()))
                .toList()
            : <GoalContribution>[],
        deadline: json['deadline'] == null
            ? null
            : DateTime.parse(json['deadline'] as String),
        colorHex: json['colorHex'] as String? ?? '06D6A0',
        iconCodePoint: (json['iconCodePoint'] as num?)?.toInt() ?? 0xe8f7,
      );
}
