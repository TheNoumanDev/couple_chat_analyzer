import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class EncodingDetector {
  Future<String> readWithBestEncoding(File file) async {
    final bytes = await file.readAsBytes();
    debugPrint("📥 Read ${bytes.length} bytes from file");

    // Try different encodings in order of preference
    try {
      // Try UTF-8 first
      final content = utf8.decode(bytes);
      debugPrint("✅ Successfully decoded with UTF-8");
      return content;
    } catch (e) {
      debugPrint("⚠️ UTF-8 decoding failed: $e");

      try {
        // Try UTF-8 with malformed handling
        final content = const Utf8Decoder(allowMalformed: true).convert(bytes);
        debugPrint("✅ Successfully decoded with UTF-8 (malformed)");
        return content;
      } catch (e) {
        debugPrint("⚠️ UTF-8 (malformed) decoding failed: $e");

        try {
          // Try Latin-1
          final content = latin1.decode(bytes);
          debugPrint("✅ Successfully decoded with Latin-1");
          return content;
        } catch (e) {
          debugPrint("⚠️ Latin-1 decoding failed: $e");

          try {
            // Try ASCII
            final content = ascii.decode(bytes, allowInvalid: true);
            debugPrint("✅ Successfully decoded with ASCII");
            return content;
          } catch (e) {
            debugPrint("⚠️ ASCII decoding failed: $e");

            // Last resort: clean ASCII with character filtering
            debugPrint("🔧 Using filtered ASCII as last resort");
            final cleanBytes = bytes
                .where((b) => b >= 32 && b < 127 || b == 10 || b == 13)
                .toList();
            return ascii.decode(cleanBytes, allowInvalid: true);
          }
        }
      }
    }
  }

  Encoding detectEncoding(List<int> bytes) {
    // Simple encoding detection based on BOM and content analysis
    
    // Check for BOM (Byte Order Mark)
    if (bytes.length >= 3) {
      if (bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
        return utf8; // UTF-8 BOM
      }
    }

    if (bytes.length >= 2) {
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
        return utf8; // UTF-16 LE (treat as UTF-8)
      }
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
        return utf8; // UTF-16 BE (treat as UTF-8)
      }
    }

    // Analyze content for encoding hints
    final sample = bytes.take(1024).toList();
    
    // Check for high-bit characters that might indicate UTF-8
    bool hasHighBitChars = sample.any((b) => b > 127);
    
    if (!hasHighBitChars) {
      return ascii; // Pure ASCII
    }

    // Default to UTF-8 for modern files
    return utf8;
  }

  bool isValidUtf8(List<int> bytes) {
    try {
      utf8.decode(bytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool isValidLatin1(List<int> bytes) {
    try {
      latin1.decode(bytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  String cleanInvisibleCharacters(String text) {
    // Remove various invisible Unicode characters that can mess up parsing
    return text
        .replaceAll(RegExp(r'[\u200B-\u200F\uFEFF\u2028-\u202F\u00AD]'), '')
        .replaceAll(RegExp(r'[\u202A-\u202E]'), '') // Bidirectional text marks
        .replaceAll(RegExp(r'[\u061C\u2066-\u2069]'), ''); // More bidirectional marks
  }

  List<String> cleanLines(List<String> lines) {
    return lines
        .map((line) => cleanInvisibleCharacters(line.trim()))
        .where((line) => line.isNotEmpty)
        .toList();
  }
}