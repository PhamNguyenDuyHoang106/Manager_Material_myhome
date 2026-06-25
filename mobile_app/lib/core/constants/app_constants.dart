class AppConstants {
  AppConstants._();

  static const String appName = 'Quản Lý Vật Liệu';
  static const double lowStockThreshold = 10;
  static const String currencySymbol = '₫';

  static String userCollection(String uid) => 'users/$uid';
  static String customersPath(String uid) => 'users/$uid/customers';
  static String materialsPath(String uid) => 'users/$uid/materials';
  static String materialCategoriesPath(String uid) => 'users/$uid/material_categories';
  static String inventoryTxPath(String uid) => 'users/$uid/inventory_transactions';
  static String invoicesPath(String uid) => 'users/$uid/invoices';
  static String paymentsPath(String uid) => 'users/$uid/payments';
  static String settingsPath(String uid) => 'users/$uid/settings';
  static String settingsDocId = 'store';
}
