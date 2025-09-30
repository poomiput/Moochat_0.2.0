import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:moochat/core/helpers/logger_debug.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      LoggerDebug.logger.e('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick image from camera
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      LoggerDebug.logger.e('Error picking image from camera: $e');
      return null;
    }
  }

  /// Save image to app directory and return the saved path
  static Future<String?> saveImageToAppDirectory(File imageFile) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String chatImagesDir = path.join(appDir.path, 'chat_images');

      // Create chat_images directory if it doesn't exist
      final Directory chatImagesDirObj = Directory(chatImagesDir);
      if (!await chatImagesDirObj.exists()) {
        await chatImagesDirObj.create(recursive: true);
      }

      // Generate unique filename
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = path.join(chatImagesDir, fileName);

      // Copy file to app directory
      final File savedFile = await imageFile.copy(savedPath);
      return savedFile.path;
    } catch (e) {
      LoggerDebug.logger.e('Error saving image: $e');
      return null;
    }
  }

  /// Get image size information
  static Future<Size?> getImageSize(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) return null;

      // This is a simplified version - you might want to use image package for more accuracy
      return const Size(300, 200); // Default size for now
    } catch (e) {
      LoggerDebug.logger.e('Error getting image size: $e');
      return null;
    }
  }

  /// Compress image if needed
  static Future<File?> compressImage(File imageFile, {int quality = 85}) async {
    try {
      // For now, return the original file
      // You can implement image compression using packages like flutter_image_compress
      return imageFile;
    } catch (e) {
      LoggerDebug.logger.e('Error compressing image: $e');
      return null;
    }
  }

  /// Delete image file
  static Future<bool> deleteImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      LoggerDebug.logger.e('Error deleting image: $e');
      return false;
    }
  }

  /// Check if file is a valid image
  static bool isValidImagePath(String path) {
    final String extension = path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  /// Get image bytes for display
  static Future<Uint8List?> getImageBytes(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        return await imageFile.readAsBytes();
      }
      return null;
    } catch (e) {
      LoggerDebug.logger.e('Error reading image bytes: $e');
      return null;
    }
  }

  /// Convert image to Base64 string for transmission
  static Future<String?> imageToBase64(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        LoggerDebug.logger.e('Image file does not exist: $imagePath');
        return null;
      }

      final Uint8List imageBytes = await imageFile.readAsBytes();
      final String base64String = base64Encode(imageBytes);

      LoggerDebug.logger.i(
        'Image converted to Base64, size: ${base64String.length} chars',
      );
      return base64String;
    } catch (e) {
      LoggerDebug.logger.e('Error converting image to Base64: $e');
      return null;
    }
  }

  /// Save Base64 string as image file
  static Future<String?> base64ToImage(
    String base64String, {
    String? fileName,
  }) async {
    try {
      final Uint8List imageBytes = base64Decode(base64String);

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String chatImagesDir = path.join(appDir.path, 'received_images');

      // Create received_images directory if it doesn't exist
      final Directory chatImagesDirObj = Directory(chatImagesDir);
      if (!await chatImagesDirObj.exists()) {
        await chatImagesDirObj.create(recursive: true);
      }

      // Generate unique filename if not provided
      final String finalFileName =
          fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = path.join(chatImagesDir, finalFileName);

      // Write bytes to file
      final File savedFile = File(savedPath);
      await savedFile.writeAsBytes(imageBytes);

      LoggerDebug.logger.i('Base64 image saved to: $savedPath');
      return savedPath;
    } catch (e) {
      LoggerDebug.logger.e('Error saving Base64 image: $e');
      return null;
    }
  }
}
