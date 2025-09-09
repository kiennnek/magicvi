import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/chat_message.dart';

part 'chat_message_model.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class ChatMessageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final bool isUser;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String? adType;

  @HiveField(5)
  final Map<String, dynamic>? metadata;

  ChatMessageModel({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.adType,
    this.metadata,
  });

  // Convert from Entity to Model
  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      content: entity.content,
      isUser: entity.isUser,
      timestamp: entity.timestamp,
      adType: entity.adType,
      metadata: entity.metadata,
    );
  }

  // Convert from Model to Entity
  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      content: content,
      isUser: isUser,
      timestamp: timestamp,
      adType: adType,
      metadata: metadata,
    );
  }

  // JSON serialization
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageModelToJson(this);

  ChatMessageModel copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    String? adType,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      adType: adType ?? this.adType,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'ChatMessageModel(id: $id, content: $content, isUser: $isUser, timestamp: $timestamp, adType: $adType)';
  }
}

