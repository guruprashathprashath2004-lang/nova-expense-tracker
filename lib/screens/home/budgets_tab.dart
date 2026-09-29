import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/glass/glass.dart';
import '../../models/expense.dart';
import '../../providers/app_state.dart';
import '../../services/currency_service.dart';
import '../budget_screen.dart';
import 'home_tab_frame.dart';

class BudgetsTab extends ConsumerWidget {
  const BudgetsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final budgets = budgetsAsync.valueOrNull ?? const [];
    final expenses = expensesAsync.valueOrNull ?? const <Expense>[];
    final now = DateTime.now();
    final currencyCode = ref.watch(currentCurrencyProvider);
    final rates = ref.watch(exchangeRatesProvider).valueOrNull ??
        CurrencyService.defaultRates;

    return HomeTabFrame(
      title: 'Budgets',
      subtitle: 'Track your monthly spending limits',
      children: [
        if (budgetsAsync.isLoading || expensesAsync.isLoading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (budgetsAsync.hasError || expensesAsync.hasError)
          _BudgetState(
            icon: Icons.cloud_off_rounded,
            message: 'Could not load budget data: '
                '${budgetsAsync.error ?? expensesAsync.error}',
            actionLabel: 'Retry',
            onAction: () {
              ref.invalidate(budgetsProvider);
              ref.invalidate(expensesProvider);
            },
          )
        else if (budgets.isEmpty)
          const _BudgetState(
            icon: Icons.savings_outlined,
            message: 'No monthly budgets yet. Add one to get started.',
          )
        else
          ...budgets.map((budget) {
            final spent = expenses
                .where((expense) =>
                    expense.category == budget.category &&
                    expense.date.year == now.year &&
                    expense.date.month == now.month &&
                    (budget.month.isEmpty ||
                        budget.month ==
                            '${now.year}-${now.month.toString().padLeft(2, '0')}'))
                .fold<double>(0,
                    (runningTotal, expense) => runningTotal + expense.amount);
            return GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(budget.category,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  BudgetProgressBar(
                    spent: CurrencyService.fromLkr(
                      spent,
                      currencyCode,
                      rates,
                    ),
                    limit: CurrencyService.fromLkr(
                      budget.limit,
                      currencyCode,
                      rates,
                    ),
                    label:
                        '${CurrencyService.format(spent, currencyCode, rates, decimalDigits: 0)} '
                        'of ${CurrencyService.format(budget.limit, currencyCode, rates, decimalDigits: 0)}',
                  ),
                ],
              ),
            );
          }),
        if (!budgetsAsync.isLoading &&
            !expensesAsync.isLoading &&
            !budgetsAsync.hasError &&
            !expensesAsync.hasError)
          GlassCard(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BudgetScreen()),
                ),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Manage budgets'),
              ),
            ),
          ),
      ],
    );
  }
}

class _BudgetState extends StatelessWidget {
  const _BudgetState({
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
    return GlassCard(
      child: Column(
        children: [
          Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
