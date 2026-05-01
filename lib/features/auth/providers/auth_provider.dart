import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:purewill/features/auth/services/auth_repository.dart';
import 'package:purewill/features/auth/services/secure_storage_repository.dart';
import 'package:purewill/features/auth/services/auth_service.dart';
import 'package:purewill/features/auth/view_models/auth_view_model.dart';


final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthRepository(authService, SecureStorageRepository());
});


final authNotifierProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  final viewModel = AuthViewModel(repository);
  Future.microtask(() => viewModel.restoreSession(requireBiometric: true));
  return viewModel;
});
