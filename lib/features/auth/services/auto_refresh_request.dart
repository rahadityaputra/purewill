import 'package:http/http.dart' as http;
import 'package:purewill/features/auth/services/auth_service.dart';

Future<http.Response> sendWithAutoRefresh({
  required Future<http.Response> Function() request,
  required AuthService? authService,
  required void Function(String token) updateAccessToken,
}) async {
  final response = await request();

  if (response.statusCode != 401 || authService == null) {
    return response;
  }

  final refreshedToken = await authService.refreshAccessToken();
  if (refreshedToken == null || refreshedToken.isEmpty) {
    return response;
  }

  updateAccessToken(refreshedToken);
  return request();
}
