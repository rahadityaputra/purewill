import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/features/auth/view_models/auth_view_model.dart';
import 'package:purewill/features/auth/providers/auth_provider.dart';
import 'package:purewill/features/auth/views/login_screen.dart';
import 'package:purewill/features/home/views/home_screen.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;

    if (authState.status == AuthStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (currentUser != null) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}
