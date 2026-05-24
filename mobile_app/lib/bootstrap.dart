import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'config/firebase/firebase_options.dart';
import 'data/datasources/hive_cache.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
await Firebase.initializeApp(
options: DefaultFirebaseOptions.currentPlatform,
);
print("Firebase initialized");
}

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await HiveCache.instance.init();
}
