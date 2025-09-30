import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:moochat/core/helpers/logger_debug.dart';

class VoiceServiceSimple {
  static final AudioPlayer _player = AudioPlayer();
  static final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  static bool _isPlaying = false;
  static bool _isRecording = false;
  static String? _currentPlayingPath;
  static bool _isRecorderInitialized = false;

  /// Initialize recorder
  static Future<void> _initializeRecorder() async {
    if (!_isRecorderInitialized) {
      await _recorder.openRecorder();
      _isRecorderInitialized = true;
    }
  }

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

  /// Start recording voice
  static Future<bool> startRecording() async {
    try {
      // Initialize recorder
      await _initializeRecorder();

      // Check permission first
      bool hasPermission = await checkMicrophonePermission();
      if (!hasPermission) {
        LoggerDebug.logger.w('Microphone permission denied');
        return false;
      }

      // Get directory for saving recordings
      Directory appDir = await getApplicationDocumentsDirectory();
      Directory voiceDir = Directory('${appDir.path}/voices');

      if (!voiceDir.existsSync()) {
        voiceDir.createSync(recursive: true);
      }

      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = 'voice_$timestamp.aac';
      String filePath = '${voiceDir.path}/$fileName';

      // Start recording
      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
        bitRate: 128000,
        sampleRate: 44100,
      );

      _isRecording = true;
      LoggerDebug.logger.i('Voice recording started: $filePath');
      return true;
    } catch (e) {
      LoggerDebug.logger.e('Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording and return file path
  static Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        LoggerDebug.logger.w('No recording in progress');
        return null;
      }

      // Stop recording and get the file path
      String? filePath = await _recorder.stopRecorder();
      _isRecording = false;

      if (filePath != null && File(filePath).existsSync()) {
        LoggerDebug.logger.i('Recording stopped: $filePath');
        return filePath;
      } else {
        LoggerDebug.logger.e('Recording failed - no file created');
        return null;
      }
    } catch (e) {
      LoggerDebug.logger.e('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Save voice file to app directory (simplified)
  static Future<String?> saveVoiceToAppDirectory(File voiceFile) async {
    try {
      // Already handled in stopRecording for simplified version
      return voiceFile.path;
    } catch (e) {
      LoggerDebug.logger.e('Error saving voice file: $e');
      return null;
    }
  }

  /// Play voice message
  static Future<bool> playVoice(String filePath) async {
    try {
      File voiceFile = File(filePath);
      if (!voiceFile.existsSync()) {
        LoggerDebug.logger.w('Voice file not found: $filePath');
        return false;
      }

      // Stop any current playback
      if (_isPlaying) {
        await stopPlaying();
      }

      LoggerDebug.logger.i('Playing voice: $filePath');

      // Play the audio file using AudioPlayer
      await _player.play(DeviceFileSource(filePath));
      _isPlaying = true;
      _currentPlayingPath = filePath;

      // Listen for completion
      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
        _currentPlayingPath = null;
        LoggerDebug.logger.i('Playback completed for: $filePath');
      });

      return true;
    } catch (e) {
      LoggerDebug.logger.e('Error playing voice: $e');
      return false;
    }
  }

  /// Stop playing voice
  static Future<void> stopPlaying() async {
    try {
      if (_isPlaying) {
        await _player.stop();
        _isPlaying = false;
        _currentPlayingPath = null;
      }
    } catch (e) {
      LoggerDebug.logger.e('Error stopping voice playback: $e');
    }
  }

  /// Pause playing voice
  static Future<void> pausePlaying() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      }
    } catch (e) {
      LoggerDebug.logger.e('Error pausing voice playback: $e');
    }
  }

  /// Resume playing voice
  static Future<void> resumePlaying() async {
    try {
      if (!_isPlaying && _currentPlayingPath != null) {
        await _player.resume();
      }
    } catch (e) {
      LoggerDebug.logger.e('Error resuming voice playback: $e');
    }
  }

  /// Get voice duration
  static Future<Duration?> getVoiceDuration(String filePath) async {
    try {
      File voiceFile = File(filePath);
      if (!voiceFile.existsSync()) {
        return const Duration(seconds: 0);
      }

      // Try to get actual duration using AudioPlayer
      try {
        // Create a temporary player to get duration
        AudioPlayer tempPlayer = AudioPlayer();
        await tempPlayer.setSource(DeviceFileSource(filePath));

        // Wait a bit for the player to load the file
        await Future.delayed(const Duration(milliseconds: 100));

        Duration? duration = await tempPlayer.getDuration();
        await tempPlayer.dispose();

        if (duration != null && duration.inSeconds > 0) {
          LoggerDebug.logger.i('Actual audio duration: ${duration.inSeconds}s');
          return duration;
        }
      } catch (e) {
        LoggerDebug.logger.w('Could not get actual duration: $e');
      }

      // Fallback: estimate based on file size
      var stat = await voiceFile.stat();
      int fileSizeKB = (stat.size / 1024).round();

      // For AAC files: roughly 16KB per second at 128kbps
      int estimatedSeconds = (fileSizeKB / 16).clamp(1, 120).toInt();

      LoggerDebug.logger.i(
        'Estimated duration: ${estimatedSeconds}s (from ${fileSizeKB}KB)',
      );
      return Duration(seconds: estimatedSeconds);
    } catch (e) {
      LoggerDebug.logger.e('Error getting voice duration: $e');
      return const Duration(seconds: 3); // Default fallback
    }
  }

  /// Delete voice file
  static Future<bool> deleteVoiceFile(String filePath) async {
    try {
      File voiceFile = File(filePath);
      if (voiceFile.existsSync()) {
        await voiceFile.delete();
        LoggerDebug.logger.i('Voice file deleted: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      LoggerDebug.logger.e('Error deleting voice file: $e');
      return false;
    }
  }

  /// Check if currently recording
  static bool get isRecording => _isRecording;

  /// Check if currently playing
  static bool get isPlaying => _isPlaying;

  /// Get current playing path
  static String? get currentPlayingPath => _currentPlayingPath;

  /// Dispose resources
  static Future<void> dispose() async {
    try {
      if (_isRecording) {
        await _recorder.stopRecorder();
        _isRecording = false;
      }
      if (_isPlaying) {
        await stopPlaying();
      }
      await _player.dispose();
      if (_isRecorderInitialized) {
        await _recorder.closeRecorder();
        _isRecorderInitialized = false;
      }
    } catch (e) {
      LoggerDebug.logger.e('Error disposing voice service: $e');
    }
  }
}
