import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<List<ChatMessage>> getAllMessages();
  Future<void> saveMessage(ChatMessage message);
  Future<void> deleteMessage(String id);
  Future<void> clearAllMessages();
  Stream<List<ChatMessage>> watchMessages();
  Future<List<ChatMessage>> getMessagesByAdType(String adType);
  Future<ChatMessage?> getMessageById(String id);
  Future<void> updateMessage(ChatMessage message);
  Future<List<ChatMessage>> getRecentMessages({int limit = 50});
}

