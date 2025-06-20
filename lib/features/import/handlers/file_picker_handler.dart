import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

class FilePickerHandler {
  static const List<String> supportedExtensions = ['txt', 'html', 'zip'];

  Future<File?> pickFile({
    List<String>? allowedExtensions,
    String? dialogTitle,
  }) async {
    try {
      debugPrint("📁 Opening file picker");

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? supportedExtensions,
        allowMultiple: false,
        dialogTitle: dialogTitle ?? 'Select WhatsApp Chat Export',
        lockParentWindow: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          final file = File(path);
          debugPrint("📄 File selected: ${file.path}");
          
          // Basic validation
          if (await file.exists()) {
            final fileSize = await file.length();
            debugPrint("📏 File size: ${fileSize} bytes");
            return file;
          } else {
            debugPrint("❌ Selected file does not exist");
            return null;
          }
        }
      }

      debugPrint("📄 No file selected");
      return null;
    } catch (e) {
      debugPrint("❌ Error picking file: $e");
      rethrow;
    }
  }

  Future<List<File>?> pickMultipleFiles({
    List<String>? allowedExtensions,
    String? dialogTitle,
    int? maxFiles,
  }) async {
    try {
      debugPrint("📁 Opening multiple file picker");

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? supportedExtensions,
        allowMultiple: true,
        dialogTitle: dialogTitle ?? 'Select WhatsApp Chat Exports',
        lockParentWindow: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final files = <File>[];
        
        for (final platformFile in result.files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            if (await file.exists()) {
              files.add(file);
              debugPrint("📄 File added: ${file.path}");
            }
          }
        }

        if (maxFiles != null && files.length > maxFiles) {
          debugPrint("⚠️ Too many files selected, taking first $maxFiles");
          return files.take(maxFiles).toList();
        }

        debugPrint("📄 ${files.length} files selected");
        return files.isNotEmpty ? files : null;
      }

      debugPrint("📄 No files selected");
      return null;
    } catch (e) {
      debugPrint("❌ Error picking multiple files: $e");
      rethrow;
    }
  }

  String getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }

  bool isSupportedFile(String filePath) {
    final extension = getFileExtension(filePath);
    return supportedExtensions.contains(extension);
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}