import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/firestore_paths.dart';
import '../datasources/hive_cache.dart';
import '../mappers/firestore_mapper.dart';

class FirestoreSettingsRepository implements SettingsRepository {
  FirestoreSettingsRepository(this._firestore, this._storage, this._uid);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final String _uid;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.doc(FirestorePaths(_uid).settings);

  @override
  Stream<AppSettings> watchSettings() {
    return _doc.snapshots().map((snap) {
      final settings = snap.exists
          ? AppSettings.fromJson(fromFirestore(snap))
          : const AppSettings();
      HiveCache.instance.saveList(
        HiveCache.instance.settingsBox,
        [settings.toJson()],
      );
      return settings;
    });
  }

  @override
  Future<AppSettings> getSettings() async {
    try {
      final snap = await _doc.get();
      if (!snap.exists) return const AppSettings();
      return AppSettings.fromJson(fromFirestore(snap));
    } catch (_) {
      final cached = HiveCache.instance.loadList(HiveCache.instance.settingsBox);
      if (cached != null && cached.isNotEmpty) {
        return AppSettings.fromJson(cached.first);
      }
      return const AppSettings();
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _doc.set(settings.toJson(), SetOptions(merge: true));
  }

  @override
  Future<String?> uploadLogo(String localPath) async {
    final file = File(localPath);
    if (!await file.exists()) return null;
    final ref = _storage.ref().child('users/$_uid/logo/store_logo.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
