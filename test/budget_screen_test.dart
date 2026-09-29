import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/models/budget.dart';
import 'package:nova/providers/app_state.dart';
import 'package:nova/screens/budget_screen.dart';
import 'package:nova/services/budget_repository.dart';
import 'package:nova/services/currency_service.dart';

class _RecordingBudgetRepository extends Fake implements BudgetRepository {
  Budget? savedBudget;

  @override
  Future<void> save(Budget budget, {required String userId}) async {
    savedBudget = budget;
  }
}

void main() {
  testWidgets(
      'saving a budget closes the dialog without widget lifecycle errors',
      (tester) async {
    final repository = _RecordingBudgetRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetRepositoryProvider.overrideWith((ref) => repository),
          budgetsProvider.overrideWith((ref) => Stream.value(const <Budget>[])),
          expensesProvider.overrideWith((ref) => const Stream.empty()),
          currencyRatesSnapshotProvider.overrideWith(
            (ref) async => const CurrencyRates(
              rates: CurrencyService.defaultRates,
              updatedAt: null,
              isOffline: true,
            ),
          ),
        ],
        child: const MaterialApp(home: BudgetScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Add budget'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextFormField), '5000');
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(repository.savedBudget, isNotNull);
    expect(repository.savedBudget!.category, 'Food');
    expect(repository.savedBudget!.limit, 5000);
    expect(find.text('Create monthly budget'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
