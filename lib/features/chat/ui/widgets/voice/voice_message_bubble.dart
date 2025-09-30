import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/styles.dart';
import 'package:moochat/features/chat/data/models/chat_message_model.dart';
import 'package:moochat/features/chat/data/enums/message_status.dart';
import 'package:moochat/features/chat/services/voice_service_simple.dart';

class VoiceMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool showAvatar;

  const VoiceMessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  bool _isPlaying = false;
  Duration? _duration;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVoiceDuration();
  }

  Future<void> _loadVoiceDuration() async {
    final duration = await VoiceServiceSimple.getVoiceDuration(
      widget.message.text,
    );
    if (mounted) {
      setState(() {
        _duration = duration;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.message.isSentByMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
          minWidth: 200.w,
        ),
        child: Column(
          crossAxisAlignment: widget.message.isSentByMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Voice container
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: widget.message.isSentByMe
                    ? ColorsManager.primary.withOpacity(0.1)
                    : ColorsManager.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft: widget.message.isSentByMe
                      ? Radius.circular(16.r)
                      : Radius.circular(4.r),
                  bottomRight: widget.message.isSentByMe
                      ? Radius.circular(4.r)
                      : Radius.circular(16.r),
                ),
                border: Border.all(
                  color: widget.message.isSentByMe
                      ? ColorsManager.primary.withOpacity(0.3)
                      : ColorsManager.outline,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Voice player controls
                  _buildVoicePlayer(),

                  SizedBox(height: 8.h),

                  // Timestamp and status
                  _buildMetadata(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoicePlayer() {
    // Check if the voice file exists
    final File voiceFile = File(widget.message.text);

    if (!voiceFile.existsSync()) {
      return _buildErrorWidget();
    }

    return Row(
      children: [
        // Play/Pause button
        _buildPlayButton(),

        SizedBox(width: 12.w),

        // Voice wave visualization (simple bars)
        Expanded(child: _buildVoiceWave()),

        SizedBox(width: 12.w),

        // Duration
        _buildDuration(),
      ],
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _togglePlayback,
      child: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: widget.message.isSentByMe
              ? ColorsManager.primary
              : ColorsManager.primary.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: _isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.message.isSentByMe ? Colors.white : Colors.white,
                  ),
                ),
              )
            : Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: widget.message.isSentByMe ? Colors.white : Colors.white,
                size: 20.sp,
              ),
      ),
    );
  }

  Widget _buildVoiceWave() {
    // Simple voice wave representation with bars
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(15, (index) {
        final heights = List.generate(
          7,
          (heightIndex) => 0.3 + (heightIndex * 0.05) % 0.7,
        ); // Random wave heights between 0.3-1.0
        return Container(
          width: 2.w,
          height: (heights[index % heights.length] * 30).h,
          decoration: BoxDecoration(
            color: widget.message.isSentByMe
                ? ColorsManager.primary.withOpacity(0.7)
                : ColorsManager.outline,
            borderRadius: BorderRadius.circular(1.r),
          ),
        );
      }),
    );
  }

  Widget _buildDuration() {
    String durationText = '0:00';
    if (_duration != null) {
      int minutes = _duration!.inMinutes;
      int seconds = _duration!.inSeconds % 60;
      durationText = '$minutes:${seconds.toString().padLeft(2, '0')}';
    }

    return Text(
      durationText,
      style: CustomTextStyles.font12WhiteRegular.copyWith(
        color: widget.message.isSentByMe
            ? Colors.white.withOpacity(0.8)
            : ColorsManager.onSurfaceVariant,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Row(
      children: [
        Icon(Icons.error_outline, size: 20.sp, color: ColorsManager.error),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            'Voice message not found',
            style: CustomTextStyles.font14WhiteRegular.copyWith(
              color: ColorsManager.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadata() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          _formatTime(widget.message.timestamp),
          style: CustomTextStyles.font12WhiteRegular.copyWith(
            color: ColorsManager.onSurfaceVariant,
          ),
        ),
        if (widget.message.isSentByMe) ...[
          SizedBox(width: 4.w),
          Icon(_getStatusIcon(), size: 16.sp, color: _getStatusColor()),
        ],
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  IconData _getStatusIcon() {
    switch (widget.message.status) {
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
    switch (widget.message.status) {
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

  Future<void> _togglePlayback() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isPlaying) {
        await VoiceServiceSimple.stopPlaying();
        setState(() {
          _isPlaying = false;
        });
      } else {
        bool success = await VoiceServiceSimple.playVoice(widget.message.text);
        if (success) {
          setState(() {
            _isPlaying = true;
          });

          // Listen for playback completion
          // Note: In a real implementation, you'd want to use a more robust
          // state management approach or stream subscription
          _checkPlaybackStatus();
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkPlaybackStatus() {
    // Check if this specific file is still playing
    // In a production app, you'd use proper stream subscriptions
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _isPlaying) {
        // Check if our file is still the one being played
        bool stillPlaying =
            VoiceServiceSimple.isPlaying &&
            VoiceServiceSimple.currentPlayingPath == widget.message.text;

        if (!stillPlaying) {
          setState(() {
            _isPlaying = false;
          });
        } else {
          _checkPlaybackStatus(); // Continue checking
        }
      }
    });
  }
}
