import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/add_expense_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/budget_screen.dart';
import '../screens/home_dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  ref.listen(
    authProvider.select((state) => state.isAuthenticated),
    (previous, next) => refreshNotifier.refresh(),
  );

  final router = GoRouter(
    initialLocation: ref.read(authProvider).isAuthenticated ? '/home' : '/auth',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthenticated = ref.read(authProvider).isAuthenticated;

      if (!isAuthenticated && location != '/auth') {
        return '/auth';
      }

      if (isAuthenticated && location == '/auth') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
          path: '/home',
          builder: (context, state) => const HomeDashboardScreen()),
      GoRoute(
          path: '/add-expense',
          builder: (context, state) => const AddExpenseScreen()),
      GoRoute(
          path: '/budget', builder: (context, state) => const BudgetScreen()),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refreshNotifier.dispose();
  });
  return router;
});

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
