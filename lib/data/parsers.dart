// data/parsers.dart
// Consolidated: chat_parser.dart + whatsapp_text_parser.dart + whatsapp_html_parser.dart

import 'dart:io';
import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../shared/models.dart';
import '../shared/domain.dart';

// ============================================================================
// CHAT PARSER INTERFACE
// ============================================================================
abstract class ChatParser {
  Future<Chat> parseChat(File file);
}

class ChatParserImpl implements ChatParser {
  final WhatsAppTextParser textParser;
  final WhatsAppHtmlParser htmlParser;

  ChatParserImpl({
    required this.textParser,
    required this.htmlParser,
  });

  @override
  Future<Chat> parseChat(File file) async {
    final String content = await file.readAsString();

    if (content.contains("<html") && content.contains("WhatsApp Chat")) {
      return htmlParser.parse(file);
    } else {
      return textParser.parse(file);
    }
  }
}

// ============================================================================
// WHATSAPP TEXT PARSER
// ============================================================================
abstract class WhatsAppTextParser {
  Future<Chat> parse(File file);
}

class WhatsAppTextParserImpl implements WhatsAppTextParser {
  final _uuid = const Uuid();

  @override
  Future<Chat> parse(File file) async {
    debugPrint("📝 Parsing WhatsApp text file: ${file.path}");

    try {
      // Enhanced encoding detection
      final content = await _readWithBestEncoding(file);
      debugPrint("📄 Successfully read file with ${content.length} characters");

      final lines = content.split('\n');
      debugPrint("📊 Processing ${lines.length} lines");

      // Extract chat title
      String title = _extractTitleFromFilename(file.path);

      final messages = <Message>[];
      final userMap = <String, User>{};

      // Parse messages with enhanced pattern matching
      await _parseMessagesWithPatterns(lines, messages, userMap);

      // Debug: Log all users created
      debugPrint("👥 Users created during parsing:");
      for (final user in userMap.values) {
        debugPrint("  - Name: '${user.name}', ID: ${user.id}");
      }

      // Validate and sort messages
      _validateAndSortMessages(messages);

      debugPrint(
          "✅ Parsing complete: ${messages.length} messages, ${userMap.length} users");

      return Chat(
        id: _uuid.v4(),
        title: title,
        importDate: DateTime.now(),
        users: userMap.values.toList(),
        messages: messages,
        firstMessageDate:
            messages.isNotEmpty ? messages.first.timestamp : DateTime.now(),
        lastMessageDate:
            messages.isNotEmpty ? messages.last.timestamp : DateTime.now(),
      );
    } catch (e, stackTrace) {
      debugPrint("❌ Error parsing text file: $e");
      debugPrint("Stack trace: $stackTrace");
      rethrow;
    }
  }

  // Fixed _readWithBestEncoding function in WhatsAppTextParserImpl
  Future<String> _readWithBestEncoding(File file) async {
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

  String _extractTitleFromFilename(String filePath) {
    String title = filePath.split('/').last;

    // Remove file extension
    if (title.toLowerCase().endsWith('.txt')) {
      title = title.substring(0, title.length - 4);
    }

    // Clean up common prefixes
    if (title.startsWith('WhatsApp Chat with ')) {
      title = title.substring('WhatsApp Chat with '.length);
    } else if (title.startsWith('WhatsApp Chat - ')) {
      title = title.substring('WhatsApp Chat - '.length);
    }

    return title.isNotEmpty ? title : 'WhatsApp Chat';
  }

  Future<void> _parseMessagesWithPatterns(List<String> lines,
      List<Message> messages, Map<String, User> userMap) async {
    // Enhanced WhatsApp message patterns
    final patterns = [
      // US format with AM/PM: 12/31/21, 11:59 PM - Sender: Message
      RegExp(
          r'^(\d{1,2}/\d{1,2}/\d{2,4}),?\s+(\d{1,2}:\d{2}\s*[APap][Mm])\s*[-–]\s*([^:]+?):\s*(.*)$'),
      // 24-hour format: 12/31/21, 23:59 - Sender: Message
      RegExp(
          r'^(\d{1,2}/\d{1,2}/\d{2,4}),?\s+(\d{1,2}:\d{2})\s*[-–]\s*([^:]+?):\s*(.*)$'),
      // European format: 31.12.21, 23:59 - Sender: Message
      RegExp(
          r'^(\d{1,2}\.\d{1,2}\.\d{2,4}),?\s+(\d{1,2}:\d{2})\s*[-–]\s*([^:]+?):\s*(.*)$'),
      // System messages: 12/31/21, 11:59 PM - System message
      RegExp(
          r'^(\d{1,2}[/.]\d{1,2}[/.]\d{2,4}),?\s+(\d{1,2}:\d{2}(?:\s*[APap][Mm])?)\s*[-–]\s*(.+)$'),
    ];

    String? currentSender;
    String? currentTimestamp;
    String currentContent = '';
    int processedLines = 0;
    int matchedMessages = 0;

    for (final line in lines) {
      processedLines++;
      bool matched = false;

      // Try each pattern
      for (int i = 0; i < patterns.length; i++) {
        final match = patterns[i].firstMatch(line);
        if (match != null) {
          matched = true;
          matchedMessages++;

          // Save previous message if exists
          if (currentSender != null &&
              currentTimestamp != null &&
              currentContent.isNotEmpty) {
            _addMessage(messages, userMap, currentSender, currentTimestamp,
                currentContent);
          }

          // Start new message
          final dateStr = match.group(1)!;
          final timeStr = match.group(2)!;

          if (i < 3) {
            // Regular message with sender
            currentSender = match.group(3)!.trim();
            currentTimestamp = '$dateStr $timeStr';
            currentContent = match.group(4)?.trim() ?? '';
          } else {
            // System message (pattern index 3)
            currentSender = "System";
            currentTimestamp = '$dateStr $timeStr';
            currentContent = match.group(3)?.trim() ?? '';
          }
          break;
        }
      }

      if (!matched && currentSender != null) {
        // Continue previous message with new line
        if (currentContent.isNotEmpty) {
          currentContent += '\n$line';
        } else {
          currentContent = line;
        }
      }

      // Progress tracking for large files
      if (processedLines % 5000 == 0) {
        debugPrint(
            "📊 Processed $processedLines lines, matched $matchedMessages messages");
        // Allow other operations to run
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    // Add the last message
    if (currentSender != null &&
        currentTimestamp != null &&
        currentContent.isNotEmpty) {
      _addMessage(
          messages, userMap, currentSender, currentTimestamp, currentContent);
    }

    debugPrint(
        "📈 Final stats: $processedLines lines processed, $matchedMessages messages matched");
  }

  void _validateAndSortMessages(List<Message> messages) {
    if (messages.isEmpty) {
      debugPrint("⚠️ No messages parsed, creating placeholder");
      final userId = _uuid.v4();
      messages.add(Message(
        id: _uuid.v4(),
        senderId: userId,
        timestamp: DateTime.now(),
        type: MessageType.text,
        content: 'No messages could be parsed from this file',
        metadata: {'placeholder': true},
      ));
    } else {
      // Sort messages by timestamp
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      debugPrint("📅 Messages sorted by timestamp");
    }
  }

  DateTime _parseTimestamp(String timestamp) {
    try {
      // Clean the timestamp string
      String cleanTimestamp = timestamp.trim();

      // Remove any invisible Unicode characters
      cleanTimestamp = cleanTimestamp.replaceAll(
          RegExp(r'[\u200B-\u200F\uFEFF\u2028-\u202F]'), '');

      // Try different timestamp patterns
      final patterns = [
        // US format with AM/PM: 12/31/21, 11:59 PM
        _TimestampPattern(
          regex: RegExp(
              r'^(\d{1,2})/(\d{1,2})/(\d{2,4}),?\s+(\d{1,2}):(\d{2})\s*(AM|PM)$',
              caseSensitive: false),
          parser: (match) => _parseUSDateTime(match),
        ),
        // US format without AM/PM: 12/31/21, 23:59
        _TimestampPattern(
          regex:
              RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4}),?\s+(\d{1,2}):(\d{2})$'),
          parser: (match) => _parse24HourDateTime(match, '/'),
        ),
        // European format: 31.12.21, 23:59
        _TimestampPattern(
          regex: RegExp(
              r'^(\d{1,2})\.(\d{1,2})\.(\d{2,4}),?\s+(\d{1,2}):(\d{2})$'),
          parser: (match) => _parseEuropeanDateTime(match),
        ),
        // ISO format: 2021-12-31, 23:59
        _TimestampPattern(
          regex: RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2}),?\s+(\d{1,2}):(\d{2})$'),
          parser: (match) => _parseISODateTime(match),
        ),
      ];

      for (final pattern in patterns) {
        final match = pattern.regex.firstMatch(cleanTimestamp);
        if (match != null) {
          return pattern.parser(match);
        }
      }

      // Fallback: try to parse as standard DateTime
      try {
        return DateTime.parse(cleanTimestamp);
      } catch (e) {
        debugPrint("⚠️ Standard DateTime.parse failed: $e");
        return DateTime.now();
      }
    } catch (e) {
      debugPrint("❌ Failed to parse timestamp '$timestamp': $e");
      return DateTime.now();
    }
  }

  void _addMessage(List<Message> messages, Map<String, User> userMap,
      String sender, String timestamp, String content) {
    try {
      // Clean sender name
      sender = sender.trim();
      if (sender.isEmpty) {
        sender = "Unknown";
      }

      // Skip system messages completely
      final systemPatterns = [
        'created group',
        'added',
        'left',
        'changed the subject',
        'security code changed',
        'joined using',
        'removed',
        'changed this group',
        'messages and calls are end-to-end encrypted',
        'you created group',
        'group icon',
        'group description',
        'admin',
        'invite link',
        'missed voice call',
        'missed video call',
        'call ended',
      ];

      // Check if this is a system message by content
      final contentLower = content.toLowerCase();
      for (final pattern in systemPatterns) {
        if (contentLower.contains(pattern)) {
          debugPrint("Skipping system message: $content");
          return; // Skip this message entirely
        }
      }

      // Skip if sender looks like a system identifier
      if (sender.toLowerCase() == "system" ||
          (sender.contains('-') && sender.length > 20)) {
        debugPrint("Skipping system sender: $sender");
        return;
      }

      // Create user if not exists
      if (!userMap.containsKey(sender)) {
        final userId = _uuid.v4();
        userMap[sender] = User(
          id: userId,
          name: sender,
        );
        debugPrint("✅ Created user: '$sender' with ID: $userId");
      }

      // Parse timestamp with enhanced function
      final DateTime parsedTimestamp = _parseTimestamp(timestamp);

      // Detect message type and clean content
      MessageType type = MessageType.text;
      Map<String, dynamic> metadata = {};
      String cleanContent = content.trim();

      // Handle different content types
      if (cleanContent.contains('<Media omitted>') ||
          cleanContent.contains('‎image omitted') ||
          cleanContent.contains('‎video omitted') ||
          cleanContent.contains('image omitted') ||
          cleanContent.contains('video omitted')) {
        type = MessageType.image;
        cleanContent = '<Media>';
      } else if (cleanContent.contains('‎audio omitted') ||
          cleanContent.contains('audio omitted') ||
          cleanContent.contains('<attached:')) {
        type = MessageType.audio;
        cleanContent = '<Audio>';
      } else if (cleanContent.contains('‎document omitted') ||
          cleanContent.contains('document omitted')) {
        type = MessageType.document;
        cleanContent = '<Document>';
      } else if (cleanContent.contains('‎Contact card omitted') ||
          cleanContent.contains('Contact card omitted')) {
        type = MessageType.contact;
        cleanContent = '<Contact>';
      } else if (cleanContent.toLowerCase().contains('location:') ||
          cleanContent.contains('‎Location:')) {
        type = MessageType.location;
      }

      // Add message
      messages.add(Message(
        id: _uuid.v4(),
        senderId: userMap[sender]!.id,
        timestamp: parsedTimestamp,
        type: type,
        content: cleanContent,
        metadata: metadata,
      ));

      
    } catch (e) {
      debugPrint("⚠️ Error adding message from '$sender': $e");
      // Continue parsing other messages
    }
  }

  // Parse US format with AM/PM
  DateTime _parseUSDateTime(RegExpMatch match) {
    int month = int.parse(match.group(1)!);
    int day = int.parse(match.group(2)!);
    int year = int.parse(match.group(3)!);
    int hour = int.parse(match.group(4)!);
    int minute = int.parse(match.group(5)!);
    String amPm = match.group(6)!.toUpperCase();

    // Convert 2-digit year to 4-digit
    if (year < 100) {
      year += (year < 50) ? 2000 : 1900;
    }

    // Convert to 24-hour format
    if (amPm == 'PM' && hour < 12) {
      hour += 12;
    } else if (amPm == 'AM' && hour == 12) {
      hour = 0;
    }

    return DateTime(year, month, day, hour, minute);
  }

  // Parse 24-hour format
  DateTime _parse24HourDateTime(RegExpMatch match, String separator) {
    int month, day, year;

    if (separator == '/') {
      month = int.parse(match.group(1)!);
      day = int.parse(match.group(2)!);
      year = int.parse(match.group(3)!);
    } else {
      day = int.parse(match.group(1)!);
      month = int.parse(match.group(2)!);
      year = int.parse(match.group(3)!);
    }

    int hour = int.parse(match.group(4)!);
    int minute = int.parse(match.group(5)!);

    // Convert 2-digit year to 4-digit
    if (year < 100) {
      year += (year < 50) ? 2000 : 1900;
    }

    return DateTime(year, month, day, hour, minute);
  }

  // Parse European format (DD.MM.YY)
  DateTime _parseEuropeanDateTime(RegExpMatch match) {
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

  // Parse ISO format (YYYY-MM-DD)
  DateTime _parseISODateTime(RegExpMatch match) {
    int year = int.parse(match.group(1)!);
    int month = int.parse(match.group(2)!);
    int day = int.parse(match.group(3)!);
    int hour = int.parse(match.group(4)!);
    int minute = int.parse(match.group(5)!);

    return DateTime(year, month, day, hour, minute);
  }
}

// Helper class for timestamp patterns
class _TimestampPattern {
  final RegExp regex;
  final DateTime Function(RegExpMatch) parser;

  _TimestampPattern({required this.regex, required this.parser});
}

// ============================================================================
// WHATSAPP HTML PARSER
// ============================================================================
abstract class WhatsAppHtmlParser {
  Future<Chat> parse(File file);
}

class WhatsAppHtmlParserImpl implements WhatsAppHtmlParser {
  final _uuid = Uuid();

  @override
  Future<Chat> parse(File file) async {
    debugPrint("Parsing WhatsApp HTML file: ${file.path}");

    // Try various encodings to read the file
    String content;
    try {
      content = await file.readAsString(encoding: utf8);
      debugPrint("File successfully read with UTF-8 encoding");
    } catch (e) {
      debugPrint("UTF-8 encoding failed, trying Latin-1");
      try {
        content = await file.readAsString(encoding: latin1);
        debugPrint("File successfully read with Latin-1 encoding");
      } catch (e) {
        debugPrint("Latin-1 encoding failed, trying to detect encoding");
        final bytes = await file.readAsBytes();
        content = _detectEncodingAndDecode(bytes);
      }
    }

    final Document document = html_parser.parse(content);

    // Extract title from HTML
    final titleElement = document.querySelector('title');
    String title = 'WhatsApp Chat';
    if (titleElement != null) {
      title = titleElement.text;
      if (title.startsWith('Chat Stats - ')) {
        title = title.substring('Chat Stats - '.length);
      }
    }

    final messages = <Message>[];
    final userMap = <String, User>{};

    // Extract messages
    _parseMessages(document, messages, userMap);

    // Sort messages by timestamp
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    debugPrint(
        "Parsed ${messages.length} messages from ${userMap.length} users");

    return Chat(
      id: _uuid.v4(),
      title: title,
      importDate: DateTime.now(),
      users: userMap.values.toList(),
      messages: messages,
      firstMessageDate:
          messages.isNotEmpty ? messages.first.timestamp : DateTime.now(),
      lastMessageDate:
          messages.isNotEmpty ? messages.last.timestamp : DateTime.now(),
    );
  }

  String _detectEncodingAndDecode(List<int> bytes) {
    try {
      debugPrint("Attempting UTF-8 decoding");
      return utf8.decode(bytes);
    } catch (e) {
      try {
        debugPrint("Attempting Latin-1 decoding");
        return latin1.decode(bytes);
      } catch (e) {
        debugPrint("Attempting ASCII decoding with cleaning");
        return ascii.decode(bytes.where((b) => b >= 0 && b < 128).toList(),
            allowInvalid: true);
      }
    }
  }

  void _parseMessages(
      Document document, List<Message> messages, Map<String, User> userMap) {
    debugPrint("Parsing HTML messages");

    final messageElements = document.querySelectorAll('.message');

    if (messageElements.isNotEmpty) {
      debugPrint("Found ${messageElements.length} messages in standard format");

      for (final element in messageElements) {
        final senderElement = element.querySelector('.sender');
        final contentElement = element.querySelector('.message-text');
        final timeElement = element.querySelector('.time');

        if (senderElement != null &&
            contentElement != null &&
            timeElement != null) {
          final sender = senderElement.text.trim();
          final content = contentElement.text.trim();
          final timestamp = timeElement.text.trim();

          _addMessageFromElements(
              messages, userMap, sender, timestamp, content);
        }
      }
    } else {
      debugPrint("Trying to parse ChatStats format");

      final userElements = document.querySelectorAll('#num_mensajes .dato');
      for (final element in userElements) {
        final text = element.text.trim();
        if (text.isNotEmpty) {
          final parts = text.split(' : ');
          if (parts.length == 2) {
            final userName = parts[1];
            final userId = _uuid.v4();
            userMap[userName] = User(
              id: userId,
              name: userName,
            );
            debugPrint("Found user: $userName");
          }
        }
      }

      final firstMessageDate = _extractFirstMessageDate(document);
      final lastMessageDate = _extractLastMessageDate(document);

      if (firstMessageDate != null &&
          lastMessageDate != null &&
          userMap.isNotEmpty) {
        debugPrint("Creating placeholder messages from date range");

        final userId = userMap.values.first.id;

        messages.add(Message(
          id: _uuid.v4(),
          senderId: userId,
          timestamp: firstMessageDate,
          type: MessageType.text,
          content: 'Chat begins',
          metadata: {'placeholder': true},
        ));

        messages.add(Message(
          id: _uuid.v4(),
          senderId: userId,
          timestamp: lastMessageDate,
          type: MessageType.text,
          content: 'Chat ends',
          metadata: {'placeholder': true},
        ));
      }
    }

    if (messages.isEmpty) {
      debugPrint("No messages found, creating default");

      final userId = _uuid.v4();
      userMap['Unknown'] = User(
        id: userId,
        name: 'Unknown',
      );

      messages.add(Message(
        id: _uuid.v4(),
        senderId: userId,
        timestamp: DateTime.now(),
        type: MessageType.text,
        content: 'No messages could be extracted from the file',
        metadata: {'placeholder': true},
      ));
    }
  }

  void _addMessageFromElements(
      List<Message> messages,
      Map<String, User> userMap,
      String sender,
      String timestamp,
      String content) {
    if (!userMap.containsKey(sender)) {
      final userId = _uuid.v4();
      userMap[sender] = User(
        id: userId,
        name: sender,
      );
    }

    final DateTime parsedTimestamp = _parseTimestamp(timestamp);

    MessageType type = MessageType.text;
    Map<String, dynamic> metadata = {};

    if (content.contains('<Media omitted>')) {
      type = MessageType.image;
      content = '<Media>';
    }

    messages.add(Message(
      id: _uuid.v4(),
      senderId: userMap[sender]!.id,
      timestamp: parsedTimestamp,
      type: type,
      content: content.trim(),
      metadata: metadata,
    ));
  }

  DateTime _parseTimestamp(String timestamp) {
    try {
      debugPrint("Parsing timestamp: $timestamp");

      if (timestamp.contains('/') && timestamp.contains(':')) {
        final parts = timestamp.split(', ');
        final dateParts = parts[0].split('/');
        final timeParts = parts[1].split(':');

        int month = int.parse(dateParts[0]);
        int day = int.parse(dateParts[1]);
        int year = int.parse(dateParts[2]);

        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);

        return DateTime(year, month, day, hour, minute);
      }

      return DateTime.parse(timestamp);
    } catch (e) {
      debugPrint("Failed to parse timestamp: $e");
      return DateTime.now();
    }
  }

  DateTime? _extractFirstMessageDate(Document document) {
    final firstMessageElement = document.querySelector('#primer_mensaje .dato');
    if (firstMessageElement != null) {
      final text = firstMessageElement.text.trim();
      final dateMatch =
          RegExp(r'(\d{2}/\d{2}/\d{4} \d{2}:\d{2})').firstMatch(text);
      if (dateMatch != null) {
        try {
          final dateStr = dateMatch.group(1)!;
          final parts = dateStr.split(' ');
          final dateParts = parts[0].split('/');
          final timeParts = parts[1].split(':');

          int day = int.parse(dateParts[0]);
          int month = int.parse(dateParts[1]);
          int year = int.parse(dateParts[2]);

          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);

          return DateTime(year, month, day, hour, minute);
        } catch (e) {
          debugPrint("Error parsing first message date: $e");
          return null;
        }
      }
    }
    return null;
  }

  DateTime? _extractLastMessageDate(Document document) {
    final lastMessageElement = document.querySelector('#ultimo_mensaje .dato');
    if (lastMessageElement != null) {
      final text = lastMessageElement.text.trim();
      final dateMatch =
          RegExp(r'(\d{2}/\d{2}/\d{4} \d{2}:\d{2})').firstMatch(text);
      if (dateMatch != null) {
        try {
          final dateStr = dateMatch.group(1)!;
          final parts = dateStr.split(' ');
          final dateParts = parts[0].split('/');
          final timeParts = parts[1].split(':');

          int day = int.parse(dateParts[0]);
          int month = int.parse(dateParts[1]);
          int year = int.parse(dateParts[2]);

          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);

          return DateTime(year, month, day, hour, minute);
        } catch (e) {
          debugPrint("Error parsing last message date: $e");
          return null;
        }
      }
    }
    return null;
  }
}
