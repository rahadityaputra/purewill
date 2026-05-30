import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:purewill/features/auth/services/auth_service.dart';
import 'package:purewill/features/auth/services/auth_refresh_client.dart';
import 'package:purewill/features/auth/services/auth_singleton.dart';
import 'package:purewill/features/auth/view_models/auth_view_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return sharedAuthService ?? AuthService();
});

final authNotifierProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  ref,
) {
  final authService = ref.watch(authServiceProvider);
  final viewModel = AuthViewModel(authService);
  Future.microtask(() => viewModel.restoreSession(requireBiometric: true));
  return viewModel;
});

final tokenExpirationCallbackProvider = Provider<Future<void> Function()?>((
  ref,
) {
  debugPrint('🔵 [AuthProvider] Creating tokenExpirationCallbackProvider');
  final authViewModel = ref.watch(authNotifierProvider.notifier);
  return () {
    debugPrint('🔵 [AuthProvider] Callback invoked, calling forceLogout');
    return authViewModel.forceLogout(
      reason: 'Your session has expired. Please login again.',
    );
  };
});

final httpClientProvider = Provider<http.Client>((ref) {
  final authService = ref.watch(authServiceProvider);
  final onTokenExpired = ref.watch(tokenExpirationCallbackProvider);
  if (sharedHttpClient != null) {
    return sharedHttpClient!;
  }

  return AuthRefreshClient(
    http.Client(),
    authService,
    onTokenExpired: onTokenExpired,
  );
});
