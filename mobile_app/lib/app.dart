import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/router/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';

class MaterialManagerApp extends ConsumerWidget {
  const MaterialManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
