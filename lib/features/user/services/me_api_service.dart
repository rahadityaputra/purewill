import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purewill/features/auth/models/auth_model.dart';

class MeApiService {
  late final String baseUrl;
  String? _accessToken;
  late final http.Client _client;

  MeApiService({http.Client? client}) {
    _client = client ?? http.Client();
    final host = dotenv.env['API_HOST'] ?? 'localhost';
    final port = dotenv.env['API_PORT'] ?? '4000';
    baseUrl = 'http://$host:$port/api';
  }

  void setAccessToken(String token) {
    _accessToken = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  String _extractErrorMessage(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        return decoded['message'].toString();
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/me'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized. Please login again.');
      } else {
        throw AuthException(
          _extractErrorMessage(response.body, 'Failed to get me data'),
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getMeHabits({String? date}) async {
    try {
      final uri = Uri.parse('$baseUrl/me/habits').replace(
        queryParameters: {if (date != null && date.isNotEmpty) 'date': date},
      );

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized. Please login again.');
      } else {
        throw AuthException(
          _extractErrorMessage(response.body, 'Failed to get me habits'),
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getMeCategories() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/me/categories'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized. Please login again.');
      } else {
        throw AuthException(
          _extractErrorMessage(response.body, 'Failed to get me categories'),
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getUnits() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/me/units'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized. Please login again.');
      } else {
        throw AuthException(
          _extractErrorMessage(response.body, 'Failed to get units'),
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getMeNofapSessions() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/me/nofap-sessions'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized. Please login again.');
      } else {
        throw AuthException(
          _extractErrorMessage(
            response.body,
            'Failed to get me nofap sessions',
          ),
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> updates) async {
    try {
      final uri = Uri.parse('$baseUrl/me');
      final request = http.MultipartRequest('PATCH', uri);
      if (_accessToken != null) {
        request.headers['Authorization'] = 'Bearer $_accessToken';
      }
      for (final entry in updates.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value == null) continue;
        if (value is File ||
            (key == 'avatar' && value is String && value.contains('/'))) {
          File file;
          if (value is File) {
            file = value;
          } else {
            file = File(value as String);
          }

          if (await file.exists()) {
            final extension = p
                .extension(file.path)
                .toLowerCase()
                .replaceAll('.', '');
            final mimeType = extension == 'png' ? 'png' : 'jpeg';

            final multipartFile = await http.MultipartFile.fromPath(
              key,
              file.path,
              contentType: MediaType('image', mimeType),
            );
            request.files.add(multipartFile);
            continue;
          }
        }
        if (value is String) {
          request.fields[key] = value;
        } else {
          request.fields[key] = value.toString();
        }
      }
      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized. Please login again.');
      } else {
        throw AuthException(
          _extractErrorMessage(response.body, 'Failed to update profile'),
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> deleteMe() async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/me'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized. Please login again.');
      } else {
        throw AuthException(
          _extractErrorMessage(response.body, 'Failed to delete me'),
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
