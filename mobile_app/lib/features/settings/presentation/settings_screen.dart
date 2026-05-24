import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/providers.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../domain/entities/app_settings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _storeName = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _storeName.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _fill(AppSettings s) {
    _storeName.text = s.storeName;
    _address.text = s.storeAddress;
    _phone.text = s.storePhone;
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
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : () => _save(settings),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Lưu cài đặt'),
              ),
              const SizedBox(height: 24),
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
      ));
      showSuccessSnackBar(context, 'Đã lưu');
    } catch (e) {
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
