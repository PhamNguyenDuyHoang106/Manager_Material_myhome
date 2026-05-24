import '../entities/customer.dart';
import '../entities/customer_summary.dart';

abstract class CustomerRepository {
  Stream<List<Customer>> watchCustomers();
  Future<List<Customer>> getCustomers({String query = ''});
  Future<void> createCustomer({required String name, required String phone, required String address});
  Future<void> updateCustomer(Customer customer);
  Future<void> deleteCustomer(String id);
  Future<CustomerSummary> getCustomerSummary(String customerId);
}
