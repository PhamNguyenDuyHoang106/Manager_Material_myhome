import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/customers/presentation/customer_detail_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/invoices/presentation/invoice_detail_screen.dart';
import '../../features/invoices/presentation/invoices_screen.dart';
import '../../features/materials/presentation/materials_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/backup_restore_screen.dart';
import '../../features/shell/presentation/main_shell_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final loggingIn = state.matchedLocation == '/login';

      if (user == null) {
        return loggingIn ? null : '/login';
      }
      if (loggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customers',
                builder: (_, __) => const CustomersScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => CustomerDetailScreen(customerId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/invoices',
                builder: (_, __) => const InvoicesScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => InvoiceDetailScreen(invoiceId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/materials', builder: (_, __) => const MaterialsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/inventory', builder: (_, __) => const InventoryScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'backup',
                    builder: (_, __) => const BackupRestoreScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}
