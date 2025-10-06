import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/helpers/logger_debug.dart';
import 'package:moochat/core/theming/styles.dart';

import 'package:moochat/core/widgets/loading_animation.dart'; // Needed for photo loading animation
import 'package:moochat/features/chat/services/image_service.dart';
import 'package:moochat/core/services/video_service.dart';
import 'package:moochat/features/chat/ui/widgets/image/image_picker_dialog.dart';
// import 'package:location/location.dart'; // Temporarily commented out

class AttachmentOptions extends StatefulWidget {
  const AttachmentOptions({
    super.key,
    // this.onLocationSelected, // Temporarily commented out
    this.onImageSelected,
    this.onVideoSelected,
  });
  // final Function(LocationData)? onLocationSelected; // Temporarily commented out
  final Function(File)? onImageSelected;
  final Function(File)? onVideoSelected;

  @override
  State<AttachmentOptions> createState() => _AttachmentOptionsState();
}

class _AttachmentOptionsState extends State<AttachmentOptions> {
  // LocationData? _location; // Temporarily commented out
  // bool _isLoading = false; // Temporarily commented out
  bool _isImagePicking = false;
  bool _isVideoPicking = false;

  // TODO: Temporarily commented out - Location functionality
  /*
  void _getLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Location location = Location();

      bool serviceEnabled;
      PermissionStatus permissionGranted;

      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _isLoading = false;
          });
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location service is disabled')),
            );
          }
          return;
        }
      }

      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() {
            _isLoading = false;
          });
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      _location = await location.getLocation();

      // Call the callback if provided
      widget.onLocationSelected?.call(_location!);

      // Close the bottom sheet and return the location data
      if (mounted) {
        Navigator.pop(context, _location);
      }
    } catch (e) {
      LoggerDebug.logger.e('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to get location')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  */

  void _selectImage() async {
    setState(() {
      _isImagePicking = true;
    });

    try {
      final File? imageFile = await ImagePickerDialog.show(context);

      if (imageFile != null) {
        // Save image to app directory
        final String? savedPath = await ImageService.saveImageToAppDirectory(
          imageFile,
        );

        if (savedPath != null) {
          final File savedImageFile = File(savedPath);

          // Call the callback if provided
          widget.onImageSelected?.call(savedImageFile);

          // Close the bottom sheet and return the image file
          if (mounted) {
            Navigator.pop(context, savedImageFile);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr("failed_to_save_image"))),
            );
          }
        }
      }
    } catch (e) {
      LoggerDebug.logger.e('Error selecting image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr("failed_to_select_image"))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImagePicking = false;
        });
      }
    }
  }

  void _selectVideo() async {
    setState(() {
      _isVideoPicking = true;
    });

    try {
      final File? videoFile = await VideoService.pickVideoFromGallery();

      if (videoFile != null) {
        LoggerDebug.logger.i('Video selected: ${videoFile.path}');

        // Check video size
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

        // Call the callback if provided
        widget.onVideoSelected?.call(videoFile);

        // Close the bottom sheet and return the video file
        if (mounted) {
          Navigator.pop(context, videoFile);
        }
      }
    } catch (e) {
      LoggerDebug.logger.e('Error selecting video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr("failed_to_select_video"))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVideoPicking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 20.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          // Options
          ListTile(
            enabled: !_isImagePicking,
            leading: _isImagePicking
                ? SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: const CustomLoadingAnimation(size: 30),
                  )
                : const Icon(Icons.photo, color: Colors.white),
            title: Text(
              _isImagePicking
                  ? context.tr("selecting_image")
                  : context.tr("photo"),
              style: CustomTextStyles.font16WhiteRegular.copyWith(
                color: _isImagePicking
                    ? const Color.fromARGB(255, 255, 169, 222).withOpacity(
                        0.7,
                      ) //บิ้กแก้เป็นสีแปลก
                    : Colors.white,
              ),
            ),
            onTap: _isImagePicking ? null : _selectImage,
          ),
          ListTile(
            leading: _isVideoPicking
                ? SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: const CustomLoadingAnimation(size: 30),
                  )
                : const Icon(Icons.videocam, color: Colors.white),
            title: Text(
              context.tr("video"),
              style: CustomTextStyles.font16WhiteRegular,
            ),
            onTap: _isVideoPicking ? null : _selectVideo,
          ),

          // TODO: Temporarily hidden - File, Location options
          /*
          ListTile(
            leading: const Icon(Icons.attach_file, color: Colors.white),
            title: Text(
              context.tr("file"),
              style: CustomTextStyles.font16WhiteRegular,
            ),
            onTap: () {
              FeatureUnavailableDialog.show(
                context,
                title: context.tr(
                  "feature_unavailable_send_file_message_title",
                ),
                description: context.tr(
                  "feature_unavailable_send_file_message_description",
                ),
              );
            },
          ),
          ListTile(
            enabled: !_isLoading, // Disable tile when loading
            leading: _isLoading
                ? SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: const CustomLoadingAnimation(size: 30),
                  )
                : const Icon(Icons.location_on, color: Colors.white),
            title: Text(
              _isLoading
                  ? context.tr("getting_location")
                  : context.tr("location"),
              style: CustomTextStyles.font16WhiteRegular.copyWith(
                color: _isLoading
                    ? Colors.white.withOpacity(0.7)
                    : Colors.white,
              ),
            ),
            onTap: _isLoading ? null : _getLocation,
          ),
          */
        ],
      ),
    );
  }
}
