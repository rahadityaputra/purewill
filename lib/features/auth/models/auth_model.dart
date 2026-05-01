class RegisterRequest {
  final String email;
  final String username;
  final String fullname;
  final String gender;
  final DateTime birthDate;
  final String password;
  final String passwordConfirmation;

  RegisterRequest({
    required this.email,
    required this.username,
    required this.fullname,
    required this.gender,
    required this.birthDate,
    required this.password,
    required this.passwordConfirmation,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'username': username,
    'fullname': fullname,
    'gender': gender,
    'birthDate': birthDate.toIso8601String(),
    'password': password,
    'passwordConfirmation': passwordConfirmation,
  };
}

class UserData {
  final int id;
  final String email;
  final String username;

  UserData({required this.id, required this.email, required this.username});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      email: json['email'],
      username: json['username'],
    );
  }
}

class AuthException implements Exception {
  final String message;
  final Map<String, List<String>>? errors;

  AuthException(this.message, {Map<String, dynamic>? errors})
    : errors = _normalizeErrors(errors);

  factory AuthException.fromResponse(
    Map<String, dynamic> response, {
    String fallbackMessage = 'Request failed',
  }) {
    return AuthException(
      response['message']?.toString() ?? fallbackMessage,
      errors: response['errors'] as Map<String, dynamic>?,
    );
  }

  static Map<String, List<String>>? _normalizeErrors(
    Map<String, dynamic>? errors,
  ) {
    if (errors == null || errors.isEmpty) {
      return null;
    }

    final normalized = <String, List<String>>{};

    for (final entry in errors.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      final messages = <String>[];

      if (value is Iterable) {
        for (final item in value) {
          final message = item?.toString().trim();
          if (message != null && message.isNotEmpty) {
            messages.add(message);
          }
        }
      } else if (value != null) {
        final message = value.toString().trim();
        if (message.isNotEmpty) {
          messages.add(message);
        }
      }

      if (messages.isNotEmpty) {
        normalized[key] = messages;
      }
    }

    return normalized.isEmpty ? null : normalized;
  }

  String get formattedMessage {
    if (errors == null || errors!.isEmpty) {
      return message;
    }

    final lines = <String>[message];

    for (final entry in errors!.entries) {
      final field = _formatFieldName(entry.key);
      for (final error in entry.value) {
        lines.add('- $field: $error');
      }
    }

    return lines.join('\n');
  }

  static String _formatFieldName(String field) {
    final normalized = field.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    if (normalized.isEmpty) {
      return field;
    }

    return normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  @override
  String toString() => formattedMessage;
}
