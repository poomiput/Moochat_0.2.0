import 'package:flutter/material.dart';
import 'package:moochat/core/theming/colors.dart';

/// Modern Chat Input Bar with updated design
///
/// Features:
/// - Clean, elevated surface design
/// - Modern rounded corners with subtle shadow
/// - Pink rose primary color for send button
/// - Better contrast and spacing
/// - Smooth animations and interactions
class ModernChatInputBar extends StatefulWidget {
  const ModernChatInputBar({
    super.key,
    required this.onSendMessage,
    this.onAttachmentTap,
    this.hintText = 'Type a message...',
  });

  final Function(String) onSendMessage;
  final VoidCallback? onAttachmentTap;
  final String hintText;

  @override
  State<ModernChatInputBar> createState() => _ModernChatInputBarState();
}

class _ModernChatInputBarState extends State<ModernChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.trim().isNotEmpty;
    });
  }

  void _sendMessage() {
    if (_hasText) {
      widget.onSendMessage(_controller.text.trim());
      _controller.clear();
      setState(() {
        _hasText = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: ColorsManager.backgroundColor,
        border: Border(
          top: BorderSide(color: ColorsManager.outline, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            if (widget.onAttachmentTap != null)
              Container(
                margin: const EdgeInsets.only(right: 12.0),
                child: Material(
                  color: ColorsManager.surface,
                  borderRadius: BorderRadius.circular(24.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24.0),
                    onTap: widget.onAttachmentTap,
                    child: Container(
                      width: 48.0,
                      height: 48.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline,
                        color: ColorsManager.onSurfaceVariant,
                        size: 24.0,
                      ),
                    ),
                  ),
                ),
              ),

            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: ColorsManager.surface,
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: ColorsManager.onSurface,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(
                      color: ColorsManager.onSurfaceVariant,
                      fontSize: 16.0,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 12.0,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),

            const SizedBox(width: 12.0),

            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: _hasText ? ColorsManager.primary : ColorsManager.surface,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: _hasText
                    ? [
                        BoxShadow(
                          color: ColorsManager.primary.withOpacity(0.3),
                          blurRadius: 8.0,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24.0),
                  onTap: _hasText ? _sendMessage : null,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: _hasText
                          ? Colors.white
                          : ColorsManager.onSurfaceVariant,
                      size: 20.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
