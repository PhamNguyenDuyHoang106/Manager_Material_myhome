import 'package:flutter/material.dart';

void showErrorSnackBar(BuildContext context, Object error) {
  final message = error is Exception ? error.toString() : 'Đã xảy ra lỗi';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message.replaceFirst('Exception: ', '')),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
