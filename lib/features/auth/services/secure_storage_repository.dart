import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer';

class SecureStorageRepository {
  static const String _keyEmail = 'saved_email';
  static const String _keyPassword = 'saved_password';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyLastLoginEmail = 'last_login_email';
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshTokenCookie = 'refresh_token_cookie';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveCredentials({
    required String email,
    required bool enableBiometric,
  }) async {
    if (enableBiometric) {
      await _storage.write(key: _keyEmail, value: email);
      await _storage.write(key: _keyBiometricEnabled, value: 'true');
      await _storage.write(key: _keyLastLoginEmail, value: email);
    } else {
      await clearCredentials();
    }
  }

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<void> saveRefreshTokenCookie(String cookie) async {
    await _storage.write(key: _keyRefreshTokenCookie, value: cookie);
  }

  Future<String?> getRefreshTokenCookie() async {
    return await _storage.read(key: _keyRefreshTokenCookie);
  }

  Future<SavedCredentials?> getSavedCredentials() async {
    try {
      final email = await _storage.read(key: _keyEmail);
      final isEnabled = await _storage.read(key: _keyBiometricEnabled);

      if (email != null && isEnabled == 'true') {
        return SavedCredentials(email: email, password: null);
      }
      return null;
    } catch (e) {
      log('Error getting saved credentials', error: e);
      return null;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final isEnabled = await _storage.read(key: _keyBiometricEnabled);
    return isEnabled == 'true';
  }

  Future<String?> getLastLoginEmail() async {
    return await _storage.read(key: _keyLastLoginEmail);
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
    await _storage.delete(key: _keyBiometricEnabled);
  }

  Future<void> clearAccessToken() async {
    await _storage.delete(key: _keyAccessToken);
  }

  Future<void> clearRefreshTokenCookie() async {
    await _storage.delete(key: _keyRefreshTokenCookie);
  }

  Future<void> clearSessionTokens() async {
    await clearAccessToken();
    await clearRefreshTokenCookie();
  }

  Future<void> disableBiometric() async {
    await clearCredentials();
  }
}

class SavedCredentials {
  final String email;
  final String? password;

  SavedCredentials({required this.email, this.password});
}
