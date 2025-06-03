// features/import/import_feature.dart
// Consolidated: import_bloc.dart + import_event.dart + import_state.dart + import_chat_usecase.dart + file_provider.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../shared/domain.dart';

// ============================================================================
// IMPORT EVENTS
// ============================================================================
abstract class ImportEvent extends Equatable {
  const ImportEvent();

  @override
  List<Object?> get props => [];
}

class PickFileEvent extends ImportEvent {}

class ImportFileEvent extends ImportEvent {
  final File file;

  const ImportFileEvent(this.file);

  @override
  List<Object?> get props => [file];
}

class FileSharedEvent extends ImportEvent {
  final File file;

  const FileSharedEvent(this.file);

  @override
  List<Object?> get props => [file];
}

// ============================================================================
// IMPORT STATES
// ============================================================================
abstract class ImportState extends Equatable {
  const ImportState();

  @override
  List<Object?> get props => [];
}

class ImportInitial extends ImportState {}

class ImportLoading extends ImportState {
  final String message;
  final double? progress;

  const ImportLoading({
    this.message = 'Processing...',
    this.progress,
  });

  @override
  List<Object?> get props => [message, progress];
}

class FileSelected extends ImportState {
  final File file;

  const FileSelected(this.file);

  @override
  List<Object?> get props => [file];
}

class ImportSuccess extends ImportState {
  final ChatEntity chat;

  const ImportSuccess(this.chat);

  @override
  List<Object?> get props => [chat];
}

class RetryImportEvent extends ImportEvent {
  final File file;

  const RetryImportEvent(this.file);

  @override
  List<Object?> get props => [file];
}

class ClearErrorEvent extends ImportEvent {}

class ImportError extends ImportState {
  final String message;
  final String? technicalDetails;
  final File? failedFile;

  const ImportError(
    this.message, {
    this.technicalDetails,
    this.failedFile,
  });

  @override
  List<Object?> get props => [message, technicalDetails, failedFile];
}

// ============================================================================
// IMPORT USE CASE
// ============================================================================
class ImportChatUseCase {
  final ChatRepository repository;

  ImportChatUseCase(this.repository);

  Future<ChatEntity> call(File file) async {
    return await repository.importChat(file);
  }
}

// ============================================================================
// FILE PROVIDER
// ============================================================================
abstract class FileProvider {
  Future<File?> pickFile();
  Stream<File?> getSharedFiles();
  Future<String> getFilePath(String fileName);
  void init();
  void dispose(); // Add this line
  Future<bool> validateFile(File file); // Add this line
}

class FileProviderImpl implements FileProvider {
  final _sharedFilesController = StreamController<File?>.broadcast();
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
      debugPrint("📁 Processing file: ${file.path}");

      // Validate file exists and is readable
      if (!await file.exists()) {
        debugPrint("❌ File does not exist: ${file.path}");
        return;
      }

      // Validate file type and content
      if (!await validateFile(file)) {
        debugPrint("⚠️ File validation failed: ${file.path}");
        return;
      }

      // Copy file to app directory to ensure persistence
      final copiedFile = await _copyToAppDirectory(file);

      debugPrint("✅ File processed successfully: ${copiedFile.path}");
      _sharedFilesController.add(copiedFile);
    } catch (e) {
      debugPrint("❌ Error processing shared file: $e");
      _sharedFilesController.addError(e);
    }
  }

  // Completely corrected _copyToAppDirectory method in FileProviderImpl
  Future<File> _copyToAppDirectory(File originalFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Get the original file name and extension
      final originalFileName = originalFile.path.split('/').last;
      String extension = 'txt'; // default

      if (originalFileName.contains('.')) {
        extension = originalFileName.split('.').last.toLowerCase();
      }

      // Preserve the original extension - this is the key fix!
      final fileName = 'shared_chat_$timestamp.$extension';
      final targetPath = '${appDir.path}/$fileName';

      debugPrint(
          "📋 Copying $originalFileName to: $targetPath (preserving .$extension extension)");
      final copiedFile = await originalFile.copy(targetPath);

      // Verify the copy was successful
      if (await copiedFile.exists()) {
        final originalSize = await originalFile.length();
        final copiedSize = await copiedFile.length();

        if (originalSize == copiedSize) {
          debugPrint(
              "✅ File copied successfully (${copiedSize} bytes) with .$extension extension");
          return copiedFile;
        } else {
          throw Exception(
              'File copy size mismatch: original=$originalSize, copied=$copiedSize');
        }
      } else {
        throw Exception('Copied file does not exist');
      }
    } catch (e) {
      debugPrint("❌ Error copying file: $e");
      rethrow;
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 2), () {
      debugPrint("🔄 Retrying file provider initialization");
      _handleInitialSharedMedia();
    });
  }

  @override
  Future<File?> pickFile() async {
    debugPrint("📂 Opening file picker");

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'html', 'zip'],
        allowCompression: false,
        withData: false,
        withReadStream: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        debugPrint("📄 File selected: ${file.path}");

        // Validate the selected file
        if (await validateFile(file)) {
          debugPrint("✅ File validation passed");
          return file;
        } else {
          debugPrint("❌ File validation failed");
          throw Exception('Invalid file format or content');
        }
      }

      debugPrint("ℹ️ No file selected");
      return null;
    } catch (e) {
      debugPrint("❌ Error picking file: $e");
      rethrow;
    }
  }

  @override
  Stream<File?> getSharedFiles() {
    return _sharedFilesController.stream;
  }

  @override
  Future<String> getFilePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }

// Helper method to check if file is ZIP by magic bytes (more reliable)
  Future<bool> _isZipFile(File file) async {
    try {
      final bytes = await file.openRead(0, 4).first;
      if (bytes.length >= 4) {
        // Check for ZIP magic numbers
        final isZip = (bytes[0] == 0x50 &&
            bytes[1] == 0x4B &&
            (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07));
        debugPrint(
            "🔍 ZIP magic bytes check: ${isZip ? 'PASS' : 'FAIL'} (${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')})");
        return isZip;
      }
      return false;
    } catch (e) {
      debugPrint("⚠️ Error checking ZIP magic bytes: $e");
      return false;
    }
  }

// Enhanced ZIP validation
  Future<bool> _validateZipFile(File file) async {
    try {
      final isZip = await _isZipFile(file);

      if (isZip) {
        debugPrint("✅ ZIP file validation passed");
        return true;
      } else {
        debugPrint("❌ File is not a valid ZIP");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error validating ZIP file: $e");
      return false;
    }
  }

// Enhanced HTML validation
  Future<bool> _validateHtmlFile(File file) async {
    try {
      // Read first 1KB to check for HTML content
      final bytes = await file.openRead(0, 1024).first;
      final content = utf8.decode(bytes, allowMalformed: true).toLowerCase();

      if (content.contains('<html') || content.contains('<!doctype')) {
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

// Enhanced text file validation with better encoding handling
  Future<bool> _validateTextFile(File file) async {
    try {
      // Try to read a sample of the file with different encodings
      final bytes = await file.openRead(0, 2048).first; // Read first 2KB

      String content;
      bool decoded = false;

      // Try UTF-8 first
      try {
        content = utf8.decode(bytes);
        decoded = true;
        debugPrint("✅ Text file decoded with UTF-8");
      } catch (e) {
        debugPrint("⚠️ UTF-8 failed: $e");

        // Try UTF-8 with malformed handling
        try {
          content = const Utf8Decoder(allowMalformed: true).convert(bytes);
          decoded = true;
          debugPrint("✅ Text file decoded with UTF-8 (malformed allowed)");
        } catch (e) {
          debugPrint("⚠️ UTF-8 (malformed) failed: $e");

          // Try Latin-1
          try {
            content = latin1.decode(bytes);
            decoded = true;
            debugPrint("✅ Text file decoded with Latin-1");
          } catch (e) {
            debugPrint("⚠️ Latin-1 failed: $e");

            // Try ASCII as last resort
            try {
              content = ascii.decode(bytes, allowInvalid: true);
              decoded = true;
              debugPrint("✅ Text file decoded with ASCII");
            } catch (e) {
              debugPrint("❌ All text decodings failed: $e");
              return false;
            }
          }
        }
      }

      if (!decoded) {
        debugPrint("❌ Cannot decode text file with any encoding");
        return false;
      }

      // Check if it looks like a WhatsApp chat
      final hasWhatsAppPatterns =
          content.contains(RegExp(r'\d{1,2}[/.]\d{1,2}[/.]\d{1,2}')) &&
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

  @override
  void dispose() {
    debugPrint("🧹 Disposing FileProvider");
    _mediaStreamSubscription?.cancel();
    _retryTimer?.cancel();
    _sharedFilesController.close();
  }
}

// ============================================================================
// IMPORT BLOC
// ============================================================================
class ImportBloc extends Bloc<ImportEvent, ImportState> {
  final ImportChatUseCase importChatUseCase;
  final FileProvider fileProvider;
  StreamSubscription? _sharedFilesSubscription;

  ImportBloc({
    required this.importChatUseCase,
    required this.fileProvider,
  }) : super(ImportInitial()) {
    on<PickFileEvent>(_onPickFile);
    on<ImportFileEvent>(_onImportFile);
    on<FileSharedEvent>(_onFileShared);
    on<RetryImportEvent>(_onRetryImport);
    on<ClearErrorEvent>(_onClearError);

    // Subscribe to shared files with better error handling
    _subscribeToSharedFiles();
  }

  void _subscribeToSharedFiles() {
    _sharedFilesSubscription?.cancel();

    _sharedFilesSubscription = fileProvider.getSharedFiles().listen(
      (file) {
        if (file != null) {
          debugPrint("📱 ImportBloc received shared file: ${file.path}");
          add(FileSharedEvent(file));
        }
      },
      onError: (error) {
        debugPrint("❌ Shared files stream error: $error");
        emit(ImportError(
          'Error receiving shared file',
          technicalDetails: 'Please try sharing the file again',
        ));
      },
    );
  }

  Future<void> _onPickFile(
      PickFileEvent event, Emitter<ImportState> emit) async {
    emit(const ImportLoading(message: 'Opening file picker...'));

    try {
      final file = await fileProvider.pickFile();
      if (file != null) {
        emit(FileSelected(file));
      } else {
        emit(ImportInitial());
      }
    } catch (e) {
      debugPrint("❌ Error picking file: $e");
      emit(ImportError(
        'Failed to select file',
        technicalDetails: e.toString(),
      ));
    }
  }

  Future<void> _onImportFile(
      ImportFileEvent event, Emitter<ImportState> emit) async {
    await _performImport(event.file, emit);
  }

  Future<void> _onFileShared(
      FileSharedEvent event, Emitter<ImportState> emit) async {
    debugPrint("📱 Processing shared file: ${event.file.path}");

    // Add a small delay to ensure UI is ready
    await Future.delayed(const Duration(milliseconds: 300));

    await _performImport(event.file, emit);
  }

  Future<void> _onRetryImport(
      RetryImportEvent event, Emitter<ImportState> emit) async {
    debugPrint("🔄 Retrying import for file: ${event.file.path}");
    await _performImport(event.file, emit);
  }

  Future<void> _onClearError(
      ClearErrorEvent event, Emitter<ImportState> emit) async {
    emit(ImportInitial());
  }

  Future<void> _performImport(File file, Emitter<ImportState> emit) async {
    try {
      emit(const ImportLoading(
        message:
            'Analyzing chat file...\nThis may take a moment for large chats',
      ));

      // Validate file again before processing
      if (!await fileProvider.validateFile(file)) {
        throw Exception(
            'File validation failed. Please ensure this is a valid WhatsApp chat export.');
      }

      emit(const ImportLoading(
        message: 'Parsing messages...',
      ));

      // Import the chat
      final chat = await importChatUseCase(file);

      emit(const ImportLoading(
        message: 'Finalizing...',
      ));

      // Validate the imported chat
      if (chat.messages.isEmpty) {
        throw Exception(
            'No messages found in the chat file. Please ensure this is a valid WhatsApp export.');
      }

      debugPrint(
          "✅ Import successful: ${chat.messages.length} messages, ${chat.users.length} users");

      emit(ImportSuccess(chat));
    } catch (e, stackTrace) {
      debugPrint("❌ Import failed: $e");
      debugPrint("Stack trace: $stackTrace");

      String userMessage;
      String technicalDetails = e.toString();

      if (e.toString().contains('File validation failed')) {
        userMessage =
            'This file doesn\'t appear to be a valid WhatsApp chat export';
      } else if (e.toString().contains('No messages found')) {
        userMessage = 'No messages could be found in this file';
      } else if (e.toString().contains('encoding')) {
        userMessage =
            'File encoding not supported. Try exporting the chat again';
      } else if (e.toString().contains('ZIP')) {
        userMessage =
            'ZIP file extraction failed. Please extract manually and share the .txt file';
      } else {
        userMessage = 'Failed to import chat file';
      }

      emit(ImportError(
        userMessage,
        technicalDetails: technicalDetails,
        failedFile: file,
      ));
    }
  }

  @override
  Future<void> close() {
    _sharedFilesSubscription?.cancel();
    fileProvider.dispose();
    return super.close();
  }
}
