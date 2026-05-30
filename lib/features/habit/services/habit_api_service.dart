import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:purewill/features/auth/models/auth_model.dart';
import 'package:purewill/features/habit/models/habit_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HabitApiService {
  late final String baseUrl;
  String? _accessToken;
  late final http.Client _client;

  HabitApiService({http.Client? client}) : _client = client ?? http.Client() {
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

  Future<Map<String, dynamic>> getUserHabits(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/me/habits'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized. Please login again.');
      } else {
        throw AuthException('Failed to get habits: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getHabitDetail(int habitId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/habits/$habitId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw AuthException('Habit not found');
      } else {
        throw AuthException(
          _extractErrorMessage(
            response.body,
            'Failed to get habit detail: ${response.statusCode}',
          ),
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getHabitReminderSettings(int habitId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/habits/$habitId/reminder-settings'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw AuthException('Habit not found');
      } else {
        throw AuthException(
          _extractErrorMessage(
            response.body,
            'Failed to get habit reminder settings',
          ),
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> createHabit(HabitModel habit) async {
    try {
      final body = {
        'name': habit.name,
        if (habit.notes != null && habit.notes!.isNotEmpty)
          'notes': habit.notes,
        'startDate': habit.startDate.toIso8601String(),
        if (habit.endDate != null) 'endDate': habit.endDate!.toIso8601String(),
        if (habit.category != null) 'categoryId': habit.category!.id,
        if (habit.unitId != null) 'unitId': habit.unitId,
        'frequencyType': habit.frequency.toUpperCase(),
        if (habit.targetValue != null) 'targetValue': habit.targetValue,
        if (habit.value != null) 'value': habit.value,
        'isLocationLocked': habit.isLocationLocked,
        if (habit.locationName != null) 'locationName': habit.locationName,
        if (habit.targetLat != null) 'targetLat': habit.targetLat,
        if (habit.targetLong != null) 'targetLong': habit.targetLong,
        if (habit.radius != null) 'radius': habit.radius,
      };

      final response = await _client.post(
        Uri.parse('$baseUrl/habits'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized. Please login again.');
      } else {
        throw AuthException(
          _extractErrorMessage(response.body, 'Failed to create habit'),
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> updateHabit(
    int habitId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final body = {'id': habitId, ...updates};

      final response = await _client.patch(
        Uri.parse('$baseUrl/habits'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized. Please login again.');
      } else if (response.statusCode == 403) {
        throw AuthException('Forbidden to update this habit');
      } else if (response.statusCode == 404) {
        throw AuthException('Habit not found');
      } else {
        throw AuthException(
          _extractErrorMessage(response.body, 'Failed to update habit'),
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> deleteHabit(int habitId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/habits'),
        headers: _headers,
        body: jsonEncode({'id': habitId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized. Please login again.');
      } else if (response.statusCode == 403) {
        throw AuthException('Forbidden to delete this habit');
      } else if (response.statusCode == 404) {
        throw AuthException('Habit not found');
      } else {
        throw AuthException(
          _extractErrorMessage(response.body, 'Failed to delete habit'),
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> toggleHabitLog(
    int habitId, {
    double? currentLat,
    double? currentLong,
  }) async {
    try {
      final body = {
        if (currentLat != null) 'currentLat': currentLat,
        if (currentLong != null) 'currentLong': currentLong,
      };

      final response = await _client.patch(
        Uri.parse('$baseUrl/habits/$habitId/logs'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized. Please login again.');
      } else {
        throw AuthException(
          _extractErrorMessage(response.body, 'Failed to toggle habit log'),
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getUserCategories(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/$userId/categories'),
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
            'Failed to get categories: ${response.statusCode}',
          ),
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> createCategory(
    String name, {
    String? description,
  }) async {
    try {
      final body = {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      };

      final response = await _client.post(
        Uri.parse('$baseUrl/categories'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized. Please login again.');
      } else {
        throw AuthException(
          _extractErrorMessage(response.body, 'Failed to create category'),
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> updateCategory(
    int id, {
    String? name,
    String? description,
  }) async {
    try {
      final body = {
        'id': id,
        if (name != null && name.isNotEmpty) 'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      };

      final response = await _client.patch(
        Uri.parse('$baseUrl/categories'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw AuthException('Category not found');
      } else {
        throw AuthException(
          _extractErrorMessage(response.body, 'Failed to update category'),
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> deleteCategory(int id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/categories'),
        headers: _headers,
        body: jsonEncode({'id': id}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw AuthException('Category not found');
      } else {
        throw AuthException(
          _extractErrorMessage(response.body, 'Failed to delete category'),
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
        Uri.parse('$baseUrl/units'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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

  Future<Map<String, dynamic>> getHabitLogs({required int habitId}) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/habits/$habitId/logs'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw AuthException('Unauthorized. Please login again.');
      } else {
        throw AuthException(
          _extractErrorMessage(response.body, 'Failed to get habit logs'),
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
