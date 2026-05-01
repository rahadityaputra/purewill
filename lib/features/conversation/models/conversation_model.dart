import 'package:intl/intl.dart';
import 'package:purewill/core/utils/indonesia_timezone.dart';

class ConversationModel {
  final String id;
  final String userId;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConversationModel({
    required this.id,
    required this.userId,
    this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['createdAt'];
    final updatedAtValue = json['updatedAt'];

    return ConversationModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String?,
      createdAt: createdAtValue is String
          ? parseUtcToIndonesia(createdAtValue)
          : nowInIndonesia(),
      updatedAt: updatedAtValue is String
          ? parseUtcToIndonesia(updatedAtValue)
          : nowInIndonesia(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  String get displayTitle =>
      title?.isEmpty ?? true ? 'New Conversation' : title!;

  String getFormattedDate() {
    final now = nowInIndonesia();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      updatedAt.year,
      updatedAt.month,
      updatedAt.day,
    );

    if (messageDate == today) {
      return DateFormat('HH:mm').format(updatedAt);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(updatedAt).inDays < 7) {
      return DateFormat('EEE').format(updatedAt);
    } else {
      return DateFormat('dd/MM/yy').format(updatedAt);
    }
  }
}



