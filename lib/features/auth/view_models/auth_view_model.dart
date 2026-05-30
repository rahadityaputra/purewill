import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:purewill/features/auth/services/auth_service.dart';
import 'package:purewill/features/auth/services/biometric_service.dart';
import 'package:purewill/features/auth/services/secure_storage_repository.dart';
import 'package:purewill/features/auth/models/auth_model.dart';
import 'package:purewill/features/user/models/user_model.dart';

enum AuthStatus { initial, success, loading, failure }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final UserModel? user;

  AuthState({this.status = AuthStatus.initial, this.errorMessage, this.user});

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    UserModel? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthService _authService;

  final BiometricService _biometricService = BiometricService();
  final SecureStorageRepository _secureStorage = SecureStorageRepository();

  AuthViewModel(this._authService)
    : super(AuthState(status: AuthStatus.loading));

  Future<void> restoreSession({bool requireBiometric = false}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final restoredUser = await _authService.restoreSession(
        requireBiometric: requireBiometric,
      );
      if (restoredUser == null) {
        state = state.copyWith(
          status: AuthStatus.initial,
          errorMessage: null,
          user: null,
        );
        return;
      }

      state = state.copyWith(
        status: AuthStatus.success,
        errorMessage: null,
        user: restoredUser,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.initial,
        errorMessage: null,
        user: null,
      );
    }
  }

  Future<void> login(String email, String password) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      final user = await _authService.login(email: email, password: password);
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.success,
          errorMessage: null,
          user: user,
        );
      }
    } on AuthException catch (e) {
      debugPrint('AuthViewModel login auth error: $e');
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.formattedMessage,
      );
      rethrow;
    } catch (e) {
      debugPrint('AuthViewModel login unexpected error: $e');
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: "Server Error",
      );
      rethrow;
    }
  }

  Future<void> signup({
    required String fullname,
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String gender,
    required DateTime birthDate,
  }) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

      final user = await _authService.signup(
        fullname: fullname,
        username: username,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        gender: gender,
        birthDate: birthDate,
      );

      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.success,
          errorMessage: null,
          user: user,
        );
      } else {
        throw AuthException('Failed to create user account');
      }
    } on AuthException catch (e) {
      debugPrint('AuthViewModel signup auth error: $e');
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.formattedMessage,
      );
      rethrow;
    } catch (e) {
      debugPrint('AuthViewModel signup unexpected error: $e');
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: "Server Error",
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      await _authService.logout();
      await clearSavedCredentials();

      state = AuthState(
        status: AuthStatus.initial,
        user: null,
        errorMessage: null,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.formattedMessage,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: "Logout failed",
      );
    }
  }

  Future<bool> loginWithBiometric() async {
    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      if (!isAvailable) {
        state = state.copyWith(
          status: AuthStatus.failure,
          errorMessage:
              'Biometric authentication is not available on this device',
        );
        return false;
      }
      final result = await _biometricService.authenticate(
        reason: 'Authenticate to login to PureWill',
        title: 'Login with Fingerprint',
        subtitle: 'Place your finger on the sensor to continue',
        cancelButtonText: 'Use Password Instead',
      );

      if (!result.success) {
        state = state.copyWith(
          status: AuthStatus.failure,
          errorMessage:
              result.errorMessage ?? 'Biometric authentication failed',
        );
        return false;
      }

      state = state.copyWith(status: AuthStatus.loading);

      try {
        final restoredUser = await _authService.restoreSession();
        if (restoredUser != null) {
          state = state.copyWith(
            status: AuthStatus.success,
            errorMessage: null,
            user: restoredUser,
          );
          return true;
        }

        state = state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Failed to restore session after biometric auth',
        );
        return false;
      } catch (e) {
        state = state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Session restore failed: $e',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Biometric login failed: $e',
      );
      return false;
    }
  }

  Future<bool> isBiometricLoginAvailable() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final isEnabled = await _secureStorage.isBiometricEnabled();
    return isAvailable && isEnabled;
  }

  Future<void> saveCredentialsForBiometric({
    required String email,
    required bool enableBiometric,
  }) async {
    await _secureStorage.saveCredentials(
      email: email,
      enableBiometric: enableBiometric,
    );
  }

  Future<void> clearSavedCredentials() async {
    await _secureStorage.clearCredentials();
  }

  Future<void> forceLogout({String? reason}) async {
    debugPrint('🔴 [AuthViewModel] forceLogout called with reason: $reason');
    try {
      await _authService.logout();
      await clearSavedCredentials();

      state = AuthState(
        status: AuthStatus.initial,
        user: null,
        errorMessage: reason ?? 'Your session has expired. Please login again.',
      );
      debugPrint('✅ [AuthViewModel] forceLogout completed, state updated');
    } catch (e) {
      debugPrint(
        '🔴 [AuthViewModel] forceLogout error: $e, but still clearing state',
      );
      state = AuthState(
        status: AuthStatus.initial,
        user: null,
        errorMessage: reason ?? 'Your session has expired. Please login again.',
      );
    }
  }
}
