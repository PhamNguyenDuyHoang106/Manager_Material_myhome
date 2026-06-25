import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../../core/errors/app_exception.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';
import '../../data/mappers/firestore_mapper.dart' as mapper;
import '../../data/datasources/hive_cache.dart';

class BackupService {
  BackupService(this._firestore, this._storage, this._settingsRepo);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final SettingsRepository _settingsRepo;

  static const String _lastBackupCheckDateKey = 'last_backup_check_date';

  String _userBackupsPath(String uid) => 'users/$uid/backups';

  Future<void> checkAndPerformDailyBackup(String uid) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastCheck = HiveCache.instance.loadString(HiveCache.instance.settingsBox, _lastBackupCheckDateKey);
    
    if (lastCheck == today) {
      return;
    }

    try {
      await backup(uid);
      await HiveCache.instance.saveString(HiveCache.instance.settingsBox, _lastBackupCheckDateKey, today);
    } catch (_) {
      // Background auto backup fail should not disrupt the application bootstrap
    }
  }

  Future<List<Map<String, dynamic>>> listBackups(String uid) async {
    final ref = _storage.ref().child(_userBackupsPath(uid));
    final listResult = await ref.listAll();
    final list = <Map<String, dynamic>>[];
    for (final item in listResult.items) {
      try {
        final meta = await item.getMetadata();
        list.add({
          'name': item.name,
          'path': item.fullPath,
          'sizeBytes': meta.size ?? 0,
          'timeCreated': meta.timeCreated,
          'ref': item,
        });
      } catch (_) {
        list.add({
          'name': item.name,
          'path': item.fullPath,
          'sizeBytes': 0,
          'timeCreated': null,
          'ref': item,
        });
      }
    }
    list.sort((a, b) => b['name'].toString().compareTo(a['name'].toString()));
    return list;
  }

  Future<void> backup(String uid) async {
    final now = DateTime.now();
    final settings = await _settingsRepo.getSettings();

    try {
      final catsSnap = await _firestore.collection('users/$uid/material_categories').get();
      final categories = catsSnap.docs.map((d) => mapper.fromFirestore(d)).toList();

      final matsSnap = await _firestore.collection('users/$uid/materials').get();
      final materials = matsSnap.docs.map((d) => mapper.fromFirestore(d)).toList();

      final custsSnap = await _firestore.collection('users/$uid/customers').get();
      final customers = custsSnap.docs.map((d) => mapper.fromFirestore(d)).toList();

      final ledgerEntries = <Map<String, dynamic>>[];
      for (final cust in customers) {
        final custId = cust['id'] as String;
        final ledgerSnap = await _firestore.collection('users/$uid/customers/$custId/ledger').get();
        for (final doc in ledgerSnap.docs) {
          ledgerEntries.add(mapper.fromFirestore(doc));
        }
      }

      final invoicesSnap = await _firestore.collection('users/$uid/invoices').get();
      final invoices = <Map<String, dynamic>>[];
      for (final doc in invoicesSnap.docs) {
        final invData = mapper.fromFirestore(doc);
        final itemsSnap = await _firestore.collection('users/$uid/invoices/${doc.id}/invoice_items').get();
        final items = itemsSnap.docs.map((i) => mapper.fromFirestore(i)).toList();
        invData['items'] = items;
        invoices.add(invData);
      }

      final paymentsSnap = await _firestore.collection('users/$uid/payments').get();
      final payments = paymentsSnap.docs.map((d) => mapper.fromFirestore(d)).toList();

      final settingsSnap = await _firestore.doc('users/$uid/settings/store').get();
      final settingsData = settingsSnap.exists ? mapper.fromFirestore(settingsSnap) : null;

      final backupMap = {
        'version': 1,
        'uid': uid,
        'createdAt': now.toIso8601String(),
        'data': {
          'material_categories': categories,
          'materials': materials,
          'customers': customers,
          'ledger_entries': ledgerEntries,
          'invoices': invoices,
          'payments': payments,
          'settings': settingsData,
        }
      };

      final jsonStr = jsonEncode(backupMap);
      final jsonBytes = utf8.encode(jsonStr);
      final checksum = sha256.convert(jsonBytes).toString();

      final archive = Archive();
      archive.addFile(ArchiveFile('backup.json', jsonBytes.length, jsonBytes));
      archive.addFile(ArchiveFile('checksum.txt', checksum.length, utf8.encode(checksum)));
      
      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) throw Exception('Lỗi nén tệp ZIP');

      final timestampStr = '${now.year.toString().padLeft(4, '0')}'
          '_${now.month.toString().padLeft(2, '0')}'
          '_${now.day.toString().padLeft(2, '0')}'
          '_${now.hour.toString().padLeft(2, '0')}'
          '_${now.minute.toString().padLeft(2, '0')}'
          '_${now.second.toString().padLeft(2, '0')}';
      final fileName = 'backup_$timestampStr.zip';
      final fileRef = _storage.ref().child('${_userBackupsPath(uid)}/$fileName');

      await fileRef.putData(Uint8List.fromList(zipBytes));

      final backupList = await listBackups(uid);
      if (backupList.length > 30) {
        for (int i = 30; i < backupList.length; i++) {
          final refToDelete = backupList[i]['ref'] as Reference;
          await refToDelete.delete();
        }
      }

      final updatedSettings = settings.copyWith(
        lastBackupTime: now,
        lastBackupSizeBytes: zipBytes.length,
        lastBackupStatus: 'success',
      );
      await _settingsRepo.saveSettings(updatedSettings);
    } catch (e) {
      final updatedSettings = settings.copyWith(
        lastBackupStatus: 'failed: $e',
      );
      await _settingsRepo.saveSettings(updatedSettings);
      rethrow;
    }
  }

  Map<String, dynamic> verifyBackupZip(List<int> zipBytes) {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final jsonFile = archive.findFile('backup.json');
    final checksumFile = archive.findFile('checksum.txt');

    if (jsonFile == null || checksumFile == null) {
      throw const ValidationException('Mã checksum hoặc tệp dữ liệu không hợp lệ hoặc thiếu trong bản sao lưu.');
    }

    final jsonStr = utf8.decode(jsonFile.content as List<int>);
    final checksumVal = utf8.decode(checksumFile.content as List<int>).trim();

    final computedChecksum = sha256.convert(utf8.encode(jsonStr)).toString();
    if (computedChecksum != checksumVal) {
      throw const ValidationException('Mã checksum không khớp. Dữ liệu bản sao lưu có thể đã bị thay đổi hoặc bị hỏng.');
    }

    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  Future<void> _runInBatches(List<void Function(WriteBatch batch)> operations) async {
    var batch = _firestore.batch();
    int count = 0;
    for (final op in operations) {
      op(batch);
      count++;
      if (count >= 400) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }
    if (count > 0) {
      await batch.commit();
    }
  }

  Map<String, dynamic> _prepareForFirestore(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    copy.remove('id');
    copy.remove('items');
    copy.remove('ledger');
    _convertStringsToTimestamps(copy);
    return copy;
  }

  void _convertStringsToTimestamps(Map<String, dynamic> data) {
    for (final entry in data.entries.toList()) {
      if (entry.value is String) {
        final val = entry.value as String;
        if (val.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(val)) {
          final dt = DateTime.tryParse(val);
          if (dt != null) {
            data[entry.key] = Timestamp.fromDate(dt);
          }
        }
      } else if (entry.value is Map) {
        final mapCopy = Map<String, dynamic>.from(entry.value as Map);
        _convertStringsToTimestamps(mapCopy);
        data[entry.key] = mapCopy;
      } else if (entry.value is List) {
        final listCopy = [];
        for (final item in entry.value as List) {
          if (item is Map) {
            final itemMap = Map<String, dynamic>.from(item as Map);
            _convertStringsToTimestamps(itemMap);
            listCopy.add(itemMap);
          } else {
            listCopy.add(item);
          }
        }
        data[entry.key] = listCopy;
      }
    }
  }

  Future<void> restoreReplace(String uid, List<int> zipBytes) async {
    final backupMap = verifyBackupZip(zipBytes);
    final data = backupMap['data'] as Map<String, dynamic>;

    final deleteOps = <void Function(WriteBatch batch)>[];

    final cats = await _firestore.collection('users/$uid/material_categories').get();
    for (final d in cats.docs) {
      deleteOps.add((batch) => batch.delete(d.reference));
    }

    final mats = await _firestore.collection('users/$uid/materials').get();
    for (final d in mats.docs) {
      deleteOps.add((batch) => batch.delete(d.reference));
    }

    final custs = await _firestore.collection('users/$uid/customers').get();
    for (final d in custs.docs) {
      deleteOps.add((batch) => batch.delete(d.reference));
      final ledger = await _firestore.collection('users/$uid/customers/${d.id}/ledger').get();
      for (final ld in ledger.docs) {
        deleteOps.add((batch) => batch.delete(ld.reference));
      }
    }

    final invs = await _firestore.collection('users/$uid/invoices').get();
    for (final d in invs.docs) {
      deleteOps.add((batch) => batch.delete(d.reference));
      final items = await _firestore.collection('users/$uid/invoices/${d.id}/invoice_items').get();
      for (final idoc in items.docs) {
        deleteOps.add((batch) => batch.delete(idoc.reference));
      }
    }

    final pays = await _firestore.collection('users/$uid/payments').get();
    for (final d in pays.docs) {
      deleteOps.add((batch) => batch.delete(d.reference));
    }

    final settingsRef = _firestore.doc('users/$uid/settings/store');
    deleteOps.add((batch) => batch.delete(settingsRef));

    await _runInBatches(deleteOps);

    final writeOps = <void Function(WriteBatch batch)>[];

    final categoriesList = data['material_categories'] as List? ?? [];
    for (final item in categoriesList) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      writeOps.add((batch) => batch.set(
        _firestore.collection('users/$uid/material_categories').doc(id),
        _prepareForFirestore(map),
      ));
    }

    final materialsList = data['materials'] as List? ?? [];
    for (final item in materialsList) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      writeOps.add((batch) => batch.set(
        _firestore.collection('users/$uid/materials').doc(id),
        _prepareForFirestore(map),
      ));
    }

    final customersList = data['customers'] as List? ?? [];
    for (final item in customersList) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      writeOps.add((batch) => batch.set(
        _firestore.collection('users/$uid/customers').doc(id),
        _prepareForFirestore(map),
      ));
    }

    final ledgerList = data['ledger_entries'] as List? ?? [];
    for (final item in ledgerList) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      final customerId = map['customerId'] as String;
      writeOps.add((batch) => batch.set(
        _firestore.collection('users/$uid/customers/$customerId/ledger').doc(id),
        _prepareForFirestore(map),
      ));
    }

    final invoicesList = data['invoices'] as List? ?? [];
    for (final item in invoicesList) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      final items = map['items'] as List? ?? [];
      writeOps.add((batch) => batch.set(
        _firestore.collection('users/$uid/invoices').doc(id),
        _prepareForFirestore(map),
      ));

      for (final line in items) {
        final lineMap = Map<String, dynamic>.from(line as Map);
        final lineId = lineMap['id'] as String;
        writeOps.add((batch) => batch.set(
          _firestore.collection('users/$uid/invoices/$id/invoice_items').doc(lineId),
          _prepareForFirestore(lineMap),
        ));
      }
    }

    final paymentsList = data['payments'] as List? ?? [];
    for (final item in paymentsList) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      writeOps.add((batch) => batch.set(
        _firestore.collection('users/$uid/payments').doc(id),
        _prepareForFirestore(map),
      ));
    }

    final settingsMap = data['settings'] as Map?;
    if (settingsMap != null) {
      final map = Map<String, dynamic>.from(settingsMap);
      writeOps.add((batch) => batch.set(
        _firestore.doc('users/$uid/settings/store'),
        _prepareForFirestore(map),
        SetOptions(merge: true),
      ));
    }

    await _runInBatches(writeOps);
  }

  bool shouldOverwrite(String? backupTimeStr, dynamic existingTimeObj) {
    if (existingTimeObj == null) return true;
    final backupTime = backupTimeStr != null ? DateTime.tryParse(backupTimeStr) : null;
    if (backupTime == null) return false;

    DateTime? existingTime;
    if (existingTimeObj is Timestamp) {
      existingTime = existingTimeObj.toDate();
    } else if (existingTimeObj is String) {
      existingTime = DateTime.tryParse(existingTimeObj);
    }

    if (existingTime == null) return true;
    return backupTime.isAfter(existingTime);
  }

  Future<void> restoreMerge(String uid, List<int> zipBytes) async {
    final backupMap = verifyBackupZip(zipBytes);
    final data = backupMap['data'] as Map<String, dynamic>;

    final existingCatsSnap = await _firestore.collection('users/$uid/material_categories').get();
    final existingCats = {for (final d in existingCatsSnap.docs) d.id: d.data()['updatedAt'] ?? d.data()['createdAt']};

    final existingMatsSnap = await _firestore.collection('users/$uid/materials').get();
    final existingMats = {for (final d in existingMatsSnap.docs) d.id: d.data()['updatedAt'] ?? d.data()['createdAt']};

    final existingCustsSnap = await _firestore.collection('users/$uid/customers').get();
    final existingCusts = {for (final d in existingCustsSnap.docs) d.id: d.data()['updatedAt'] ?? d.data()['createdAt']};

    final existingInvsSnap = await _firestore.collection('users/$uid/invoices').get();
    final existingInvs = {for (final d in existingInvsSnap.docs) d.id: d.data()['updatedAt'] ?? d.data()['createdAt']};

    final existingPaysSnap = await _firestore.collection('users/$uid/payments').get();
    final existingPays = {for (final d in existingPaysSnap.docs) d.id: d.data()['updatedAt'] ?? d.data()['createdAt']};

    final existingLedgers = <String, dynamic>{};
    for (final customerId in existingCusts.keys) {
      final ledgerSnap = await _firestore.collection('users/$uid/customers/$customerId/ledger').get();
      for (final doc in ledgerSnap.docs) {
        existingLedgers[doc.id] = doc.data()['createdAt'] ?? doc.data()['date'];
      }
    }

    final writeOps = <void Function(WriteBatch batch)>[];

    final categoriesList = data['material_categories'] as List? ?? [];
    for (final item in categoriesList) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      final backupTime = (map['updatedAt'] ?? map['createdAt']) as String?;
      if (shouldOverwrite(backupTime, existingCats[id])) {
        writeOps.add((batch) => batch.set(
          _firestore.collection('users/$uid/material_categories').doc(id),
          _prepareForFirestore(map),
        ));
      }
    }

    final materialsList = data['materials'] as List? ?? [];
    for (final item in materialsList) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      final backupTime = (map['updatedAt'] ?? map['createdAt']) as String?;
      if (shouldOverwrite(backupTime, existingMats[id])) {
        writeOps.add((batch) => batch.set(
          _firestore.collection('users/$uid/materials').doc(id),
          _prepareForFirestore(map),
        ));
      }
    }

    final customersList = data['customers'] as List? ?? [];
    for (final item in customersList) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      final backupTime = (map['updatedAt'] ?? map['createdAt']) as String?;
      if (shouldOverwrite(backupTime, existingCusts[id])) {
        writeOps.add((batch) => batch.set(
          _firestore.collection('users/$uid/customers').doc(id),
          _prepareForFirestore(map),
        ));
      }
    }

    final ledgerList = data['ledger_entries'] as List? ?? [];
    for (final item in ledgerList) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      final customerId = map['customerId'] as String;
      final backupTime = (map['createdAt'] ?? map['date']) as String?;
      if (shouldOverwrite(backupTime, existingLedgers[id])) {
        writeOps.add((batch) => batch.set(
          _firestore.collection('users/$uid/customers/$customerId/ledger').doc(id),
          _prepareForFirestore(map),
        ));
      }
    }

    final invoicesList = data['invoices'] as List? ?? [];
    for (final item in invoicesList) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      final backupTime = (map['updatedAt'] ?? map['createdAt']) as String?;
      final items = map['items'] as List? ?? [];
      
      if (shouldOverwrite(backupTime, existingInvs[id])) {
        writeOps.add((batch) => batch.set(
          _firestore.collection('users/$uid/invoices').doc(id),
          _prepareForFirestore(map),
        ));

        for (final line in items) {
          final lineMap = Map<String, dynamic>.from(line as Map);
          final lineId = lineMap['id'] as String;
          writeOps.add((batch) => batch.set(
            _firestore.collection('users/$uid/invoices/$id/invoice_items').doc(lineId),
            _prepareForFirestore(lineMap),
          ));
        }
      }
    }

    final paymentsList = data['payments'] as List? ?? [];
    for (final item in paymentsList) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      final backupTime = (map['updatedAt'] ?? map['createdAt']) as String?;
      if (shouldOverwrite(backupTime, existingPays[id])) {
        writeOps.add((batch) => batch.set(
          _firestore.collection('users/$uid/payments').doc(id),
          _prepareForFirestore(map),
        ));
      }
    }

    final settingsMap = data['settings'] as Map?;
    if (settingsMap != null) {
      final map = Map<String, dynamic>.from(settingsMap);
      final backupTime = (map['updatedAt'] ?? map['createdAt']) as String?;
      final existingStoreSnap = await _firestore.doc('users/$uid/settings/store').get();
      final existingStoreTime = existingStoreSnap.exists 
          ? (existingStoreSnap.data()?['updatedAt'] ?? existingStoreSnap.data()?['createdAt'])
          : null;
      if (shouldOverwrite(backupTime, existingStoreTime)) {
        writeOps.add((batch) => batch.set(
          _firestore.doc('users/$uid/settings/store'),
          _prepareForFirestore(map),
          SetOptions(merge: true),
        ));
      }
    }

    if (writeOps.isNotEmpty) {
      await _runInBatches(writeOps);
    }
  }
}
