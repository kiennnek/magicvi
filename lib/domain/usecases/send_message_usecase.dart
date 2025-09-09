import 'package:uuid/uuid.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';
import '../../data/datasources/remote/gemini_api_service.dart';
import '../../core/errors/exceptions.dart';

class SendMessageUseCase {
  final ChatRepository _chatRepository;
  final GeminiApiService _geminiApiService;
  final Uuid _uuid = const Uuid();

  SendMessageUseCase(this._chatRepository, this._geminiApiService);

  // Persist a user message separately so UI can show it immediately before streaming.
  Future<ChatMessage> saveUserMessage({
    required String content,
    String? adType,
    Map<String, dynamic>? context,
  }) async {
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
      adType: adType,
      metadata: context,
    );

    try {
      await _chatRepository.saveMessage(userMessage);
      return userMessage;
    } catch (e) {
      throw DatabaseException('Failed to save user message: $e');
    }
  }

  Future<ChatMessage> execute({
    required String content,
    String? adType,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Save user message
      final userMessage = ChatMessage(
        id: _uuid.v4(),
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
        adType: adType,
        metadata: context,
      );

      await _chatRepository.saveMessage(userMessage);

      // Generate AI response
      final aiResponse = await _geminiApiService.generateContent(
        prompt: content,
        adType: adType,
        context: context,
      );

      // Save AI message
      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
        adType: adType,
        metadata: {
          'response_to': userMessage.id,
          ...?context,
        },
      );

      await _chatRepository.saveMessage(aiMessage);

      return aiMessage;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ApiException('Failed to send message: $e');
    }
  }

  Stream<String> executeStream({
    required String content,
    String? adType,
    Map<String, dynamic>? context,
    ChatMessage? userMessage,
  }) async* {
    try {
      // If userMessage wasn't provided, create and save it now so the UI
      // can show the user's bubble immediately before streaming begins.
      if (userMessage == null) {
        userMessage = ChatMessage(
          id: _uuid.v4(),
          content: content,
          isUser: true,
          timestamp: DateTime.now(),
          adType: adType,
          metadata: context,
        );

        await _chatRepository.saveMessage(userMessage);
      }

      // Generate AI response stream
      final responseStream = await _geminiApiService.generateContentStream(
        prompt: content,
        adType: adType,
        context: context,
      );

      final responseBuffer = StringBuffer();

      await for (final chunk in responseStream) {
        if (chunk.isNotEmpty) {
          responseBuffer.write(chunk);
          yield chunk;
        }
      }

      // If streaming yielded content, save AI message (user already saved).
      if (responseBuffer.isNotEmpty) {
        final aiMessage = ChatMessage(
          id: _uuid.v4(),
          content: responseBuffer.toString(),
          isUser: false,
          timestamp: DateTime.now(),
          adType: adType,
          metadata: {
            'response_to': userMessage.id,
            'streaming': true,
            ...?context,
          },
        );

        // Persist user first, then AI so ordering is consistent.
        await _chatRepository.saveMessage(aiMessage);
      } else {
        // Fallback: if stream produced nothing, call non-streaming generateContent
        try {
          final aiResponse = await _geminiApiService.generateContent(
            prompt: content,
            adType: adType,
            context: context,
          );

          if (aiResponse.isNotEmpty) {
            // Yield the full response so UI can display streaming bubble content
            yield aiResponse;

            final aiMessage = ChatMessage(
              id: _uuid.v4(),
              content: aiResponse,
              isUser: false,
              timestamp: DateTime.now(),
              adType: adType,
              metadata: {
                'response_to': userMessage.id,
                'streaming': false,
                ...?context,
              },
            );

            // Persist both messages
            await _chatRepository.saveMessage(aiMessage);
          }
        } catch (e) {
          // If fallback fails, rethrow to be handled by caller
          if (e is AppException) rethrow;
          throw ApiException('Failed to get fallback AI response: $e');
        }
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ApiException('Failed to send streaming message: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _chatRepository.deleteMessage(messageId);
    } catch (e) {
      throw DatabaseException('Failed to delete message: $e');
    }
  }

  Future<void> clearChatHistory() async {
    try {
      await _chatRepository.clearAllMessages();
    } catch (e) {
      throw DatabaseException('Failed to clear chat history: $e');
    }
  }

  Future<List<ChatMessage>> getChatHistory({int limit = 50}) async {
    try {
      return await _chatRepository.getRecentMessages(limit: limit);
    } catch (e) {
      throw DatabaseException('Failed to get chat history: $e');
    }
  }

  Future<List<ChatMessage>> getChatHistoryByAdType(String adType) async {
    try {
      return await _chatRepository.getMessagesByAdType(adType);
    } catch (e) {
      throw DatabaseException('Failed to get chat history by ad type: $e');
    }
  }

  // Expose repository stream for real-time updates
  Stream<List<ChatMessage>> watchMessages() {
    return _chatRepository.watchMessages();
  }
}
