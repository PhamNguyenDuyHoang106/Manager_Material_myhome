import '../entities/dashboard_summary.dart';

abstract class DashboardRepository {
  Future<DashboardSummary> getSummary();
  Stream<DashboardSummary> watchSummary();
}
