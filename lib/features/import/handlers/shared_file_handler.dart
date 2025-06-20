import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class SharedFileHandler {
  final StreamController<File?> _sharedFilesController = StreamController<File?>.broadcast();
  StreamSubscription<List<SharedMediaFile>>? _mediaStreamSubscription;
  Timer? _retryTimer;

  Stream<File?> get sharedFiles => _sharedFilesController.stream;

  void initialize() {
    debugPrint("🔄 Initializing SharedFileHandler");

    try {
      _cleanup();
      _handleInitialSharedMedia();
      _setupMediaStreamListener();
      
      debugPrint("✅ SharedFileHandler initialized successfully");
    } catch (e) {
      debugPrint("❌ Error initializing SharedFileHandler: $e");
    }
  }

  void _cleanup() {
    _mediaStreamSubscription?.cancel();
    _retryTimer?.cancel();
  }

  void _handleInitialSharedMedia() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final List<SharedMediaFile> files =
          await ReceiveSharingIntent.instance.getInitialMedia();
      debugPrint("📱 Initial shared files found: ${files.length}");

      for (final sharedFile in files) {
        debugPrint("📄 Processing initial file: ${sharedFile.path}");
        await _processSharedFile(sharedFile);
      }

      ReceiveSharingIntent.instance.reset();
    } catch (e) {
      debugPrint("❌ Error handling initial shared media: $e");
      _scheduleRetry();
    }
  }

  void _setupMediaStreamListener() {
    _mediaStreamSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> files) async {
        debugPrint("📨 Stream received ${files.length} files");

        for (final sharedFile in files) {
          debugPrint("📄 Processing stream file: ${sharedFile.path}");
          await _processSharedFile(sharedFile);
        }
      },
      onError: (error) {
        debugPrint("❌ Media stream error: $error");
        _scheduleRetry();
      },
    );
  }

  Future<void> _processSharedFile(SharedMediaFile sharedFile) async {
    try {
      if (sharedFile.path == null) {
        debugPrint("⚠️ Shared file path is null");
        return;
      }

      final file = File(sharedFile.path!);

      if (!await file.exists()) {
        debugPrint("⚠️ Shared file does not exist: ${sharedFile.path}");
        return;
      }

      debugPrint("✅ Processing valid shared file: ${file.path}");
      _sharedFilesController.add(file);
    } catch (e) {
      debugPrint("❌ Error processing shared file: $e");
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 3), () {
      debugPrint("🔄 Retrying SharedFileHandler initialization");
      _handleInitialSharedMedia();
    });
  }

  void dispose() {
    debugPrint("🧹 Disposing SharedFileHandler");
    _cleanup();
    _sharedFilesController.close();
  }
}