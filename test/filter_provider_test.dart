import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/models/expense.dart';
import 'package:nova/providers/app_state.dart';

void main() {
  final expenses = [
    Expense(
      id: 'feb',
      title: 'February fare',
      category: 'Transport',
      amount: 5,
      date: DateTime(2026, 2, 28, 23, 59),
    ),
    Expense(
      id: 'march-first',
      title: 'Bus',
      category: 'Transport',
      amount: 10,
      date: DateTime(2026, 3, 1),
    ),
    Expense(
      id: 'march-mid',
      title: 'Lunch',
      category: 'Food',
      amount: 20,
      date: DateTime(2026, 3, 15),
      note: 'Coffee shop',
    ),
    Expense(
      id: 'march-last',
      title: 'Groceries',
      category: 'Food',
      amount: 30,
      date: DateTime(2026, 3, 31, 23, 59, 59),
    ),
    Expense(
      id: 'april',
      title: 'April bill',
      category: 'Bills',
      amount: 100,
      date: DateTime(2026, 4, 1),
    ),
  ];

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        expensesProvider.overrideWith((ref) => Stream.value(expenses)),
      ],
    );
  }

  Future<List<Expense>> filtered(ProviderContainer container) async {
    await container.read(expensesProvider.future);
    return container.read(filteredExpensesProvider).valueOrNull!;
  }

  test('search matches title, category, and note without case sensitivity',
      () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(expensesProvider.future);

    container.read(expenseSearchProvider.notifier).state = 'COFFEE';

    expect((await filtered(container)).map((expense) => expense.id),
        ['march-mid']);
  });

  test('category filter only returns the selected category', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(expensesProvider.future);

    container.read(selectedExpenseCategoryFilterProvider.notifier).state =
        'Food';

    expect((await filtered(container)).map((expense) => expense.id),
        ['march-last', 'march-mid']);
  });

  test('date range includes the entire selected end date', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(expensesProvider.future);

    container.read(expenseHistoryDateRangeProvider.notifier).state =
        DateTimeRange(
      start: DateTime(2026, 3, 1),
      end: DateTime(2026, 3, 31),
    );

    expect((await filtered(container)).map((expense) => expense.id),
        ['march-last', 'march-mid', 'march-first']);
  });

  test('all four sort modes order expenses correctly', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(expensesProvider.future);

    final expected = {
      ExpenseHistorySort.newest: [
        'april',
        'march-last',
        'march-mid',
        'march-first',
        'feb',
      ],
      ExpenseHistorySort.oldest: [
        'feb',
        'march-first',
        'march-mid',
        'march-last',
        'april',
      ],
      ExpenseHistorySort.highestAmount: [
        'april',
        'march-last',
        'march-mid',
        'march-first',
        'feb',
      ],
      ExpenseHistorySort.lowestAmount: [
        'feb',
        'march-first',
        'march-mid',
        'march-last',
        'april',
      ],
    };

    for (final entry in expected.entries) {
      container.read(expenseHistorySortProvider.notifier).state = entry.key;
      expect(
        (await filtered(container)).map((expense) => expense.id),
        entry.value,
      );
    }
  });
}
