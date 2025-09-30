import 'package:flutter/material.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/widgets/modern_message_bubble.dart';
import 'package:moochat/core/widgets/modern_chat_input_bar.dart';
import 'package:moochat/core/widgets/modern_user_avatar.dart';
import 'package:moochat/core/widgets/modern_dialog.dart';

/// Example screen showcasing the new modern UI components
///
/// This demonstrates how to use the updated color scheme and components:
/// - ModernMessageBubble for chat messages
/// - ModernChatInputBar for message input
/// - ModernUserAvatar for user profiles
/// - ModernDialog for alerts and confirmations
class ModernUIShowcase extends StatefulWidget {
  const ModernUIShowcase({super.key});

  @override
  State<ModernUIShowcase> createState() => _ModernUIShowcaseState();
}

class _ModernUIShowcaseState extends State<ModernUIShowcase> {
  final List<Message> _messages = [
    Message(
      text: "Hey! Check out the new modern design 🎨",
      isFromCurrentUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      senderName: "Alex",
    ),
    Message(
      text:
          "Wow, this looks amazing! The new pink rose and emerald colors are so clean and professional.",
      isFromCurrentUser: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      senderName: "You",
    ),
    Message(
      text:
          "I love the subtle shadows and rounded corners. Much more modern than before!",
      isFromCurrentUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      senderName: "Alex",
    ),
    Message(
      text:
          "The dark theme works perfectly with these colors. Great choice! 👍",
      isFromCurrentUser: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      senderName: "You",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.backgroundColor,
      appBar: AppBar(
        backgroundColor: ColorsManager.surface,
        elevation: 0,
        title: Row(
          children: [
            const ModernUserAvatar(
              name: "Alex Johnson",
              isOnline: true,
              showOnlineStatus: true,
              radius: 24.0,
            ),
            const SizedBox(width: 12.0),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alex Johnson',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: ColorsManager.onSurface,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: ColorsManager.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: ColorsManager.onSurfaceVariant,
            ),
            onPressed: () => _showInfoDialog(),
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: ColorsManager.onSurfaceVariant,
            ),
            onPressed: () => _showMoreOptions(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onLongPress: () => _showMessageOptions(message),
                    child: ModernMessageBubble(
                      message: message.text,
                      isMe: message.isFromCurrentUser,
                      timestamp: _formatTimestamp(message.timestamp),
                      senderName: message.senderName,
                    ),
                  ),
                );
              },
            ),
          ),

          // Chat input
          ModernChatInputBar(
            onSendMessage: _sendMessage,
            onAttachmentTap: _showAttachmentOptions,
            hintText: 'Type your message...',
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    setState(() {
      _messages.add(
        Message(
          text: text,
          isFromCurrentUser: true,
          timestamp: DateTime.now(),
          senderName: "You",
        ),
      );
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  void _showInfoDialog() {
    ModernDialogUtils.showInfo(
      context: context,
      title: 'Modern UI Showcase',
      message:
          'This demo showcases the new modern color palette with pink rose primary, emerald secondary, and professional dark backgrounds. The design emphasizes clean lines, subtle shadows, and improved accessibility.',
    );
  }

  void _showMoreOptions() {
    ModernDialog.show(
      context: context,
      title: 'Chat Options',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              Icons.palette_outlined,
              color: ColorsManager.primary,
            ),
            title: const Text(
              'Theme Settings',
              style: TextStyle(color: ColorsManager.onSurface),
            ),
            onTap: () {
              Navigator.pop(context);
              _showThemeInfo();
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.notifications_outlined,
              color: ColorsManager.secondary,
            ),
            title: const Text(
              'Notifications',
              style: TextStyle(color: ColorsManager.onSurface),
            ),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(
              Icons.security_outlined,
              color: ColorsManager.onSurfaceVariant,
            ),
            title: const Text(
              'Privacy',
              style: TextStyle(color: ColorsManager.onSurface),
            ),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
      actions: [
        ModernDialogButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _showThemeInfo() {
    ModernDialog.show(
      context: context,
      title: 'Modern Color Palette',
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ColorSwatch(
            color: ColorsManager.primary,
            name: 'Primary (Pink Rose)',
            description: 'Main brand color for buttons and highlights',
          ),
          SizedBox(height: 16.0),
          _ColorSwatch(
            color: ColorsManager.secondary,
            name: 'Secondary (Emerald)',
            description:
                'Accent color for success states and secondary actions',
          ),
          SizedBox(height: 16.0),
          _ColorSwatch(
            color: ColorsManager.surface,
            name: 'Surface',
            description: 'Cards, dialogs, and elevated surfaces',
          ),
          SizedBox(height: 16.0),
          _ColorSwatch(
            color: ColorsManager.backgroundColor,
            name: 'Background',
            description: 'Main app background',
          ),
        ],
      ),
      actions: [
        ModernDialogButton(
          onPressed: () => Navigator.pop(context),
          variant: ModernButtonVariant.filled,
          child: const Text('Got it!'),
        ),
      ],
    );
  }

  void _showMessageOptions(Message message) {
    ModernDialogUtils.showConfirmation(
      context: context,
      title: 'Message Options',
      message: 'What would you like to do with this message?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed) {
        setState(() {
          _messages.remove(message);
        });
      }
    });
  }

  void _showAttachmentOptions() {
    ModernDialog.show(
      context: context,
      title: 'Send Attachment',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              Icons.photo_outlined,
              color: ColorsManager.primary,
            ),
            title: const Text(
              'Photo',
              style: TextStyle(color: ColorsManager.onSurface),
            ),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(
              Icons.videocam_outlined,
              color: ColorsManager.secondary,
            ),
            title: const Text(
              'Video',
              style: TextStyle(color: ColorsManager.onSurface),
            ),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(
              Icons.insert_drive_file_outlined,
              color: ColorsManager.onSurfaceVariant,
            ),
            title: const Text(
              'Document',
              style: TextStyle(color: ColorsManager.onSurface),
            ),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
      actions: [
        ModernDialogButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.name,
    required this.description,
  });

  final Color color;
  final String name;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32.0,
          height: 32.0,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: ColorsManager.outline.withOpacity(0.3)),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ColorsManager.onSurface,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12.0,
                  color: ColorsManager.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class Message {
  final String text;
  final bool isFromCurrentUser;
  final DateTime timestamp;
  final String senderName;

  Message({
    required this.text,
    required this.isFromCurrentUser,
    required this.timestamp,
    required this.senderName,
  });
}
