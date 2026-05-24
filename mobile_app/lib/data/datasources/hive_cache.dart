import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

class HiveCache {
  HiveCache._();
  static final HiveCache instance = HiveCache._();

  static const _customersBox = 'customers_cache';
  static const _materialsBox = 'materials_cache';
  static const _invoicesBox = 'invoices_cache';
  static const _settingsBox = 'settings_cache';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_customersBox);
    await Hive.openBox<String>(_materialsBox);
    await Hive.openBox<String>(_invoicesBox);
    await Hive.openBox<String>(_settingsBox);
  }

  Future<void> saveList(String boxName, List<Map<String, dynamic>> items, {String key = 'all'}) async {
    final box = Hive.box<String>(boxName);
    await box.put(key, jsonEncode(items));
  }

  List<Map<String, dynamic>>? loadList(String boxName, {String key = 'all'}) {
    final box = Hive.box<String>(boxName);
    final raw = box.get(key);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  String get customersBox => _customersBox;
  String get materialsBox => _materialsBox;
  String get invoicesBox => _invoicesBox;
  String get settingsBox => _settingsBox;
}
