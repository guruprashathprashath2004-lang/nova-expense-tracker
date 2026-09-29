import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/glass/glass.dart';
import '../../models/expense.dart';
import '../../providers/app_state.dart';
import '../../providers/auth_provider.dart';
import '../../services/currency_service.dart';
import '../../widgets/expense_tile.dart';
import '../add_expense_screen.dart';
import 'home_tab_frame.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final expenses = expensesAsync.valueOrNull ?? const <Expense>[];
    final filteredAsync = ref.watch(filteredExpensesProvider);
    final filtered = filteredAsync.valueOrNull ?? const <Expense>[];
    final currencyCode = ref.watch(currentCurrencyProvider);
    final rates = ref.watch(exchangeRatesProvider).valueOrNull ??
        CurrencyService.defaultRates;

    return HomeTabFrame(
      title: 'History',
      subtitle: 'Expense timeline and filters',
      onRefresh: () async {
        ref.invalidate(expensesProvider);
        await ref.read(expensesProvider.future);
      },
      children: [
        GlassCard(
          child: Column(
            children: [
              TextFormField(
                key: ValueKey(ref.watch(expenseSearchProvider).isEmpty),
                initialValue: ref.watch(expenseSearchProvider),
                decoration: const InputDecoration(
                  labelText: 'Search expenses',
                  prefixIcon: Icon(Icons.search_rounded),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) =>
                    ref.read(expenseSearchProvider.notifier).state = value,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  ChoiceChip(
                    label: const Text('Every category'),
                    selected:
                        ref.watch(selectedExpenseCategoryFilterProvider) ==
                            null,
                    onSelected: (_) => ref
                        .read(selectedExpenseCategoryFilterProvider.notifier)
                        .state = null,
                  ),
                  ...ref.watch(expenseCategoriesProvider).map(
                        (category) => ChoiceChip(
                          label: Text(category.name),
                          selected: ref.watch(
                                  selectedExpenseCategoryFilterProvider) ==
                              category.name,
                          onSelected: (_) => ref
                              .read(selectedExpenseCategoryFilterProvider
                                  .notifier)
                              .state = category.name,
                        ),
                      ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _selectDateRange(context, ref),
                    icon: const Icon(Icons.date_range_rounded),
                    label: Text(_dateRangeLabel(
                        ref.watch(expenseHistoryDateRangeProvider))),
                  ),
                  if (ref.watch(expenseHistoryDateRangeProvider) != null)
                    IconButton(
                      tooltip: 'Clear date range',
                      onPressed: () => ref
                          .read(expenseHistoryDateRangeProvider.notifier)
                          .state = null,
                      icon: const Icon(Icons.clear_rounded),
                    ),
                  DropdownButton<ExpenseHistorySort>(
                    value: ref.watch(expenseHistorySortProvider),
                    onChanged: (sort) {
                      if (sort != null) {
                        ref.read(expenseHistorySortProvider.notifier).state =
                            sort;
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: ExpenseHistorySort.newest,
                        child: Text('Newest'),
                      ),
                      DropdownMenuItem(
                        value: ExpenseHistorySort.oldest,
                        child: Text('Oldest'),
                      ),
                      DropdownMenuItem(
                        value: ExpenseHistorySort.highestAmount,
                        child: Text('Amount high-low'),
                      ),
                      DropdownMenuItem(
                        value: ExpenseHistorySort.lowestAmount,
                        child: Text('Amount low-high'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (expensesAsync.isLoading)
          const _HistoryState(
            icon: Icons.hourglass_top_rounded,
            message: 'Loading expenses…',
          )
        else if (expensesAsync.hasError || filteredAsync.hasError)
          _HistoryState(
            icon: Icons.cloud_off_rounded,
            message: 'Could not load expenses: '
                '${expensesAsync.error ?? filteredAsync.error}',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(expensesProvider),
          )
        else if (expenses.isEmpty)
          _HistoryState(
            icon: Icons.receipt_long_outlined,
            message: 'No expenses yet. Tap + to add your first one.',
            actionLabel: 'Add expense',
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
            ),
          )
        else if (filtered.isEmpty)
          _HistoryState(
            icon: Icons.filter_alt_off_rounded,
            message: 'No expenses match your search or filters.',
            actionLabel: 'Clear filters',
            onAction: () => _clearFilters(ref),
          )
        else
          ...filtered.map(
            (expense) => ExpenseTile(
              expense: expense,
              amount: CurrencyService.format(
                expense.amount,
                currencyCode,
                rates,
              ),
              onEdit: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddExpenseScreen(expense: expense),
                ),
              ),
              onDelete: () => _deleteExpense(context, ref, expense),
            ),
          ),
      ],
    );
  }

  void _clearFilters(WidgetRef ref) {
    ref.read(expenseSearchProvider.notifier).state = '';
    ref.read(selectedExpenseCategoryFilterProvider.notifier).state = null;
    ref.read(expenseHistoryDateRangeProvider.notifier).state = null;
    ref.read(expenseHistorySortProvider.notifier).state =
        ExpenseHistorySort.newest;
  }

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: ref.read(expenseHistoryDateRangeProvider),
    );
    if (!context.mounted || range == null) return;
    ref.read(expenseHistoryDateRangeProvider.notifier).state = range;
  }

  String _dateRangeLabel(DateTimeRange? range) {
    if (range == null) return 'Date range';
    return '${DateFormat.yMMMd().format(range.start)} – '
        '${DateFormat.yMMMd().format(range.end)}';
  }

  Future<void> _deleteExpense(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Delete "${expense.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(expenseRepositoryProvider).delete(
            expense.id,
            userId: ref.read(authProvider).uid,
          );
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Could not delete the expense.'),
        ),
      );
    } on StateError catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
}

class _HistoryState extends StatelessWidget {
  const _HistoryState({
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
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
