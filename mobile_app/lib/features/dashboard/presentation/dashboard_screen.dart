import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../application/providers/providers.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/dashboard_summary.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getVietnameseDayOfWeek(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Thứ Hai';
      case DateTime.tuesday:
        return 'Thứ Ba';
      case DateTime.wednesday:
        return 'Thứ Tư';
      case DateTime.thursday:
        return 'Thứ Năm';
      case DateTime.friday:
        return 'Thứ Sáu';
      case DateTime.saturday:
        return 'Thứ Bảy';
      case DateTime.sunday:
        return 'Chủ Nhật';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardStreamProvider);
    final settingsAsync = ref.watch(settingsStreamProvider);
    final now = DateTime.now();
    final todayText = '${_getVietnameseDayOfWeek(now.weekday)}, ${DateFormat('dd/MM/yyyy').format(now)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1B5E20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.storefront, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  settingsAsync.when(
                    data: (settings) => Text(
                      settings.storeName.isNotEmpty ? settings.storeName : 'Quản Lý Vật Liệu',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    loading: () => const Text('Quản Lý Vật Liệu', style: TextStyle(fontSize: 16, color: Colors.white)),
                    error: (_, __) => const Text('Quản Lý Vật Liệu', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                  Text(
                    todayText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới dữ liệu',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.invalidate(dashboardStreamProvider);
              ref.invalidate(settingsStreamProvider);
            },
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const AppLoading(message: 'Đang tải tổng quan...'),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Không thể tải dữ liệu: $e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    ref.invalidate(dashboardStreamProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (summary) {
          final settings = settingsAsync.valueOrNull ?? const AppSettings();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardStreamProvider);
              ref.invalidate(settingsStreamProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              children: [
                // 1. Hero Revenue Banner (Doanh thu hôm nay)
                _TodayRevenueHeroCard(summary: summary),
                const SizedBox(height: 14),

                // 2. Financial Overview Grid (Doanh thu tháng + Tổng dư nợ)
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Doanh thu tháng',
                        amount: MoneyUtils.format(summary.revenueMonthCents),
                        subtitle: 'Lũy kế tháng ${now.month}',
                        icon: Icons.calendar_month,
                        iconColor: const Color(0xFF00897B),
                        backgroundColor: Colors.white,
                        accentColor: const Color(0xFFE0F2F1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Tổng nợ khách',
                        amount: MoneyUtils.format(summary.totalDebtCents),
                        subtitle: '${summary.unpaidInvoiceCount} hóa đơn chưa thu',
                        icon: Icons.account_balance_wallet,
                        iconColor: const Color(0xFFD32F2F),
                        backgroundColor: Colors.white,
                        accentColor: const Color(0xFFFFEBEE),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Quick Action Buttons Bar
                const _SectionTitle(title: 'Thao tác nhanh', icon: Icons.bolt),
                const SizedBox(height: 10),
                _QuickActionsBar(),
                const SizedBox(height: 20),

                // 4. Inventory Overview & Low Stock Alert
                const _SectionTitle(title: 'Tình trạng kho hàng', icon: Icons.inventory_2_outlined),
                const SizedBox(height: 10),
                _InventorySection(summary: summary),
                const SizedBox(height: 20),

                // 5. Data & Cloud Backup Status
                const _SectionTitle(title: 'An toàn dữ liệu', icon: Icons.cloud_done_outlined),
                const SizedBox(height: 10),
                _BackupStatusCard(settings: settings),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1B5E20)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }
}

/// Thẻ Doanh thu hôm nay nổi bật dạng Hero Gradient
class _TodayRevenueHeroCard extends StatelessWidget {
  const _TodayRevenueHeroCard({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.payments, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'DOANH THU HÔM NAY',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Thu tiền mặt & CK',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            MoneyUtils.format(summary.revenueTodayCents),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tổng tiền thu từ khách hàng trong ngày',
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Thẻ chỉ số chuẩn (Doanh thu tháng / Tổng nợ)
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.accentColor,
  });

  final String title;
  final String amount;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF607D8B),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: iconColor == const Color(0xFFD32F2F) ? const Color(0xFFC62828) : const Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Hàng phím tắt thao tác nhanh
class _QuickActionsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            title: 'Tạo đơn mới',
            icon: Icons.add_circle,
            iconColor: const Color(0xFF1B5E20),
            backgroundColor: const Color(0xFFE8F5E9),
            onTap: () {
              context.push('/invoices/new');
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionTile(
            title: 'Khách hàng',
            icon: Icons.people,
            iconColor: const Color(0xFF1565C0),
            backgroundColor: const Color(0xFFE3F2FD),
            onTap: () {
              context.go('/customers');
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionTile(
            title: 'Nhập kho',
            icon: Icons.inventory_2,
            iconColor: const Color(0xFFE65100),
            backgroundColor: const Color(0xFFFFF3E0),
            onTap: () {
              context.go('/inventory');
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionTile(
            title: 'Hóa đơn',
            icon: Icons.receipt_long,
            iconColor: const Color(0xFF6A1B9A),
            backgroundColor: const Color(0xFFF3E5F5),
            onTap: () {
              context.go('/invoices');
            },
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Khối tổng quan kho hàng & Cảnh báo tồn kho
class _InventorySection extends StatelessWidget {
  const _InventorySection({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.category, color: Color(0xFF3F51B5), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mặt hàng',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          '${summary.materialCount} loại',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: Colors.grey.shade200),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.monetization_on, color: Color(0xFFFFA000), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ước tính vốn tồn',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              MoneyUtils.format(summary.totalStockValueCents),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Cảnh báo vật liệu sắp hết kho nếu có
          if (summary.lowStockMaterials.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Cần nhập thêm hàng (${summary.lowStockMaterials.length} mặt hàng dưới mức tối thiểu)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: summary.lowStockMaterials.take(6).map((m) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFFCC80)),
                        ),
                        child: Text(
                          '${m.name}: ${MoneyUtils.formatQty(m.currentStock)} ${m.unit}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFBF360C),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Khối hiển thị trạng thái sao lưu dữ liệu
class _BackupStatusCard extends StatelessWidget {
  const _BackupStatusCard({required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final hasBackup = settings.lastBackupTime != null;
    final timeStr = hasBackup
        ? DateFormat('HH:mm - dd/MM/yyyy').format(settings.lastBackupTime!.toLocal())
        : 'Chưa từng sao lưu';
    final sizeStr = settings.lastBackupSizeBytes > 0
        ? '${(settings.lastBackupSizeBytes / 1024).toStringAsFixed(1)} KB'
        : '0 KB';

    final isSuccess = settings.lastBackupStatus == 'success';
    final isFailed = settings.lastBackupStatus.startsWith('failed');

    Color statusColor = const Color(0xFF757575);
    IconData statusIcon = Icons.cloud_queue;
    String statusTitle = 'Dữ liệu thiết bị';
    String statusDescription = 'Nên tạo bản sao lưu lên Cloud định kỳ để bảo vệ dữ liệu';

    if (isSuccess) {
      statusColor = const Color(0xFF2E7D32);
      statusIcon = Icons.cloud_done;
      statusTitle = 'Dữ liệu an toàn trên Cloud';
      statusDescription = 'Lần sao lưu gần nhất: $timeStr ($sizeStr)';
    } else if (isFailed) {
      statusColor = const Color(0xFFC62828);
      statusIcon = Icons.cloud_off;
      statusTitle = 'Sao lưu gần nhất thất bại';
      statusDescription = 'Vui lòng kiểm tra lại kết nối mạng';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusDescription,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => context.push('/settings/backup'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(60, 32),
              side: BorderSide(color: statusColor.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Sao lưu',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
