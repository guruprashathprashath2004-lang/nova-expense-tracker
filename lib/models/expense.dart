import 'package:flutter/material.dart';

class Expense {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String note;
  final String userId;

  const Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
    this.userId = '',
  });

  String get categoryKey => category;

  Expense copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    DateTime? date,
    String? note,
    String? userId,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
        'userId': userId,
      };

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Expense',
      category: json['category'] as String? ?? 'Other',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      note: json['note'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
    );
  }

  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_filled_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'entertainment':
        return Icons.movie_filter_rounded;
      case 'education':
        return Icons.school_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
