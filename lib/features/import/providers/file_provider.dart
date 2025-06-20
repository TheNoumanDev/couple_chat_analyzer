import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../../core/app.dart';

abstract class FileProvider {
  Future<File?> pickFile();
  Future<bool> validateFile(File file);
  Stream<File?> getSharedFiles();
  void init();
  void dispose();
}

class FileProviderImpl implements FileProvider {
  final StreamController<File?> _sharedFilesController = StreamController<File?>.broadcast();
  StreamSubscription<List<SharedMediaFile>>? _mediaStreamSubscription;
  Timer? _retryTimer;

  @override
  void init() {
    debugPrint("🔄 Initializing Enhanced FileProvider");

    try {
      // Clear any previous subscriptions
      _mediaStreamSubscription?.cancel();

      // Handle initial shared media with retry logic
      _handleInitialSharedMedia();

      // Set up stream listener with better error handling
      _setupMediaStreamListener();

      debugPrint("✅ FileProvider initialized successfully");
    } catch (e) {
      debugPrint("❌ Error initializing FileProvider: $e");
    }
  }

  void _handleInitialSharedMedia() async {
    try {
      // Add delay to ensure app is fully initialized
      await Future.delayed(const Duration(milliseconds: 500));

      final List<SharedMediaFile> files =
          await ReceiveSharingIntent.instance.getInitialMedia();
      debugPrint("📱 Initial shared files found: ${files.length}");

      for (final sharedFile in files) {
        debugPrint("📄 Processing initial file: ${sharedFile.path}");
        await _processSharedFile(sharedFile);
      }

      // Reset the initial media to prevent duplicate processing
      ReceiveSharingIntent.instance.reset();
    } catch (e) {
      debugPrint("❌ Error handling initial shared media: $e");
      // Retry after a delay
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
      debugPrint("🔄 Retrying FileProvider initialization");
      _handleInitialSharedMedia();
    });
  }

  @override
  Future<File?> pickFile() async {
    try {
      debugPrint("📁 Opening file picker");

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.supportedFileExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          final file = File(path);
          debugPrint("📄 File selected: ${file.path}");
          return file;
        }
      }

      debugPrint("📄 No file selected");
      return null;
    } catch (e) {
      debugPrint("❌ Error picking file: $e");
      rethrow;
    }
  }

  @override
  Stream<File?> getSharedFiles() => _sharedFilesController.stream;

  @override
  Future<bool> validateFile(File file) async {
    try {
      debugPrint("🔍 Validating file: ${file.path}");

      // Check if file exists
      if (!await file.exists()) {
        debugPrint("❌ File does not exist");
        return false;
      }

      // Check file size (should not be empty, but not too large)
      final fileSize = await file.length();
      debugPrint("📏 File size: ${fileSize} bytes");

      if (fileSize == 0) {
        debugPrint("❌ File is empty");
        return false;
      }

      if (fileSize > 100 * 1024 * 1024) {
        // 100MB limit
        debugPrint("❌ File too large: ${fileSize} bytes");
        return false;
      }

      // Get file path for checking
      final fileName = file.path.toLowerCase();

      // First, always check by magic bytes to determine actual file type
      final isActuallyZip = await _isZipFile(file);

      if (isActuallyZip) {
        debugPrint("📦 File is actually a ZIP (detected by magic bytes)");
        return await _validateZipFile(file);
      }

      // If not ZIP, check other formats
      if (fileName.endsWith('.html')) {
        debugPrint("🌐 Detected HTML file");
        return await _validateHtmlFile(file);
      }

      if (fileName.endsWith('.txt')) {
        debugPrint("📝 Detected text file");
        return await _validateTextFile(file);
      }

      // If no recognized extension, try to validate as text
      debugPrint("🔍 Unknown extension, trying as text file");
      return await _validateTextFile(file);
    } catch (e) {
      debugPrint("❌ Error during file validation: $e");
      return false;
    }
  }

  Future<bool> _isZipFile(File file) async {
    try {
      final bytes = await file.openRead(0, 4).first;
      // ZIP files start with PK (0x504B)
      return bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _validateZipFile(File file) async {
    // For now, assume ZIP files are valid if they pass the magic byte test
    // In a more complete implementation, you'd extract and validate the contents
    debugPrint("✅ ZIP file validation passed");
    return true;
  }

  Future<bool> _validateHtmlFile(File file) async {
    try {
      final content = await file.readAsString();
      
      if (content.contains('<html') && 
          (content.contains('WhatsApp') || content.contains('<!doctype'))) {
        debugPrint("✅ HTML file validation passed");
        return true;
      } else {
        debugPrint("❌ Invalid HTML file");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error reading HTML file: $e");
      return false;
    }
  }

  Future<bool> _validateTextFile(File file) async {
    try {
      final content = await file.readAsString();
      
      // Check if it looks like a WhatsApp chat
      final hasWhatsAppPatterns =
          content.contains(RegExp(r'\d{1,2}[/.]\d{1,2}[/.]\d{2,4}')) &&
              (content.contains(' - ') || content.contains(': '));

      if (!hasWhatsAppPatterns) {
        debugPrint(
            "⚠️ File doesn't appear to be a WhatsApp chat, but allowing it");
      } else {
        debugPrint("✅ WhatsApp chat patterns detected");
      }

      debugPrint("✅ Text file validation passed");
      return true;
    } catch (e) {
      debugPrint("❌ Error reading text file: $e");
      return false;
    }
  }

  @override
  void dispose() {
    debugPrint("🧹 Disposing FileProvider");
    _mediaStreamSubscription?.cancel();
    _retryTimer?.cancel();
    _sharedFilesController.close();
  }
}