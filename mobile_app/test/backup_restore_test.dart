import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:material_manager_mobile/domain/repositories/settings_repository.dart';
import 'package:material_manager_mobile/domain/services/backup_service.dart';

void main() {
  group('Backup & Checksum Validation Tests', () {
    test('ZIP Generation and Checksum Verification', () {
      final data = {
        'version': 1,
        'uid': 'test-uid',
        'createdAt': DateTime.now().toIso8601String(),
        'data': {
          'materials': [],
          'customers': [],
        }
      };

      final jsonStr = jsonEncode(data);
      final jsonBytes = utf8.encode(jsonStr);
      final checksum = sha256.convert(jsonBytes).toString();

      final archive = Archive();
      archive.addFile(ArchiveFile('backup.json', jsonBytes.length, jsonBytes));
      archive.addFile(ArchiveFile('checksum.txt', checksum.length, utf8.encode(checksum)));
      
      final zipBytes = ZipEncoder().encode(archive);
      expect(zipBytes, isNotNull);

      final decodedArchive = ZipDecoder().decodeBytes(zipBytes!);
      final decodedJsonFile = decodedArchive.findFile('backup.json');
      final decodedChecksumFile = decodedArchive.findFile('checksum.txt');

      expect(decodedJsonFile, isNotNull);
      expect(decodedChecksumFile, isNotNull);

      final decodedJsonStr = utf8.decode(decodedJsonFile!.content as List<int>);
      final decodedChecksum = utf8.decode(decodedChecksumFile!.content as List<int>).trim();

      expect(decodedJsonStr, equals(jsonStr));
      expect(decodedChecksum, equals(checksum));

      final recomputed = sha256.convert(utf8.encode(decodedJsonStr)).toString();
      expect(recomputed, equals(decodedChecksum));
    });

    test('Should Overwrite Date Comparison Logic', () {
      final service = BackupService(
        FakeFirebaseFirestore(),
        FakeFirebaseStorage(),
        FakeSettingsRepository(),
      );

      // 1. Existing is null -> should overwrite
      expect(service.shouldOverwrite('2026-06-25T12:00:00Z', null), isTrue);

      // 2. Backup is newer than existing (string)
      expect(service.shouldOverwrite('2026-06-25T15:00:00Z', '2026-06-25T12:00:00Z'), isTrue);

      // 3. Backup is older than existing (string)
      expect(service.shouldOverwrite('2026-06-25T10:00:00Z', '2026-06-25T12:00:00Z'), isFalse);

      // 4. Backup is same as existing (string)
      expect(service.shouldOverwrite('2026-06-25T12:00:00Z', '2026-06-25T12:00:00Z'), isFalse);

      // 5. Existing is Timestamp (newer than backup)
      final existingTs = Timestamp.fromDate(DateTime.parse('2026-06-25T13:00:00Z'));
      expect(service.shouldOverwrite('2026-06-25T12:00:00Z', existingTs), isFalse);

      // 6. Existing is Timestamp (older than backup)
      final existingTsOld = Timestamp.fromDate(DateTime.parse('2026-06-25T11:00:00Z'));
      expect(service.shouldOverwrite('2026-06-25T12:00:00Z', existingTsOld), isTrue);
    });

    test('ZIP verification throws error if files are missing or modified', () {
      final service = BackupService(
        FakeFirebaseFirestore(),
        FakeFirebaseStorage(),
        FakeSettingsRepository(),
      );

      // 1. Empty zip bytes
      final emptyArchive = Archive();
      final emptyZipBytes = ZipEncoder().encode(emptyArchive)!;
      expect(() => service.verifyBackupZip(emptyZipBytes), throwsException);

      // 2. Zip with modified checksum
      final jsonStr = '{"data": {}}';
      final jsonBytes = utf8.encode(jsonStr);
      
      final archive = Archive();
      archive.addFile(ArchiveFile('backup.json', jsonBytes.length, jsonBytes));
      archive.addFile(ArchiveFile('checksum.txt', 12, utf8.encode('badchecksum')));
      final modifiedZipBytes = ZipEncoder().encode(archive)!;

      expect(() => service.verifyBackupZip(modifiedZipBytes), throwsException);
    });
  });
}

// Fakes for testing
class FakeFirebaseFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseStorage implements FirebaseStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSettingsRepository implements SettingsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
