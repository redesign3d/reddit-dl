import 'package:flutter/material.dart';

import '../tokens.dart';

class AppToast {
  static void show(BuildContext context, String message) {
    final colors = context.appColors;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colors.foreground,
      ),
    );
  }
}
