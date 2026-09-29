import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/glass/glass.dart';
import 'add_expense_screen.dart';
import 'home/analytics_tab.dart';
import 'home/budgets_tab.dart';
import 'home/history_tab.dart';
import 'home/home_tab.dart';
import 'home/settings_tab.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() =>
      _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  int _selectedTab = 0;

  static const _titles = <String>[
    'Nova',
    'History',
    'Budgets',
    'Analytics',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    const tabs = [
      HomeTab(),
      HistoryTab(),
      BudgetsTab(),
      AnalyticsTab(),
      SettingsTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              GlassAppBar(
                title: _titles[_selectedTab],
                accent: kAppAccent,
                actions: const [ThemeToggleButton()],
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: tabs,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AddExpenseScreen(),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New expense'),
            )
          : null,
      bottomNavigationBar: GlassBottomNavBar(
        accent: kAppAccent,
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        items: const [
          GlassNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          GlassNavItem(
            icon: Icons.history_outlined,
            activeIcon: Icons.history_rounded,
            label: 'History',
          ),
          GlassNavItem(
            icon: Icons.pie_chart_outline_rounded,
            activeIcon: Icons.pie_chart_rounded,
            label: 'Budgets',
          ),
          GlassNavItem(
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart_rounded,
            label: 'Analytics',
          ),
          GlassNavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
