import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../../application/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_snackbar.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _backups = [];
  bool _loading = false;
  String _statusMessage = '';
  double _progress = 0.0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    Future.microtask(_loadBackups);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadBackups() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    setState(() {
      _loading = true;
      _statusMessage = 'Đang tải danh sách sao lưu...';
      _progress = 0.0;
    });
    try {
      final backupService = ref.read(backupServiceProvider);
      if (backupService != null) {
        final list = await backupService.listBackups(uid);
        setState(() => _backups = list);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _statusMessage = '';
        });
      }
    }
  }

  Future<void> _createBackup() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    setState(() {
      _loading = true;
      _statusMessage = 'Đang nén và mã hóa dữ liệu...';
      _progress = 0.3;
    });
    try {
      final backupService = ref.read(backupServiceProvider);
      if (backupService != null) {
        setState(() {
          _statusMessage = 'Đang tải lên đám mây...';
          _progress = 0.7;
        });
        await backupService.backup(uid);
        setState(() => _progress = 1.0);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Tạo bản sao lưu thành công!'),
                ],
              ),
              backgroundColor: AppTheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        await _loadBackups();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _statusMessage = '';
          _progress = 0.0;
        });
      }
    }
  }

  Future<void> _shareBackup(Map<String, dynamic> backup) async {
    setState(() {
      _loading = true;
      _statusMessage = 'Đang chuẩn bị tệp chia sẻ...';
    });
    try {
      final ref = backup['ref'] as Reference;
      final bytes = await ref.getData();
      if (bytes == null) throw Exception('Không thể tải dữ liệu bản sao lưu');

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${backup['name']}');
      await tempFile.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Bản sao lưu VLXD - ${backup['name']}',
      );
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _statusMessage = '';
        });
      }
    }
  }

  Future<void> _performRestore(Map<String, dynamic> backup, {required bool isReplace}) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    setState(() {
      _loading = true;
      _statusMessage = isReplace
          ? 'Đang xóa dữ liệu cũ và ghi đè...'
          : 'Đang gộp dữ liệu mới hơn...';
      _progress = 0.4;
    });
    try {
      final refBack = backup['ref'] as Reference;
      final bytes = await refBack.getData();
      if (bytes == null) throw Exception('Không thể tải tệp sao lưu từ đám mây');

      setState(() {
        _statusMessage = isReplace
            ? 'Đang khôi phục dữ liệu...'
            : 'Đang đồng bộ dữ liệu...';
        _progress = 0.7;
      });

      final backupService = ref.read(backupServiceProvider);
      if (backupService != null) {
        if (isReplace) {
          await backupService.restoreReplace(uid, bytes);
        } else {
          await backupService.restoreMerge(uid, bytes);
        }
        setState(() => _progress = 1.0);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    isReplace ? 'Khôi phục thành công!' : 'Gộp dữ liệu thành công!',
                  ),
                ],
              ),
              backgroundColor: AppTheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _statusMessage = '';
          _progress = 0.0;
        });
      }
    }
  }

  void _showBackupActions(Map<String, dynamic> backup) {
    final sizeStr = _formatSize(backup['sizeBytes'] as int);
    final timeStr = _formatDateTime(backup['timeCreated'] as DateTime?);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Backup info header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.archive_rounded, color: AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dung lượng: $sizeStr',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Action buttons
            _buildActionTile(
              icon: Icons.share_rounded,
              color: const Color(0xFF1976D2),
              title: 'Chia sẻ tệp ZIP',
              subtitle: 'Xuất và gửi qua Zalo, Email...',
              onTap: () {
                Navigator.pop(ctx);
                _shareBackup(backup);
              },
            ),
            const SizedBox(height: 8),
            _buildActionTile(
              icon: Icons.merge_type_rounded,
              color: AppTheme.accent,
              title: 'Khôi phục gộp',
              subtitle: 'Chỉ gộp dữ liệu mới hơn bản hiện tại',
              onTap: () {
                Navigator.pop(ctx);
                _confirmMergeRestore(backup);
              },
            ),
            const SizedBox(height: 8),
            _buildActionTile(
              icon: Icons.restore_rounded,
              color: AppTheme.error,
              title: 'Khôi phục thay thế',
              subtitle: 'Xóa toàn bộ và ghi đè bằng bản sao lưu',
              onTap: () {
                Navigator.pop(ctx);
                _confirmReplaceRestore(backup);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmMergeRestore(Map<String, dynamic> backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.merge_type_rounded, color: AppTheme.accent),
            SizedBox(width: 10),
            Text('Khôi phục gộp'),
          ],
        ),
        content: const Text(
          'Hệ thống sẽ chỉ khôi phục các dữ liệu chưa có hoặc có ngày cập nhật mới hơn bản hiện tại.\n\nDữ liệu cũ hơn sẽ giữ nguyên. Bạn có muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _performRestore(backup, isReplace: false);
    }
  }

  Future<void> _confirmReplaceRestore(Map<String, dynamic> backup) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    // Step 1: Warning dialog
    final step1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('Cảnh báo ghi đè'),
          ],
        ),
        content: const Text(
          'Khôi phục thay thế sẽ XÓA TOÀN BỘ dữ liệu hiện tại và thay thế bằng bản sao lưu.\n\nBạn có muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
    if (step1 != true) return;

    // Step 2: Double check dialog
    final step2 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận chắc chắn'),
        content: const Text(
          'HÀNH ĐỘNG NÀY KHÔNG THỂ HOÀN TÁC.\nTất cả doanh thu, tồn kho, công nợ hiện tại sẽ bị xóa sạch.\n\nBạn có thực sự chắc chắn?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Tôi chắc chắn'),
          ),
        ],
      ),
    );
    if (step2 != true) return;

    // Step 3: Confirmation code
    final textController = TextEditingController();
    final step3 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nhập mã xác nhận'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nhập chính xác cụm từ bên dưới để xác nhận:'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.error.withOpacity(0.3)),
              ),
              child: const SelectableText(
                'XAC_NHAN_RESTORE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                  color: AppTheme.error,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Nhập mã xác nhận',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (textController.text.trim() == 'XAC_NHAN_RESTORE') {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mã xác nhận không chính xác.')),
                );
                Navigator.pop(context, false);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Khôi phục ngay'),
          ),
        ],
      ),
    );
    if (step3 != true) return;

    _performRestore(backup, isReplace: true);
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Không rõ thời gian';
    return DateFormat('HH:mm  dd/MM/yyyy').format(dt.toLocal());
  }

  String _relativeTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Sao lưu & Khôi phục'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadBackups,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Hero Header ──
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppTheme.primary, Color(0xFF2E7D32)],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                      child: Column(
                        children: [
                          // Cloud icon with glow
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cloud_upload_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Sao lưu đám mây an toàn',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Last backup status
                          settingsAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (settings) {
                              final lastTime = settings.lastBackupTime;
                              final lastSize = settings.lastBackupSizeBytes;
                              final lastStatus = settings.lastBackupStatus;
                              if (lastTime == null) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.info_outline_rounded, color: Colors.white70, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Chưa có bản sao lưu nào',
                                        style: TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              final isSuccess = lastStatus == 'success';
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                                      color: isSuccess ? Colors.greenAccent.shade100 : Colors.orangeAccent.shade100,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Lần cuối: ${_relativeTime(lastTime)}${lastSize > 0 ? '  •  ${_formatSize(lastSize)}' : ''}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          // Create backup button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _loading ? null : _createBackup,
                              icon: const Icon(Icons.backup_rounded, size: 22),
                              label: const Text(
                                'Tạo bản sao lưu ngay',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primary,
                                disabledBackgroundColor: Colors.white.withOpacity(0.6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Section Title ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    children: [
                      const Text(
                        'Danh sách bản sao lưu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_backups.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Backup List ──
              if (_backups.isEmpty && !_loading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có bản sao lưu nào',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bấm nút ở trên để tạo bản sao lưu đầu tiên',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _backups[index];
                        final sizeStr = _formatSize(item['sizeBytes'] as int);
                        final time = item['timeCreated'] as DateTime?;
                        final timeStr = _formatDateTime(time);
                        final relStr = _relativeTime(time);
                        final isLatest = index == 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            elevation: isLatest ? 2 : 0.5,
                            shadowColor: isLatest
                                ? AppTheme.primary.withOpacity(0.2)
                                : Colors.black12,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _showBackupActions(item),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: isLatest
                                    ? BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: AppTheme.primary.withOpacity(0.25),
                                          width: 1.5,
                                        ),
                                      )
                                    : null,
                                child: Row(
                                  children: [
                                    // Icon
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isLatest
                                            ? AppTheme.primary.withOpacity(0.1)
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isLatest ? Icons.cloud_done_rounded : Icons.archive_outlined,
                                        color: isLatest ? AppTheme.primary : Colors.grey.shade500,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  timeStr,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                    color: isLatest
                                                        ? const Color(0xFF1A1A1A)
                                                        : Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                              if (isLatest)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primary.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text(
                                                    'Mới nhất',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppTheme.primary,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$relStr  •  $sizeStr',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.more_vert_rounded, color: Colors.grey.shade400, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: _backups.length,
                    ),
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),

          // ── Loading Overlay ──
          if (_loading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(40),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated icon
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, child) => Transform.scale(
                          scale: 1.0 + _pulseController.value * 0.1,
                          child: child,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_sync_rounded,
                            size: 36,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _progress > 0 ? _progress : null,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
