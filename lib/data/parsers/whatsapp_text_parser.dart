import 'dart:io';
import 'package:chatreport/shared/domain.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/models.dart';
import 'utils/encoding_detector.dart';
import 'utils/timestamp_parser.dart';
import 'utils/message_validator.dart';

abstract class WhatsAppTextParser {
  Future<Chat> parse(File file);
}

class WhatsAppTextParserImpl implements WhatsAppTextParser {
  final _uuid = const Uuid();
  final EncodingDetector _encodingDetector = EncodingDetector();
  final TimestampParser _timestampParser = TimestampParser();
  final MessageValidator _messageValidator = MessageValidator();

  @override
  Future<Chat> parse(File file) async {
    debugPrint("📝 Parsing WhatsApp text file: ${file.path}");

    try {
      // Enhanced encoding detection
      final content = await _encodingDetector.readWithBestEncoding(file);
      debugPrint("📄 Successfully read file with ${content.length} characters");

      // Clean and split lines
      final rawLines = content.split('\n');
      final lines = _encodingDetector.cleanLines(rawLines);
      debugPrint("📊 Processing ${lines.length} clean lines (from ${rawLines.length} raw lines)");

      // Extract chat title
      String title = _extractTitleFromFilename(file.path);

      final messages = <Message>[];
      final userMap = <String, User>{};

      // Parse messages with enhanced pattern matching
      await _parseMessagesWithPatterns(lines, messages, userMap);

      // Validate and clean results
      final validationResult = _messageValidator.validateChat(messages, userMap.values.toList());
      
      debugPrint("👥 Users created during parsing:");
      for (final user in validationResult.validUsers) {
        debugPrint("  - Name: '${user.name}', ID: ${user.id}");
      }

      // Update userMap with only valid users
      userMap.clear();
      for (final user in validationResult.validUsers) {
        userMap[user.id] = user;
      }

      // Sort messages by timestamp
      validationResult.validMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      debugPrint("✅ Parsing complete: ${validationResult.validMessageCount} messages, ${validationResult.validUserCount} users");

      return Chat(
        id: _uuid.v4(),
        title: title,
        importDate: DateTime.now(),
        users: validationResult.validUsers,
        messages: validationResult.validMessages,
        firstMessageDate: validationResult.validMessages.isNotEmpty 
            ? validationResult.validMessages.first.timestamp 
            : DateTime.now(),
        lastMessageDate: validationResult.validMessages.isNotEmpty 
            ? validationResult.validMessages.last.timestamp 
            : DateTime.now(),
      );
    } catch (e, stackTrace) {
      debugPrint("❌ Error parsing text file: $e");
      debugPrint("Stack trace: $stackTrace");
      rethrow;
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

  Future<void> _parseMessagesWithPatterns(
    List<String> lines,
    List<Message> messages,
    Map<String, User> userMap,
  ) async {
    debugPrint("🔍 Starting message parsing with ${lines.length} lines");
    
    Message? currentMessage;
    String currentContent = '';
    int processedLines = 0;
    int matchedMessages = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      processedLines++;

      if (line.isEmpty) continue;

      // Try to parse as a new message
      final parsedMessage = _timestampParser.tryParseMessage(line);

      if (parsedMessage != null) {
        // Save previous message if exists
        if (currentMessage != null && currentContent.isNotEmpty) {
          await _addMessage(
            messages,
            userMap,
            currentMessage.senderId,
            currentMessage.timestamp,
            currentContent.trim(),
          );
          matchedMessages++;
        }

        // Start new message
        final userId = _getOrCreateUser(parsedMessage.senderName, userMap);
        currentMessage = Message(
          id: _uuid.v4(),
          senderId: userId,
          content: '',
          timestamp: parsedMessage.timestamp,
          type: MessageType.text,
        );

        currentContent = parsedMessage.content;
      } else {
        // Continuation of previous message
        if (currentMessage != null) {
          if (currentContent.isNotEmpty) {
            currentContent += '\n';
          }
          currentContent += line;
        } else {
          // Line without timestamp - might be start of file info, skip
          debugPrint("⚠️ Skipping line without timestamp: ${line.substring(0, 50)}...");
        }
      }

      // Progress tracking for large files
      if (processedLines % 5000 == 0) {
        debugPrint("📊 Processed $processedLines lines, matched $matchedMessages messages");
        // Allow other operations to run
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    // Don't forget the last message
    if (currentMessage != null && currentContent.isNotEmpty) {
      await _addMessage(
        messages,
        userMap,
        currentMessage.senderId,
        currentMessage.timestamp,
        currentContent.trim(),
      );
      matchedMessages++;
    }

    debugPrint("📈 Final parsing stats: $processedLines lines processed, $matchedMessages messages created");
  }

  String _getOrCreateUser(String userName, Map<String, User> userMap) {
    // Clean the username
    final cleanUserName = userName.trim();
    
    if (cleanUserName.isEmpty) {
      return _getOrCreateUser('Unknown User', userMap);
    }

    // Find existing user by name
    for (final user in userMap.values) {
      if (user.name == cleanUserName) {
        return user.id;
      }
    }

    // Create new user
    final userId = _uuid.v4();
    userMap[userId] = User(
      id: userId,
      name: cleanUserName,
    );

    debugPrint("👤 Created user: '$cleanUserName' with ID: $userId");
    return userId;
  }

  Future<void> _addMessage(
    List<Message> messages,
    Map<String, User> userMap,
    String senderId,
    DateTime timestamp,
    String content,
  ) async {
    try {
      // Clean the content
      final cleanContent = _messageValidator.cleanMessageContent(content);
      
      if (cleanContent.isEmpty && !_isMediaMessage(content)) {
        debugPrint("⚠️ Skipping empty message");
        return;
      }

      // Determine message type
      final messageType = _messageValidator.detectMessageType(cleanContent);

      // Create message
      final message = Message(
        id: _uuid.v4(),
        senderId: senderId,
        content: cleanContent,
        timestamp: timestamp,
        type: messageType,
      );

      // Validate message before adding
      if (_messageValidator.isValidMessage(message)) {
        messages.add(message);
      } else {
        debugPrint("⚠️ Invalid message filtered out: ${cleanContent.substring(0, 30)}...");
      }
    } catch (e) {
      debugPrint("❌ Error adding message: $e");
    }
  }

  bool _isMediaMessage(String content) {
    final lowerContent = content.toLowerCase();
    return lowerContent.contains('omitted') ||
           lowerContent.contains('<media>') ||
           lowerContent.contains('<audio>') ||
           lowerContent.contains('<video>') ||
           lowerContent.contains('<image>') ||
           lowerContent.contains('<document>');
  }
}