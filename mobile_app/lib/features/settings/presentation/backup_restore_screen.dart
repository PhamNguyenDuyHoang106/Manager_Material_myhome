import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../../application/providers/providers.dart';
import '../../../core/widgets/error_snackbar.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  List<Map<String, dynamic>> _backups = [];
  bool _loading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadBackups);
  }

  Future<void> _loadBackups() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    setState(() {
      _loading = true;
      _statusMessage = 'Đang tải danh sách bản sao lưu...';
    });
    try {
      final backupService = ref.read(backupServiceProvider);
      if (backupService != null) {
        final list = await backupService.listBackups(uid);
        setState(() {
          _backups = list;
        });
      }
    } catch (e) {
      showErrorSnackBar(context, e);
    } finally {
      setState(() {
        _loading = false;
        _statusMessage = '';
      });
    }
  }

  Future<void> _createBackup() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    setState(() {
      _loading = true;
      _statusMessage = 'Đang tạo bản sao lưu mới...';
    });
    try {
      final backupService = ref.read(backupServiceProvider);
      if (backupService != null) {
        await backupService.backup(uid);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo bản sao lưu thành công')),
        );
        await _loadBackups();
      }
    } catch (e) {
      showErrorSnackBar(context, e);
    } finally {
      setState(() {
        _loading = false;
        _statusMessage = '';
      });
    }
  }

  Future<void> _shareBackup(Map<String, dynamic> backup) async {
    setState(() {
      _loading = true;
      _statusMessage = 'Đang chuẩn bị chia sẻ tệp sao lưu...';
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
        text: 'Bản sao lưu dữ liệu quản lý vật liệu VLXD - ${backup['name']}',
      );
    } catch (e) {
      showErrorSnackBar(context, e);
    } finally {
      setState(() {
        _loading = false;
        _statusMessage = '';
      });
    }
  }

  Future<void> _performRestore(Map<String, dynamic> backup, {required bool isReplace}) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    setState(() {
      _loading = true;
      _statusMessage = isReplace ? 'Đang thực hiện khôi phục thay thế (Xóa & Ghi đè)...' : 'Đang thực hiện khôi phục gộp (Merge)...';
    });
    try {
      final refBack = backup['ref'] as Reference;
      final bytes = await refBack.getData();
      if (bytes == null) throw Exception('Không thể tải tệp sao lưu từ đám mây');

      final backupService = ref.read(backupServiceProvider);
      if (backupService != null) {
        if (isReplace) {
          await backupService.restoreReplace(uid, bytes);
        } else {
          await backupService.restoreMerge(uid, bytes);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isReplace
                  ? 'Đã khôi phục hoàn thành (Thay thế)'
                  : 'Đã khôi phục hoàn thành (Gộp dữ liệu mới hơn)',
            ),
          ),
        );
      }
    } catch (e) {
      showErrorSnackBar(context, e);
    } finally {
      setState(() {
        _loading = false;
        _statusMessage = '';
      });
    }
  }

  Future<void> _confirmMergeRestore(Map<String, dynamic> backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận Khôi phục Gộp'),
        content: const Text(
          'Hệ thống sẽ chỉ khôi phục các dữ liệu chưa có hoặc có ngày cập nhật mới hơn bản hiện tại trong máy. Dữ liệu cũ hơn sẽ giữ nguyên.\n\nBạn có muốn tiếp tục?',
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
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Cảnh báo ghi đè'),
          ],
        ),
        content: const Text(
          'Khôi phục thay thế (Replace Restore) sẽ XÓA TOÀN BỘ dữ liệu hiện tại của cửa hàng trên thiết bị này và Cloud để thay thế bằng dữ liệu bản sao lưu.\n\nBạn có muốn tiếp tục?',
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
        title: const Text('Xác nhận chắc chắn'),
        content: const Text(
          'HÀNH ĐỘNG NÀY KHÔNG THỂ HOÀN TÁC.\nTất cả doanh thu, tồn kho, công nợ hiện tại sẽ bị xóa sạch.\n\nBạn có thực sự chắc chắn không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tôi chắc chắn'),
          ),
        ],
      ),
    );
    if (step2 != true) return;

    // Step 3: Confirmation code dialog
    final textController = TextEditingController();
    final step3 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập mã xác nhận'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Để xác nhận, vui lòng nhập chính xác cụm từ bên dưới (viết hoa, có dấu gạch dưới):',
            ),
            const SizedBox(height: 8),
            const SelectableText(
              'XAC_NHAN_RESTORE',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1, color: Colors.red),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Nhập XAC_NHAN_RESTORE',
                border: OutlineInputBorder(),
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
                  const SnackBar(content: Text('Mã xác minh không chính xác. Đã hủy khôi phục.')),
                );
                Navigator.pop(context, false);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
    return DateFormat('HH:mm:ss dd/MM/yyyy').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sao lưu & Khôi phục'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadBackups,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload, size: 48, color: Colors.blue),
                    const SizedBox(height: 8),
                    const Text(
                      'Sao lưu đám mây nén ZIP và bảo mật bằng mã SHA256.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _createBackup,
                      icon: const Icon(Icons.backup),
                      label: const Text('Tạo bản sao lưu đám mây ngay'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _backups.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có bản sao lưu nào.\nBấm nút ở trên để tạo bản sao lưu đầu tiên.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _backups.length,
                        itemBuilder: (context, index) {
                          final item = _backups[index];
                          final sizeStr = _formatSize(item['sizeBytes'] as int);
                          final timeStr = _formatDateTime(item['timeCreated'] as DateTime?);
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.archive_outlined, color: Colors.amber),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item['name'] as String,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Dung lượng: $sizeStr',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      Text(
                                        timeStr,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        onPressed: _loading ? null : () => _shareBackup(item),
                                        icon: const Icon(Icons.share, color: Colors.blue),
                                        tooltip: 'Chia sẻ / Xuất tệp ZIP',
                                      ),
                                      const Spacer(),
                                      TextButton.icon(
                                        onPressed: _loading ? null : () => _confirmMergeRestore(item),
                                        icon: const Icon(Icons.merge_type, size: 18),
                                        label: const Text('Khôi phục Gộp'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: _loading ? null : () => _confirmReplaceRestore(item),
                                        icon: const Icon(Icons.restore_page, size: 18),
                                        label: const Text('Khôi phục Thay thế'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.withOpacity(0.9),
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.55),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
