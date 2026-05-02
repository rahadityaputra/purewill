import 'package:flutter/material.dart';

class AppLoadingDialog extends StatelessWidget {
  const AppLoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
