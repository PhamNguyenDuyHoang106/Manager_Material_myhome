import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../domain/entities/dashboard_summary.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardStreamProvider);
    final settingsAsync = ref.watch(settingsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tổng quan')),
      body: summaryAsync.when(
        loading: () => const AppLoading(message: 'Đang tải...'),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (summary) {
          final overdueCustomers = <String, _OverdueCustomerGroup>{};
          for (final inv in summary.overdueInvoices) {
            final date = DateTime.tryParse(inv.invoiceDate);
            final age = date != null ? DateTime.now().difference(date).inDays : 0;
            
            final existing = overdueCustomers[inv.customerId];
            overdueCustomers[inv.customerId] = existing == null
                ? _OverdueCustomerGroup(
                    customerName: inv.customerName,
                    totalOverdueCents: inv.remainingCents.toInt(),
                    maxOverdueDays: age,
                  )
                : _OverdueCustomerGroup(
                    customerName: inv.customerName,
                    totalOverdueCents: (existing.totalOverdueCents + inv.remainingCents).toInt(),
                    maxOverdueDays: age > existing.maxOverdueDays ? age : existing.maxOverdueDays,
                  );
          }
          final overdueCustomerList = overdueCustomers.values.toList();
          overdueCustomerList.sort((a, b) => b.maxOverdueDays.compareTo(a.maxOverdueDays));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardStreamProvider);
              ref.invalidate(settingsStreamProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                settingsAsync.when(
                  data: (settings) {
                    final timeStr = settings.lastBackupTime != null 
                        ? DateFormat('HH:mm dd/MM/yyyy').format(settings.lastBackupTime!.toLocal())
                        : 'Chưa từng sao lưu';
                    final sizeStr = settings.lastBackupSizeBytes > 0 
                        ? '${(settings.lastBackupSizeBytes / 1024).toStringAsFixed(1)} KB'
                        : '0 KB';
                    
                    Color statusColor = Colors.grey;
                    IconData statusIcon = Icons.backup_outlined;
                    String statusText = 'Chưa sao lưu';

                    if (settings.lastBackupStatus == 'success') {
                      statusColor = Colors.green;
                      statusIcon = Icons.cloud_done;
                      statusText = 'Thành công';
                    } else if (settings.lastBackupStatus.startsWith('failed')) {
                      statusColor = Colors.red;
                      statusIcon = Icons.cloud_off;
                      statusText = 'Thất bại';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 36),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Trạng thái sao lưu', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text('Lần cuối: $timeStr ($sizeStr)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                _SummaryGrid(summary: summary),
                const SizedBox(height: 16),
                if (summary.lowStockMaterials.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Vật liệu sắp hết hàng', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...summary.lowStockMaterials.map(
                    (m) => Card(
                      color: Colors.orange.shade50,
                      child: ListTile(
                        leading: Icon(Icons.warning_amber, color: Colors.orange.shade800),
                        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Tồn kho: ${m.currentStock} ${m.unit} (Tối thiểu: ${m.minimumStock} ${m.unit})'),
                      ),
                    ),
                  ),
                ],
                if (overdueCustomerList.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Khách nợ lâu (Nợ quá 30 ngày)', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red.shade900)),
                  const SizedBox(height: 8),
                  ...overdueCustomerList.map(
                    (cust) => Card(
                      color: Colors.red.shade50,
                      child: ListTile(
                        leading: Icon(Icons.error_outline, color: Colors.red.shade800),
                        title: Text(cust.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Thời gian nợ lâu nhất: ${cust.maxOverdueDays} ngày'),
                        trailing: Text(
                          MoneyUtils.format(cust.totalOverdueCents),
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverdueCustomerGroup {
  final String customerName;
  final int totalOverdueCents;
  final int maxOverdueDays;
  _OverdueCustomerGroup({
    required this.customerName,
    required this.totalOverdueCents,
    required this.maxOverdueDays,
  });
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      _Kpi('Doanh thu hôm nay', MoneyUtils.format(summary.revenueTodayCents), Icons.payments, Colors.green),
      _Kpi('Doanh thu tháng', MoneyUtils.format(summary.revenueMonthCents), Icons.calendar_month, Colors.teal),
      _Kpi('Tổng nợ', MoneyUtils.format(summary.totalDebtCents), Icons.account_balance_wallet, Colors.red),
      _Kpi('HĐ chưa TT', '${summary.unpaidInvoiceCount}', Icons.receipt, Colors.orange),
      _Kpi('Số vật liệu', '${summary.materialCount}', Icons.inventory, Colors.blue),
      _Kpi('Giá trị kho', MoneyUtils.format(summary.totalStockValueCents), Icons.warehouse, Colors.brown),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final kpi = items[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(kpi.icon, color: kpi.color),
                const Spacer(),
                Text(kpi.label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(kpi.value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Kpi {
  const _Kpi(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}
