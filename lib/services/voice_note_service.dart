import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceNoteService {
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  SupabaseClient get _supabase => Supabase.instance.client;

  VoiceNoteService() {
    _recorder = FlutterSoundRecorder();
  }

  Future<bool> checkPermission() async {
    final status = await Permission.microphone.status;
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  Future<bool> startRecording() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        debugPrint('Microphone permission denied');
        return false;
      }

      // Initialize recorder
      await _recorder!.openRecorder();

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/voice_note_$timestamp.aac';

      await _recorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacADTS,
        bitRate: 128000,
        sampleRate: 44100,
      );

      _isRecording = true;
      debugPrint('Recording started: $_currentRecordingPath');
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        debugPrint('Not currently recording');
        return null;
      }

      await _recorder!.stopRecorder();
      await _recorder!.closeRecorder();
      _isRecording = false;

      debugPrint('Recording stopped: $_currentRecordingPath');
      return _currentRecordingPath;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder!.stopRecorder();
        await _recorder!.closeRecorder();
        _isRecording = false;
      }
      
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _currentRecordingPath = null;
      debugPrint('Recording cancelled');
    } catch (e) {
      debugPrint('Error cancelling recording: $e');
    }
  }

  Future<Map<String, dynamic>?> uploadVoiceNote({
    required String filePath,
    required String roomId,
    required String senderId,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Voice note file not found: $filePath');
        return null;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${senderId}_$timestamp.aac';
      final storagePath = 'voice_notes/$roomId/$fileName';

      // Upload to Supabase Storage
      await _supabase.storage
          .from('voice-notes')
          .upload(
            storagePath,
            file,
            fileOptions: const FileOptions(
              contentType: 'audio/aac',
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('voice-notes')
          .getPublicUrl(storagePath);

      // Get file size and estimate duration
      final fileSize = await file.length();
      final estimatedDuration = (fileSize / 16000).round(); // ~128kbps

      debugPrint('Voice note uploaded to Supabase: $publicUrl');

      // Clean up local file
      await file.delete();

      return {
        'url': publicUrl,
        'duration': estimatedDuration,
      };
    } catch (e) {
      debugPrint('Error uploading voice note to Supabase: $e');
      return null;
    }
  }

  Future<int> getRecordingDuration(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return 0;

      final fileSize = await file.length();
      return (fileSize / 16000).round();
    } catch (e) {
      debugPrint('Error getting recording duration: $e');
      return 0;
    }
  }

  void dispose() {
    _recorder?.closeRecorder();
    _recorder = null;
  }
}