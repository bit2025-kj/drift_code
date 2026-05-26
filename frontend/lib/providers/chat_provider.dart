import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:nafa_edu/models/chat_model.dart';

// ── Read-only providers ───────────────────────────────────────────────────────

final conversationsListProvider = FutureProvider<List<ConversationThread>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.conversations);
  return (res.data as List)
      .map((j) => ConversationThread.fromJson(j as Map<String, dynamic>))
      .toList();
});

final conversationDetailProvider =
    FutureProvider.family<ConversationDetail, String>((ref, threadId) async {
  final res = await ApiClient.instance.dio.get(
    ApiEndpoints.conversation(threadId),
  );
  return ConversationDetail.fromJson(res.data as Map<String, dynamic>);
});

// ── Chat state ────────────────────────────────────────────────────────────────

class ChatState {
  final bool isLoading;
  final String? error;
  final String? currentThreadId;
  final List<ChatMessage> messages;
  final List<ChatDocument> documents;

  const ChatState({
    this.isLoading = false,
    this.error,
    this.currentThreadId,
    this.messages = const [],
    this.documents = const [],
  });

  ChatState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? currentThreadId,
    List<ChatMessage>? messages,
    List<ChatDocument>? documents,
  }) =>
      ChatState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        currentThreadId: currentThreadId ?? this.currentThreadId,
        messages: messages ?? this.messages,
        documents: documents ?? this.documents,
      );
}

// ── ChatNotifier ──────────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(const ChatState());

  Future<void> createConversation(String title, {String? description}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiClient.instance.dio.post(
        ApiEndpoints.conversations,
        data: {'title': title, if (description != null) 'description': description},
      );
      final thread = ConversationThread.fromJson(res.data as Map<String, dynamic>);
      state = state.copyWith(
        isLoading: false,
        currentThreadId: thread.id,
        messages: [],
        documents: [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> loadConversation(String threadId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiClient.instance.dio.get(
        ApiEndpoints.conversation(threadId),
      );
      final detail = ConversationDetail.fromJson(res.data as Map<String, dynamic>);
      state = state.copyWith(
        isLoading: false,
        currentThreadId: threadId,
        messages: detail.messages,
        documents: detail.documents,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> sendMessage(String content, {String? documentId}) async {
    if (state.currentThreadId == null) return;
    final threadId = state.currentThreadId!;

    final userMsg = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: content,
      documentId: documentId,
      createdAt: DateTime.now(),
    );
    final withUser = [...state.messages, userMsg];
    state = state.copyWith(isLoading: true, clearError: true, messages: withUser);

    try {
      final res = await ApiClient.instance.dio.post(
        ApiEndpoints.sendMessage(threadId),
        data: {'content': content, if (documentId != null) 'document_id': documentId},
      );
      final reply = (res.data['reply'] as String?) ?? 'Erreur de génération';
      final messageId =
          (res.data['message_id'] as String?) ?? 'msg_${DateTime.now().millisecondsSinceEpoch}';
      final assistantMsg = ChatMessage(
        id: messageId,
        role: 'assistant',
        content: reply,
        createdAt: DateTime.now(),
      );
      state = state.copyWith(isLoading: false, messages: [...withUser, assistantMsg]);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> uploadDocument(String threadId, String filePath) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  String _parseError(dynamic e) {
    try {
      final data = (e as dynamic).response?.data;
      if (data is Map && data['detail'] != null) return data['detail'].toString();
    } catch (_) {}
    return "Erreur lors de l'opération";
  }
}

final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) => ChatNotifier());
