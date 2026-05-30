import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/features/conversation/services/conversation_repository.dart';
import 'package:purewill/features/conversation/services/conversation_api_service.dart';
import 'package:purewill/features/conversation/models/conversation_model.dart';
import 'package:purewill/features/conversation/models/message_model.dart';
import 'package:purewill/features/auth/providers/auth_provider.dart';

final conversationApiServiceProvider = Provider<ConversationApiService>((ref) {
  final client = ref.watch(httpClientProvider);
  final service = ConversationApiService(client: client);
  final authService = ref.watch(authServiceProvider);
  if (authService.accessToken != null) {
    service.setAccessToken(authService.accessToken!);
  }
  return service;
});

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  final apiService = ref.watch(conversationApiServiceProvider);
  return ConversationRepository(apiService);
});

final conversationsProvider = FutureProvider<List<ConversationModel>>((
  ref,
) async {
  final repository = ref.watch(conversationRepositoryProvider);
  return repository.getConversations();
});

final conversationDetailProvider =
    FutureProvider.family<ConversationModel, String>((
      ref,
      conversationId,
    ) async {
      final repository = ref.watch(conversationRepositoryProvider);
      return repository.getConversationDetail(conversationId);
    });

final conversationMessagesProvider =
    FutureProvider.family<List<MessageModel>, String>((
      ref,
      conversationId,
    ) async {
      final repository = ref.watch(conversationRepositoryProvider);
      return repository.getMessages(conversationId: conversationId);
    });

class ConversationNotifier extends AsyncNotifier<List<ConversationModel>> {
  late ConversationRepository _repository;

  @override
  Future<List<ConversationModel>> build() async {
    _repository = ref.watch(conversationRepositoryProvider);
    return await _repository.getConversations();
  }

  Future<ConversationModel?> createConversation({String? title}) async {
    try {
      final conversation = await _repository.createConversation(title: title);
      await refresh();

      return conversation;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }

  Future<bool> deleteConversation(String conversationId) async {
    try {
      await _repository.deleteConversation(conversationId);
      await refresh();

      return true;
    } catch (e) {
      debugPrint(e.toString());
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getConversations());
  }
}

final conversationNotifierProvider =
    AsyncNotifierProvider<ConversationNotifier, List<ConversationModel>>(
      ConversationNotifier.new,
    );

class ConversationMessagesNotifier extends AsyncNotifier<List<MessageModel>> {
  late ConversationRepository _repository;
  late String _conversationId;

  @override
  Future<List<MessageModel>> build() async {
    _repository = ref.watch(conversationRepositoryProvider);
    return await _repository.getMessages(conversationId: _conversationId);
  }

  void setConversationId(String conversationId) {
    _conversationId = conversationId;
  }

  Future<bool> sendMessage(String content) async {
    try {
      final response = await _repository.sendMessage(
        conversationId: _conversationId,
        content: content,
      );
      final currentMessages = state.maybeWhen(
        data: (messages) => messages,
        orElse: () => <MessageModel>[],
      );

      final updatedMessages = [
        ...currentMessages,
        response.userMessage,
        response.assistantMessage,
      ];

      state = AsyncValue.data(updatedMessages);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getMessages(conversationId: _conversationId),
    );
  }
}

final conversationMessagesNotifierProvider =
    AsyncNotifierProvider.family<
      ConversationMessagesNotifier,
      List<MessageModel>,
      String
    >(
      (conversationId) =>
          ConversationMessagesNotifier()..setConversationId(conversationId),
    );
