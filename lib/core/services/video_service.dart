import 'dart:convert';
import 'dart:io';
import 'package:video_compress/video_compress.dart';
import 'package:path/path.dart' as path;
import '../helpers/logger_debug.dart' as logger;

class VideoService {
  static const int maxFileSizeMB = 10; // ขนาดไฟล์สูงสุด (MB)

  /// คำนวณขนาดไฟล์วิดีโอใน MB
  static Future<double> getVideoSizeMB(String videoPath) async {
    try {
      final file = File(videoPath);
      if (!await file.exists()) return 0;
      
      final fileSizeBytes = await file.length();
      return fileSizeBytes / (1024 * 1024); // แปลงเป็น MB
    } catch (e) {
      logger.LoggerDebug.logger.e('Error getting video size: $e');
      return 0;
    }
  }

  /// บีบอัดวิดีโอด้วยระบบอัจฉริยะ
  static Future<File> compressVideo(File videoFile) async {
    try {
      final originalSizeMB = await getVideoSizeMB(videoFile.path);
      logger.LoggerDebug.logger.i('Original video size: ${originalSizeMB.toStringAsFixed(1)}MB');

      // ถ้าไฟล์เล็กพอแล้ว ไม่ต้องบีบอัด
      if (originalSizeMB <= maxFileSizeMB) {
        logger.LoggerDebug.logger.i('Video is already within size limit');
        return videoFile;
      }

      // Strategy 1: บีบอัดคุณภาพปานกลาง
      MediaInfo? compressedVideo = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (compressedVideo?.file != null) {
        final compressedSizeMB = await getVideoSizeMB(compressedVideo!.file!.path);
        logger.LoggerDebug.logger.i('Medium quality compression result: ${compressedSizeMB.toStringAsFixed(1)}MB');
        
        if (compressedSizeMB <= maxFileSizeMB) {
          logger.LoggerDebug.logger.i('Medium quality compression successful');
          return compressedVideo.file!;
        }
      }

      // Strategy 2: บีบอัดคุณภาพต่ำ
      logger.LoggerDebug.logger.i('Trying low quality compression...');
      compressedVideo = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (compressedVideo?.file != null) {
        final compressedSizeMB = await getVideoSizeMB(compressedVideo!.file!.path);
        logger.LoggerDebug.logger.i('Low quality compression result: ${compressedSizeMB.toStringAsFixed(1)}MB');
        
        if (compressedSizeMB <= maxFileSizeMB) {
          logger.LoggerDebug.logger.i('Low quality compression successful');
          return compressedVideo.file!;
        }
      }

      // Strategy 3: บีบอัดคุณภาพต่ำสุด
      logger.LoggerDebug.logger.i('Trying lowest quality compression...');
      compressedVideo = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.DefaultQuality,
        deleteOrigin: false,
        includeAudio: false, // ลบเสียงเพื่อลดขนาด
      );

      if (compressedVideo?.file != null) {
        final compressedSizeMB = await getVideoSizeMB(compressedVideo!.file!.path);
        logger.LoggerDebug.logger.i('Lowest quality compression result: ${compressedSizeMB.toStringAsFixed(1)}MB');
        
        if (compressedSizeMB <= maxFileSizeMB) {
          logger.LoggerDebug.logger.i('Lowest quality compression successful');
          return compressedVideo.file!;
        }
      }

      // ถ้าบีบอัดแล้วยังใหญ่เกินไป ใช้ไฟล์ต้นฉบับ
      logger.LoggerDebug.logger.w('All compression strategies failed, using original file');
      return videoFile;

    } catch (e) {
      logger.LoggerDebug.logger.e('Error compressing video: $e');
      return videoFile; // คืนไฟล์ต้นฉบับหากเกิดข้อผิดพลาด
    }
  }

  /// แปลงวิดีโอเป็น Base64
  static Future<String?> videoToBase64(String videoPath) async {
    try {
      final file = File(videoPath);
      if (!await file.exists()) {
        logger.LoggerDebug.logger.e('Video file not found: $videoPath');
        return null;
      }

      // ตรวจสอบขนาดไฟล์ก่อนแปลง
      final fileSizeMB = await getVideoSizeMB(videoPath);
      if (fileSizeMB > maxFileSizeMB) {
        logger.LoggerDebug.logger.w('Video file too large: ${fileSizeMB.toStringAsFixed(1)}MB');
        // อย่าคืน null แต่ให้ลองแปลงต่อไป
      }

      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      
      logger.LoggerDebug.logger.i('Video converted to base64, size: ${(base64String.length / 1024 / 1024).toStringAsFixed(1)}MB');
      return base64String;

    } catch (e) {
      logger.LoggerDebug.logger.e('Error converting video to base64: $e');
      return null;
    }
  }

  /// บันทึกวิดีโอจาก Base64
  static Future<String?> saveVideoFromBase64({
    required String base64Data,
    required String fileName,
  }) async {
    try {
      final bytes = base64Decode(base64Data);
      
      // สร้างพาธสำหรับบันทึกไฟล์
      final directory = Directory('/data/data/com.example.moochat/files/videos');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      final filePath = path.join(directory.path, fileName);
      final file = File(filePath);
      
      await file.writeAsBytes(bytes);
      logger.LoggerDebug.logger.i('Video saved successfully: $filePath');
      
      return filePath;
    } catch (e) {
      logger.LoggerDebug.logger.e('Error saving video from base64: $e');
      return null;
    }
  }

  /// ลบไฟล์วิดีโอชั่วคราว
  static Future<void> cleanupTempFiles() async {
    try {
      await VideoCompress.deleteAllCache();
      logger.LoggerDebug.logger.i('Video cache cleaned up');
    } catch (e) {
      logger.LoggerDebug.logger.e('Error cleaning up video cache: $e');
    }
  }

  /// รับข้อมูลวิดีโอ
  static Future<MediaInfo?> getVideoInfo(String videoPath) async {
    try {
      return await VideoCompress.getMediaInfo(videoPath);
    } catch (e) {
      logger.LoggerDebug.logger.e('Error getting video info: $e');
      return null;
    }
  }

  /// เลือกวิดีโอจาก Gallery  
  static Future<File?> pickVideoFromGallery() async {
    try {
      // Import image_picker package เพื่อใช้ในการเลือกไฟล์
      return null; // ต้อง implement ด้วย image_picker
    } catch (e) {
      logger.LoggerDebug.logger.e('Error picking video from gallery: $e');
      return null;
    }
  }

  /// บันทึกวิดีโอลง app directory
  static Future<String?> saveVideoToAppDirectory(File videoFile, String fileName) async {
    try {
      final directory = Directory('/data/data/com.example.moochat/files/videos');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      final filePath = path.join(directory.path, fileName);
      final newFile = await videoFile.copy(filePath);
      
      logger.LoggerDebug.logger.i('Video saved to app directory: $filePath');
      return newFile.path;
    } catch (e) {
      logger.LoggerDebug.logger.e('Error saving video to app directory: $e');
      return null;
    }
  }

  /// แปลงจาก Base64 เป็นวิดีโอไฟล์
  static Future<String?> base64ToVideo(String base64Data, String fileName) async {
    return await saveVideoFromBase64(
      base64Data: base64Data, 
      fileName: fileName
    );
  }
}