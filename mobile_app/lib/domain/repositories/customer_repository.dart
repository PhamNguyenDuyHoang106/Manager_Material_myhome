import '../entities/customer.dart';
import '../entities/customer_ledger_entry.dart';
import '../entities/customer_summary.dart';

abstract class CustomerRepository {
  Future<Customer?> getCustomer(String id);
  Stream<List<Customer>> watchCustomers();
  Future<List<Customer>> getCustomers({String query = ''});
  Future<void> createCustomer({
    required String name,
    required String phone,
    required String address,
    required String defaultNote,
    required String note,
  });
  Future<void> updateCustomer(Customer customer);
  Future<void> deleteCustomer(String id);
  Future<CustomerSummary> getCustomerSummary(String customerId);
  Stream<List<CustomerLedgerEntry>> watchCustomerLedger(String customerId);
  Future<void> recalculateLedger(String customerId);
  Future<void> migrateCustomerIfNeeded(String customerId);
}
