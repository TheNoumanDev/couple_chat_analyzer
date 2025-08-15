import 'dart:io';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models.dart';
import '../../shared/domain.dart';
import 'utils/encoding_detector.dart';
import 'utils/timestamp_parser.dart';
import 'utils/message_validator.dart';

abstract class WhatsAppHtmlParser {
  Future<Chat> parse(File file);
}

class WhatsAppHtmlParserImpl implements WhatsAppHtmlParser {
  final _uuid = const Uuid();
  final EncodingDetector _encodingDetector = EncodingDetector();
  final TimestampParser _timestampParser = TimestampParser();
  final MessageValidator _messageValidator = MessageValidator();

  @override
  Future<Chat> parse(File file) async {
    debugPrint("🌐 Parsing WhatsApp HTML file: ${file.path}");

    try {
      // Try various encodings to read the file
      final content = await _encodingDetector.readWithBestEncoding(file);
      debugPrint("📄 File successfully read with ${content.length} characters");

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

      // Extract messages using multiple strategies
      await _parseMessages(document, messages, userMap);

      // Validate results
      final validationResult = _messageValidator.validateChat(messages, userMap.values.toList());

      // Sort messages by timestamp
      validationResult.validMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      debugPrint("✅ HTML parsing complete: ${validationResult.validMessageCount} messages from ${validationResult.validUserCount} users");

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
      debugPrint("❌ Error parsing HTML file: $e");
      debugPrint("Stack trace: $stackTrace");
      rethrow;
    }
  }

  Future<void> _parseMessages(Document document, List<Message> messages, Map<String, User> userMap) async {
    debugPrint("🔍 Parsing HTML messages with multiple strategies");

    // Strategy 1: Look for standard WhatsApp HTML export format
    await _tryStandardFormat(document, messages, userMap);

    // Strategy 2: Look for alternative message structures
    if (messages.isEmpty) {
      await _tryAlternativeFormats(document, messages, userMap);
    }

    // Strategy 3: Parse any text that looks like messages
    if (messages.isEmpty) {
      await _tryTextExtraction(document, messages, userMap);
    }

    debugPrint("🔍 HTML parsing strategies completed. Found ${messages.length} messages");
  }

  Future<void> _tryStandardFormat(Document document, List<Message> messages, Map<String, User> userMap) async {
    // Look for common HTML structures in WhatsApp exports
    final selectors = [
      '.message',
      '.msg',
      '[data-id]',
      '.chat-message',
      '.whatsapp-message',
    ];

    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        debugPrint("📱 Found ${elements.length} messages using selector: $selector");
        
        for (final element in elements) {
          await _parseHtmlMessage(element, messages, userMap);
        }
        break; // Use the first successful selector
      }
    }
  }

  Future<void> _tryAlternativeFormats(Document document, List<Message> messages, Map<String, User> userMap) async {
    // Look for div or p elements that might contain messages
    final elements = document.querySelectorAll('div, p, li');
    
    for (final element in elements) {
      final text = element.text.trim();
      if (text.isNotEmpty && _looksLikeMessage(text)) {
        await _parseHtmlMessage(element, messages, userMap);
      }
    }
  }

  Future<void> _tryTextExtraction(Document document, List<Message> messages, Map<String, User> userMap) async {
    // Extract all text and try to parse line by line
    final allText = document.body?.text ?? '';
    final lines = allText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    debugPrint("📄 Extracted ${lines.length} text lines from HTML");
    
    String? currentSender;
    DateTime? currentTimestamp;
    String currentContent = '';

    for (final line in lines) {
      final parsedMessage = _timestampParser.tryParseMessage(line);
      
      if (parsedMessage != null) {
        // Save previous message
        if (currentSender != null && currentTimestamp != null && currentContent.isNotEmpty) {
          await _addHtmlMessage(messages, userMap, currentSender, currentTimestamp, currentContent);
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
      await _addHtmlMessage(messages, userMap, currentSender, currentTimestamp, currentContent);
    }
  }

  bool _looksLikeMessage(String text) {
    // Check if text looks like a WhatsApp message
    return _timestampParser.tryParseMessage(text) != null;
  }

  Future<void> _parseHtmlMessage(Element element, List<Message> messages, Map<String, User> userMap) async {
    try {
      final text = element.text.trim();
      if (text.isEmpty) return;

      // Try to parse the message using timestamp parser
      final parsedMessage = _timestampParser.tryParseMessage(text);
      if (parsedMessage == null) return;

      await _addHtmlMessage(
        messages,
        userMap,
        parsedMessage.senderName,
        parsedMessage.timestamp,
        parsedMessage.content,
      );
    } catch (e) {
      debugPrint("⚠️ Error parsing HTML message element: $e");
    }
  }

  Future<void> _addHtmlMessage(
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
      debugPrint("❌ Error adding HTML message: $e");
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

    debugPrint("👤 Created HTML user: '$cleanUserName' with ID: $userId");
    return userId;
  }
}