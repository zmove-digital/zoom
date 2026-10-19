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

/// Datas das ocorrências seguintes a [start] (sem incluir a própria [start]).
///
/// [count] limita quantas ocorrências gerar; [until] limita a data final.
/// Informe pelo menos um dos dois (sem nenhum não há fim para a repetição).
List<DateTime> recurrenceDates(
  DateTime start,
  RecurrencePeriod period, {
  int? count,
  DateTime? until,
}) {
  final List<DateTime> dates = <DateTime>[];
  if (count != null && count <= 0) return dates;
  if (count == null && until == null) return dates;
  DateTime cursor = start;
  while (true) {
    if (count != null && dates.length >= count) break;
    cursor = period.next(cursor);
    if (until != null && cursor.isAfter(until)) break;
    dates.add(cursor);
  }
  return dates;
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
    this.recurrenceCount,
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

  /// Quantos lançamentos a série tem ao todo (o primeiro incluído).
  /// `null` = repetição sem número definido (usa o horizonte padrão).
  int? recurrenceCount;
  final DateTime createdAt;

  bool get isRecurring => recurrenceId != null && recurrence != null;

  bool get isFuture {
    final DateTime now = DateTime.now();
    return date.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));
  }

  /// A data do lançamento já passou (antes de hoje).
  bool get isPastDue {
    final DateTime now = DateTime.now();
    return date.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Efetivado somente quando o usuário confirma a efetivação
  /// (`isPaid == true`). Lançamentos futuros nunca são efetivados sozinhos.
  bool get isSettled => !isFuture && isPaid == true;

  /// Pendente de efetivação (inclui futuros e vencidos).
  bool get isPending => !isSettled;

  /// Vencido: a data já passou e o lançamento ainda não foi efetivado.
  bool get isOverdue => isPastDue && !isSettled;

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
      recurrenceCount: recurrenceCount,
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
        'recurrenceCount': recurrenceCount,
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
        recurrenceCount: (json['recurrenceCount'] as num?)?.toInt(),
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.parse(json['createdAt'] as String),
      );
}
