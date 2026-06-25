import 'package:cloud_firestore/cloud_firestore.dart';

Map<String, dynamic> fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = Map<String, dynamic>.from(doc.data() ?? {});
  data['id'] = doc.id;
  _convertTimestamps(data);
  return data;
}

void _convertTimestamps(Map<String, dynamic> data) {
  for (final entry in data.entries.toList()) {
    if (entry.value is Timestamp) {
      data[entry.key] = (entry.value as Timestamp).toDate().toIso8601String();
    } else if (entry.value is Map) {
      final mapCopy = Map<String, dynamic>.from(entry.value as Map);
      _convertTimestamps(mapCopy);
      data[entry.key] = mapCopy;
    } else if (entry.value is List) {
      final listCopy = [];
      for (final item in entry.value as List) {
        if (item is Map) {
          final itemMap = Map<String, dynamic>.from(item as Map);
          _convertTimestamps(itemMap);
          listCopy.add(itemMap);
        } else {
          listCopy.add(item);
        }
      }
      data[entry.key] = listCopy;
    }
  }
}

Map<String, dynamic> toFirestore(Map<String, dynamic> data) {
  final copy = Map<String, dynamic>.from(data);
  copy.remove('id');
  copy.remove('items');
  copy.remove('customerName');
  copy.remove('materialName');
  copy.remove('unit');
  _convertStringsToTimestamps(copy);
  return copy;
}

void _convertStringsToTimestamps(Map<String, dynamic> data) {
  for (final entry in data.entries.toList()) {
    if (entry.value is String) {
      final val = entry.value as String;
      // Match ISO8601 formats (e.g. 2026-06-25T15:30:00.000 or 2026-06-25)
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
