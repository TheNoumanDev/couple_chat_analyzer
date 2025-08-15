// ============================================================================
// FILE: core/utils.dart
// Consolidated utilities - Date, File, String, and ZIP operations
// ============================================================================
import 'dart:io';
import 'dart:convert';
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
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _dayFormat = DateFormat('EEEE');
  static final DateFormat _monthFormat = DateFormat('MMMM');
  static final DateFormat _yearMonthFormat = DateFormat('yyyy-MM');

  /// Format date to YYYY-MM-DD
  static String formatDate(DateTime date) => _dateFormat.format(date);
  
  /// Format date to YYYY-MM-DD HH:MM
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  
  /// Format date range as "From X to Y"
  static String formatDateRange(DateTime start, DateTime end) {
    return 'From ${formatDate(start)} to ${formatDate(end)}';
  }
  
  /// Get day of week name
  static String getDayOfWeek(DateTime date) => _dayFormat.format(date);
  
  /// Get month name
  static String getMonthName(DateTime date) => _monthFormat.format(date);
  
  /// Get year and month
  static String getYearMonth(DateTime date) => _yearMonthFormat.format(date);
  
  /// Calculate duration between two dates in days
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }
  
  /// Format duration in seconds to human-readable format
  static String formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Get relative time string (e.g., "2 hours ago", "yesterday")
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) return '${difference.inDays} days ago';
      if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';
      if (difference.inDays < 365) return '${(difference.inDays / 30).floor()} months ago';
      return '${(difference.inDays / 365).floor()} years ago';
    }

    if (difference.inHours > 0) return '${difference.inHours} hours ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes} minutes ago';
    return 'Just now';
  }
}

// ============================================================================
// FILE UTILITIES
// ============================================================================
class FileUtils {
  /// Get file extension without the dot
  static String getFileExtension(String filePath) {
    return path.extension(filePath).replaceAll('.', '').toLowerCase();
  }
  
  /// Check if file has supported extension
  static bool isSupportedFileExtension(String filePath) {
    final extension = getFileExtension(filePath);
    return AppConstants.supportedFileExtensions.contains(extension);
  }
  
  /// Get file mime type based on extension
  static String? getFileMimeType(String filePath) {
    final extension = getFileExtension(filePath);
    
    switch (extension) {
      case 'txt':
        return 'text/plain';
      case 'html':
        return 'text/html';
      case 'zip':
        return 'application/zip';
      default:
        return null;
    }
  }
  
  /// Create directory if it doesn't exist
  static Future<Directory> ensureDirectoryExists(String dirPath) async {
    final directory = Directory(dirPath);
    
    if (await directory.exists()) {
      return directory;
    } else {
      return await directory.create(recursive: true);
    }
  }
  
  /// Get application documents directory
  static Future<Directory> getAppDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }
  
  /// Get reports directory
  static Future<Directory> getReportsDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${appDocDir.path}/${AppConstants.reportsFolderName}');
    
    return await ensureDirectoryExists(reportsDir.path);
  }
  
  /// Generate unique filename with timestamp
  static String generateUniqueFilename(String prefix, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${prefix}_${formattedDate}_$timestamp.$extension';
  }
  
  /// Copy file to app documents directory
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
  
  /// Read file as string with encoding detection
  static Future<String> readFileAsString(File file) async {
    try {
      // Try UTF-8 first
      try {
        return await file.readAsString(encoding: utf8);
      } catch (_) {
        // Fall back to latin1 if UTF-8 fails
        return await file.readAsString(encoding: latin1);
      }
    } catch (e) {
      throw FileReadException(filePath: file.path, error: e);
    }
  }

  /// Get human-readable file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Check if file is likely a text file
  static Future<bool> isTextFile(File file) async {
    try {
      final bytes = await file.openRead(0, 512).first;
      // Check for null bytes which indicate binary files
      return !bytes.contains(0);
    } catch (e) {
      return false;
    }
  }

  /// Get file name without extension
  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }
}

// ============================================================================
// STRING UTILITIES
// ============================================================================
class StringUtils {
  static final RegExp _emojiRegExp = RegExp(
    r'[\u{1F600}-\u{1F64F}|\u{1F300}-\u{1F5FF}|\u{1F680}-\u{1F6FF}|\u{2600}-\u{26FF}|\u{2700}-\u{27BF}]',
    unicode: true,
  );

  static final RegExp _urlRegExp = RegExp(
    r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
  );

  /// Check if a string is mostly emoji
  static bool isMostlyEmoji(String text) {
    if (text.isEmpty) return false;
    
    final emojiMatches = _emojiRegExp.allMatches(text);
    final emojiLength = emojiMatches.fold<int>(0, (sum, match) => sum + (match.end - match.start));
    
    return emojiLength > text.length / 2;
  }
  
  /// Extract URLs from text
  static List<String> extractUrls(String text) {
    return _urlRegExp
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
  }
  
  /// Extract domain from URL
  static String? extractDomain(String url) {
    try {
      // Add protocol if missing
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      debugPrint('Error extracting domain from URL: $url - $e');
      return null;
    }
  }
  
  /// Count words in text
  static int countWords(String text) {
    if (text.trim().isEmpty) return 0;
    
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }
  
  /// Get user initials from name
  static String getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    
    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'.toUpperCase();
  }
  
  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Clean text by removing extra whitespace and newlines
  static String cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Capitalize first letter of each word
  static String titleCase(String text) {
    return text.split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : word)
        .join(' ');
  }

  /// Count emojis in text
  static int countEmojis(String text) {
    return _emojiRegExp.allMatches(text).length;
  }

  /// Remove emojis from text
  static String removeEmojis(String text) {
    return text.replaceAll(_emojiRegExp, '');
  }

  /// Check if string contains only emojis and whitespace
  static bool isOnlyEmojis(String text) {
    final withoutEmojis = removeEmojis(text).trim();
    return withoutEmojis.isEmpty && text.trim().isNotEmpty;
  }

  /// Generate a slug from text (URL-friendly)
  static String toSlug(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}

// ============================================================================
// ZIP UTILITIES
// ============================================================================
class ZipUtils {
  /// Extract WhatsApp chat text file from a ZIP archive
  static Future<File?> extractWhatsAppChatFromZip(File zipFile) async {
    try {
      debugPrint("📦 Extracting WhatsApp chat from ZIP: ${zipFile.path}");
      
      // Read the Zip file
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Create a temp directory to extract files
      final tempDir = await getTemporaryDirectory();
      final extractDir = Directory('${tempDir.path}/whatsapp_extract_${DateTime.now().millisecondsSinceEpoch}');
      await extractDir.create(recursive: true);
      
      debugPrint("📂 Archive contains ${archive.length} files");
      
      // Look for chat text file
      File? chatFile;
      
      for (final file in archive) {
        if (file.isFile) {
          final filename = file.name.toLowerCase();
          debugPrint("📄 Found file: ${file.name}");
          
          // Check if this looks like a chat file
          if (filename.endsWith('.txt') && 
              (filename.contains('chat') || 
               filename.contains('whatsapp') ||
               filename.contains('_chat.txt'))) {
            
            final outFile = File('${extractDir.path}/${file.name}');
            await outFile.create(recursive: true);
            await outFile.writeAsBytes(file.content as List<int>);
            chatFile = outFile;
            
            debugPrint("✅ Extracted chat file: ${outFile.path}");
            break;
          }
        }
      }
      
      // If no specific chat file found, use the first .txt file
      if (chatFile == null) {
        for (final file in archive) {
          if (file.isFile && file.name.toLowerCase().endsWith('.txt')) {
            final outFile = File('${extractDir.path}/${file.name}');
            await outFile.create(recursive: true);
            await outFile.writeAsBytes(file.content as List<int>);
            chatFile = outFile;
            debugPrint("📝 Using first txt file: ${outFile.path}");
            break;
          }
        }
      }
      
      return chatFile;
    } catch (e, stackTrace) {
      debugPrint('❌ Error extracting WhatsApp chat from ZIP: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Check if file is a ZIP archive
  static Future<bool> isZipFile(File file) async {
    try {
      final bytes = await file.openRead(0, 4).first;
      // ZIP files start with PK (0x504B)
      return bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B;
    } catch (e) {
      debugPrint('Error checking if file is ZIP: $e');
      return false;
    }
  }

  /// Get list of files in ZIP archive without extracting
  static Future<List<String>> listZipContents(File zipFile) async {
    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      return archive
          .where((file) => file.isFile)
          .map((file) => file.name)
          .toList();
    } catch (e) {
      debugPrint('Error listing ZIP contents: $e');
      return [];
    }
  }
}