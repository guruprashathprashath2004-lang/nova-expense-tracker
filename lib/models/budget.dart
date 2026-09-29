class Budget {
  final String id;
  final String userId;
  final String category;
  final double limit;
  final double spent;
  final String month;

  const Budget({
    this.id = '',
    this.userId = '',
    required this.category,
    required this.limit,
    this.spent = 0,
    this.month = '',
  });

  double get remaining => limit - spent;

  Budget copyWith({
    String? id,
    String? userId,
    String? category,
    double? limit,
    double? spent,
    String? month,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      limit: limit ?? this.limit,
      spent: spent ?? this.spent,
      month: month ?? this.month,
    );
  }

  factory Budget.fromJson(String id, Map<String, dynamic> json) => Budget(
        id: id,
        userId: json['userId'] as String? ?? '',
        category: json['category'] as String? ?? 'Other',
        limit: (json['limit'] as num?)?.toDouble() ?? 0,
        spent: (json['spent'] as num?)?.toDouble() ?? 0,
        month: json['month'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'category': category,
        'limit': limit,
        'month': month,
      };
}
