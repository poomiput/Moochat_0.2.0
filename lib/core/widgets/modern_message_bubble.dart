import 'package:flutter/material.dart';
import 'package:moochat/core/theming/colors.dart';

/// Modern Message Bubble with updated color scheme
///
/// Features:
/// - Clean, minimal design with subtle shadows
/// - Modern color palette with pink rose primary and emerald secondary
/// - Smooth rounded corners with asymmetric bubble shapes
/// - Better contrast and accessibility
class ModernMessageBubble extends StatelessWidget {
  const ModernMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    this.isConsecutive = false,
    this.senderName,
  });

  final String message;
  final bool isMe;
  final String timestamp;
  final bool isConsecutive;
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        top: isConsecutive ? 4.0 : 12.0,
        bottom: 4.0,
        left: isMe ? 64.0 : 16.0,
        right: isMe ? 16.0 : 64.0,
      ),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Sender name for group chats
          if (!isConsecutive && senderName != null && !isMe)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
              child: Text(
                senderName!,
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: ColorsManager.onSurfaceVariant,
                ),
              ),
            ),

          // Message bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isMe ? ColorsManager.primary : ColorsManager.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20.0),
                topRight: const Radius.circular(20.0),
                bottomLeft: Radius.circular(isMe ? 20.0 : 6.0),
                bottomRight: Radius.circular(isMe ? 6.0 : 20.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message text
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w400,
                    color: isMe ? Colors.white : ColorsManager.onSurface,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 6.0),

                // Timestamp
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timestamp,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: isMe
                            ? Colors.white.withOpacity(0.8)
                            : ColorsManager.onSurfaceVariant,
                      ),
                    ),

                    // Delivery status for sent messages
                    if (isMe) ...[
                      const SizedBox(width: 4.0),
                      Icon(
                        Icons.done_all,
                        size: 16.0,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
