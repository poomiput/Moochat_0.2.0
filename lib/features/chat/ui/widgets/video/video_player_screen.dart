import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/helpers/logger_debug.dart' as logger;
import 'package:moochat/core/helpers/shared_prefences.dart';
import 'package:moochat/core/shared/providers/managing_bluetooth_state_privder.dart';
import 'package:moochat/features/chat/data/enums/message_status.dart';
import 'package:moochat/features/chat/data/enums/message_type.dart';
import 'package:moochat/features/chat/data/models/chat_message_model.dart';
import 'package:moochat/core/services/video_service.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final File videoFile;
  final String? uuid2P; // UUID ของผู้รับที่จะส่งวิดีโอไป
  final Function(ChatMessage)? onSendMessage; // Callback สำหรับส่งข้อความ

  const VideoPlayerScreen({
    super.key,
    required this.videoFile,
    this.uuid2P,
    this.onSendMessage,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isLoading = true;
  bool _isSending = false; // เพิ่มตัวแปรสำหรับสถานะการส่ง
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      // Check if file exists first
      if (!widget.videoFile.existsSync()) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Video file not found';
        });
        return;
      }

      print('Initializing video player for: ${widget.videoFile.path}');
      _controller = VideoPlayerController.file(widget.videoFile);

      // Add listener for player state changes
      _controller!.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _controller!.value.isPlaying;
          });
        }
      });

      await _controller!.initialize();
      print('Video player initialized successfully');

      setState(() {
        _isLoading = false;
      });

      // Auto-hide controls after 3 seconds
      _hideControlsAfterDelay();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load video: ${e.toString()}';
      });
      print('Video player error: $e');
    }
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _togglePlayPause() {
    print('_togglePlayPause called');
    print('Controller is null: ${_controller == null}');
    print(
      'Controller initialized: ${_controller?.value.isInitialized ?? false}',
    );
    print('Current playing state: ${_controller?.value.isPlaying ?? false}');

    if (_controller != null && _controller!.value.isInitialized) {
      try {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
          print('✅ Video paused successfully');
        } else {
          _controller!.play();
          print('✅ Video started playing successfully');
        }
        // Reset controls hide timer
        _hideControlsAfterDelay();
      } catch (e) {
        print('❌ Error toggling play/pause: $e');
      }
    } else {
      print('❌ Cannot toggle play/pause - controller not ready');
    }
  }

  void _toggleControls() {
    print('Controls toggled. Show controls: ${!_showControls}');
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // ฟังก์ชั่นส่งวิดีโอผ่าน Bluetooth
  Future<void> _sendVideo() async {
    if (widget.uuid2P == null) {
      _showSnackBar('ไม่สามารถส่งได้: ไม่พบผู้รับ', isError: true);
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      logger.LoggerDebug.logger.i(
        'Starting to send video: ${widget.videoFile.path}',
      );

      // ตรวจสอบและบีบอัดวิดีโอถ้าจำเป็น
      final double originalSizeMB = await VideoService.getVideoSizeMB(
        widget.videoFile.path,
      );

      logger.LoggerDebug.logger.i(
        'Original video size: ${originalSizeMB.toStringAsFixed(1)}MB',
      );

      // บีบอัดวิดีโอถ้าจำเป็น
      File processedVideoFile = await VideoService.compressVideo(
        widget.videoFile,
      );

      final double finalSizeMB = await VideoService.getVideoSizeMB(
        processedVideoFile.path,
      );

      logger.LoggerDebug.logger.i(
        'Final video size: ${finalSizeMB.toStringAsFixed(1)}MB',
      );

      // แสดงข้อมูลการบีบอัด
      if (originalSizeMB != finalSizeMB) {
        _showSnackBar(
          'บีบอัดวิดีโอสำเร็จ: ${originalSizeMB.toStringAsFixed(1)}MB → ${finalSizeMB.toStringAsFixed(1)}MB',
          isError: false,
        );
      }

      // แปลงวิดีโอเป็น Base64
      final String? base64Video = await VideoService.videoToBase64(
        processedVideoFile.path,
      );
      if (base64Video == null) {
        _showSnackBar('ไม่สามารถแปลงวิดีโอได้', isError: true);
        return;
      }

      // สร้าง ChatMessage สำหรับวิดีโอ
      final myUUID = await SharedPrefHelper.getString('uuid');
      final myUsername = await SharedPrefHelper.getString('username');

      final ChatMessage videoMessage = ChatMessage.video(
        videoPath: widget.videoFile.path,
        isSentByMe: true,
        status: MessageStatus.sending,
        username2P: myUsername ?? 'Unknown',
        uuid2P: myUUID ?? '',
      );

      // เพิ่มข้อความในแชทก่อน (ให้ผู้ส่งเห็น)
      if (widget.onSendMessage != null) {
        widget.onSendMessage!(videoMessage);
      }

      // ส่งผ่าน Bluetooth
      final bluetoothProvider = ref.read(nearbayStateProvider.notifier);
      final isConnected = bluetoothProvider.isUserConnected(widget.uuid2P!);

      if (!isConnected) {
        _showSnackBar('ไม่ได้เชื่อมต่อกับผู้รับ', isError: true);
        return;
      }

      final device = bluetoothProvider.getConnectedDeviceByUsername(
        widget.uuid2P!,
      );
      if (device == null) {
        _showSnackBar('ไม่พบอุปกรณ์ผู้รับ', isError: true);
        return;
      }

      // สร้าง payload สำหรับส่ง
      final messagePayload = {
        'id': videoMessage.id,
        'text': base64Video, // ส่ง Base64 string
        'timestamp': videoMessage.timestamp.toIso8601String(),
        'type': MessageType.video.toString(),
        'senderUsername': myUUID,
      };

      final jsonMessage = jsonEncode(messagePayload);
      logger.LoggerDebug.logger.i('Sending video message to ${device.id}');

      final sendResult = await bluetoothProvider.sendMessageToDevice(
        device.id,
        jsonMessage,
      );

      if (sendResult) {
        _showSnackBar('ส่งวิดีโอสำเร็จ');
        // กลับไปหน้าแชทหลังส่งสำเร็จ
        Navigator.of(context).pop();
      } else {
        _showSnackBar('ส่งวิดีโอไม่สำเร็จ', isError: true);
      }
    } catch (e) {
      logger.LoggerDebug.logger.e('Error sending video: $e');
      _showSnackBar('เกิดข้อผิดพลาด: $e', isError: true);
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            children: [
              // Video Player
              Center(child: _buildVideoPlayer()),

              // Controls Overlay
              if (_showControls) _buildControlsOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.white),
            SizedBox(height: 16.h),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_controller != null && _controller!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildControlsOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Column(
        children: [
          // Top bar with close button and send button
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      print('Back button tapped');
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: EdgeInsets.all(8.w),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
                const Spacer(),

                // ปุ่มส่งวิดีโอ (แสดงเฉพาะเมื่อมี uuid2P)
                if (widget.uuid2P != null && !_isSending)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _sendVideo,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: ColorsManager.primary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.send, color: Colors.white, size: 20.sp),
                            SizedBox(width: 4.w),
                            Text(
                              'ส่ง',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // แสดง loading indicator เมื่อกำลังส่ง
                if (_isSending)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16.w,
                          height: 16.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'กำลังส่ง...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (widget.uuid2P != null) SizedBox(width: 8.w),

                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      print('Fullscreen button tapped');
                      // Toggle fullscreen orientation
                      if (MediaQuery.of(context).orientation ==
                          Orientation.portrait) {
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.landscapeLeft,
                          DeviceOrientation.landscapeRight,
                        ]);
                      } else {
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.portraitUp,
                        ]);
                      }
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: EdgeInsets.all(8.w),
                      child: Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Center play/pause button
          Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  print('Play/Pause button tapped');
                  _togglePlayPause();
                },
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 48.sp,
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Bottom controls
          if (_controller != null && _controller!.value.isInitialized)
            _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Progress bar
          VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: ColorsManager.primary,
              bufferedColor: Colors.white.withOpacity(0.3),
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
          SizedBox(height: 8.h),

          // Time indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_controller!.value.position),
                style: TextStyle(color: Colors.white, fontSize: 12.sp),
              ),
              Text(
                _formatDuration(_controller!.value.duration),
                style: TextStyle(color: Colors.white, fontSize: 12.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
