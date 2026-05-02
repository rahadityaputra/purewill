import 'package:flutter/material.dart';

class AppInputDialog extends StatelessWidget {
  final String title;
  final String hintText;
  final TextEditingController controller;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final bool autofocus;
  final int maxLines;

  const AppInputDialog({
    super.key,
    required this.title,
    required this.hintText,
    required this.controller,
    required this.onConfirm,
    this.cancelLabel = 'Cancel',
    this.confirmLabel = 'Create',
    this.autofocus = true,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: autofocus,
        decoration: InputDecoration(
          hintText: hintText,
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
