import '../../core/constants/app_constants.dart';

class FirestorePaths {
  FirestorePaths(this.uid);

  final String uid;

  String get user => '${AppConstants.userCollection(uid)}';
  String get customers => AppConstants.customersPath(uid);
  String get materials => AppConstants.materialsPath(uid);
  String get materialCategories => AppConstants.materialCategoriesPath(uid);
  String get inventoryTransactions => AppConstants.inventoryTxPath(uid);
  String get invoices => AppConstants.invoicesPath(uid);
  String invoiceItems(String invoiceId) => '${invoices}/$invoiceId/invoice_items';
  String get payments => AppConstants.paymentsPath(uid);
  String ledger(String customerId) => '$customers/$customerId/ledger';
  String get settings => '${AppConstants.settingsPath(uid)}/${AppConstants.settingsDocId}';
}
