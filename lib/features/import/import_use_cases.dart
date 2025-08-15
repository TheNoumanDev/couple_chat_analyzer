// ============================================================================
// FILE: features/import/import_use_cases.dart
// Import use cases - Fixed constructor for DI compatibility
// ============================================================================
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../shared/domain.dart';

class ImportChatUseCase {
  final ChatRepository repository;

  // Fixed: Use positional parameter to match DI registration
  ImportChatUseCase(this.repository);

  Future<ChatEntity> call(File file) async {
    debugPrint("ImportChatUseCase: Starting import for file: ${file.path}");

    try {
      final chat = await repository.importChat(file);
      
      debugPrint("ImportChatUseCase: Import completed successfully");
      debugPrint("  - Messages: ${chat.messages.length}");
      debugPrint("  - Users: ${chat.users.length}");
      debugPrint("  - Date range: ${chat.firstMessageDate} to ${chat.lastMessageDate}");

      return chat;
    } catch (e, stackTrace) {
      debugPrint("ImportChatUseCase: Import failed with error: $e");
      debugPrint("Stack trace: $stackTrace");
      rethrow;
    }
  }

  // Alternative method with named parameters for flexibility
  Future<ChatEntity> execute({required File file}) async {
    return await call(file);
  }

  // Method to validate file before import
  Future<bool> validateFile(File file) async {
    try {
      debugPrint("ImportChatUseCase: Validating file: ${file.path}");

      // Check if file exists
      if (!await file.exists()) {
        debugPrint("ImportChatUseCase: File does not exist");
        return false;
      }

      // Check file size (should not be empty or too large)
      final fileSize = await file.length();
      if (fileSize == 0) {
        debugPrint("ImportChatUseCase: File is empty");
        return false;
      }

      const maxFileSize = 100 * 1024 * 1024; // 100MB
      if (fileSize > maxFileSize) {
        debugPrint("ImportChatUseCase: File too large: ${fileSize} bytes");
        return false;
      }

      // Check file extension
      final fileName = file.path.toLowerCase();
      final supportedExtensions = ['.txt', '.html', '.zip'];
      final hasValidExtension = supportedExtensions.any((ext) => fileName.endsWith(ext));
      
      if (!hasValidExtension) {
        debugPrint("ImportChatUseCase: Unsupported file extension");
        return false;
      }

      debugPrint("ImportChatUseCase: File validation passed");
      return true;
    } catch (e) {
      debugPrint("ImportChatUseCase: Error validating file: $e");
      return false;
    }
  }

  // Method to get file info before import
  Future<Map<String, dynamic>> getFileInfo(File file) async {
    try {
      final stat = await file.stat();
      final fileName = file.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();
      
      return {
        'fileName': fileName,
        'fileSize': stat.size,
        'fileSizeFormatted': _formatFileSize(stat.size),
        'fileExtension': fileExtension,
        'lastModified': stat.modified,
        'isValid': await validateFile(file),
        'estimatedMessages': await _estimateMessageCount(file),
      };
    } catch (e) {
      debugPrint("ImportChatUseCase: Error getting file info: $e");
      return {
        'fileName': 'Unknown',
        'fileSize': 0,
        'fileSizeFormatted': '0 B',
        'fileExtension': 'unknown',
        'lastModified': DateTime.now(),
        'isValid': false,
        'estimatedMessages': 0,
      };
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<int> _estimateMessageCount(File file) async {
    try {
      // Read a sample of the file to estimate message count
      final sampleSize = 1024 * 10; // 10KB sample
      final bytes = await file.openRead(0, sampleSize).first;
      final sample = String.fromCharCodes(bytes);
      
      // Count lines that look like messages (contain timestamps)
      final lines = sample.split('\n');
      int messageLines = 0;
      
      for (final line in lines) {
        // Simple check for timestamp patterns
        if (RegExp(r'\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4}').hasMatch(line)) {
          messageLines++;
        }
      }
      
      if (messageLines == 0) return 0;
      
      // Estimate total based on sample
      final fileSize = await file.length();
      final estimatedTotal = (messageLines * fileSize / sampleSize).round();
      
      debugPrint("ImportChatUseCase: Estimated $estimatedTotal messages based on sample");
      return estimatedTotal;
    } catch (e) {
      debugPrint("ImportChatUseCase: Error estimating message count: $e");
      return 0;
    }
  }
}