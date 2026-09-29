import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/glass/glass.dart';
import '../models/expense.dart';

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    required this.expense,
    required this.amount,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final Expense expense;
  final String amount;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final category = categoryByName(expense.category);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(expense.categoryIcon, color: category.color),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.title,
                      style: Theme.of(context).textTheme.bodyLarge),
                  Text(
                    '${expense.category} • '
                    '${expense.date.day}/${expense.date.month}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(amount, style: Theme.of(context).textTheme.bodyMedium),
            if (onEdit != null)
              IconButton(
                tooltip: 'Edit expense',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            if (onDelete != null)
              IconButton(
                tooltip: 'Delete expense',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
      ),
    );
  }
}
