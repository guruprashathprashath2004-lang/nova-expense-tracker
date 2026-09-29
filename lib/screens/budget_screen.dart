import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../core/glass/glass.dart';
import '../core/validators.dart';
import '../models/budget.dart';
import '../providers/app_state.dart';
import '../providers/auth_provider.dart';
import '../services/currency_service.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final budgets = budgetsAsync.valueOrNull ?? const <Budget>[];
    final expenses = expensesAsync.valueOrNull ?? const [];
    final userId = ref.watch(authProvider).uid;
    final currencyCode = ref.watch(currentCurrencyProvider);
    final rates = ref.watch(exchangeRatesProvider).valueOrNull ??
        CurrencyService.defaultRates;
    String formatAmount(double amount, {int digits = 0}) =>
        CurrencyService.format(
          amount,
          currencyCode,
          rates,
          decimalDigits: digits,
        );
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editBudget(context, ref, userId: userId),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add budget'),
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              GlassAppBar(
                title: 'Budget manager',
                accent: kAppAccent,
                leading: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    if (budgetsAsync.isLoading || expensesAsync.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (budgetsAsync.hasError || expensesAsync.hasError)
                      GlassCard(
                        child: Column(
                          children: [
                            const Icon(Icons.cloud_off_rounded, size: 36),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Could not load budget data: '
                              '${budgetsAsync.error ?? expensesAsync.error}',
                            ),
                            TextButton(
                              onPressed: () {
                                ref.invalidate(budgetsProvider);
                                ref.invalidate(expensesProvider);
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else if (budgets.isEmpty)
                      const GlassCard(
                        child: Column(
                          children: [
                            Icon(Icons.savings_outlined, size: 36),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              'No monthly budgets yet. Add one to get started.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    if (!budgetsAsync.isLoading &&
                        !expensesAsync.isLoading &&
                        !budgetsAsync.hasError &&
                        !expensesAsync.hasError &&
                        budgets.isNotEmpty)
                      ...budgets.map((budget) {
                        final spent = expenses
                            .where((expense) =>
                                expense.category == budget.category &&
                                expense.date.year == now.year &&
                                expense.date.month == now.month &&
                                (budget.month.isEmpty || budget.month == month))
                            .fold<double>(
                                0, (total, expense) => total + expense.amount);
                        return GlassCard(
                          onTap: () => _editBudget(
                            context,
                            ref,
                            userId: userId,
                            existing: budget,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      budget.category,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                  Text(
                                      '${formatAmount(budget.limit - spent)} left'),
                                  IconButton(
                                    tooltip: 'Delete budget',
                                    onPressed: () => _deleteBudget(
                                      context,
                                      ref,
                                      budget,
                                      userId,
                                    ),
                                    icon: const Icon(
                                        Icons.delete_outline_rounded),
                                  ),
                                ],
                              ),
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
                                label: 'Category budget',
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Spent ${formatAmount(spent)} of '
                                '${formatAmount(budget.limit)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (spent > budget.limit)
                                Text(
                                  'Over budget by '
                                  '${formatAmount(spent - budget.limit)}',
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error),
                                ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editBudget(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    Budget? existing,
  }) async {
    final currencyCode = ref.read(currentCurrencyProvider);
    final rates = ref.read(exchangeRatesProvider).valueOrNull ??
        CurrencyService.defaultRates;
    final result = await showDialog<Budget>(
      context: context,
      builder: (_) => _BudgetEditDialog(
        existing: existing,
        currencyCode: currencyCode,
        rates: rates,
      ),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref.read(budgetRepositoryProvider).save(result, userId: userId);
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Could not save budget.')),
      );
    } on StateError catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _deleteBudget(
    BuildContext context,
    WidgetRef ref,
    Budget budget,
    String userId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete budget?'),
        content: Text('Delete the ${budget.category} budget for this month?'),
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
      await ref
          .read(budgetRepositoryProvider)
          .delete(budget.id, userId: userId);
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Could not delete budget.')),
      );
    } on StateError catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
}

class _BudgetEditDialog extends StatefulWidget {
  const _BudgetEditDialog({
    required this.existing,
    required this.currencyCode,
    required this.rates,
  });

  final Budget? existing;
  final String currencyCode;
  final Map<String, double> rates;

  @override
  State<_BudgetEditDialog> createState() => _BudgetEditDialogState();
}

class _BudgetEditDialogState extends State<_BudgetEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _categoryController;
  late final TextEditingController _amountController;
  bool _limitEdited = false;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(
      text: widget.existing?.category ?? 'Food',
    );
    _amountController = TextEditingController(
      text: widget.existing == null
          ? ''
          : CurrencyService.fromLkr(
              widget.existing!.limit,
              widget.currencyCode,
              widget.rates,
            ).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final inputAmount = parseExpenseAmount(_amountController.text);
    if (inputAmount == null) return;

    final now = DateTime.now();
    Navigator.of(context).pop(
      Budget(
        id: widget.existing?.id ?? '',
        category: _categoryController.text,
        limit: widget.existing != null && !_limitEdited
            ? widget.existing!.limit
            : CurrencyService.toLkr(
                inputAmount,
                widget.currencyCode,
                widget.rates,
              ),
        month: '${now.year}-${now.month.toString().padLeft(2, '0')}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null
          ? 'Create monthly budget'
          : 'Edit monthly budget'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownMenu<String>(
              initialSelection: _categoryController.text,
              label: const Text('Category'),
              dropdownMenuEntries: kDefaultCategories
                  .map((category) => DropdownMenuEntry(
                        value: category.name,
                        label: category.name,
                      ))
                  .toList(),
              onSelected: (value) {
                if (value != null) _categoryController.text = value;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _amountController,
              onChanged: (_) => _limitEdited = true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monthly limit',
                prefixText:
                    '${kCurrencies[widget.currencyCode] ?? widget.currencyCode} ',
              ),
              validator: validateExpenseAmount,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
