import 'dart:developer';

import 'package:purewill/features/conversation/services/conversation_api_service.dart';
import 'package:purewill/features/auth/models/auth_model.dart';
import 'package:purewill/features/conversation/models/conversation_model.dart';
import 'package:purewill/features/conversation/models/message_model.dart';

class ConversationRepository {
  final ConversationApiService _apiService;

  ConversationRepository(this._apiService);

  Future<List<ConversationModel>> getConversations() async {
    try {
      return await _apiService.getConversations();
    } on AuthException {
      rethrow;
    } catch (e, stackTrace) {
      log(
        'FAILURE: Failed to get conversations',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Create a new conversation
  Future<ConversationModel> createConversation({String? title}) async {
    try {
      return await _apiService.createConversation(title: title);
    } on AuthException {
      rethrow;
    } catch (e, stackTrace) {
      log(
        'FAILURE: Failed to create conversation',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get conversation detail by ID
  Future<ConversationModel> getConversationDetail(String conversationId) async {
    try {
      return await _apiService.getConversationDetail(conversationId);
    } on AuthException {
      rethrow;
    } catch (e, stackTrace) {
      log(
        'FAILURE: Failed to get conversation detail',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete conversation by ID
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _apiService.deleteConversation(conversationId);
    } on AuthException {
      rethrow;
    } catch (e, stackTrace) {
      log(
        'FAILURE: Failed to delete conversation',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get messages for a conversation (with pagination support)
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    int limit = 10,
    String? cursor,
  }) async {
    try {
      return await _apiService.getMessages(
        conversationId: conversationId,
        limit: limit,
        cursor: cursor,
      );
    } on AuthException {
      rethrow;
    } catch (e, stackTrace) {
      log('FAILURE: Failed to get messages', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Send a message and get AI response
  Future<MessageResponseModel> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      return await _apiService.sendMessage(
        conversationId: conversationId,
        content: content,
      );
    } on AuthException {
      rethrow;
    } catch (e, stackTrace) {
      print(e.toString());
      log('FAILURE: Failed to send message', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
