import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:purewill/features/auth/models/auth_model.dart';
import 'package:purewill/features/auth/services/biometric_service.dart';
import 'package:purewill/features/auth/services/memory_only_token_service.dart';
import 'package:purewill/features/auth/services/secure_storage_repository.dart';
import 'package:purewill/features/user/models/profile_model.dart';
import 'package:purewill/features/user/models/user_model.dart';

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client() {
    final host = dotenv.env['API_HOST'] ?? 'localhost';
    final port = dotenv.env['API_PORT'] ?? '4000';
    _baseUrl = 'http://$host:$port/api';
  }

  final http.Client _client;
  late final String _baseUrl;

  final MemoryOnlyTokenService _memoryTokenService = MemoryOnlyTokenService();
  final SecureStorageRepository _secureStorageRepository =
      SecureStorageRepository();
  final BiometricService _biometricService = BiometricService();

  String? _accessToken;
  String? _refreshTokenCookie;

  String? get accessToken => _accessToken;
  String? get refreshTokenCookie => _refreshTokenCookie;

  void setAccessToken(String token) {
    _accessToken = token;
  }

  void setRefreshTokenCookie(String cookie) {
    _refreshTokenCookie = cookie;
  }

  Future<void> restoreAccessToken() async {
    final storedToken = await _memoryTokenService.getAccessToken();
    final storedRefreshCookie = await _secureStorageRepository
        .getRefreshTokenCookie();

    _accessToken = storedToken;

    if (storedToken != null) {
      setAccessToken(storedToken);
      debugPrint("✅ Restored access token from memory");
    } else {
      debugPrint("ℹ️ No access token in memory");
    }

    if (storedRefreshCookie != null) {
      setRefreshTokenCookie(storedRefreshCookie);
      debugPrint("✅ Restored refresh token cookie from secure storage");
    } else {
      debugPrint("ℹ️ No refresh token cookie in secure storage");
    }
  }

  Future<UserModel?> restoreSession({bool requireBiometric = false}) async {
    await restoreAccessToken();

    if (_accessToken != null) {
      try {
        final response = await checkSession(skipRefresh: true);
        _accessToken = accessToken;
        if (_accessToken != null) {
          await _memoryTokenService.saveAccessToken(_accessToken!);
        }

        final refreshCookie = refreshTokenCookie;
        if (refreshCookie != null) {
          await _secureStorageRepository.saveRefreshTokenCookie(refreshCookie);
        }

        return _userFromSessionResponse(response);
      } on AuthException {
        await _memoryTokenService.clearAccessToken();
        _accessToken = null;
      }
    }

    final storedRefreshCookie = await _secureStorageRepository
        .getRefreshTokenCookie();
    if (storedRefreshCookie == null) {
      return null;
    }

    if (requireBiometric) {
      final isEnabled = await _secureStorageRepository.isBiometricEnabled();
      if (isEnabled) {
        final result = await _biometricService.authenticate(
          reason: 'Authenticate to restore session',
          title: 'Unlock PureWill',
          subtitle: 'Use your fingerprint to continue',
          cancelButtonText: 'Use Password',
        );

        if (!result.success) {
          await _memoryTokenService.clearSessionTokens();
          await _secureStorageRepository.clearSessionTokens();
          _accessToken = null;
          return null;
        }
      }
    }

    try {
      final refreshed = await refreshSession();
      _accessToken = refreshed['accessToken'] as String?;
      if (_accessToken != null) {
        await _memoryTokenService.saveAccessToken(_accessToken!);
      }

      final refreshCookie = refreshTokenCookie;
      if (refreshCookie != null) {
        await _secureStorageRepository.saveRefreshTokenCookie(refreshCookie);
      }

      final session = await checkSession();
      return _userFromSessionResponse(session);
    } on AuthException {
      await _memoryTokenService.clearSessionTokens();
      await _secureStorageRepository.clearSessionTokens();
      _accessToken = null;
      rethrow;
    }
  }

  Future<String?> refreshAccessToken() async {
    try {
      debugPrint("refresh token access token");
      debugPrint(
        "🔄 Current state - _refreshTokenCookie: ${_refreshTokenCookie != null ? 'SET' : 'NULL'}",
      );
      final refreshed = await refreshSession();
      _accessToken = refreshed['accessToken'] as String?;

      if (_accessToken != null) {
        await _memoryTokenService.saveAccessToken(_accessToken!);
      }

      final refreshCookie = refreshTokenCookie;
      if (refreshCookie != null) {
        await _secureStorageRepository.saveRefreshTokenCookie(refreshCookie);
      }

      return _accessToken;
    } on AuthException {
      await _memoryTokenService.clearSessionTokens();
      await _secureStorageRepository.clearSessionTokens();
      _accessToken = null;
      rethrow;
    }
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await createSession(email: email, password: password);

      _accessToken = response['accessToken'] as String?;
      if (_accessToken != null) {
        await _memoryTokenService.saveAccessToken(_accessToken!);
      }

      final refreshCookie = refreshTokenCookie;
      if (refreshCookie != null) {
        await _secureStorageRepository.saveRefreshTokenCookie(refreshCookie);
      }

      return UserModel(
        id: 'temp',
        email: email,
        profile: ProfileModel(
          fullName: email.split('@').first,
          avatarUrl: null,
        ),
      );
    } on AuthException catch (e, stackTrace) {
      log('AUTH FAILURE: Login failed.', error: e, stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      log(
        'GENERAL FAILURE: Unexpected error during login.',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<UserModel?> signup({
    required String fullname,
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String gender,
    required DateTime birthDate,
  }) async {
    try {
      final request = RegisterRequest(
        email: email,
        username: username,
        fullname: fullname,
        gender: gender.toUpperCase(),
        birthDate: birthDate,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      final response = await register(request);

      if (response['data'] != null) {
        final userData = response['data'];
        return UserModel(
          id: userData['id'].toString(),
          email: userData['email'],
          profile: ProfileModel(
            fullName: userData['username']?.toString() ?? '',
            avatarUrl: null,
          ),
        );
      }

      return null;
    } on AuthException catch (e, stackTrace) {
      log(
        'AUTH FAILURE: Signup failed: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      log(
        'GENERAL FAILURE: Unexpected error during signup: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await deleteSession();
      _accessToken = null;
      await _memoryTokenService.clearSessionTokens();
      await _secureStorageRepository.clearSessionTokens();
    } on AuthException catch (e, stackTrace) {
      log('AUTH FAILURE: Logout failed.', error: e, stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      log(
        'GENERAL FAILURE: Unexpected error during logout.',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  UserModel? _userFromSessionResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final profile = data['profile'];
    final fullname = profile is Map<String, dynamic>
        ? profile['fullname']?.toString()
        : null;
    final email = data['email']?.toString() ?? '';
    final username = data['username']?.toString();

    return UserModel(
      id: data['id']?.toString() ?? '',
      email: email,
      profile: ProfileModel(
        fullName: fullname ?? username ?? email.split('@').first,
        avatarUrl: null,
      ),
    );
  }

  Future<Map<String, dynamic>> createSession({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = _decodeBody(response);
      _accessToken = data['accessToken'] as String?;
      _refreshTokenCookie = _extractRefreshTokenCookie(response);

      return data;
    }

    if (response.statusCode == 400) {
      final error = _decodeBody(response);
      throw AuthException.fromResponse(
        error,
        fallbackMessage: 'user not registered',
      );
    }

    if (response.statusCode == 409) {
      final error = _decodeBody(response);
      throw AuthException.fromResponse(
        error,
        fallbackMessage: 'request conflict',
      );
    }

    throw AuthException('Server error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> register(RegisterRequest request) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 201) {
      return _decodeBody(response);
    }
    if (response.statusCode == 400) {
      final error = _decodeBody(response);
      throw AuthException.fromResponse(
        error,
        fallbackMessage: 'user not registered',
      );
    }

    if (response.statusCode == 409) {
      final error = _decodeBody(response);
      throw AuthException.fromResponse(
        error,
        fallbackMessage: 'email already used',
      );
    }

    throw AuthException('Server error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> refreshSession() async {
    if (_refreshTokenCookie == null) {
      final storedCookie = await _secureStorageRepository
          .getRefreshTokenCookie();
      if (storedCookie != null) {
        _refreshTokenCookie = storedCookie;
      } else {
        throw AuthException('refresh token is required');
      }
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/refresh'),
      headers: {
        'Content-Type': 'application/json',
        if (_refreshTokenCookie != null) 'Cookie': _refreshTokenCookie!,
      },
    );

    if (response.statusCode == 200) {
      final data = _decodeBody(response);
      _accessToken = data['accessToken'] as String?;

      final refreshedCookie = _extractRefreshTokenCookie(response);
      if (refreshedCookie != null) {
        _refreshTokenCookie = refreshedCookie;
      }

      return data;
    }

    final error = _decodeBody(response);

    if (response.statusCode == 401) {
      throw AuthException.fromResponse(
        error,
        fallbackMessage: 'refresh token is required',
      );
    }

    if (response.statusCode == 400) {
      throw AuthException.fromResponse(
        error,
        fallbackMessage: 'refresh token not valid',
      );
    }

    if (response.statusCode == 500) {
      throw AuthException.fromResponse(
        error,
        fallbackMessage: 'refresh token processing failed',
      );
    }

    throw AuthException('Refresh failed: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> refreshToken() => refreshSession();

  Future<void> deleteSession() async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/auth/session'),
      headers: {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        if (_refreshTokenCookie != null) 'Cookie': _refreshTokenCookie!,
      },
    );

    if (response.statusCode == 200) {
      _accessToken = null;
      _refreshTokenCookie = null;
      return;
    }

    final error = _decodeBody(response);

    if (response.statusCode == 400) {
      throw AuthException.fromResponse(
        error,
        fallbackMessage: 'user id not found',
      );
    }

    if (response.statusCode == 500) {
      throw AuthException.fromResponse(
        error,
        fallbackMessage: 'delete refresh token failed',
      );
    }

    throw AuthException('Logout failed: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> checkSession({bool skipRefresh = false}) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/auth/session'),
      headers: {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode == 200) {
      return _decodeBody(response);
    }

    if (response.statusCode == 401) {
      if (!skipRefresh && _refreshTokenCookie != null) {
        await refreshSession();
        return checkSession(skipRefresh: true);
      }

      final error = _decodeBody(response);
      throw AuthException.fromResponse(error, fallbackMessage: 'Unauthorized');
    }

    throw AuthException('Check session failed: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getCurrentSession() => checkSession();

  Future<void> clearSessionTokens() async {
    _accessToken = null;
    _refreshTokenCookie = null;
    await _memoryTokenService.clearSessionTokens();
    await _secureStorageRepository.clearSessionTokens();
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {};
  }

  String? _extractRefreshTokenCookie(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) {
      return null;
    }

    final match = RegExp(r'refreshToken=([^;]+)').firstMatch(setCookie);
    if (match == null) {
      return null;
    }

    final extractedCookie = 'refreshToken=${match.group(1)}';
    return extractedCookie;
  }

  void dispose() {
    _client.close();
  }
}
