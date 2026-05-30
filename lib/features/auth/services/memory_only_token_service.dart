import 'dart:developer';

class MemoryOnlyTokenService {
  String? _accessToken;

  Future<void> saveAccessToken(String token) async {
    _accessToken = token;
    log('MemoryOnlyTokenService: access token saved in memory');
  }

  Future<String?> getAccessToken() async {
    return _accessToken;
  }

  Future<void> clearAccessToken() async {
    _accessToken = null;
    log('MemoryOnlyTokenService: access token cleared from memory');
  }

  Future<void> clearSessionTokens() async {
    _accessToken = null;
    log('MemoryOnlyTokenService: all session tokens cleared from memory');
  }

  bool hasAccessToken() => _accessToken != null;
  String getDebugInfo() =>
      '''
Memory Token Storage Debug Info:
- Has Access Token: ${hasAccessToken()}
  ''';
}
