import 'package:flutter/material.dart';

class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool dismissible;
  final EdgeInsetsGeometry? contentPadding;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.cancelLabel = 'Cancel',
    this.confirmLabel = 'Confirm',
    this.confirmColor = Colors.red,
    this.onCancel,
    this.dismissible = true,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      contentPadding: contentPadding,
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onCancel?.call();
          },
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: confirmColor),
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
