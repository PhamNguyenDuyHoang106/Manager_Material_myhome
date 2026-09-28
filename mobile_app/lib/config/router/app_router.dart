import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/providers.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/customers/presentation/customer_detail_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/inventory/presentation/supplier_detail_screen.dart';
import '../../features/invoices/presentation/invoice_detail_screen.dart';
import '../../features/invoices/presentation/invoice_form_screen.dart';
import '../../features/invoices/presentation/invoices_screen.dart';
import '../../features/materials/presentation/materials_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/backup_restore_screen.dart';
import '../../features/shell/presentation/main_shell_screen.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._authRepo) {
    _user = _authRepo.currentUser;
    _subscription = _authRepo.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final AuthRepository _authRepo;
  late final StreamSubscription<User?> _subscription;
  User? _user;

  User? get user => _user ?? _authRepo.currentUser;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final authNotifierProvider = Provider<AuthNotifier>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final notifier = AuthNotifier(repo);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final user = authNotifier.user;
      final loggingIn = state.matchedLocation == '/login';

      if (user == null) {
        return loggingIn ? null : '/login';
      }
      if (loggingIn) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/invoices/new',
        builder: (_, __) => const InvoiceFormScreen(),
      ),
      // Standalone invoice detail route (accessible from customer ledger)
      GoRoute(
        path: '/invoices/:id',
        builder: (_, state) => InvoiceDetailScreen(invoiceId: state.pathParameters['id']!),
      ),
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
              GoRoute(
                path: '/inventory',
                builder: (_, __) => const InventoryScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => SupplierDetailScreen(
                        supplierId: state.pathParameters['id']!),
                  ),
                ],
              ),
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
