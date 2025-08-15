// ============================================================================
// FILE: data/parsers/whatsapp_text_parser.dart
// Complete implementation with abstract class
// ============================================================================
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../shared/models.dart';
import '../../shared/domain.dart';
import 'utils/encoding_detector.dart';
import 'utils/timestamp_parser.dart';
import 'utils/message_validator.dart';

// Abstract class
abstract class WhatsAppTextParser {
  Future<Chat> parse(File file);
}

// Implementation class
class WhatsAppTextParserImpl implements WhatsAppTextParser {
  final _uuid = const Uuid();
  final EncodingDetector _encodingDetector = EncodingDetector();
  final TimestampParser _timestampParser = TimestampParser();
  final MessageValidator _messageValidator = MessageValidator();

  @override
  Future<Chat> parse(File file) async {
    debugPrint("📄 Parsing WhatsApp text file: ${file.path}");

    try {
      // Read the file with encoding detection
      final content = await _encodingDetector.readWithBestEncoding(file);
      final lines = _encodingDetector.cleanLines(content.split('\n'));

      debugPrint("📄 File contains ${lines.length} lines");

      final messages = <Message>[];
      final userMap = <String, User>{};

      // Parse messages
      await _parseMessages(lines, messages, userMap);

      // Validate results
      final validationResult = _messageValidator.validateChat(messages, userMap.values.toList());

      // Sort messages by timestamp
      validationResult.validMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Generate title
      String title = 'WhatsApp Chat';
      if (validationResult.validUsers.length == 2) {
        title = 'Chat with ${validationResult.validUsers.where((u) => u.name != 'You').map((u) => u.name).join(', ')}';
      } else if (validationResult.validUsers.length > 2) {
        title = 'Group Chat (${validationResult.validUsers.length} members)';
      }

      debugPrint("✅ Text parsing complete: ${validationResult.validMessageCount} messages from ${validationResult.validUserCount} users");

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

  Future<void> _parseMessages(List<String> lines, List<Message> messages, Map<String, User> userMap) async {
    String? currentSender;
    DateTime? currentTimestamp;
    String currentContent = '';

    for (final line in lines) {
      final parsedMessage = _timestampParser.tryParseMessage(line);
      
      if (parsedMessage != null) {
        // Save previous message
        if (currentSender != null && currentTimestamp != null && currentContent.isNotEmpty) {
          await _addMessage(messages, userMap, currentSender, currentTimestamp, currentContent);
        }
        
        // Start new message
        currentSender = parsedMessage.senderName;
        currentTimestamp = parsedMessage.timestamp;
        currentContent = parsedMessage.content;
      } else if (currentSender != null) {
        // Continue previous message
        if (currentContent.isNotEmpty) {
          currentContent += '\n';
        }
        currentContent += line.trim();
      }
    }

    // Add last message
    if (currentSender != null && currentTimestamp != null && currentContent.isNotEmpty) {
      await _addMessage(messages, userMap, currentSender, currentTimestamp, currentContent);
    }

    debugPrint("📊 Parsed ${messages.length} messages from ${userMap.length} users");
  }

  Future<void> _addMessage(
    List<Message> messages,
    Map<String, User> userMap,
    String senderName,
    DateTime timestamp,
    String content,
  ) async {
    try {
      // Get or create user
      final userId = _getOrCreateUser(senderName, userMap);

      // Clean content
      final cleanContent = _messageValidator.cleanMessageContent(content);
      
      // Determine message type
      final messageType = _messageValidator.detectMessageType(cleanContent);

      // Create message
      final message = Message(
        id: _uuid.v4(),
        senderId: userId,
        content: cleanContent,
        timestamp: timestamp,
        type: messageType,
      );

      if (_messageValidator.isValidMessage(message)) {
        messages.add(message);
      }
    } catch (e) {
      debugPrint("❌ Error adding message: $e");
    }
  }

  String _getOrCreateUser(String userName, Map<String, User> userMap) {
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
}