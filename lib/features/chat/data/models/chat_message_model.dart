import 'package:moochat/features/chat/data/enums/message_status.dart';
import 'package:moochat/features/chat/data/enums/message_type.dart';
import 'package:uuid/uuid.dart';

import 'package:json_annotation/json_annotation.dart';
part 'chat_message_model.g.dart';
// using uuid for id generation

@JsonSerializable()
class ChatMessage {
  final String id;
  final String text;
  final bool isSentByMe;
  final DateTime timestamp;
  final MessageStatus status;
  final MessageType type;
  final String username2P;
  final String uuid2P;

  ChatMessage({
    String? id,
    required this.text,
    required this.isSentByMe,
    DateTime? timestamp,
    this.status = MessageStatus.sending,
    this.type = MessageType.text,
    required this.username2P,
    required this.uuid2P,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  // Named constructor for image messages
  ChatMessage.image({
    String? id,
    required String imagePath,
    String caption = '',
    required this.isSentByMe,
    DateTime? timestamp,
    this.status = MessageStatus.sending,
    required this.username2P,
    required this.uuid2P,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now(),
       text = imagePath, // Store image path in text field
       type = MessageType.image;

  // Named constructor for voice messages
  ChatMessage.voice({
    String? id,
    required String voicePath,
    required this.isSentByMe,
    DateTime? timestamp,
    this.status = MessageStatus.sending,
    required this.username2P,
    required this.uuid2P,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now(),
       text = voicePath, // Store voice path in text field
       type = MessageType.voice;

  // Named constructor for video messages
  ChatMessage.video({
    String? id,
    required String videoPath,
    required this.isSentByMe,
    DateTime? timestamp,
    this.status = MessageStatus.sending,
    required this.username2P,
    required this.uuid2P,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now(),
       text = videoPath, // Store video path in text field
       type = MessageType.video;
  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}
