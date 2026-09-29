import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../core/glass/glass.dart';
import '../core/validators.dart';
import '../models/expense.dart';
import '../providers/app_state.dart';
import '../providers/auth_provider.dart';
import '../services/currency_service.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.expense});

  final Expense? expense;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  String selectedCategory = '';
  DateTime selectedDate = DateTime.now();
  bool isSubmitting = false;
  bool _amountManuallyEdited = false;
  bool _settingAmountProgrammatically = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    if (expense == null) return;
    titleController.text = expense.title;
    noteController.text = expense.note;
    selectedCategory = expense.category;
    selectedDate = expense.date;
    amountController.addListener(() {
      if (!_settingAmountProgrammatically) _amountManuallyEdited = true;
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final enteredAmount = parseExpenseAmount(amountController.text);
    if (enteredAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid positive amount.')),
      );
      return;
    }
    if (selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an active expense category.')),
      );
      return;
    }
    final userId = ref.read(authProvider).uid;
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in again to save this expense.')),
      );
      return;
    }

    final currencyCode = ref.read(currentCurrencyProvider);
    final rates = ref.read(exchangeRatesProvider).valueOrNull ??
        CurrencyService.defaultRates;
    final currentExpense = widget.expense;
    final amount = currentExpense != null && !_amountManuallyEdited
        ? currentExpense.amount
        : CurrencyService.toLkr(
            enteredAmount,
            currencyCode,
            rates,
          );
    setState(() => isSubmitting = true);
    final expenseId = widget.expense?.id ?? const Uuid().v4();

    final newExpense = Expense(
      id: expenseId,
      title: titleController.text.trim(),
      category: selectedCategory,
      amount: amount,
      date: selectedDate,
      note: noteController.text.trim(),
      userId: userId,
    );

    try {
      final repository = ref.read(expenseRepositoryProvider);
      if (currentExpense == null) {
        await repository.create(newExpense, userId: userId);
      } else {
        await repository.update(newExpense, userId: userId);
      }
      if (mounted) Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Could not save the expense.')),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(exchangeRatesProvider, (previous, next) {
      final rates = next.valueOrNull;
      if (rates != null) {
        _syncEditedAmount(ref.read(currentCurrencyProvider), rates);
      }
    });
    ref.listen(currentCurrencyProvider, (previous, next) {
      final rates = ref.read(exchangeRatesProvider).valueOrNull ??
          CurrencyService.defaultRates;
      _syncEditedAmount(next, rates);
    });
    final currencyCode = ref.watch(currentCurrencyProvider);
    final rates = ref.watch(exchangeRatesProvider).valueOrNull ??
        CurrencyService.defaultRates;
    _syncEditedAmount(currencyCode, rates);
    final categories = ref.watch(expenseCategoriesProvider);
    if (selectedCategory.isEmpty && categories.isNotEmpty) {
      selectedCategory = categories.first.name;
    }
    const accent = kAppAccent;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              GlassAppBar(
                title: widget.expense == null ? 'Add expense' : 'Edit expense',
                accent: accent,
                leading: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Expense details',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: titleController,
                                maxLength: 60,
                                decoration: const InputDecoration(
                                  labelText: 'Title',
                                  border: OutlineInputBorder(),
                                ),
                                validator: validateExpenseTitle,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Amount ($currencyCode)',
                                  prefixText:
                                      '${kCurrencies[currencyCode] ?? currencyCode} ',
                                  border: const OutlineInputBorder(),
                                ),
                                validator: validateExpenseAmount,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text('Category',
                                  style:
                                      Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: AppSpacing.sm),
                              if (categories.isEmpty)
                                const Text('No expense categories available.'),
                              if (categories.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: categories.map((category) {
                                    final isSelected =
                                        category.name == selectedCategory;
                                    return CategoryChip(
                                      category: category,
                                      selected: isSelected,
                                      onTap: () => setState(
                                        () => selectedCategory = category.name,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: selectedDate,
                                          firstDate: DateTime(2024),
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked != null) {
                                          setState(() => selectedDate = picked);
                                        }
                                      },
                                      icon: const Icon(
                                          Icons.calendar_today_rounded),
                                      label: Text(
                                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: noteController,
                                maxLines: 3,
                                maxLength: 200,
                                decoration: const InputDecoration(
                                  labelText: 'Note (optional)',
                                  border: OutlineInputBorder(),
                                ),
                                validator: validateExpenseNote,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: isSubmitting ? null : _saveExpense,
                            icon: isSubmitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(
                                isSubmitting ? 'Saving...' : 'Save expense'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _syncEditedAmount(
    String currencyCode,
    Map<String, double> rates,
  ) {
    final expense = widget.expense;
    if (expense == null || _amountManuallyEdited) return;
    _settingAmountProgrammatically = true;
    amountController.text = CurrencyService.fromLkr(
      expense.amount,
      currencyCode,
      rates,
    ).toStringAsFixed(2);
    _settingAmountProgrammatically = false;
  }
}
