import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../services/budget_repository.dart';
import '../services/currency_service.dart';
import '../services/expense_repository.dart';
import '../services/firebase_auth_service.dart';
import 'auth_provider.dart';

final currentCurrencyProvider = Provider<String>(
  (ref) => ref.watch(authProvider.select((session) => session.currencyCode)),
);

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  final service = CurrencyService();
  ref.onDispose(service.dispose);
  return service;
});

final currencyRefreshRequestProvider = StateProvider<int>((ref) => 0);

final currencyRatesSnapshotProvider = FutureProvider<CurrencyRates>(
  (ref) => ref.watch(currencyServiceProvider).getRates(
        forceRefresh: ref.watch(currencyRefreshRequestProvider) > 0,
      ),
);

final exchangeRatesProvider = Provider<AsyncValue<Map<String, double>>>(
  (ref) => ref
      .watch(currencyRatesSnapshotProvider)
      .whenData((snapshot) => snapshot.rates),
);

final expenseSearchProvider = StateProvider<String>((ref) => '');

final selectedExpenseCategoryFilterProvider =
    StateProvider<String?>((ref) => null);
final expenseHistoryDateRangeProvider =
    StateProvider<DateTimeRange?>((ref) => null);

enum ExpenseHistorySort {
  newest,
  oldest,
  highestAmount,
  lowestAmount,
}

final expenseHistorySortProvider =
    StateProvider<ExpenseHistorySort>((ref) => ExpenseHistorySort.newest);

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final firestore = ref.watch(firebaseAuthServiceProvider).firestore;
  if (firestore == null) {
    throw StateError('Firebase Firestore is unavailable.');
  }
  return ExpenseRepository(firestore);
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final firestore = ref.watch(firebaseAuthServiceProvider).firestore;
  if (firestore == null) {
    throw StateError('Firebase Firestore is unavailable.');
  }
  return BudgetRepository(firestore);
});

final expenseCategoriesProvider =
    Provider<List<AppCategory>>((ref) => kDefaultCategories);

final expensesProvider = StreamProvider<List<Expense>>((ref) {
  final userId = ref.watch(authProvider.select((session) => session.uid));
  if (userId.isEmpty) return Stream.value(const <Expense>[]);
  return ref.watch(expenseRepositoryProvider).watchForUser(userId);
});

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final filteredExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final expenses = ref.watch(expensesProvider);
  final search = ref.watch(expenseSearchProvider).trim().toLowerCase();
  final category = ref.watch(selectedExpenseCategoryFilterProvider);
  final dateRange = ref.watch(expenseHistoryDateRangeProvider);
  final sort = ref.watch(expenseHistorySortProvider);

  return expenses.whenData((items) {
    final filtered = items.where((expense) {
      final matchesSearch = search.isEmpty ||
          expense.title.toLowerCase().contains(search) ||
          expense.category.toLowerCase().contains(search) ||
          expense.note.toLowerCase().contains(search);
      final matchesCategory = category == null || expense.category == category;
      final endExclusive = dateRange == null
          ? null
          : DateTime(
              dateRange.end.year,
              dateRange.end.month,
              dateRange.end.day + 1,
            );
      final matchesRange = dateRange == null ||
          (!expense.date.isBefore(DateTime(
                dateRange.start.year,
                dateRange.start.month,
                dateRange.start.day,
              )) &&
              expense.date.isBefore(endExclusive!));
      return matchesSearch && matchesCategory && matchesRange;
    }).toList();

    filtered.sort((left, right) => switch (sort) {
          ExpenseHistorySort.newest => right.date.compareTo(left.date),
          ExpenseHistorySort.oldest => left.date.compareTo(right.date),
          ExpenseHistorySort.highestAmount =>
            right.amount.compareTo(left.amount),
          ExpenseHistorySort.lowestAmount =>
            left.amount.compareTo(right.amount),
        });
    return filtered;
  });
});

final budgetsProvider = StreamProvider<List<Budget>>((ref) {
  final userId = ref.watch(authProvider.select((session) => session.uid));
  if (userId.isEmpty) return Stream.value(const <Budget>[]);
  return ref.watch(budgetRepositoryProvider).watchForUser(userId);
});

final monthlyTotalProvider = Provider<AsyncValue<double>>((ref) {
  final expenses = ref.watch(expensesProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final monthStart = DateTime(selectedMonth.year, selectedMonth.month);
  final nextMonthStart = DateTime(selectedMonth.year, selectedMonth.month + 1);
  return expenses.whenData((items) => items
      .where((expense) =>
          !expense.date.isBefore(monthStart) &&
          expense.date.isBefore(nextMonthStart))
      .fold<double>(0, (total, expense) => total + expense.amount));
});

final monthlyCategoryTotalsProvider =
    Provider<AsyncValue<Map<String, double>>>((ref) {
  final expenses = ref.watch(expensesProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final monthStart = DateTime(selectedMonth.year, selectedMonth.month);
  final nextMonthStart = DateTime(selectedMonth.year, selectedMonth.month + 1);
  return expenses.whenData((items) {
    final totals = <String, double>{};
    for (final expense in items) {
      if (!expense.date.isBefore(monthStart) &&
          expense.date.isBefore(nextMonthStart)) {
        totals.update(
          expense.category,
          (total) => total + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }
    }
    return totals;
  });
});
