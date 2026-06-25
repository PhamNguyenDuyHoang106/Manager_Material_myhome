import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/providers.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../domain/entities/app_settings.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _storeName = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _truckVolume = TextEditingController();
  bool _saving = false;
  bool _syncingDebts = false;

  @override
  void dispose() {
    _storeName.dispose();
    _address.dispose();
    _phone.dispose();
    _truckVolume.dispose();
    super.dispose();
  }

  void _fill(AppSettings s) {
    _storeName.text = s.storeName;
    _address.text = s.storeAddress;
    _phone.text = s.storePhone;
    _truckVolume.text = s.truckVolume.toString();
  }

  Future<void> _syncAllDebts() async {
    setState(() => _syncingDebts = true);
    try {
      final customerRepo = ref.read(customerRepositoryProvider);
      if (customerRepo == null) return;
      final customers = await customerRepo.getCustomers();
      for (final cust in customers) {
        await customerRepo.recalculateLedger(cust.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đồng bộ lại công nợ của tất cả khách hàng')),
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _syncingDebts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (settings) {
          _fill(settings as AppSettings);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(user?.email ?? ''),
                  subtitle: const Text('Tài khoản đăng nhập'),
                ),
              ),
              const SizedBox(height: 16),
              Text('Thông tin cửa hàng', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(controller: _storeName, decoration: const InputDecoration(labelText: 'Tên cửa hàng')),
              TextField(controller: _address, decoration: const InputDecoration(labelText: 'Địa chỉ')),
              TextField(controller: _phone, decoration: const InputDecoration(labelText: 'SĐT')),
              TextField(
                controller: _truckVolume,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Dung tích xe mặc định (Khối/Xe)'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : () => _save(settings),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Lưu cài đặt'),
              ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Sao lưu & Khôi phục'),
                  subtitle: const Text('Sao lưu đám mây & Chia sẻ tệp ZIP sao lưu'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/backup'),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _syncingDebts ? null : _syncAllDebts,
                icon: _syncingDebts
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sync),
                label: const Text('Đồng bộ lại toàn bộ công nợ'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
              ),
              const SizedBox(height: 16),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.cloud_done),
                  title: Text('Đồng bộ Firebase'),
                  subtitle: Text('Dữ liệu tự đồng bộ khi có mạng. Hoạt động offline với Firestore cache + Hive.'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save(AppSettings current) async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(settingsRepositoryProvider);
      if (repo == null) return;
      await repo.saveSettings(current.copyWith(
        storeName: _storeName.text.trim(),
        storeAddress: _address.text.trim(),
        storePhone: _phone.text.trim(),
        truckVolume: double.tryParse(_truckVolume.text.trim()) ?? current.truckVolume,
      ));
      showSuccessSnackBar(context, 'Đã lưu');
    } catch (e) {
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
