import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import 'package:moochat/core/theming/colors.dart';

class VideoPlayerScreen extends StatefulWidget {
  final File videoFile;

  const VideoPlayerScreen({super.key, required this.videoFile});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isLoading = true;
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
          // Top bar with close button
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
