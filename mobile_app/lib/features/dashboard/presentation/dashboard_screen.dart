import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../domain/entities/dashboard_summary.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tổng quan')),
      body: summaryAsync.when(
        loading: () => const AppLoading(message: 'Đang tải...'),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (summary) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStreamProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryGrid(summary: summary),
              const SizedBox(height: 16),
              if (summary.lowStockCount > 0)
                Card(
                  color: Colors.orange.shade50,
                  child: ListTile(
                    leading: Icon(Icons.warning_amber, color: Colors.orange.shade800),
                    title: const Text('Cảnh báo tồn kho thấp'),
                    subtitle: Text('${summary.lowStockCount} vật liệu dưới ${AppConstants.lowStockThreshold}'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
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
