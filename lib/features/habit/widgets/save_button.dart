import 'package:flutter/material.dart';
import 'package:purewill/core/widgets/primary_action_button.dart';

class SaveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;

  const SaveButton({
    super.key,
    this.onPressed,
    this.text = 'Save',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryActionButton(
      onPressed: onPressed,
      text: text,
      isLoading: isLoading,
      width: double.infinity,
      height: 50,
    );
  }
}
