import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class ParsedMessage {
  final DateTime timestamp;
  final String senderName;
  final String content;

  ParsedMessage({
    required this.timestamp,
    required this.senderName,
    required this.content,
  });

  @override
  String toString() {
    return 'ParsedMessage(timestamp: $timestamp, sender: $senderName, content: ${content.length} chars)';
  }
}

class TimestampParser {
  // All supported WhatsApp timestamp patterns
  final List<_TimestampPattern> _patterns = [
    // US format with AM/PM: 12/31/21, 11:59 PM - Sender: Message
    _TimestampPattern(
      name: 'US AM/PM',
      regex: RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4}),?\s+(\d{1,2}):(\d{2})\s*([APap][Mm])\s*[-–]\s*([^:]+?):\s*(.*)$'),
      parser: (match) => ParsedMessage(
        timestamp: _parseUSDateTime(match),
        senderName: match.group(7)!.trim(),
        content: match.group(8)!.trim(),
      ),
    ),
    
    // European format: 31/12/2021, 23:59 - Sender: Message
    _TimestampPattern(
      name: 'European 24h',
      regex: RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4}),?\s+(\d{1,2}):(\d{2})\s*[-–]\s*([^:]+?):\s*(.*)$'),
      parser: (match) => ParsedMessage(
        timestamp: _parseEuropeanDateTime(match),
        senderName: match.group(6)!.trim(),
        content: match.group(7)!.trim(),
      ),
    ),
    
    // Dot format: 31.12.2021, 23:59 - Sender: Message
    _TimestampPattern(
      name: 'Dot format',
      regex: RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{2,4}),?\s+(\d{1,2}):(\d{2})\s*[-–]\s*([^:]+?):\s*(.*)$'),
      parser: (match) => ParsedMessage(
        timestamp: TimestampParser._parseDotDateTime(match),
        senderName: match.group(6)!.trim(),
        content: match.group(7)!.trim(),
      ),
    ),
    
    // ISO format: 2021-12-31, 23:59 - Sender: Message
    _TimestampPattern(
      name: 'ISO format',
      regex: RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2}),?\s+(\d{1,2}):(\d{2})\s*[-–]\s*([^:]+?):\s*(.*)$'),
      parser: (match) => ParsedMessage(
        timestamp: _parseISODateTime(match),
        senderName: match.group(6)!.trim(),
        content: match.group(7)!.trim(),
      ),
    ),

    // Alternative format with brackets: [31/12/21, 23:59:45] Sender: Message
    _TimestampPattern(
      name: 'Bracket format',
      regex: RegExp(r'^\[(\d{1,2})/(\d{1,2})/(\d{2,4}),?\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\]\s*([^:]+?):\s*(.*)$'),
      parser: (match) => ParsedMessage(
        timestamp: _parseEuropeanDateTime(match),
        senderName: match.group(7)!.trim(),
        content: match.group(8)!.trim(),
      ),
    ),

    // WhatsApp Business format: DD/MM/YYYY HH:MM - Sender: Message
    _TimestampPattern(
      name: 'Business format',
      regex: RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{2})\s*[-–]\s*([^:]+?):\s*(.*)$'),
      parser: (match) => ParsedMessage(
        timestamp: TimestampParser._parseBusinessDateTime(match),
        senderName: match.group(5)!.trim(),
        content: match.group(6)!.trim(),
      ),
    ),

    // System message format (no sender): 31/12/2021, 23:59 - Message
    _TimestampPattern(
      name: 'System message',
      regex: RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4}),?\s+(\d{1,2}):(\d{2})\s*[-–]\s*(.*)$'),
      parser: (match) => ParsedMessage(
        timestamp: _parseEuropeanDateTime(match),
        senderName: 'System',
        content: match.group(5)!.trim(),
      ),
    ),
  ];

  ParsedMessage? tryParseMessage(String line) {
    // Clean the line first
    final cleanLine = line.trim();
    if (cleanLine.isEmpty) return null;

    // Try each pattern
    for (final pattern in _patterns) {
      final match = pattern.regex.firstMatch(cleanLine);
      if (match != null) {
        try {
          final parsed = pattern.parser(match);
          
          // Validate the parsed message
          if (_isValidParsedMessage(parsed)) {
            debugPrint("✅ Parsed with ${pattern.name}: ${parsed.senderName}");
            return parsed;
          } else {
            debugPrint("⚠️ Invalid parsed message from ${pattern.name}");
          }
        } catch (e) {
          debugPrint("⚠️ Error parsing with ${pattern.name}: $e");
          continue;
        }
      }
    }
    
    return null;
  }

  bool _isValidParsedMessage(ParsedMessage parsed) {
    // Check if timestamp is reasonable
    if (!isValidTimestamp(parsed.timestamp)) {
      return false;
    }

    // Check if sender name is reasonable
    if (parsed.senderName.isEmpty || parsed.senderName.length > 100) {
      return false;
    }

    // Content can be empty (for media messages)
    if (parsed.content.length > 65536) { // 64KB max
      return false;
    }

    return true;
  }

  static DateTime _parseUSDateTime(RegExpMatch match) {
    int month = int.parse(match.group(1)!);
    int day = int.parse(match.group(2)!);
    int year = int.parse(match.group(3)!);
    int hour = int.parse(match.group(4)!);
    int minute = int.parse(match.group(5)!);
    String ampm = match.group(6)!.toLowerCase();

    // Convert 12-hour to 24-hour format
    if (ampm == 'pm' && hour != 12) {
      hour += 12;
    } else if (ampm == 'am' && hour == 12) {
      hour = 0;
    }

    // Convert 2-digit year to 4-digit
    if (year < 100) {
      year += (year < 50) ? 2000 : 1900;
    }

    return DateTime(year, month, day, hour, minute);
  }

  static DateTime _parseEuropeanDateTime(RegExpMatch match) {
    int day = int.parse(match.group(1)!);
    int month = int.parse(match.group(2)!);
    int year = int.parse(match.group(3)!);
    int hour = int.parse(match.group(4)!);
    int minute = int.parse(match.group(5)!);

    // Convert 2-digit year to 4-digit
    if (year < 100) {
      year += (year < 50) ? 2000 : 1900;
    }

    return DateTime(year, month, day, hour, minute);
  }

  static DateTime _parseDotDateTime(RegExpMatch match) {
    int day = int.parse(match.group(1)!);
    int month = int.parse(match.group(2)!);
    int year = int.parse(match.group(3)!);
    int hour = int.parse(match.group(4)!);
    int minute = int.parse(match.group(5)!);

    // Convert 2-digit year to 4-digit
    if (year < 100) {
      year += (year < 50) ? 2000 : 1900;
    }

    return DateTime(year, month, day, hour, minute);
  }

  static DateTime _parseISODateTime(RegExpMatch match) {
    int year = int.parse(match.group(1)!);
    int month = int.parse(match.group(2)!);
    int day = int.parse(match.group(3)!);
    int hour = int.parse(match.group(4)!);
    int minute = int.parse(match.group(5)!);

    return DateTime(year, month, day, hour, minute);
  }

  static DateTime _parseBusinessDateTime(RegExpMatch match) {
    int day = int.parse(match.group(1)!);
    int month = int.parse(match.group(2)!);
    int year = int.parse(match.group(3)!);
    int hour = int.parse(match.group(4)!);
    int minute = int.parse(match.group(5)!);

    return DateTime(year, month, day, hour, minute);
  }

  bool isValidTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final earliestDate = DateTime(2009, 1, 1); // WhatsApp was founded in 2009
    final futureLimit = now.add(Duration(days: 1)); // Allow 1 day in future for timezone issues
    
    return timestamp.isAfter(earliestDate) && timestamp.isBefore(futureLimit);
  }

  String formatTimestamp(DateTime timestamp) {
    return DateFormat('yyyy-MM-dd HH:mm').format(timestamp);
  }

  // Get statistics about parsing patterns used
  Map<String, int> getPatternStats() {
    final stats = <String, int>{};
    for (final pattern in _patterns) {
      stats[pattern.name] = 0;
    }
    return stats;
  }

  // Test a line against all patterns for debugging
  List<String> testAllPatterns(String line) {
    final results = <String>[];
    for (final pattern in _patterns) {
      final match = pattern.regex.firstMatch(line);
      if (match != null) {
        results.add('✅ ${pattern.name}: matches');
        try {
          final parsed = pattern.parser(match);
          results.add('   Sender: ${parsed.senderName}');
          results.add('   Time: ${parsed.timestamp}');
          results.add('   Content: ${parsed.content.substring(0, 50)}...');
        } catch (e) {
          results.add('   ❌ Parse error: $e');
        }
      } else {
        results.add('❌ ${pattern.name}: no match');
      }
    }
    return results;
  }
}

class _TimestampPattern {
  final String name;
  final RegExp regex;
  final ParsedMessage Function(RegExpMatch) parser;

  _TimestampPattern({
    required this.name,
    required this.regex,
    required this.parser,
  });
}