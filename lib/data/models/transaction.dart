enum TransactionType { income, expense }

TransactionType transactionTypeFromName(String name) {
  return TransactionType.values.firstWhere(
    (TransactionType t) => t.name == name,
    orElse: () => TransactionType.expense,
  );
}

class Transaction {
  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.description = '',
    this.notes = '',
    this.isPaid = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  TransactionType type;
  double amount;
  String categoryId;
  DateTime date;
  String description;
  String notes;
  bool isPaid;
  final DateTime createdAt;

  double get signedAmount =>
      type == TransactionType.income ? amount : -amount;

  Transaction copyWith({
    TransactionType? type,
    double? amount,
    String? categoryId,
    DateTime? date,
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
      description: description ?? this.description,
      notes: notes ?? this.notes,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.name,
        'amount': amount,
        'categoryId': categoryId,
        'date': date.toIso8601String(),
        'description': description,
        'notes': notes,
        'isPaid': isPaid,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        type: transactionTypeFromName(json['type'] as String? ?? 'expense'),
        amount: (json['amount'] as num).toDouble(),
        categoryId: json['categoryId'] as String,
        date: DateTime.parse(json['date'] as String),
        description: json['description'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        isPaid: json['isPaid'] as bool? ?? true,
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.parse(json['createdAt'] as String),
      );
}
