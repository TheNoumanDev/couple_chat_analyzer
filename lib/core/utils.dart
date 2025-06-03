// core/utils.dart
// Consolidated: date_utils.dart + file_utils.dart + string_utils.dart + zip_utils.dart

import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'app.dart';
import 'exceptions.dart';

// ============================================================================
// DATE UTILITIES
// ============================================================================
class DateUtils {
  // Format date to YYYY-MM-DD
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
  
  // Format date to YYYY-MM-DD HH:MM
  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }
  
  // Format date range as "From X to Y"
  static String formatDateRange(DateTime start, DateTime end) {
    return 'From ${formatDate(start)} to ${formatDate(end)}';
  }
  
  // Get day of week name
  static String getDayOfWeek(DateTime date) {
    return DateFormat('EEEE').format(date);
  }
  
  // Get month name
  static String getMonthName(DateTime date) {
    return DateFormat('MMMM').format(date);
  }
  
  // Get year and month
  static String getYearMonth(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }
  
  // Calculate duration between two dates in days
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }
  
  // Format duration in seconds to human-readable format
  static String formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

// ============================================================================
// FILE UTILITIES
// ============================================================================
class FileUtils {
  // Get file extension
  static String getFileExtension(String filePath) {
    return path.extension(filePath).replaceAll('.', '').toLowerCase();
  }
  
  // Check if file has supported extension
  static bool isSupportedFileExtension(String filePath) {
    final extension = getFileExtension(filePath);
    return AppConstants.supportedFileExtensions.contains(extension);
  }
  
  // Get file mime type based on extension
  static String? getFileMimeType(String filePath) {
    final extension = getFileExtension(filePath);
    
    switch (extension) {
      case 'txt':
        return 'text/plain';
      case 'html':
        return 'text/html';
      default:
        return null;
    }
  }
  
  // Create directory if it doesn't exist
  static Future<Directory> ensureDirectoryExists(String dirPath) async {
    final directory = Directory(dirPath);
    
    if (await directory.exists()) {
      return directory;
    } else {
      return await directory.create(recursive: true);
    }
  }
  
  // Get application documents directory
  static Future<Directory> getAppDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }
  
  // Get reports directory
  static Future<Directory> getReportsDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${appDocDir.path}/${AppConstants.reportsFolderName}');
    
    return await ensureDirectoryExists(reportsDir.path);
  }
  
  // Generate unique filename
  static String generateUniqueFilename(String prefix, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$prefix-$timestamp.$extension';
  }
  
  // Copy file to app documents directory
  static Future<File> copyToAppDocuments(File sourceFile, {String? filename}) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final fileName = filename ?? path.basename(sourceFile.path);
      final targetPath = '${appDocDir.path}/$fileName';
      
      return await sourceFile.copy(targetPath);
    } catch (e) {
      throw FileException('Failed to copy file to app documents: $e');
    }
  }
  
  // Read file as string
  static Future<String> readFileAsString(File file) async {
    try {
      return await file.readAsString();
    } catch (e) {
      throw FileReadException(filePath: file.path, error: e);
    }
  }
}

// ============================================================================
// STRING UTILITIES
// ============================================================================
class StringUtils {
  // Check if a string is mostly emoji
  static bool isMostlyEmoji(String text) {
    if (text.isEmpty) return false;
    
    final emojiRegExp = RegExp(
      r'[\u{1F600}-\u{1F64F}|\u{1F300}-\u{1F5FF}|\u{1F680}-\u{1F6FF}|\u{2600}-\u{26FF}|\u{2700}-\u{27BF}]',
      unicode: true,
    );
    
    final emojiMatches = emojiRegExp.allMatches(text);
    final emojiLength = emojiMatches.fold<int>(0, (sum, match) => sum + (match.end - match.start));
    
    return emojiLength > text.length / 2;
  }
  
  // Extract URLs from text
  static List<String> extractUrls(String text) {
    final urlRegExp = RegExp(
      r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
    );
    
    return urlRegExp
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
  }
  
  // Extract domain from URL
  static String? extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return null;
    }
  }
  
  // Count words in text
  static int countWords(String text) {
    if (text.isEmpty) return 0;
    
    return text
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }
  
  // Get user initials from name
  static String getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final parts = name.split(' ');
    if (parts.length == 1) {
      return name.substring(0, 1).toUpperCase();
    }
    
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
  
  // Truncate text with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

// ============================================================================
// ZIP UTILITIES
// ============================================================================
class ZipUtils {
  /// Extracts WhatsApp chat text file from a ZIP archive
  /// Returns the extracted chat file or null if not found
  static Future<File?> extractWhatsAppChatFromZip(File zipFile) async {
    try {
      // Read the Zip file
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Create a temp directory to extract files
      final tempDir = await getTemporaryDirectory();
      final extractDir = Directory('${tempDir.path}/whatsapp_extract_${DateTime.now().millisecondsSinceEpoch}');
      await extractDir.create(recursive: true);
      
      // Print all files in the archive
      debugPrint("All files in archive:");
      for (final file in archive) {
        if (file.isFile) {
          debugPrint("- ${file.name} (${file.size} bytes)");
        }
      }
      
      // Look for chat text file (typically named _chat.txt or WhatsApp Chat with X.txt)
      File? chatFile;
      
      for (final file in archive) {
        if (file.isFile) {
          final filename = file.name.toLowerCase();
          debugPrint("Found file in archive: ${file.name}");
          
          // Check if this looks like a chat file
          if (filename.endsWith('.txt') && 
              (filename.contains('chat') || filename.contains('whatsapp'))) {
            final outFile = File('${extractDir.path}/${file.name}');
            await outFile.create(recursive: true);
            await outFile.writeAsBytes(file.content as List<int>);
            chatFile = outFile;
            debugPrint("Extracted chat file: ${outFile.path}");
            
            // Read the first few lines to verify content
            try {
              final content = await outFile.readAsString();
              final lines = content.split('\n');
              final firstLines = lines.take(10).join('\n');
              debugPrint("First 10 lines of extracted chat file:");
              debugPrint(firstLines);
            } catch (e) {
              debugPrint("Error reading extracted file: $e");
            }
            
            break;
          }
        }
      }
      
      // If no specific chat file found, just use the first .txt file
      if (chatFile == null) {
        for (final file in archive) {
          if (file.isFile && file.name.toLowerCase().endsWith('.txt')) {
            final outFile = File('${extractDir.path}/${file.name}');
            await outFile.create(recursive: true);
            await outFile.writeAsBytes(file.content as List<int>);
            chatFile = outFile;
            debugPrint("No chat file found, using first txt file: ${outFile.path}");
            break;
          }
        }
      }
      
      return chatFile;
    } catch (e) {
      debugPrint('Error extracting WhatsApp chat: $e');
      return null;
    }
  }
}