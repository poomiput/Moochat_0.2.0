import 'dart:async';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moochat/core/helpers/logger_debug.dart';
import 'package:moochat/core/shared/providers/managing_bluetooth_state_privder.dart';
import 'package:moochat/features/chat/data/enums/message_status.dart';
import 'package:moochat/features/chat/data/enums/message_type.dart';
import 'package:moochat/features/chat/data/models/chat_message_model.dart';
import 'package:moochat/features/chat/services/image_service.dart';
import 'package:moochat/core/services/video_service.dart';
import 'package:moochat/features/chat/services/voice_service_simple.dart';
import 'package:moochat/features/home/providrs/user_data_provider.dart';
import 'package:moochat/features/home/services/notifications_service.dart';

// Provider to handle incoming Bluetooth messages
final messageHandlerProvider = Provider<MessageHandler>((ref) {
  return MessageHandler(ref);
});

class MessageHandler {
  final Ref ref;
  StreamSubscription<Map<String, String>>? _messageSubscription;

  MessageHandler(this.ref) {
    _initializeMessageListener();
  }

  void _initializeMessageListener() {
    final bluetoothState = ref.read(nearbayStateProvider);

    if (bluetoothState.messageStream != null) {
      _messageSubscription = bluetoothState.messageStream!.listen(
        (messageData) {
          _handleIncomingMessage(messageData);
        },
        onError: (error) {
          LoggerDebug.logger.e('Error listening to messages: $error');
        },
      );
    }
  }

  void _handleIncomingMessage(Map<String, String> messageData) async {
    try {
      final String senderId = messageData['senderId'] ?? '';
      final String rawMessage = messageData['message'] ?? '';

      LoggerDebug.logger.d('Processing message from $senderId: $rawMessage');

      // Decode the message properly for UTF-8 support
      Map<String, dynamic> messageJson;

      try {
        // First, try to decode as base64 (if you're using base64 encoding)
        List<int> decodedBytes = base64Decode(rawMessage);
        String decodedString = utf8.decode(decodedBytes);
        messageJson = jsonDecode(decodedString);
      } catch (e) {
        // Fallback to direct JSON decode (for backward compatibility)
        try {
          messageJson = jsonDecode(rawMessage);
        } catch (e2) {
          // If direct decode fails, try UTF-8 decode first
          List<int> messageBytes = rawMessage.codeUnits;
          String utf8String = utf8.decode(messageBytes, allowMalformed: true);
          messageJson = jsonDecode(utf8String);
        }
      }

      LoggerDebug.logger.f('Decoded message test: $messageJson');

      // Extract message details
      final String messageId = messageJson['id'] ?? '';
      final String text = messageJson['text'] ?? '';
      final String timestampStr = messageJson['timestamp'] ?? '';
      final String typeStr = messageJson['type'] ?? 'MessageType.text';
      final String senderUsername = messageJson['senderUsername'] ?? '';
      final String senderUuid = senderId;

      // Parse timestamp
      DateTime timestamp;
      try {
        timestamp = DateTime.parse(timestampStr);
      } catch (e) {
        timestamp = DateTime.now();
      }

      // Parse message type
      MessageType messageType = MessageType.text;
      try {
        messageType = MessageType.values.firstWhere(
          (type) => type.toString() == typeStr,
          orElse: () => MessageType.text,
        );
      } catch (e) {
        messageType = MessageType.text;
      }

      // Handle image messages - convert Base64 to local file
      String finalText = text;
      if (messageType == MessageType.image && text.isNotEmpty) {
        try {
          // Save Base64 image to local file
          final String? savedImagePath = await ImageService.base64ToImage(
            text,
            fileName: 'received_${messageId}.jpg',
          );

          if (savedImagePath != null) {
            finalText = savedImagePath; // Use local path for display
            LoggerDebug.logger.i('Image saved to: $savedImagePath');
          } else {
            LoggerDebug.logger.e('Failed to save received image');
            finalText = 'Image not available'; // Fallback text
          }
        } catch (e) {
          LoggerDebug.logger.e('Error processing received image: $e');
          finalText = 'Image not available'; // Fallback text
        }
      } else if (messageType == MessageType.voice && text.isNotEmpty) {
        try {
          // Save Base64 voice to local file
          final String? savedVoicePath = await VoiceServiceSimple.base64ToVoice(
            text,
            fileName: 'received_${messageId}.aac',
          );

          if (savedVoicePath != null) {
            finalText = savedVoicePath; // Use local path for playback
            LoggerDebug.logger.i('Voice saved to: $savedVoicePath');
          } else {
            LoggerDebug.logger.e('Failed to save received voice');
            finalText = 'Voice not available'; // Fallback text
          }
        } catch (e) {
          LoggerDebug.logger.e('Error processing received voice: $e');
          finalText = 'Voice not available'; // Fallback text
        }
      } else if (messageType == MessageType.video && text.isNotEmpty) {
        try {
          // Save Base64 video to local file
          final String? savedVideoPath = await VideoService.base64ToVideo(
            text,
            'received_${messageId}.mp4',
          );

          if (savedVideoPath != null) {
            finalText = savedVideoPath; // Use local path for playback
            LoggerDebug.logger.i('Video saved to: $savedVideoPath');
          } else {
            LoggerDebug.logger.e('Failed to save received video');
            finalText = 'Video not available'; // Fallback text
          }
        } catch (e) {
          LoggerDebug.logger.e('Error processing received video: $e');
          finalText = 'Video not available'; // Fallback text
        }
      }

      // Create ChatMessage object
      final ChatMessage incomingMessage = ChatMessage(
        id: messageId,
        text: finalText, // Use processed text (media path or original text)
        isSentByMe: false,
        timestamp: timestamp,
        status: MessageStatus.delivered,
        type: messageType,
        username2P: senderUsername,
        uuid2P: senderUuid,
      );

      // Add message to the appropriate chat using sender's UUID (senderUsername)
      ref
          .read(userDataProvider.notifier)
          .addMessageToChat(senderUsername, incomingMessage);
      // show notification with the message and sender username
      // get the current user username
      final realUsernameSender = ref
          .read(userDataProvider.notifier)
          .getUsernameByUuid(senderUsername);
      LoggerDebug.logger.e('usernameSender: $senderId');
      NotificationService().showNotification(
        id: 2,
        // '⟟ ${orContext.tr("location")} check if type of message is location or not',
        title: realUsernameSender ?? 'Notify All Area Allert',
        body: incomingMessage.type == MessageType.location
            ? '⟟ ${tr("location")}'
            : incomingMessage.text,
      );

      LoggerDebug.logger.d(
        'Added incoming message to chat with $senderUsername: ${text.length} chars',
      );
    } catch (e) {
      LoggerDebug.logger.e('Error processing incoming message: $e');
    }
  }

  void dispose() {
    _messageSubscription?.cancel();
  }
}

// Provider to initialize message handling
final messageHandlerInitProvider = Provider<void>((ref) {
  final handler = ref.watch(messageHandlerProvider);

  // Clean up when provider is disposed
  ref.onDispose(() {
    handler.dispose();
  });

  return;
});
