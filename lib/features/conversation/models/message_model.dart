import 'package:purewill/core/utils/indonesia_timezone.dart';
class MessageModel {
  final String id;
  final String conversationId;
  final String role; 
  final String content;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['createdAt'];

    return MessageModel(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      role: json['role'] as String? ?? 'USER',
      content: json['content'] as String? ?? '',
      createdAt: createdAtValue is String
          ? parseUtcToIndonesia(createdAtValue)
          : nowInIndonesia(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'role': role,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  bool get isUserMessage => role == 'USER';
  bool get isAssistantMessage => role == 'ASSISTANT';
}

class MessageResponseModel {
  final MessageModel userMessage;
  final MessageModel assistantMessage;

  MessageResponseModel({
    required this.userMessage,
    required this.assistantMessage,
  });

  factory MessageResponseModel.fromJson(Map<String, dynamic> json) {
    return MessageResponseModel(
      userMessage: MessageModel.fromJson(
        json['userMessage'] as Map<String, dynamic>,
      ),
      assistantMessage: MessageModel.fromJson(
        json['assistantMessage'] as Map<String, dynamic>,
      ),
    );
  }
}
