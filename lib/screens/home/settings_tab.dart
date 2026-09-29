import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/glass/glass.dart';
import '../../providers/app_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currentCurrencyProvider);
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final ratesAsync = ref.watch(currencyRatesSnapshotProvider);
    final rates = ratesAsync.valueOrNull;

    return ListView(
      padding: const EdgeInsets.only(bottom: 96, top: AppSpacing.md),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(authState.email.isEmpty ? 'Not signed in' : authState.email),
              const SizedBox(height: AppSpacing.md),
              FilledButton.tonal(
                onPressed: () => ref.read(authProvider.notifier).signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Currency', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 10,
                children: kCurrencies.keys.map((code) {
                  final selected = code == currency;
                  return ChoiceChip(
                    label: Text(code),
                    selected: selected,
                    onSelected: selected
                        ? null
                        : (_) => _updateCurrency(context, ref, code),
                    selectedColor: kAppAccent,
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rates?.updatedAt == null
                          ? rates?.isOffline == true
                              ? 'Using offline rates'
                              : 'Loading exchange rates…'
                          : '${rates!.isOffline ? 'Using offline rates · ' : ''}'
                              'Rates as of ${DateFormat('d MMM yyyy, HH:mm').format(rates.updatedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh exchange rates',
                    onPressed: ratesAsync.isLoading
                        ? null
                        : () => ref
                            .read(currencyRefreshRequestProvider.notifier)
                            .state++,
                    icon: ratesAsync.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
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
              Text('Appearance',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Material(
                color: Colors.transparent,
                child: SwitchListTile.adaptive(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (isDark) async {
                    try {
                      await ref.read(themeModeProvider.notifier).setThemeMode(
                            isDark ? ThemeMode.dark : ThemeMode.light,
                          );
                    } on StateError catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.message)),
                      );
                    }
                  },
                  title: const Text('Dark mode'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _updateCurrency(
    BuildContext context,
    WidgetRef ref,
    String currencyCode,
  ) async {
    try {
      await ref.read(authProvider.notifier).updateCurrencyCode(currencyCode);
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Could not update currency.'),
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
