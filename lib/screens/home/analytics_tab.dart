import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/glass/glass.dart';
import '../../models/expense.dart';
import '../../providers/app_state.dart';
import '../../services/currency_service.dart';
import '../../services/export_service.dart';
import 'home_tab_frame.dart';

class AnalyticsTab extends ConsumerWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final expenses = expensesAsync.valueOrNull ?? const <Expense>[];
    final currencyCode = ref.watch(currentCurrencyProvider);
    final rates = ref.watch(exchangeRatesProvider).valueOrNull ??
        CurrencyService.defaultRates;

    if (expensesAsync.isLoading) {
      return const HomeTabFrame(
        title: 'Analytics',
        subtitle: 'Calculated from your Firestore expense records',
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }
    if (expensesAsync.hasError) {
      return HomeTabFrame(
        title: 'Analytics',
        subtitle: 'Calculated from your Firestore expense records',
        children: [
          _AnalyticsState(
            icon: Icons.cloud_off_rounded,
            message: 'Could not load expenses: ${expensesAsync.error}',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(expensesProvider),
          ),
        ],
      );
    }
    if (expenses.isEmpty) {
      return const HomeTabFrame(
        title: 'Analytics',
        subtitle: 'Calculated from your Firestore expense records',
        children: [
          _AnalyticsState(
            icon: Icons.insert_chart_outlined_rounded,
            message:
                'No expense data yet. Add expenses to see your spending trends.',
          ),
        ],
      );
    }

    final now = DateTime.now();
    final firstMonth = DateTime(now.year, now.month - 5);
    final monthStarts = List.generate(
      6,
      (index) => DateTime(firstMonth.year, firstMonth.month + index),
    );
    final monthTotals = monthStarts.map((month) {
      final total = expenses
          .where((expense) =>
              expense.date.year == month.year &&
              expense.date.month == month.month)
          .fold<double>(0, (sum, expense) => sum + expense.amount);
      return CurrencyService.fromLkr(total, currencyCode, rates);
    }).toList();

    final categoryTotals = <String, double>{};
    final spendingByWeekday = <int, double>{};
    for (final expense in expenses) {
      categoryTotals.update(
        expense.category,
        (amount) => amount + expense.amount,
        ifAbsent: () => expense.amount,
      );
      spendingByWeekday.update(
        expense.date.weekday,
        (amount) => amount + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    categoryTotals.updateAll(
      (_, amount) => CurrencyService.fromLkr(amount, currencyCode, rates),
    );
    final categories = categoryTotals.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    final busiestDay = spendingByWeekday.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    const weekdays = {
      DateTime.monday: 'Monday',
      DateTime.tuesday: 'Tuesday',
      DateTime.wednesday: 'Wednesday',
      DateTime.thursday: 'Thursday',
      DateTime.friday: 'Friday',
      DateTime.saturday: 'Saturday',
      DateTime.sunday: 'Sunday',
    };

    return HomeTabFrame(
      title: 'Analytics',
      subtitle: 'Calculated from your Firestore expense records',
      onRefresh: () async {
        ref.invalidate(expensesProvider);
        await ref.read(expensesProvider.future);
      },
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Export expenses',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _exportCsv(
                      context,
                      expenses,
                      currencyCode,
                      rates,
                    ),
                    icon: const Icon(Icons.table_view_rounded),
                    label: const Text('CSV'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _exportPdf(
                      context,
                      expenses,
                      currencyCode,
                      rates,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('PDF'),
                  ),
                ],
              ),
            ],
          ),
        ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Six-month spend',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    barGroups: List.generate(
                      monthTotals.length,
                      (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: monthTotals[index],
                            color: kAppAccent,
                            width: 18,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= monthStarts.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                  DateFormat.MMM().format(monthStarts[index])),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category breakdown',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 32,
                    sections: categories.map((entry) {
                      return PieChartSectionData(
                        value: entry.value,
                        color: categoryByName(entry.key).color,
                        radius: 72,
                        title: entry.key,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Text('Top category: ${categories.first.key}'),
              if (busiestDay.isNotEmpty)
                Text(
                  'Highest spend day: '
                  '${weekdays[busiestDay.first.key] ?? 'Unknown'}',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _exportCsv(
    BuildContext context,
    List<Expense> expenses,
    String currencyCode,
    Map<String, double> rates,
  ) async {
    try {
      await const ExportService().exportCsv(
        expenses: expenses,
        currencyCode: currencyCode,
        rates: rates,
      );
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.message ?? 'Could not share the CSV file.')),
      );
    }
  }

  Future<void> _exportPdf(
    BuildContext context,
    List<Expense> expenses,
    String currencyCode,
    Map<String, double> rates,
  ) async {
    try {
      await const ExportService().exportPdf(
        expenses: expenses,
        currencyCode: currencyCode,
        rates: rates,
      );
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.message ?? 'Could not share the PDF file.')),
      );
    }
  }
}

class _AnalyticsState extends StatelessWidget {
  const _AnalyticsState({
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
