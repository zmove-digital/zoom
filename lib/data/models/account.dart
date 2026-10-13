import 'package:flutter/material.dart';

import 'category.dart';

enum AccountType { cash, checking, savings, credit, investment, other }

AccountType accountTypeFromName(String name) {
  return AccountType.values.firstWhere(
    (AccountType t) => t.name == name,
    orElse: () => AccountType.other,
  );
}

extension AccountTypeMeta on AccountType {
  String get label {
    switch (this) {
      case AccountType.cash:
        return 'Dinheiro / Carteira';
      case AccountType.checking:
        return 'Conta Corrente / Banco';
      case AccountType.savings:
        return 'Poupança';
      case AccountType.credit:
        return 'Cartão de Crédito';
      case AccountType.investment:
        return 'Investimento';
      case AccountType.other:
        return 'Outros';
    }
  }

  String get shortLabel {
    switch (this) {
      case AccountType.cash:
        return 'Dinheiro';
      case AccountType.checking:
        return 'Banco';
      case AccountType.savings:
        return 'Poupança';
      case AccountType.credit:
        return 'Cartão';
      case AccountType.investment:
        return 'Investimento';
      case AccountType.other:
        return 'Outros';
    }
  }

  IconData get icon {
    switch (this) {
      case AccountType.cash:
        return Icons.payments_outlined;
      case AccountType.checking:
        return Icons.account_balance_outlined;
      case AccountType.savings:
        return Icons.savings_outlined;
      case AccountType.credit:
        return Icons.credit_card_outlined;
      case AccountType.investment:
        return Icons.trending_up_outlined;
      case AccountType.other:
        return Icons.account_balance_wallet_outlined;
    }
  }

  String get defaultColorHex {
    switch (this) {
      case AccountType.cash:
        return '06D6A0';
      case AccountType.checking:
        return '457B9D';
      case AccountType.savings:
        return '4ECDC4';
      case AccountType.credit:
        return 'EF476F';
      case AccountType.investment:
        return 'A06CD5';
      case AccountType.other:
        return '577590';
    }
  }
}

class Account {
  Account({
    required this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0,
    String? colorHex,
    DateTime? createdAt,
  })  : colorHex = colorHex ?? type.defaultColorHex,
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  AccountType type;
  double initialBalance;
  String colorHex;
  final DateTime createdAt;

  Color get color => colorFromHex(colorHex);

  IconData get icon => type.icon;

  Account copyWith({
    String? name,
    AccountType? type,
    double? initialBalance,
    String? colorHex,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'type': type.name,
        'initialBalance': initialBalance,
        'colorHex': colorHex,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        type: accountTypeFromName(json['type'] as String? ?? 'other'),
        initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0,
        colorHex: json['colorHex'] as String?,
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.parse(json['createdAt'] as String),
      );
}
