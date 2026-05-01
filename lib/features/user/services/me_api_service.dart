import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purewill/features/auth/services/auth_repository.dart';
import 'package:purewill/features/auth/models/auth_model.dart';
import 'package:purewill/features/auth/services/auth_refresh_client.dart';

class MeApiService {
  late final String baseUrl;
  String? _accessToken;
  late final http.Client _client;

  MeApiService({http.Client? client, AuthRepository? authRepository}) {
    _client = authRepository != null
        ? AuthRefreshClient(
            client ?? http.Client(),
            authRepository,
            onTokenRefreshed: (token) {
              _accessToken = token;
            },
          )
        : (client ?? http.Client());
    final host = dotenv.env['API_HOST'] ?? 'localhost';
    final port = dotenv.env['API_PORT'] ?? '4000';
    baseUrl = 'http://$host:$port/api';

    if (kDebugMode) {
      print('🌐 Me API Base URL: $baseUrl');
    }
  }

  void setAccessToken(String token) {
    _accessToken = token;
    if (kDebugMode) {
      print('🔐 MeApiService: Access token set');
    }
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

  /// GET /api/me - Get current user profile
  Future<Map<String, dynamic>> getMe() async {
    try {
      if (kDebugMode) print('📡 GET $baseUrl/me');

      final response = await _client.get(
        Uri.parse('$baseUrl/me'),
        headers: _headers,
      );

      if (kDebugMode) print('📡 Response status: ${response.statusCode}');

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

  /// GET /api/me/habits - Get current user's habits (optional date filter)
  Future<Map<String, dynamic>> getMeHabits({String? date}) async {
    try {
      final uri = Uri.parse('$baseUrl/me/habits').replace(
        queryParameters: {if (date != null && date.isNotEmpty) 'date': date},
      );

      if (kDebugMode) print('📡 GET $uri');

      final response = await _client.get(uri, headers: _headers);

      if (kDebugMode) print('📡 Response status: ${response.statusCode}');

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

  /// GET /api/me/categories - Get current user's categories
  Future<Map<String, dynamic>> getMeCategories() async {
    try {
      if (kDebugMode) print('📡 GET $baseUrl/me/categories');

      final response = await _client.get(
        Uri.parse('$baseUrl/me/categories'),
        headers: _headers,
      );

      if (kDebugMode) print('📡 Response status: ${response.statusCode}');

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

  /// GET /api/me/units - Get available units
  Future<Map<String, dynamic>> getUnits() async {
    try {
      if (kDebugMode) print('📡 GET $baseUrl/me/units');

      final response = await _client.get(
        Uri.parse('$baseUrl/me/units'),
        headers: _headers,
      );

      if (kDebugMode) print('📡 Response status: ${response.statusCode}');

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

  /// GET /api/me/nofap-sessions - Get current user's nofap session
  Future<Map<String, dynamic>> getMeNofapSessions() async {
    try {
      if (kDebugMode) print('📡 GET $baseUrl/me/nofap-sessions');

      final response = await _client.get(
        Uri.parse('$baseUrl/me/nofap-sessions'),
        headers: _headers,
      );

      if (kDebugMode) print('📡 Response status: ${response.statusCode}');

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

  /// PATCH /api/me - Update current user
  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> updates) async {
    try {
      if (kDebugMode) print('📡 PATCH $baseUrl/me');

      final uri = Uri.parse('$baseUrl/me');
      final request = http.MultipartRequest('PATCH', uri);

      // 1. Tambahkan Headers
      if (_accessToken != null) {
        request.headers['Authorization'] = 'Bearer $_accessToken';
      }
      // Content-Type tidak perlu disetel manual untuk MultipartRequest

      // 2. Iterasi data updates
      for (final entry in updates.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value == null) continue;

        // CEK JIKA VALUE ADALAH FILE (Avatar)
        if (value is File ||
            (key == 'avatar' && value is String && value.contains('/'))) {
          File file;
          if (value is File) {
            file = value;
          } else {
            file = File(value as String);
          }

          if (await file.exists()) {
            // Ambil ekstensi file untuk menentukan MediaType
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

            if (kDebugMode) print('📎 Attached file: ${file.path}');
            continue; // Lanjut ke loop berikutnya, jangan eksekusi request.fields
          }
        }

        // 3. Penanganan Field Teks Biasa
        if (value is String) {
          request.fields[key] = value;
        } else {
          request.fields[key] = value.toString();
        }
      }

      // 4. Kirim Request
      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);

      if (kDebugMode) {
        print('📡 Response status: ${response.statusCode}');
        print('📡 Response body: ${response.body}');
      }

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
      if (kDebugMode) print('❌ Error in updateMe: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  /// DELETE /api/me - Soft delete current user
  Future<Map<String, dynamic>> deleteMe() async {
    try {
      if (kDebugMode) print('📡 DELETE $baseUrl/me');

      final response = await _client.delete(
        Uri.parse('$baseUrl/me'),
        headers: _headers,
      );

      if (kDebugMode) print('📡 Response status: ${response.statusCode}');

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
