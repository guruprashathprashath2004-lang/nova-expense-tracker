import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/models/expense.dart';
import 'package:nova/providers/app_state.dart';

void main() {
  test('monthly total includes the last instant in month but excludes next',
      () async {
    final container = ProviderContainer(
      overrides: [
        expensesProvider.overrideWith(
          (ref) => Stream.value([
            Expense(
              id: 'start',
              title: 'First day',
              category: 'Food',
              amount: 10,
              date: DateTime(2026, 3, 1),
            ),
            Expense(
              id: 'end',
              title: 'Last day',
              category: 'Food',
              amount: 20,
              date: DateTime(2026, 3, 31, 23, 59, 59, 999, 999),
            ),
            Expense(
              id: 'next',
              title: 'Next month',
              category: 'Food',
              amount: 100,
              date: DateTime(2026, 4, 1),
            ),
          ]),
        ),
        selectedMonthProvider.overrideWith((ref) => DateTime(2026, 3)),
      ],
    );
    addTearDown(container.dispose);

    await container.read(expensesProvider.future);

    expect(container.read(monthlyTotalProvider).valueOrNull, 30);
  });

  test('changing selected month recomputes the total and category summary',
      () async {
    final container = ProviderContainer(
      overrides: [
        expensesProvider.overrideWith(
          (ref) => Stream.value([
            Expense(
              id: 'march-food',
              title: 'March lunch',
              category: 'Food',
              amount: 10,
              date: DateTime(2026, 3, 15),
            ),
            Expense(
              id: 'april-bills',
              title: 'April bill',
              category: 'Bills',
              amount: 40,
              date: DateTime(2026, 4, 2),
            ),
          ]),
        ),
        selectedMonthProvider.overrideWith((ref) => DateTime(2026, 3)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(expensesProvider.future);

    expect(container.read(monthlyTotalProvider).valueOrNull, 10);
    expect(container.read(monthlyCategoryTotalsProvider).valueOrNull,
        {'Food': 10});

    container.read(selectedMonthProvider.notifier).state = DateTime(2026, 4);

    expect(container.read(monthlyTotalProvider).valueOrNull, 40);
    expect(container.read(monthlyCategoryTotalsProvider).valueOrNull,
        {'Bills': 40});
  });
}
