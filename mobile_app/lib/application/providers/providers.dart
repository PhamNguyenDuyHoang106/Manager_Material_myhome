import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/firestore_customer_repository.dart';
import '../../data/repositories/firestore_dashboard_repository.dart';
import '../../data/repositories/firestore_inventory_repository.dart';
import '../../data/repositories/firestore_invoice_repository.dart';
import '../../data/repositories/firestore_material_category_repository.dart';
import '../../data/repositories/firestore_material_repository.dart';
import '../../data/repositories/firestore_payment_repository.dart';
import '../../data/repositories/firestore_settings_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/repositories/material_category_repository.dart';
import '../../domain/repositories/material_repository.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/services/backup_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(ref.watch(firebaseAuthProvider));
});

final customerRepositoryProvider = Provider<CustomerRepository?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;
  return FirestoreCustomerRepository(ref.watch(firestoreProvider), uid);
});

final materialRepositoryProvider = Provider<MaterialRepository?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;
  return FirestoreMaterialRepository(ref.watch(firestoreProvider), uid);
});

final materialCategoryRepositoryProvider = Provider<MaterialCategoryRepository?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;
  return FirestoreMaterialCategoryRepository(ref.watch(firestoreProvider), uid);
});

final inventoryRepositoryProvider = Provider<InventoryRepository?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final materialRepo = ref.watch(materialRepositoryProvider);
  if (uid == null || materialRepo == null) return null;
  return FirestoreInventoryRepository(
    ref.watch(firestoreProvider),
    uid,
    materialRepo as FirestoreMaterialRepository,
  );
});

final invoiceRepositoryProvider = Provider<InvoiceRepository?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final inventoryRepo = ref.watch(inventoryRepositoryProvider);
  if (uid == null || inventoryRepo == null) return null;
  return FirestoreInvoiceRepository(
    ref.watch(firestoreProvider),
    uid,
    inventoryRepo as FirestoreInventoryRepository,
  );
});

final paymentRepositoryProvider = Provider<PaymentRepository?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;
  return FirestorePaymentRepository(ref.watch(firestoreProvider), uid);
});

final dashboardRepositoryProvider = Provider<DashboardRepository?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;
  return FirestoreDashboardRepository(ref.watch(firestoreProvider), uid);
});

final settingsRepositoryProvider = Provider<SettingsRepository?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;
  return FirestoreSettingsRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseStorageProvider),
    uid,
  );
});

final customersStreamProvider = StreamProvider((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchCustomers();
});

final materialsStreamProvider = StreamProvider((ref) {
  final repo = ref.watch(materialRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchMaterials();
});

final categoriesStreamProvider = StreamProvider((ref) {
  final repo = ref.watch(materialCategoryRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchCategories();
});

final invoicesStreamProvider = StreamProvider.family((ref, String query) {
  final repo = ref.watch(invoiceRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchInvoices(query: query);
});

final inventoryTxStreamProvider = StreamProvider((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchTransactions();
});

final dashboardStreamProvider = StreamProvider((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchSummary();
});

final settingsStreamProvider = StreamProvider((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchSettings();
});

final customerLedgerStreamProvider = StreamProvider.family((ref, String customerId) {
  final repo = ref.watch(customerRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchCustomerLedger(customerId);
});

final backupServiceProvider = Provider<BackupService?>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final storage = ref.watch(firebaseStorageProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  if (settingsRepo == null) return null;
  return BackupService(firestore, storage, settingsRepo);
});
