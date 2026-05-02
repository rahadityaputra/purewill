import 'package:flutter/material.dart';

class AppAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;
  final Color? actionColor;

  const AppAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel = 'OK',
    this.onAction,
    this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onAction?.call();
          },
          child: Text(actionLabel, style: TextStyle(color: actionColor)),
        ),
      ],
    );
  }
}
