import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/styles.dart';
import 'package:moochat/features/chat/data/models/chat_message_model.dart';
import 'package:moochat/features/chat/data/enums/message_status.dart';
import 'package:moochat/features/chat/ui/widgets/image/image_viewer_dialog.dart';

class ImageMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;

  const ImageMessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isSentByMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
          minWidth: 200.w,
        ),
        child: Column(
          crossAxisAlignment: message.isSentByMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Image container
            Container(
              decoration: BoxDecoration(
                color: message.isSentByMe
                    ? ColorsManager.primary.withOpacity(0.1)
                    : ColorsManager.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft: message.isSentByMe
                      ? Radius.circular(16.r)
                      : Radius.circular(4.r),
                  bottomRight: message.isSentByMe
                      ? Radius.circular(4.r)
                      : Radius.circular(16.r),
                ),
                border: Border.all(
                  color: message.isSentByMe
                      ? ColorsManager.primary.withOpacity(0.3)
                      : ColorsManager.outline,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15.r),
                  topRight: Radius.circular(15.r),
                  bottomLeft: message.isSentByMe
                      ? Radius.circular(15.r)
                      : Radius.circular(3.r),
                  bottomRight: message.isSentByMe
                      ? Radius.circular(3.r)
                      : Radius.circular(15.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image
                    _buildImageWidget(context),

                    // Caption if exists
                    if (message.text.isNotEmpty) _buildCaption(),

                    // Timestamp and status
                    _buildMetadata(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullImage(context),
      child: Container(height: 200.h, child: _buildImageContent()),
    );
  }

  Widget _buildImageContent() {
    // Check if the image path exists
    final File imageFile = File(message.text);

    if (imageFile.existsSync()) {
      return Image.file(
        imageFile,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    } else {
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      color: ColorsManager.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 48.sp,
            color: ColorsManager.onSurfaceVariant,
          ),
          SizedBox(height: 8.h),
          Text(
            'Image not found',
            style: CustomTextStyles.font12WhiteRegular.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaption() {
    return Container(
      padding: EdgeInsets.all(12.w),
      child: Text(message.text, style: CustomTextStyles.font14WhiteRegular),
    );
  }

  Widget _buildMetadata() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            _formatTime(message.timestamp),
            style: CustomTextStyles.font12WhiteRegular.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
          ),
          if (message.isSentByMe) ...[
            SizedBox(width: 4.w),
            Icon(_getStatusIcon(), size: 16.sp, color: _getStatusColor()),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  IconData _getStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.done;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
    }
  }

  Color _getStatusColor() {
    switch (message.status) {
      case MessageStatus.sending:
        return ColorsManager.onSurfaceVariant;
      case MessageStatus.sent:
        return ColorsManager.onSurfaceVariant;
      case MessageStatus.delivered:
        return ColorsManager.onSurfaceVariant;
      case MessageStatus.read:
        return ColorsManager.primary;
    }
  }

  void _showFullImage(BuildContext context) {
    ImageViewerDialog.show(context, message.text);
  }
}
