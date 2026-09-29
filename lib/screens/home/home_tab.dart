import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/glass/glass.dart';
import '../../models/expense.dart';
import '../../providers/app_state.dart';
import '../../services/currency_service.dart';
import '../../widgets/expense_tile.dart';
import '../add_expense_screen.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final expenses = expensesAsync.valueOrNull ?? const <Expense>[];
    final totalAsync = ref.watch(monthlyTotalProvider);
    final categoryTotalsAsync = ref.watch(monthlyCategoryTotalsProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final budgets = ref.watch(budgetsProvider).valueOrNull ?? const [];
    final currencyCode = ref.watch(currentCurrencyProvider);
    final rates = ref.watch(exchangeRatesProvider).valueOrNull ??
        CurrencyService.defaultRates;
    final total = CurrencyService.fromLkr(
      totalAsync.valueOrNull ?? 0,
      currencyCode,
      rates,
    );
    final monthlyBudget = budgets.fold<double>(
      0,
      (sum, budget) => sum + budget.limit,
    );
    final displayBudget =
        CurrencyService.fromLkr(monthlyBudget, currencyCode, rates);

    return ListView(
      padding: const EdgeInsets.only(bottom: 96, top: AppSpacing.md),
      children: [
        if (expensesAsync.isLoading || totalAsync.isLoading)
          const LinearProgressIndicator(),
        if (expensesAsync.hasError || totalAsync.hasError)
          _HomeState(
            icon: Icons.cloud_off_rounded,
            message: 'Could not load your expenses.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(expensesProvider),
          ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Previous month',
                    onPressed: () {
                      ref.read(selectedMonthProvider.notifier).state =
                          DateTime(selectedMonth.year, selectedMonth.month - 1);
                    },
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Text(
                    DateFormat.yMMMM().format(selectedMonth),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    tooltip: 'Next month',
                    onPressed: _isCurrentMonth(selectedMonth)
                        ? null
                        : () {
                            ref.read(selectedMonthProvider.notifier).state =
                                DateTime(
                              selectedMonth.year,
                              selectedMonth.month + 1,
                            );
                          },
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AnimatedCounterText(
                value: total,
                currencySymbol: '${kCurrencies[currencyCode] ?? currencyCode} ',
              ),
              const SizedBox(height: AppSpacing.md),
              BudgetProgressBar(
                spent: total,
                limit: displayBudget,
                label: displayBudget > 0
                    ? 'Budget total ${CurrencyService.format(monthlyBudget, currencyCode, rates, decimalDigits: 0)}'
                    : 'No monthly budget set',
              ),
            ],
          ),
        ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category summary',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              if (categoryTotalsAsync.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (categoryTotalsAsync.hasError)
                const Text('Could not load this month’s category totals.')
              else if (categoryTotalsAsync.valueOrNull!.isEmpty)
                const Text('No category spending for this month yet.')
              else
                ...categoryTotalsAsync.valueOrNull!.entries.map((entry) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(child: Text(entry.key)),
                        Text(CurrencyService.format(
                          entry.value,
                          currencyCode,
                          rates,
                          decimalDigits: 0,
                        )),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent expenses',
                      style: Theme.of(context).textTheme.titleSmall),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddExpenseScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add'),
                  ),
                ],
              ),
              if (expensesAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (expensesAsync.hasError)
                const Text('Recent expenses are unavailable. Retry loading.'),
              if (!expensesAsync.isLoading &&
                  !expensesAsync.hasError &&
                  expenses.isEmpty)
                const _HomeState(
                  icon: Icons.receipt_long_outlined,
                  message:
                      'No expenses yet. Add your first expense to get started.',
                ),
              if (!expensesAsync.isLoading && !expensesAsync.hasError)
                ...expenses.take(5).map(
                      (expense) => ExpenseTile(
                        expense: expense,
                        amount: CurrencyService.format(
                          expense.amount,
                          currencyCode,
                          rates,
                          decimalDigits: 0,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isCurrentMonth(DateTime month) {
    final now = DateTime.now();
    return month.year == now.year && month.month == now.month;
  }
}

class _HomeState extends StatelessWidget {
  const _HomeState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
