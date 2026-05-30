import 'package:http/http.dart' as http;
import 'package:purewill/features/auth/services/auth_service.dart';
import 'package:purewill/features/auth/models/auth_model.dart';

class AuthRefreshClient extends http.BaseClient {
  AuthRefreshClient(
    this._inner,
    this._authService, {
    this.onTokenRefreshed,
    this.onTokenExpired,
  });

  final http.Client _inner;
  final AuthService? _authService;
  final void Function(String token)? onTokenRefreshed;

  final Future<void> Function()? onTokenExpired;

  bool _shouldAttemptRefresh(http.BaseRequest request, int statusCode) {
    if (_authService == null) {
      return false;
    }

    final hasBearerAuth =
        request.headers['Authorization']?.toLowerCase().startsWith('bearer ') ??
        false;
    if (!hasBearerAuth) {
      return false;
    }
    return statusCode == 401 || statusCode == 403;
  }

  bool _isTerminalAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    const terminalMarkers = <String>[
      'jwt expired',
      'token expired',
      'refresh token',
      'unauthorized',
      'not valid',
      'invalid token',
    ];

    return terminalMarkers.any(message.contains);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);

    if (!_shouldAttemptRefresh(request, response.statusCode)) {
      return response;
    }

    final authService = _authService;
    if (authService == null) {
      return response;
    }

    try {
      final refreshedToken = await _ensureRefreshedToken(authService);

      if (refreshedToken == null || refreshedToken.isEmpty) {
        if (onTokenExpired != null) {
          await onTokenExpired!();
        }
        return response;
      }

      onTokenRefreshed?.call(refreshedToken);

      final retryRequest = _cloneRequest(request);
      if (retryRequest == null) {
        return response;
      }

      retryRequest.headers['Authorization'] = 'Bearer $refreshedToken';

      return _inner.send(retryRequest);
    } on AuthException catch (e) {
      if (_isTerminalAuthError(e)) {
        if (onTokenExpired != null) {
          await onTokenExpired!();
        }
      }

      return response;
    } catch (e) {
      return response;
    }
  }

  http.BaseRequest? _cloneRequest(http.BaseRequest request) {
    if (request is http.Request) {
      final clone = http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection
        ..body = request.body;
      return clone;
    }

    if (request is http.MultipartRequest) {
      final clone = http.MultipartRequest(request.method, request.url)
        ..headers.addAll(request.headers)
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
      return clone;
    }

    return null;
  }

  Future<String?> _ensureRefreshedToken(AuthService authService) async {
    if (_authService == null) return null;

    if (_refreshing != null) {
      try {
        return await _refreshing;
      } catch (_) {
        return null;
      }
    }

    _refreshing = (() async {
      try {
        return await authService.refreshAccessToken();
      } finally {
        _refreshing = null;
      }
    })();

    try {
      return await _refreshing;
    } catch (_) {
      return null;
    }
  }

  Future<String?>? _refreshing;

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
