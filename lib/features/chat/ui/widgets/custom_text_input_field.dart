import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/helpers/logger_debug.dart';
import 'package:moochat/core/helpers/shared_prefences.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/styles.dart';

import 'package:moochat/features/chat/data/enums/message_status.dart';
import 'package:moochat/features/chat/data/enums/message_type.dart';
import 'package:moochat/features/chat/data/models/chat_message_model.dart';
import 'package:moochat/features/chat/services/image_service.dart';
import 'package:moochat/core/services/video_service.dart';
import 'package:moochat/features/chat/services/voice_service_simple.dart';
import 'package:moochat/features/chat/ui/widgets/attachment_options.dart';
// import 'package:location/location.dart'; // Temporarily commented out
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomTextInputField extends ConsumerStatefulWidget {
  const CustomTextInputField({super.key, this.onSendMessage, this.uuid2P});
  final Function(ChatMessage chatMessage)? onSendMessage;
  final String? uuid2P;

  @override
  ConsumerState<CustomTextInputField> createState() =>
      _CustomTextInputFieldState();
}

class _CustomTextInputFieldState extends ConsumerState<CustomTextInputField> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();

  bool _hasText = false;
  bool _showEmojiPicker = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _textController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  // TODO: Temporarily commented out - Location functionality
  /*
  void _sendLocation(LocationData locationData) async {
    LoggerDebug.logger.i(
      'Location: Latitude: ${locationData.latitude}, Longitude: ${locationData.longitude}',
    );
    final myUUID = await SharedPrefHelper.getString('uuid');
    final myUsername = await SharedPrefHelper.getString('username');
    // call onSendMessage callback if provided
    final ChatMessage locationMessage = ChatMessage(
      text:
          'https://www.google.com/maps/search/?api=1&query=${locationData.latitude},${locationData.longitude}',
      isSentByMe: true,
      status: MessageStatus.delivered,
      type: MessageType.location,
      username2P: myUsername ?? 'Unknown',
      uuid2P: myUUID ?? '',
    );
    widget.onSendMessage!(locationMessage);
    // Create a message with the location data
  }
  */

  void _sendImage(File imageFile) async {
    LoggerDebug.logger.i('Sending image: ${imageFile.path}');
    final myUUID = await SharedPrefHelper.getString('uuid');
    final myUsername = await SharedPrefHelper.getString('username');

    // Convert image to Base64 for transmission
    final String? base64Image = await ImageService.imageToBase64(
      imageFile.path,
    );

    if (base64Image == null) {
      LoggerDebug.logger.e('Failed to convert image to Base64');
      return;
    }

    // Create image message using the image constructor with Base64 data
    final ChatMessage imageMessage = ChatMessage.image(
      imagePath: imageFile.path, // Keep local path for sender
      isSentByMe: true,
      status: MessageStatus.delivered,
      username2P: myUsername ?? 'Unknown',
      uuid2P: myUUID ?? '',
    );

    // Store Base64 data in the message text field for transmission
    final ChatMessage transmissionMessage = ChatMessage(
      id: imageMessage.id,
      text: base64Image, // Base64 image data
      isSentByMe: true,
      timestamp: imageMessage.timestamp,
      status: MessageStatus.sending,
      type: MessageType.image,
      username2P: myUsername ?? 'Unknown',
      uuid2P: myUUID ?? '',
    );

    // Call onSendMessage callback with LOCAL image message (sender sees image)
    widget.onSendMessage?.call(imageMessage);
  }

  void _sendVoice(File voiceFile) async {
    LoggerDebug.logger.i('Sending voice: ${voiceFile.path}');
    final myUUID = await SharedPrefHelper.getString('uuid');
    final myUsername = await SharedPrefHelper.getString('username');

    // Convert voice to Base64 for transmission
    final String? base64Voice = await VoiceServiceSimple.voiceToBase64(
      voiceFile.path,
    );

    if (base64Voice == null) {
      LoggerDebug.logger.e('Failed to convert voice to Base64');
      return;
    }

    // Create voice message with local path for display (sender hears voice)
    final ChatMessage localVoiceMessage = ChatMessage.voice(
      voicePath: voiceFile.path, // Local path for sender to hear voice
      isSentByMe: true,
      status: MessageStatus.sending,
      username2P: myUsername ?? 'Unknown',
      uuid2P: myUUID ?? '',
    );

    // Call onSendMessage callback with LOCAL voice message (sender hears voice)
    widget.onSendMessage?.call(localVoiceMessage);
  }

  void _sendVideo(File videoFile) async {
    LoggerDebug.logger.i('Sending video: ${videoFile.path}');
    final myUUID = await SharedPrefHelper.getString('uuid');
    final myUsername = await SharedPrefHelper.getString('username');

    // Check video size first
    final double videoSizeMB = await VideoService.getVideoSizeMB(
      videoFile.path,
    );
    if (videoSizeMB > 50) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Video too large (${videoSizeMB.toStringAsFixed(1)}MB). Max size is 50MB.',
            ),
          ),
        );
      }
      return;
    }

    // Save video to app directory for consistent storage
    final String? savedPath = await VideoService.saveVideoToAppDirectory(
      videoFile,
      'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );
    if (savedPath == null) {
      LoggerDebug.logger.e('Failed to save video to app directory');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to process video')),
        );
      }
      return;
    }

    // Create video message with local path for display (sender sees video)
    final ChatMessage localVideoMessage = ChatMessage.video(
      videoPath: savedPath, // Use saved path for sender to see video
      isSentByMe: true,
      status: MessageStatus.sending,
      username2P: myUsername ?? 'Unknown',
      uuid2P: myUUID ?? '',
    );

    // Call onSendMessage callback with LOCAL video message (sender sees video)
    // The Base64 conversion and transmission will be handled in chat_screen.dart
    widget.onSendMessage?.call(localVideoMessage);
  }

  void _sendMessage() async {
    if (_hasText) {
      final myUUID = await SharedPrefHelper.getString('uuid');
      final myUsername = await SharedPrefHelper.getString('username');
      final message = _textController.text.trim();
      // TODO: Add your send message logic here
      print('Sending message: $message');
      final ChatMessage chatMessage = ChatMessage(
        text: message,
        isSentByMe: true,
        status: MessageStatus.delivered,
        type: MessageType.text,
        username2P: myUsername ?? 'Unknown',
        uuid2P: myUUID ?? '',
      );
      // call function to handle sending message
      widget.onSendMessage?.call(chatMessage);

      // Clear the input field
      _textController.clear();

      // Remove focus and hide emoji picker
      //      _focusNode.unfocus();
      if (_showEmojiPicker) {
        setState(() {
          _showEmojiPicker = false;
        });
      }
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });

    if (_showEmojiPicker) {
      // Hide keyboard when showing emoji picker
      _focusNode.unfocus();
    } else {
      // Show keyboard when hiding emoji picker
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Input field
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: ColorsManager.customGray.withOpacity(1),
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Row(
            children: [
              // Attachment button
              Container(
                margin: EdgeInsets.only(left: 4.w, right: 8.w),
                child: IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: Colors.white.withOpacity(0.7),
                    size: 24.sp,
                  ),
                  onPressed: () {
                    _showAttachmentOptions();
                  },
                  splashRadius: 24.r,
                ),
              ),
              // Text input field
              Expanded(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: 20.h,
                    maxHeight: 120.h,
                  ),
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    cursorWidth: 2.5.w,
                    cursorColor: ColorsManager.whiteColor,
                    cursorRadius: Radius.circular(2.r),
                    cursorOpacityAnimates: true,
                    focusNode: _focusNode,
                    style: CustomTextStyles.font16WhiteRegular.copyWith(
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: context.tr("write_message"),
                      hintStyle: CustomTextStyles.font16WhiteRegular.copyWith(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    onTap: () {
                      // Hide emoji picker when tapping on text field
                      if (_showEmojiPicker) {
                        setState(() {
                          _showEmojiPicker = false;
                        });
                      }
                    },
                  ),
                ),
              ),
              // Emoji button
              Container(
                margin: EdgeInsets.only(right: 4.w),
                child: IconButton(
                  icon: Icon(
                    _showEmojiPicker
                        ? Icons.keyboard
                        : Icons.emoji_emotions_outlined,
                    color: _showEmojiPicker
                        ? ColorsManager.customGreen
                        : Colors.white.withOpacity(0.7),
                    size: 24.sp,
                  ),
                  onPressed: _toggleEmojiPicker,
                  splashRadius: 24.r,
                ),
              ),
              // Voice/Send button with animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(left: 4.w, right: 4.w),
                decoration: BoxDecoration(
                  color: _hasText
                      ? ColorsManager.customGreen
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: _hasText
                      ? [
                          BoxShadow(
                            color: ColorsManager.customGreen.withOpacity(0.3),
                            blurRadius: 8.r,
                            offset: Offset(0, 2.h),
                          ),
                        ]
                      : [],
                ),
                child: IconButton(
                  icon: Icon(
                    _hasText
                        ? Icons.send_rounded
                        : _isRecording
                        ? Icons.stop
                        : Icons.mic,
                    color: _isRecording ? Colors.red : Colors.white,
                    size: 20.sp,
                  ),
                  onPressed: _hasText ? _sendMessage : _recordVoice,
                  splashRadius: 24.r,
                ),
              ),
            ],
          ),
        ),
        // Emoji Picker (Official API)
        if (_showEmojiPicker)
          SizedBox(
            height: 250.h,
            child: EmojiPicker(
              textEditingController: _textController,
              onBackspacePressed: () {
                // Handle backspace button press
                _textController
                  ..text = _textController.text.characters
                      .skipLast(1)
                      .toString()
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: _textController.text.length),
                  );
              },
              config: Config(
                height: 250.h,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  emojiSizeMax:
                      28.sp *
                      (foundation.defaultTargetPlatform ==
                              TargetPlatform.android
                          ? 1.20
                          : 1.0),
                  backgroundColor: ColorsManager.backgroundColor,
                  columns: 7,
                  verticalSpacing: 0,
                  horizontalSpacing: 0,
                  recentsLimit: 28,
                  replaceEmojiOnLimitExceed: false,
                  noRecents: Text(
                    'No Recents',
                    style: CustomTextStyles.font16WhiteRegular.copyWith(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 20.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  loadingIndicator: const SizedBox.shrink(),
                  buttonMode: ButtonMode.MATERIAL,
                ),
                viewOrderConfig: const ViewOrderConfig(
                  top: EmojiPickerItem.categoryBar,
                  middle: EmojiPickerItem.emojiView,
                  bottom: EmojiPickerItem.searchBar,
                ),
                skinToneConfig: SkinToneConfig(
                  dialogBackgroundColor: ColorsManager.backgroundColor,
                  indicatorColor: Colors.white.withOpacity(0.5),
                ),
                categoryViewConfig: CategoryViewConfig(
                  tabBarHeight: 46.h,
                  tabIndicatorAnimDuration: const Duration(milliseconds: 300),
                  initCategory: Category.RECENT,
                  backgroundColor: ColorsManager.backgroundColor,
                  indicatorColor: ColorsManager.customGreen,
                  iconColor: Colors.white.withOpacity(0.7),
                  iconColorSelected: ColorsManager.customGreen,
                  backspaceColor: ColorsManager.customGreen,
                  categoryIcons: const CategoryIcons(),
                  extraTab: CategoryExtraTab.NONE,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  showBackspaceButton: true,
                  showSearchViewButton: true,
                  backgroundColor: ColorsManager.backgroundColor,
                  buttonColor: Colors.white.withOpacity(0.1),
                  buttonIconColor: Colors.white.withOpacity(0.7),
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: ColorsManager.backgroundColor,
                  buttonIconColor: Colors.white.withOpacity(0.7),
                  hintText: 'Search emoji',
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showAttachmentOptions() {
    // Hide emoji picker when showing attachments
    if (_showEmojiPicker) {
      setState(() {
        _showEmojiPicker = false;
      });
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: ColorsManager.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => AttachmentOptions(
        // onLocationSelected: _sendLocation, // Temporarily commented out
        onImageSelected: _sendImage,
        onVideoSelected: _sendVideo,
      ),
    );
  }

  void _recordVoice() async {
    try {
      if (_isRecording) {
        // Stop recording
        setState(() {
          _isRecording = false;
        });

        String? voicePath = await VoiceServiceSimple.stopRecording();

        if (voicePath != null) {
          File voiceFile = File(voicePath);
          _sendVoice(voiceFile);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr("failed_to_save_voice"))),
            );
          }
        }
      } else {
        // Start recording
        bool hasPermission =
            await VoiceServiceSimple.checkMicrophonePermission();

        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr("microphone_permission_required")),
              ),
            );
          }
          return;
        }

        bool started = await VoiceServiceSimple.startRecording();

        if (started) {
          setState(() {
            _isRecording = true;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr("failed_to_record_voice"))),
            );
          }
        }
      }
    } catch (e) {
      LoggerDebug.logger.e('Error in voice recording: $e');
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr("failed_to_record_voice"))),
        );
      }
    }
  }
}
