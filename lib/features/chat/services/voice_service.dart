import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:moochat/core/helpers/logger_debug.dart';

class VoiceService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isRecording = false;
  static bool _isPlaying = false;
  static String? _currentPlayingPath;
  static bool _isRecorderInitialized = false;

  /// Check and request microphone permission
  static Future<bool> checkMicrophonePermission() async {
    try {
      PermissionStatus permission = await Permission.microphone.status;

      if (permission.isDenied) {
        permission = await Permission.microphone.request();
      }

      return permission.isGranted;
    } catch (e) {
      LoggerDebug.logger.e('Error checking microphone permission: $e');
      return false;
    }
  }

  /// Initialize recorder if needed
  static Future<bool> initRecorder() async {
    try {
      _isRecorderInitialized = true;
      LoggerDebug.logger.w(
        'Voice recording temporarily disabled - flutter_sound compatibility issue',
      );
      return false;
    } catch (e) {
      LoggerDebug.logger.e('Error initializing recorder: $e');
      return false;
    }
  }

  /// Start recording and return success status
  static Future<bool> startRecording() async {
    try {
      LoggerDebug.logger.w(
        'Voice recording temporarily disabled - flutter_sound compatibility issue',
      );
      return false;
    } catch (e) {
      LoggerDebug.logger.e('Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording and return file path
  static Future<String?> stopRecording() async {
    try {
      LoggerDebug.logger.w(
        'Voice recording temporarily disabled - flutter_sound compatibility issue',
      );
      return null;
    } catch (e) {
      LoggerDebug.logger.e('Error stopping recording: $e');
      return null;
    }
  }

  /// Save voice file to app directory
  static Future<String?> saveVoiceToAppDirectory(File voiceFile) async {
    try {
      LoggerDebug.logger.w(
        'Voice recording temporarily disabled - flutter_sound compatibility issue',
      );
      return null;
    } catch (e) {
      LoggerDebug.logger.e('Error saving voice file: $e');
      return null;
    }
  }

  /// Play voice message
  static Future<bool> playVoice(String filePath) async {
    try {
      if (_isPlaying) {
        await stopPlaying();
      }

      await _player.play(DeviceFileSource(filePath));
      _isPlaying = true;
      _currentPlayingPath = filePath;

      LoggerDebug.logger.i('Playing voice: $filePath');
      return true;
    } catch (e) {
      LoggerDebug.logger.e('Error playing voice: $e');
      return false;
    }
  }

  /// Stop playing voice
  static Future<void> stopPlaying() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _currentPlayingPath = null;
    } catch (e) {
      LoggerDebug.logger.e('Error stopping voice playback: $e');
    }
  }

  /// Pause playing voice
  static Future<void> pausePlaying() async {
    try {
      await _player.pause();
      _isPlaying = false;
    } catch (e) {
      LoggerDebug.logger.e('Error pausing voice playback: $e');
    }
  }

  /// Resume playing voice
  static Future<void> resumePlaying() async {
    try {
      await _player.resume();
      _isPlaying = true;
    } catch (e) {
      LoggerDebug.logger.e('Error resuming voice playback: $e');
    }
  }

  /// Get voice duration
  static Future<Duration?> getVoiceDuration(String filePath) async {
    try {
      LoggerDebug.logger.w(
        'Voice recording temporarily disabled - flutter_sound compatibility issue',
      );
      return null;
    } catch (e) {
      LoggerDebug.logger.e('Error getting voice duration: $e');
      return null;
    }
  }

  /// Delete voice file
  static Future<bool> deleteVoiceFile(String filePath) async {
    try {
      File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        LoggerDebug.logger.i('Voice file deleted: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      LoggerDebug.logger.e('Error deleting voice file: $e');
      return false;
    }
  }

  /// Getters
  static bool get isRecording => _isRecording;
  static bool get isPlaying => _isPlaying;
  static String? get currentPlayingPath => _currentPlayingPath;

  /// Dispose resources
  static Future<void> dispose() async {
    try {
      await _player.dispose();
      _isRecording = false;
      _isPlaying = false;
      _currentPlayingPath = null;
    } catch (e) {
      LoggerDebug.logger.e('Error disposing voice service: $e');
    }
  }
}
