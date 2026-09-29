import 'package:flutter_test/flutter_test.dart';
import 'package:nova/models/expense.dart';

void main() {
  test('expense JSON roundtrip preserves every field', () {
    final expense = Expense(
      id: 'expense-roundtrip',
      title: 'Lunch',
      category: 'Food',
      amount: 1250.5,
      date: DateTime(2026, 9, 29, 12, 30),
      note: 'At work',
      userId: 'user-1',
    );

    expect(Expense.fromJson(expense.toJson()).toJson(), expense.toJson());
  });

  test('expense JSON decoding applies defaults to missing optional fields', () {
    final expense = Expense.fromJson({
      'id': 'expense-defaults',
      'date': '2026-09-01T00:00:00.000',
    });

    expect(expense.title, 'Expense');
    expect(expense.category, 'Other');
    expect(expense.amount, 0);
    expect(expense.note, isEmpty);
    expect(expense.userId, isEmpty);
  });

  test('copyWith changes selected fields and preserves the rest', () {
    final original = Expense(
      id: 'expense-copy',
      title: 'Lunch',
      category: 'Food',
      amount: 100,
      date: DateTime(2026, 9, 29),
      note: 'Before',
      userId: 'user-1',
    );

    final updated = original.copyWith(title: 'Dinner', amount: 200);

    expect(updated.title, 'Dinner');
    expect(updated.amount, 200);
    expect(updated.id, original.id);
    expect(updated.category, original.category);
    expect(updated.date, original.date);
    expect(updated.note, original.note);
    expect(updated.userId, original.userId);
  });

  test('expense serialization contains assignment fields only', () {
    final expense = Expense(
      id: 'expense-1',
      title: 'Lunch',
      category: 'Food',
      amount: 12.5,
      date: DateTime.utc(2026, 9, 29),
      note: 'Team lunch',
      userId: 'user-1',
    );

    final json = expense.toJson();

    expect(json['title'], 'Lunch');
    expect(json['amount'], 12.5);
    expect(json['category'], 'Food');
    expect(json['note'], 'Team lunch');
    expect(json.containsKey('recurring'), isFalse);
    expect(json.containsKey('recurrenceInterval'), isFalse);
  });

  test('legacy recurrence metadata is ignored when reading old records', () {
    final expense = Expense.fromJson({
      'id': 'legacy-expense',
      'title': 'Rent',
      'category': 'Bills',
      'amount': 1000,
      'date': '2026-09-01T00:00:00.000Z',
      'recurring': true,
      'recurrenceInterval': 'monthly',
    });

    expect(expense.title, 'Rent');
    expect(expense.amount, 1000);
    expect(expense.toJson().containsKey('recurring'), isFalse);
  });
}
