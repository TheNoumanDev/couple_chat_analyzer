// ============================================================================
// FILE: data/parsers/whatsapp_text_parser.dart
// Complete implementation with abstract class
// ============================================================================
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../shared/models.dart';
import 'utils/encoding_detector.dart';
import 'utils/timestamp_parser.dart';
import 'utils/message_validator.dart';

// Abstract class
abstract class WhatsAppTextParser {
  Future<Chat> parse(File file);
}

// Top-level function for isolate
Future<Chat> _parseInIsolate(String filePath) async {
  final file = File(filePath);
  final uuid = const Uuid();
  final encodingDetector = EncodingDetector();
  final timestampParser = TimestampParser();
  final messageValidator = MessageValidator();
  
  try {
    // Read the file with encoding detection
    final content = await encodingDetector.readWithBestEncoding(file);
    final lines = encodingDetector.cleanLines(content.split('\n'));

    final messages = <Message>[];
    final userMap = <String, User>{};

    // Parse messages
    await _parseMessagesInIsolate(lines, messages, userMap, timestampParser, messageValidator, uuid);

    // Validate results
    final validationResult = messageValidator.validateChat(messages, userMap.values.toList());

    // Sort messages by timestamp
    validationResult.validMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Generate title
    String title = 'WhatsApp Chat';
    if (validationResult.validUsers.length == 2) {
      title = 'Chat with ${validationResult.validUsers.where((u) => u.name != 'You').map((u) => u.name).join(', ')}';
    } else if (validationResult.validUsers.length > 2) {
      title = 'Group Chat (${validationResult.validUsers.length} members)';
    }

    return Chat(
      id: uuid.v4(),
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

Future<void> _parseMessagesInIsolate(
  List<String> lines, 
  List<Message> messages, 
  Map<String, User> userMap,
  TimestampParser timestampParser,
  MessageValidator messageValidator,
  Uuid uuid,
) async {
  String? currentSender;
  DateTime? currentTimestamp;
  String currentContent = '';

  // Note: No yielding needed here - this runs in an isolate via compute(),
  // which is separate from the UI thread. The isolate doesn't have an event
  // loop that responds to Future.delayed(Duration.zero) anyway.
  for (final line in lines) {
    final parsedMessage = timestampParser.tryParseMessage(line);
    
    if (parsedMessage != null) {
      // Save previous message
      if (currentSender != null && currentTimestamp != null && currentContent.isNotEmpty) {
        await _addMessageInIsolate(messages, userMap, currentSender, currentTimestamp, currentContent, messageValidator, uuid);
      }
      
      // Start new message
      currentSender = parsedMessage.senderName;
      currentTimestamp = parsedMessage.timestamp;
      currentContent = parsedMessage.content;
    } else if (currentSender != null) {
      // Continue multi-line message
      currentContent += '\n$line';
    }
  }

  // Save last message
  if (currentSender != null && currentTimestamp != null && currentContent.isNotEmpty) {
    await _addMessageInIsolate(messages, userMap, currentSender, currentTimestamp, currentContent, messageValidator, uuid);
  }
}

Future<void> _addMessageInIsolate(
  List<Message> messages,
  Map<String, User> userMap,
  String senderName,
  DateTime timestamp,
  String content,
  MessageValidator messageValidator,
  Uuid uuid,
) async {
  try {
    // Get or create user
    final userId = _getOrCreateUserInIsolate(senderName, userMap, uuid);

    // Clean content
    final cleanContent = messageValidator.cleanMessageContent(content);
    
    // Determine message type
    final messageType = messageValidator.detectMessageType(cleanContent);

    // Create message
    final message = Message(
      id: uuid.v4(),
      senderId: userId,
      content: cleanContent,
      timestamp: timestamp,
      type: messageType,
    );

    if (messageValidator.isValidMessage(message)) {
      messages.add(message);
    }
  } catch (e, stackTrace) {
    debugPrint("❌ Error adding message: $e");
    debugPrint("   Sender: $senderName");
    debugPrint("   Timestamp: $timestamp");
    debugPrint("   Content length: ${content.length}");
    debugPrint("   Content preview: ${content.length > 100 ? content.substring(0, 100) + '...' : content}");
    debugPrint("   Stack trace: $stackTrace");
    debugPrint("   ⚠️ This message structure was not processed - may need format handling");
  }
}

String _getOrCreateUserInIsolate(String userName, Map<String, User> userMap, Uuid uuid) {
  final cleanUserName = userName.trim();
  
  if (cleanUserName.isEmpty) {
    return _getOrCreateUserInIsolate('Unknown User', userMap, uuid);
  }

  // Find existing user by name
  for (final user in userMap.values) {
    if (user.name == cleanUserName) {
      return user.id;
    }
  }

  // Create new user
  final userId = uuid.v4();
  userMap[userId] = User(
    id: userId,
    name: cleanUserName,
    phoneNumber: null,
  );
  
  return userId;
}

// Implementation class
class WhatsAppTextParserImpl implements WhatsAppTextParser {
  final _uuid = const Uuid();
  final EncodingDetector _encodingDetector = EncodingDetector();
  final TimestampParser _timestampParser = TimestampParser();
  final MessageValidator _messageValidator = MessageValidator();

  @override
  Future<Chat> parse(File file) async {
    // Run parsing in isolate to prevent blocking main thread
    debugPrint("🚀 Starting text parsing in background isolate: ${file.path}");
    try {
      final result = await compute(_parseInIsolate, file.path);
      debugPrint("✅ Text parsing completed in isolate");
      return result;
    } catch (e) {
      debugPrint("❌ Isolate parsing failed, falling back to main thread: $e");
      // Fallback to main thread if isolate fails
      return await _parseOnMainThread(file);
    }
  }
  
  Future<Chat> _parseOnMainThread(File file) async {
    debugPrint("⚠️ Parsing on main thread (fallback)");
    try {
      // Read the file with encoding detection
      final content = await _encodingDetector.readWithBestEncoding(file);
      final lines = _encodingDetector.cleanLines(content.split('\n'));

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

    int processedLines = 0;
    for (final line in lines) {
      // Yield to UI every 100 lines to prevent blocking
      if (processedLines % 100 == 0 && processedLines > 0) {
        await Future.delayed(Duration.zero);
      }
      processedLines++;
      
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
    } catch (e, stackTrace) {
      debugPrint("❌ Error adding message: $e");
      debugPrint("   Sender: $senderName");
      debugPrint("   Timestamp: $timestamp");
      debugPrint("   Content length: ${content.length}");
      debugPrint("   Content preview: ${content.length > 100 ? content.substring(0, 100) + '...' : content}");
      debugPrint("   Stack trace: $stackTrace");
      debugPrint("   ⚠️ This message structure was not processed - may need format handling");
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

    return userId;
  }
}