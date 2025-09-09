import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/advertisement.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../core/errors/exceptions.dart';

enum ChatState {
  idle,
  loading,
  streaming,
  error,
}

class ChatProvider extends ChangeNotifier {
  final SendMessageUseCase _sendMessageUseCase;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  ChatProvider(this._sendMessageUseCase) {
    // Load initial history and subscribe to repository updates so that
    // any saved messages (user or AI) are reflected immediately.
    _loadChatHistory();
    _messagesSubscription = _sendMessageUseCase.watchMessages().listen((messages) {
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _messages = messages;
      notifyListeners();
    });
  }

  // State
  ChatState _state = ChatState.idle;
  List<ChatMessage> _messages = [];
  String? _errorMessage;
  AdType? _selectedAdType;
  String _currentStreamingMessage = '';
  bool _isStreaming = false;

  // Getters
  ChatState get state => _state;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String? get errorMessage => _errorMessage;
  AdType? get selectedAdType => _selectedAdType;
  String get currentStreamingMessage => _currentStreamingMessage;
  bool get isStreaming => _isStreaming;
  bool get isLoading => _state == ChatState.loading;

  // Methods
  void setSelectedAdType(AdType? adType) {
    _selectedAdType = adType;
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    try {
      _setState(ChatState.loading);
      _clearError();

      final context = _selectedAdType != null 
          ? {'adType': _selectedAdType!.value}
          : null;

      await _sendMessageUseCase.execute(
        content: content,
        adType: _selectedAdType?.value,
        context: context,
      );

      await _loadChatHistory();
      _setState(ChatState.idle);
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setState(ChatState.error);
    }
  }

  Future<void> sendMessageStream(String content) async {
    if (content.trim().isEmpty) return;

    try {
      _setState(ChatState.streaming);
      _clearError();
      _currentStreamingMessage = '';
      _isStreaming = true;

      final context = _selectedAdType != null 
          ? {'adType': _selectedAdType!.value}
          : null;

      // Persist user message immediately so the user's bubble shows right away
      // while the AI reply is streaming.
      final userMessage = await _sendMessageUseCase.saveUserMessage(
        content: content,
        adType: _selectedAdType?.value,
        context: context,
      );

      // Add to in-memory list and notify UI immediately.
      _messages.add(userMessage);
      notifyListeners();

      // Start streaming AI response without preloading the chat history.
      // This ensures the user's message is not immediately shown in the
      // messages list — it will appear only after the AI response completes
      // and we reload the history. Meanwhile we show a streaming placeholder
      // with the partial AI content.
      final stream = _sendMessageUseCase.executeStream(
        content: content,
        adType: _selectedAdType?.value,
        context: context,
        userMessage: userMessage,
      );

      await for (final chunk in stream) {
        _currentStreamingMessage += chunk;
        notifyListeners();
      }

      // Streaming finished: clear temporary streaming state and reload
      // the chat history so the user's message and the final AI message
      // are both shown from the persisted store.
      _isStreaming = false;
      _currentStreamingMessage = '';

      // Small delay to ensure DB writes (if any) complete before reloading.
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadChatHistory();

      _setState(ChatState.idle);
    } catch (e) {
      _isStreaming = false;
      _currentStreamingMessage = '';
      _setError(_getErrorMessage(e));
      _setState(ChatState.error);
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _sendMessageUseCase.deleteMessage(messageId);
      await _loadChatHistory();
    } catch (e) {
      _setError(_getErrorMessage(e));
    }
  }

  Future<void> clearChatHistory() async {
    try {
      await _sendMessageUseCase.clearChatHistory();
      _messages.clear();
      notifyListeners();
    } catch (e) {
      _setError(_getErrorMessage(e));
    }
  }

  Future<void> loadChatHistoryByAdType(AdType adType) async {
    try {
      _setState(ChatState.loading);
      final messages = await _sendMessageUseCase.getChatHistoryByAdType(adType.value);
      _messages = messages;
      _setState(ChatState.idle);
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setState(ChatState.error);
    }
  }

  Future<void> refreshChatHistory() async {
    await _loadChatHistory();
  }

  void clearError() {
    _clearError();
  }

  // Private methods
  Future<void> _loadChatHistory() async {
    try {
      final messages = await _sendMessageUseCase.getChatHistory();
      // Ensure messages are in chronological order (oldest first) so the newest
      // message appears at the bottom of the ListView and auto-scroll works.
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _messages = messages;
      notifyListeners();
    } catch (e) {
      _setError(_getErrorMessage(e));
    }
  }

  void _setState(ChatState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is NetworkException) {
      return 'No internet connection. Please check your connection and try again.';
    } else if (error is ApiException) {
      return 'Server error: ${error.message}';
    } else if (error is DatabaseException) {
      return 'Database error: ${error.message}';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
