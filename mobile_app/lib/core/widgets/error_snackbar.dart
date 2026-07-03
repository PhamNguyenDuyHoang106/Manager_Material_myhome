import 'package:flutter/material.dart';

void showErrorSnackBar(BuildContext context, Object error) {
  print("showErrorSnackBar: $error");
  final message = error.toString();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message.replaceFirst('Exception: ', '').replaceFirst('Exception: ', '')),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
