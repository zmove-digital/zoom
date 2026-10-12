class Budget {
  Budget({
    required this.id,
    required this.categoryId,
    required this.limit,
    required this.monthKey,
  });

  final String id;
  String categoryId;
  double limit;
  String monthKey;

  Budget copyWith({String? categoryId, double? limit, String? monthKey}) {
    return Budget(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      limit: limit ?? this.limit,
      monthKey: monthKey ?? this.monthKey,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'categoryId': categoryId,
        'limit': limit,
        'monthKey': monthKey,
      };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String,
        limit: (json['limit'] as num).toDouble(),
        monthKey: json['monthKey'] as String,
      );
}
