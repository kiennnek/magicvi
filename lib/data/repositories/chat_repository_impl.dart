import 'dart:async';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/local/hive_database.dart';
import '../models/chat_message_model.dart';
import '../../core/errors/exceptions.dart';

class ChatRepositoryImpl implements ChatRepository {
  final StreamController<List<ChatMessage>> _messagesController = 
      StreamController<List<ChatMessage>>.broadcast();

  @override
  Future<List<ChatMessage>> getAllMessages() async {
    try {
      final models = HiveDatabase.getAllChatMessages();
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException('Failed to get all messages: $e');
    }
  }

  @override
  Future<void> saveMessage(ChatMessage message) async {
    try {
      final model = ChatMessageModel.fromEntity(message);
      await HiveDatabase.saveChatMessage(model);
      _notifyMessagesChanged();
    } catch (e) {
      throw DatabaseException('Failed to save message: $e');
    }
  }

  @override
  Future<void> deleteMessage(String id) async {
    try {
      await HiveDatabase.deleteChatMessage(id);
      _notifyMessagesChanged();
    } catch (e) {
      throw DatabaseException('Failed to delete message: $e');
    }
  }

  @override
  Future<void> clearAllMessages() async {
    try {
      await HiveDatabase.chatMessagesBox.clear();
      _notifyMessagesChanged();
    } catch (e) {
      throw DatabaseException('Failed to clear all messages: $e');
    }
  }

  @override
  Stream<List<ChatMessage>> watchMessages() {
    // Initial load
    getAllMessages().then((messages) {
      if (!_messagesController.isClosed) {
        _messagesController.add(messages);
      }
    });
    
    return _messagesController.stream;
  }

  @override
  Future<List<ChatMessage>> getMessagesByAdType(String adType) async {
    try {
      final allMessages = await getAllMessages();
      return allMessages
          .where((message) => message.adType == adType)
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to get messages by ad type: $e');
    }
  }

  @override
  Future<ChatMessage?> getMessageById(String id) async {
    try {
      final model = HiveDatabase.chatMessagesBox.get(id);
      return model?.toEntity();
    } catch (e) {
      throw DatabaseException('Failed to get message by id: $e');
    }
  }

  @override
  Future<void> updateMessage(ChatMessage message) async {
    try {
      final model = ChatMessageModel.fromEntity(message);
      await HiveDatabase.saveChatMessage(model);
      _notifyMessagesChanged();
    } catch (e) {
      throw DatabaseException('Failed to update message: $e');
    }
  }

  @override
  Future<List<ChatMessage>> getRecentMessages({int limit = 50}) async {
    try {
      final allMessages = await getAllMessages();
      allMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return allMessages.take(limit).toList();
    } catch (e) {
      throw DatabaseException('Failed to get recent messages: $e');
    }
  }

  void _notifyMessagesChanged() {
    getAllMessages().then((messages) {
      if (!_messagesController.isClosed) {
        _messagesController.add(messages);
      }
    });
  }

  void dispose() {
    _messagesController.close();
  }
}

