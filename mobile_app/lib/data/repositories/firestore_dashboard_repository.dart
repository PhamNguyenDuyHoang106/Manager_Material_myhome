import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/firestore_paths.dart';
import '../mappers/firestore_mapper.dart';

class FirestoreDashboardRepository implements DashboardRepository {
  FirestoreDashboardRepository(this._firestore, this._uid);

  final FirebaseFirestore _firestore;
  final String _uid;

  FirestorePaths get _paths => FirestorePaths(_uid);

  InvoiceStatus _statusFromString(String s) => switch (s) {
        'paid' => InvoiceStatus.paid,
        'partially_paid' => InvoiceStatus.partiallyPaid,
        'cancelled' => InvoiceStatus.cancelled,
        _ => InvoiceStatus.unpaid,
      };

  @override
  Future<DashboardSummary> getSummary() async {
    final now = DateTime.now();
    final invoicesSnap = await _firestore.collection(_paths.invoices).get();
    final paymentsSnap = await _firestore.collection(_paths.payments).get();
    final materialsSnap = await _firestore
        .collection(_paths.materials)
        .where('isDeleted', isEqualTo: false)
        .get();

    int unpaidCount = 0;
    int totalDebt = 0;
    int revenueToday = 0;
    int revenueMonth = 0;
    int lowStock = 0;
    double stockValue = 0;
    final overdueInvoicesList = <OverdueInvoice>[];
    final lowStockMaterialsList = <LowStockMaterialSummary>[];

    for (final doc in invoicesSnap.docs) {
      final data = doc.data();
      final isDeleted = data['isDeleted'] as bool? ?? false;
      if (isDeleted) continue;

      final status = _statusFromString(data['status'] as String? ?? 'unpaid');
      final total = data['totalAmountCents'] as int? ?? 0;
      final paid = data['paidAmountCents'] as int? ?? 0;
      final remaining = total - paid;

      final dateStr = data['invoiceDate'] as String? ?? '';
      final date = DateTime.tryParse(dateStr);
      final age = date != null ? now.difference(date).inDays : 0;

      if (status != InvoiceStatus.paid && status != InvoiceStatus.cancelled && remaining > 0) {
        unpaidCount++;
        totalDebt += remaining;
        if (age > 30) {
          overdueInvoicesList.add(OverdueInvoice(
            id: doc.id,
            customerId: data['customerId'] as String? ?? '',
            customerName: data['customerName'] as String? ?? '',
            invoiceDate: dateStr,
            remainingCents: remaining,
          ));
        }
      }
    }

    for (final doc in paymentsSnap.docs) {
      final data = fromFirestore(doc);
      final isDeleted = data['isDeleted'] as bool? ?? false;
      if (isDeleted) continue;

      final date = data['paymentDate'] as String;
      final amount = data['amountCents'] as int;
      if (AppDateUtils.isSameDay(date, now)) revenueToday += amount;
      if (AppDateUtils.isSameMonth(date, now)) revenueMonth += amount;
    }

    for (final doc in materialsSnap.docs) {
      final data = doc.data();
      final stock = (data['currentStock'] as num).toDouble();
      final importPrice = data['defaultImportPriceCents'] as int? ?? 0;
      stockValue += stock * importPrice;
      
      final minStock = (data['minimumStock'] as num? ?? AppConstants.lowStockThreshold).toDouble();
      if (stock <= minStock) {
        lowStock++;
        lowStockMaterialsList.add(LowStockMaterialSummary(
          id: doc.id,
          name: data['name'] as String? ?? '',
          currentStock: stock,
          unit: data['unit'] as String? ?? '',
          minimumStock: minStock,
        ));
      }
    }

    return DashboardSummary(
      unpaidInvoiceCount: unpaidCount,
      totalDebtCents: totalDebt,
      revenueTodayCents: revenueToday,
      revenueMonthCents: revenueMonth,
      materialCount: materialsSnap.docs.length,
      lowStockCount: lowStock,
      totalStockValueCents: stockValue.round(),
      overdueInvoices: overdueInvoicesList,
      lowStockMaterials: lowStockMaterialsList,
    );
  }

  @override
  Stream<DashboardSummary> watchSummary() async* {
    yield await getSummary();
    await for (final _ in _firestore.collection(_paths.invoices).snapshots()) {
      yield await getSummary();
    }
  }
}
