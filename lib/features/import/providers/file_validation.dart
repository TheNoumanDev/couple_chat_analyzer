import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class FileValidationService {
  static const int maxFileSizeBytes = 100 * 1024 * 1024; // 100MB
  static const List<String> supportedExtensions = ['txt', 'html', 'zip'];

  static Future<FileValidationResult> validateFile(File file) async {
    try {
      // Check file existence
      if (!await file.exists()) {
        return FileValidationResult.error('File does not exist');
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize == 0) {
        return FileValidationResult.error('File is empty');
      }

      if (fileSize > maxFileSizeBytes) {
        return FileValidationResult.error('File too large (max 100MB)');
      }

      // Check file type
      final fileName = file.path.toLowerCase();
      final extension = fileName.split('.').last;

      if (!supportedExtensions.contains(extension)) {
        return FileValidationResult.warning(
          'Unsupported file extension: .$extension',
          canProceed: true,
        );
      }

      // Validate content based on file type
      if (extension == 'zip') {
        return await _validateZipContent(file);
      } else if (extension == 'html') {
        return await _validateHtmlContent(file);
      } else if (extension == 'txt') {
        return await _validateTextContent(file);
      }

      return FileValidationResult.success('File validation passed');
    } catch (e) {
      debugPrint("❌ File validation error: $e");
      return FileValidationResult.error('Validation failed: $e');
    }
  }

  static Future<FileValidationResult> _validateZipContent(File file) async {
    try {
      final bytes = await file.openRead(0, 4).first;
      if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
        return FileValidationResult.success('Valid ZIP file');
      }
      return FileValidationResult.error('Invalid ZIP file format');
    } catch (e) {
      return FileValidationResult.error('Could not read ZIP file');
    }
  }

  static Future<FileValidationResult> _validateHtmlContent(File file) async {
    try {
      final content = await file.readAsString(encoding: utf8);
      
      if (content.contains('<html') && 
          (content.contains('WhatsApp') || content.contains('<!doctype'))) {
        return FileValidationResult.success('Valid HTML chat file');
      }
      
      return FileValidationResult.warning(
        'HTML file may not be a WhatsApp export',
        canProceed: true,
      );
    } catch (e) {
      return FileValidationResult.error('Could not read HTML file');
    }
  }

  static Future<FileValidationResult> _validateTextContent(File file) async {
    try {
      String content;
      
      // Try different encodings
      try {
        content = await file.readAsString(encoding: utf8);
      } catch (e) {
        try {
          content = await file.readAsString(encoding: latin1);
        } catch (e) {
          content = await file.readAsString(encoding: ascii);
        }
      }
      
      // Check for WhatsApp patterns
      final hasDatePattern = content.contains(RegExp(r'\d{1,2}[/.]\d{1,2}[/.]\d{2,4}'));
      final hasMessagePattern = content.contains(' - ') || content.contains(': ');
      
      if (hasDatePattern && hasMessagePattern) {
        return FileValidationResult.success('Valid WhatsApp chat file');
      }
      
      return FileValidationResult.warning(
        'File may not be a WhatsApp export',
        canProceed: true,
      );
    } catch (e) {
      return FileValidationResult.error('Could not read text file');
    }
  }
}

class FileValidationResult {
  final bool isValid;
  final bool canProceed;
  final String message;
  final FileValidationType type;

  const FileValidationResult._({
    required this.isValid,
    required this.canProceed,
    required this.message,
    required this.type,
  });

  factory FileValidationResult.success(String message) {
    return FileValidationResult._(
      isValid: true,
      canProceed: true,
      message: message,
      type: FileValidationType.success,
    );
  }

  factory FileValidationResult.warning(String message, {bool canProceed = false}) {
    return FileValidationResult._(
      isValid: false,
      canProceed: canProceed,
      message: message,
      type: FileValidationType.warning,
    );
  }

  factory FileValidationResult.error(String message) {
    return FileValidationResult._(
      isValid: false,
      canProceed: false,
      message: message,
      type: FileValidationType.error,
    );
  }
}

enum FileValidationType {
  success,
  warning,
  error,
}