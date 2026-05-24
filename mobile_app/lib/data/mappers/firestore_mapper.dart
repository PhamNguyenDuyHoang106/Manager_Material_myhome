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
      _convertTimestamps(Map<String, dynamic>.from(entry.value as Map));
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
  return copy;
}
