import 'dart:async';
import 'dart:io';
import 'package:chatreport/features/import/providers/file_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'import_events.dart';
import 'import_states.dart';
import 'import_use_cases.dart';
import 'providers/file_provider.dart';

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