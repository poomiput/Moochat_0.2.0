import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:video_compress/video_compress.dart';
import 'package:moochat/core/helpers/logger_debug.dart';

class VideoService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick video from gallery
  static Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5), // Limit to 5 minutes
      );

      if (video != null) {
        return File(video.path);
      }
      return null;
    } catch (e) {
      LoggerDebug.logger.e('Error picking video from gallery: $e');
      return null;
    }
  }

  /// Pick video from camera
  static Future<File?> pickVideoFromCamera() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5), // Limit to 5 minutes
      );

      if (video != null) {
        return File(video.path);
      }
      return null;
    } catch (e) {
      LoggerDebug.logger.e('Error picking video from camera: $e');
      return null;
    }
  }

  /// Save video to app directory and return the saved path
  static Future<String?> saveVideoToAppDirectory(File videoFile) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String chatVideosDir = path.join(appDir.path, 'chat_videos');

      // Create chat_videos directory if it doesn't exist
      final Directory chatVideosDirObj = Directory(chatVideosDir);
      if (!await chatVideosDirObj.exists()) {
        await chatVideosDirObj.create(recursive: true);
      }

      // Generate unique filename
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final String savedPath = path.join(chatVideosDir, fileName);

      // Copy file to app directory
      final File savedFile = await videoFile.copy(savedPath);
      return savedFile.path;
    } catch (e) {
      LoggerDebug.logger.e('Error saving video: $e');
      return null;
    }
  }

  /// Compress video if needed
  static Future<File?> compressVideo(File videoFile) async {
    try {
      // Check if compression is needed based on file size
      final int fileSize = await videoFile.length();
      const int maxSize = 10 * 1024 * 1024; // 10MB

      if (fileSize <= maxSize) {
        LoggerDebug.logger.i(
          'Video file size acceptable: ${fileSize / (1024 * 1024)} MB',
        );
        return videoFile;
      }

      LoggerDebug.logger.i(
        'Compressing video from ${fileSize / (1024 * 1024)} MB',
      );
      return await _compressVideoToSize(videoFile, maxSize);
    } catch (e) {
      LoggerDebug.logger.e('Error compressing video: $e');
      return videoFile; // Return original if compression fails
    }
  }

  /// Compress video to target size using multiple strategies
  static Future<File?> _compressVideoToSize(
    File videoFile,
    int targetSize,
  ) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      // Strategy 1: Try different video qualities
      final List<VideoQuality> qualities = [
        VideoQuality.MediumQuality,
        VideoQuality.LowQuality,
        VideoQuality.Res640x480Quality,
      ];

      for (VideoQuality quality in qualities) {
        try {
          LoggerDebug.logger.i('Trying compression with quality: $quality');

          final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
            videoFile.path,
            quality: quality,
            deleteOrigin: false,
            includeAudio: true,
          );

          if (mediaInfo?.file != null) {
            final compressedFile = mediaInfo!.file!;
            final compressedSize = await compressedFile.length();

            LoggerDebug.logger.i(
              'Quality $quality: ${compressedSize / (1024 * 1024)} MB',
            );

            if (compressedSize <= targetSize) {
              // Copy to temp path for consistency
              await compressedFile.copy(tempPath);
              return File(tempPath);
            }
          }
        } catch (e) {
          LoggerDebug.logger.w('Compression failed for quality $quality: $e');
        }
      }

      // Strategy 2: Custom compression with lower bitrate
      try {
        LoggerDebug.logger.i('Trying custom compression...');
        final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
          videoFile.path,
          quality: VideoQuality.LowQuality,
          deleteOrigin: false,
          includeAudio: true,
          frameRate: 24, // Lower frame rate
        );

        if (mediaInfo?.file != null) {
          final compressedFile = mediaInfo!.file!;
          final compressedSize = await compressedFile.length();

          LoggerDebug.logger.i(
            'Custom compression: ${compressedSize / (1024 * 1024)} MB',
          );

          await compressedFile.copy(tempPath);
          return File(tempPath);
        }
      } catch (e) {
        LoggerDebug.logger.w('Custom compression failed: $e');
      }

      LoggerDebug.logger.w(
        'Could not compress video to target size, using original',
      );
      return videoFile;
    } catch (e) {
      LoggerDebug.logger.e('Error in _compressVideoToSize: $e');
      return videoFile;
    }
  }

  /// Delete video file
  static Future<bool> deleteVideo(String videoPath) async {
    try {
      final File videoFile = File(videoPath);
      if (await videoFile.exists()) {
        await videoFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      LoggerDebug.logger.e('Error deleting video: $e');
      return false;
    }
  }

  /// Check if file is a valid video
  static bool isValidVideoPath(String path) {
    final String extension = path.toLowerCase().split('.').last;
    return ['mp4', 'mov', 'avi', 'mkv', '3gp', 'webm'].contains(extension);
  }

  /// Get video file size in MB
  static Future<double> getVideoSizeMB(String videoPath) async {
    try {
      final File videoFile = File(videoPath);
      if (await videoFile.exists()) {
        final int sizeInBytes = await videoFile.length();
        return sizeInBytes / (1024 * 1024);
      }
      return 0.0;
    } catch (e) {
      LoggerDebug.logger.e('Error getting video size: $e');
      return 0.0;
    }
  }

  /// Convert video to Base64 string for transmission
  static Future<String?> videoToBase64(String videoPath) async {
    try {
      final File videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        LoggerDebug.logger.e('Video file does not exist: $videoPath');
        return null;
      }

      // Check file size and compress if needed
      File processedFile = videoFile;
      final int originalSize = await videoFile.length();
      const int maxSize = 10 * 1024 * 1024; // 10MB

      LoggerDebug.logger.i(
        'Original video size: ${originalSize / (1024 * 1024)} MB',
      );

      if (originalSize > maxSize) {
        LoggerDebug.logger.i('Video too large, compressing...');
        processedFile =
            await _compressVideoToSize(videoFile, maxSize) ?? videoFile;

        final int compressedSize = await processedFile.length();
        LoggerDebug.logger.i(
          'Compressed video size: ${compressedSize / (1024 * 1024)} MB',
        );
      }

      final Uint8List videoBytes = await processedFile.readAsBytes();
      final String base64String = base64Encode(videoBytes);

      LoggerDebug.logger.i(
        'Video converted to Base64, size: ${base64String.length} chars',
      );
      return base64String;
    } catch (e) {
      LoggerDebug.logger.e('Error converting video to Base64: $e');
      return null;
    }
  }

  /// Save Base64 string as video file
  static Future<String?> base64ToVideo(
    String base64String, {
    String? fileName,
  }) async {
    try {
      final Uint8List videoBytes = base64Decode(base64String);

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String chatVideosDir = path.join(appDir.path, 'received_videos');

      // Create received_videos directory if it doesn't exist
      final Directory chatVideosDirObj = Directory(chatVideosDir);
      if (!await chatVideosDirObj.exists()) {
        await chatVideosDirObj.create(recursive: true);
      }

      // Generate unique filename if not provided
      final String finalFileName =
          fileName ?? '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final String savedPath = path.join(chatVideosDir, finalFileName);

      // Write bytes to file
      final File savedFile = File(savedPath);
      await savedFile.writeAsBytes(videoBytes);

      LoggerDebug.logger.i('Base64 video saved to: $savedPath');
      return savedPath;
    } catch (e) {
      LoggerDebug.logger.e('Error saving Base64 video: $e');
      return null;
    }
  }

  /// Get video thumbnail
  static Future<File?> getVideoThumbnail(String videoPath) async {
    try {
      final thumbnail = await VideoCompress.getFileThumbnail(
        videoPath,
        quality: 50,
        position: -1, // Get thumbnail from middle of video
      );
      return thumbnail;
    } catch (e) {
      LoggerDebug.logger.e('Error getting video thumbnail: $e');
      return null;
    }
  }

  /// Get video information
  static Future<MediaInfo?> getVideoInfo(String videoPath) async {
    try {
      return await VideoCompress.getMediaInfo(videoPath);
    } catch (e) {
      LoggerDebug.logger.e('Error getting video info: $e');
      return null;
    }
  }

  /// Initialize video compression (call this once in app startup)
  static Future<void> initialize() async {
    try {
      VideoCompress.setLogLevel(0); // Disable verbose logs
    } catch (e) {
      LoggerDebug.logger.e('Error initializing video service: $e');
    }
  }

  /// Cleanup video compression resources
  static Future<void> dispose() async {
    try {
      await VideoCompress.deleteAllCache();
    } catch (e) {
      LoggerDebug.logger.e('Error disposing video service: $e');
    }
  }
}
