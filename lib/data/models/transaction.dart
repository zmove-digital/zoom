enum TransactionType { income, expense }

TransactionType transactionTypeFromName(String name) {
  return TransactionType.values.firstWhere(
    (TransactionType t) => t.name == name,
    orElse: () => TransactionType.expense,
  );
}

enum RecurrencePeriod { weekly, biweekly, monthly }

RecurrencePeriod? recurrencePeriodFromName(String? name) {
  if (name == null) return null;
  for (final RecurrencePeriod p in RecurrencePeriod.values) {
    if (p.name == name) return p;
  }
  return null;
}

extension RecurrencePeriodLabel on RecurrencePeriod {
  String get label {
    switch (this) {
      case RecurrencePeriod.weekly:
        return 'Semanal';
      case RecurrencePeriod.biweekly:
        return 'Quinzenal';
      case RecurrencePeriod.monthly:
        return 'Mensal';
    }
  }

  DateTime next(DateTime from) {
    switch (this) {
      case RecurrencePeriod.weekly:
        return from.add(const Duration(days: 7));
      case RecurrencePeriod.biweekly:
        return from.add(const Duration(days: 14));
      case RecurrencePeriod.monthly:
        return addMonths(from, 1);
    }
  }
}

DateTime addMonths(DateTime date, int months) {
  final int target = date.month - 1 + months;
  final int year = date.year + (target ~/ 12);
  final int month = target % 12 + 1;
  final int lastDay = DateTime(year, month + 1, 0).day;
  final int day = date.day <= lastDay ? date.day : lastDay;
  return DateTime(year, month, day, date.hour, date.minute, date.second);
}

class Transaction {
  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.accountId,
    this.description = '',
    this.notes = '',
    this.isPaid,
    this.recurrenceId,
    this.recurrence,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  TransactionType type;
  double amount;
  String categoryId;
  DateTime date;
  String? accountId;
  String description;
  String notes;

  /// `null` = automático (decide pela data); `true` = efetivado; `false` = pendente.
  bool? isPaid;
  String? recurrenceId;
  RecurrencePeriod? recurrence;
  final DateTime createdAt;

  bool get isRecurring => recurrenceId != null && recurrence != null;

  bool get isFuture {
    final DateTime now = DateTime.now();
    return date.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));
  }

  /// Efetivado somente quando a data é hoje ou passada e não foi marcado
  /// manualmente como pendente. Lançamentos futuros nunca são efetivados.
  bool get isSettled => !isFuture && isPaid != false;

  double get signedAmount =>
      type == TransactionType.income ? amount : -amount;

  Transaction copyWith({
    TransactionType? type,
    double? amount,
    String? categoryId,
    DateTime? date,
    String? accountId,
    String? description,
    String? notes,
    bool? isPaid,
  }) {
    return Transaction(
      id: id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      isPaid: isPaid ?? this.isPaid,
      recurrenceId: recurrenceId,
      recurrence: recurrence,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.name,
        'amount': amount,
        'categoryId': categoryId,
        'date': date.toIso8601String(),
        'accountId': accountId,
        'description': description,
        'notes': notes,
        'isPaid': isPaid,
        'recurrenceId': recurrenceId,
        'recurrence': recurrence?.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        type: transactionTypeFromName(json['type'] as String? ?? 'expense'),
        amount: (json['amount'] as num).toDouble(),
        categoryId: json['categoryId'] as String,
        date: DateTime.parse(json['date'] as String),
        accountId: json['accountId'] as String?,
        description: json['description'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        isPaid: json['isPaid'] as bool?,
        recurrenceId: json['recurrenceId'] as String?,
        recurrence: recurrencePeriodFromName(json['recurrence'] as String?),
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.parse(json['createdAt'] as String),
      );
}
