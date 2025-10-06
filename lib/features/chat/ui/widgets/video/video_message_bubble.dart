import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/styles.dart';
import 'package:moochat/features/chat/data/models/chat_message_model.dart';
import 'package:moochat/features/chat/data/enums/message_status.dart';
import 'package:moochat/features/chat/ui/widgets/video/video_player_screen.dart';

class VideoMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;
  final String? uuid2P; // เพิ่ม uuid2P สำหรับการส่งวิดีโอ
  final Function(ChatMessage)? onSendMessage; // เพิ่ม callback สำหรับส่งข้อความ

  const VideoMessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
    this.uuid2P,
    this.onSendMessage,
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
            // Video container
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
                    // Video thumbnail/player
                    _buildVideoWidget(context),

                    // Metadata (timestamp and status)
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

  Widget _buildVideoWidget(BuildContext context) {
    return GestureDetector(
      onTap: () => _playVideo(context),
      child: Container(height: 200.h, child: _buildVideoContent()),
    );
  }

  Widget _buildVideoContent() {
    // Check if the video path exists
    final File videoFile = File(message.text);

    if (videoFile.existsSync()) {
      return Container(
        color: Colors.black.withOpacity(0.8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video thumbnail placeholder
            Icon(
              Icons.video_library,
              size: 60.sp,
              color: Colors.white.withOpacity(0.8),
            ),
            // Play button overlay
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.6),
              ),
              padding: EdgeInsets.all(12.w),
              child: Icon(Icons.play_arrow, size: 40.sp, color: Colors.white),
            ),
            // Video info at bottom
            Positioned(
              bottom: 8.h,
              right: 8.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  "VIDEO",
                  style: CustomTextStyles.font16WhiteRegular.copyWith(
                    fontSize: 12.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 200.h,
      color: ColorsManager.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48.sp, color: ColorsManager.error),
          SizedBox(height: 8.h),
          Text(
            "Video not found",
            style: CustomTextStyles.font16WhiteRegular.copyWith(
              color: ColorsManager.error,
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // File size info (optional)
          Text(
            _getVideoInfo(),
            style: CustomTextStyles.font16WhiteRegular.copyWith(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          // Timestamp and status
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.timestamp),
                style: CustomTextStyles.font16WhiteRegular.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12.sp,
                ),
              ),
              if (message.isSentByMe) ...[
                SizedBox(width: 4.w),
                _buildMessageStatus(message.status),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageStatus(MessageStatus status) {
    IconData iconData;
    Color iconColor;

    switch (status) {
      case MessageStatus.sending:
        iconData = Icons.access_time;
        iconColor = Colors.grey;
        break;
      case MessageStatus.sent:
        iconData = Icons.done;
        iconColor = Colors.grey;
        break;
      case MessageStatus.delivered:
        iconData = Icons.done_all;
        iconColor = Colors.grey;
        break;
      case MessageStatus.read:
        iconData = Icons.done_all;
        iconColor = ColorsManager.primary;
        break;
    }

    return Icon(iconData, size: 16.sp, color: iconColor);
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  String _getVideoInfo() {
    final File videoFile = File(message.text);
    if (videoFile.existsSync()) {
      final int sizeInBytes = videoFile.lengthSync();
      final double sizeInMB = sizeInBytes / (1024 * 1024);
      return "${sizeInMB.toStringAsFixed(1)} MB";
    }
    return "";
  }

  void _playVideo(BuildContext context) {
    final File videoFile = File(message.text);

    print('Attempting to play video: ${message.text}');
    print('Video file exists: ${videoFile.existsSync()}');

    if (videoFile.existsSync()) {
      print('Video file size: ${videoFile.lengthSync()} bytes');
    }

    if (!videoFile.existsSync()) {
      print('Video file not found at path: ${message.text}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Video not found at: ${message.text}"),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      // Open full-screen video player
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            videoFile: videoFile,
            uuid2P: uuid2P, // ส่ง uuid2P ของผู้รับ
            onSendMessage: onSendMessage, // ส่ง callback
          ),
        ),
      );
    } catch (e) {
      print('Error opening video player: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error opening video player: $e"),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
