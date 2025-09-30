import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/styles.dart';
import 'package:moochat/features/chat/services/image_service.dart';

class ImagePickerDialog extends StatelessWidget {
  const ImagePickerDialog({super.key});

  static Future<File?> show(BuildContext context) async {
    return await showModalBottomSheet<File?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ImagePickerDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 20.h),
            decoration: BoxDecoration(
              color: ColorsManager.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Title
          Text(
            context.tr("select_image_source"),
            style: CustomTextStyles.font18WhiteMedium,
          ),
          SizedBox(height: 20.h),

          // Options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Camera option
              _ImageSourceOption(
                icon: Icons.camera_alt,
                label: context.tr("camera_source"),
                onTap: () => _pickImage(context, ImageSource.camera),
              ),

              // Gallery option
              _ImageSourceOption(
                icon: Icons.photo_library,
                label: context.tr("gallery_source"),
                onTap: () => _pickImage(context, ImageSource.gallery),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr("cancel"),
              style: CustomTextStyles.font16WhiteRegular.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    File? imageFile;

    if (source == ImageSource.camera) {
      imageFile = await ImageService.pickImageFromCamera();
    } else {
      imageFile = await ImageService.pickImageFromGallery();
    }

    if (context.mounted) {
      Navigator.pop(context, imageFile);
    }
  }
}

class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 120.w,
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: ColorsManager.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: ColorsManager.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: ColorsManager.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: ColorsManager.primary, size: 32.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              label,
              style: CustomTextStyles.font14WhiteRegular,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
