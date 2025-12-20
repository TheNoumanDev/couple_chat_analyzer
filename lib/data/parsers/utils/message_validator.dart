import 'package:flutter/foundation.dart';
import '../../../shared/models.dart';
import '../../../shared/domain.dart';

class MessageValidator {
  static const int maxMessageLength = 65536; // 64KB max message size
  static const int minMessageLength = 0; // Allow empty messages for media
  static const int maxSenderNameLength = 100;

  // System message patterns to filter out - using specific patterns only
  // These should match actual WhatsApp system messages, not user messages
  // Avoid single words like "left" or "added" that appear in normal conversation
  static const List<String> systemMessagePatterns = [
    'created group',
    'changed the subject',
    'security code changed',
    'joined using',
    'changed this group',
    'messages and calls are end-to-end encrypted',
    'missed voice call',
    'missed video call',
    'you added',
    'you removed',
    'you changed',
    'changed their phone number',
    'your security code with',
    'changed to',
    'group description was changed',
    'group icon changed',
    'group settings changed',
    'waiting for this message',
    'deleted this message',
    'this message was deleted',
    'message deleted',
    'you deleted this message',
    'calling...',
    'call ended',
    'no answer',
    'busy',
    'unavailable',
  ];
  
  // Patterns that need word boundary checking (common words that appear in system messages)
  static const List<String> systemMessageWordPatterns = [
    'left the group',
    'left this group',
    'added you',
    'removed you',
    'removed from',
  ];

  bool isValidMessage(Message message) {
    try {
      // Check basic requirements
      if (message.id.isEmpty || message.senderId.isEmpty) {
        debugPrint("⚠️ Message missing ID or sender ID");
        return false;
      }

      // Check message length
      if (message.content.length < minMessageLength || 
          message.content.length > maxMessageLength) {
        debugPrint("⚠️ Invalid message length: ${message.content.length}");
        return false;
      }

      // Check timestamp validity
      if (!_isValidTimestamp(message.timestamp)) {
        debugPrint("⚠️ Invalid timestamp: ${message.timestamp}");
        return false;
      }

      // Filter out system messages (but allow them if explicitly marked as system)
      if (message.senderId != "System" && _isSystemMessage(message.content)) {
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint("❌ Error validating message: $e");
      debugPrint("   Message ID: ${message.id}");
      debugPrint("   Sender ID: ${message.senderId}");
      debugPrint("   Timestamp: ${message.timestamp}");
      debugPrint("   Content length: ${message.content.length}");
      debugPrint("   Content preview: ${message.content.length > 100 ? message.content.substring(0, 100) + '...' : message.content}");
      debugPrint("   Message type: ${message.type}");
      debugPrint("   Stack trace: $stackTrace");
      debugPrint("   ⚠️ This message structure failed validation - may need format handling");
      return false;
    }
  }

  bool _isValidTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final earliestDate = DateTime(2009, 1, 1); // WhatsApp founded in 2009
    final futureLimit = now.add(Duration(days: 1)); // Allow 1 day future for timezone issues
    
    return timestamp.isAfter(earliestDate) && timestamp.isBefore(futureLimit);
  }

  bool _isSystemMessage(String content) {
    final lowerContent = content.toLowerCase().trim();
    
    // Additional checks for system-like messages
    if (lowerContent.isEmpty) return true;
    
    // Messages that are just timestamps or metadata (standalone dates)
    // Only match if the entire message is just a date
    if (RegExp(r'^\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4}\s*$').hasMatch(lowerContent)) {
      return true;
    }

    // Messages that look like notifications
    if (lowerContent.startsWith('notification:') || 
        lowerContent.startsWith('alert:') ||
        lowerContent.startsWith('system:')) {
      return true;
    }

    // Check against known system message patterns (multi-word, specific patterns)
    for (final pattern in systemMessagePatterns) {
      if (lowerContent.contains(pattern.toLowerCase())) {
        return true;
      }
    }
    
    // Check word-based patterns (need to match exact phrases)
    for (final pattern in systemMessageWordPatterns) {
      if (lowerContent.contains(pattern.toLowerCase())) {
        return true;
      }
    }

    return false;
  }


  bool isValidUser(User user) {
    if (user.id.isEmpty || user.name.isEmpty) {
      return false;
    }

    // Filter out system users
    if (user.id == "System" || user.name.toLowerCase() == "system") {
      return true; // System user is valid but special
    }

    // Check for reasonable name length
    if (user.name.length > maxSenderNameLength) {
      debugPrint("⚠️ User name too long: ${user.name}");
      return false;
    }

    // Check for suspicious patterns in names
    if (_isSystemLikeName(user.name)) {
      debugPrint("⚠️ System-like user name: ${user.name}");
      return false;
    }

    return true;
  }

  bool _isSystemLikeName(String name) {
    final lowerName = name.toLowerCase().trim();
    
    // Common system-like names
    const systemLikeNames = [
      'whatsapp',
      'system',
      'notification',
      'admin',
      'moderator',
      'bot',
      'automated',
      'service',
    ];

    return systemLikeNames.any((systemName) => lowerName.contains(systemName));
  }

  List<Message> filterValidMessages(List<Message> messages) {
    final validMessages = messages.where(isValidMessage).toList();
    final filtered = messages.length - validMessages.length;
    
    if (filtered > 0) {
      debugPrint("📋 Filtered $filtered invalid messages (${(filtered/messages.length*100).toStringAsFixed(1)}%)");
    }
    
    return validMessages;
  }

  List<User> filterValidUsers(List<User> users) {
    final validUsers = users.where(isValidUser).toList();
    final filtered = users.length - validUsers.length;
    
    if (filtered > 0) {
      debugPrint("👥 Filtered $filtered invalid users");
    }
    
    return validUsers;
  }

  MessageValidationResult validateChat(List<Message> messages, List<User> users) {
    final validMessages = filterValidMessages(messages);
    final validUsers = filterValidUsers(users);

    final result = MessageValidationResult(
      originalMessageCount: messages.length,
      validMessageCount: validMessages.length,
      originalUserCount: users.length,
      validUserCount: validUsers.length,
      validMessages: validMessages,
      validUsers: validUsers,
    );

    debugPrint("📊 Chat validation complete:");
    debugPrint("  Messages: ${result.validMessageCount}/${result.originalMessageCount} (${(result.messageValidityRate*100).toStringAsFixed(1)}%)");
    debugPrint("  Users: ${result.validUserCount}/${result.originalUserCount} (${(result.userValidityRate*100).toStringAsFixed(1)}%)");
    debugPrint("  Overall quality: ${result.isReasonablyValid ? 'Good' : 'Poor'}");

    return result;
  }

  // Validate and clean content
  String cleanMessageContent(String content) {
    // Remove invisible Unicode characters
    String cleaned = content.replaceAll(RegExp(r'[\u200B-\u200F\uFEFF\u2028-\u202F\u00AD]'), '');
    
    // Remove bidirectional text marks
    cleaned = cleaned.replaceAll(RegExp(r'[\u202A-\u202E\u061C\u2066-\u2069]'), '');
    
    // Normalize line endings
    cleaned = cleaned.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    
    // Trim whitespace
    cleaned = cleaned.trim();
    
    return cleaned;
  }

  // Check if message content suggests it's media
  MessageType detectMessageType(String content) {
    final lowerContent = content.toLowerCase().trim();
    
    if (lowerContent.contains('<media omitted>') ||
        lowerContent.contains('image omitted') ||
        lowerContent.contains('photo omitted') ||
        lowerContent.contains('picture omitted')) {
      return MessageType.image;
    }
    
    if (lowerContent.contains('video omitted') ||
        lowerContent.contains('gif omitted')) {
      return MessageType.video;
    }
    
    if (lowerContent.contains('audio omitted') ||
        lowerContent.contains('voice message') ||
        lowerContent.contains('ptt')) {
      return MessageType.audio;
    }
    
    if (lowerContent.contains('document omitted') ||
        lowerContent.contains('file omitted')) {
      return MessageType.document;
    }
    
    if (lowerContent.contains('contact card omitted') ||
        lowerContent.contains('contact omitted')) {
      return MessageType.contact;
    }
    
    if (lowerContent.contains('location:') ||
        lowerContent.contains('live location') ||
        lowerContent.contains('shared location')) {
      return MessageType.location;
    }
    
    if (lowerContent.contains('sticker omitted')) {
      return MessageType.sticker;
    }
    
    return MessageType.text;
  }
}

class MessageValidationResult {
  final int originalMessageCount;
  final int validMessageCount;
  final int originalUserCount;
  final int validUserCount;
  final List<Message> validMessages;
  final List<User> validUsers;

  MessageValidationResult({
    required this.originalMessageCount,
    required this.validMessageCount,
    required this.originalUserCount,
    required this.validUserCount,
    required this.validMessages,
    required this.validUsers,
  });

  double get messageValidityRate => 
      originalMessageCount > 0 ? validMessageCount / originalMessageCount : 0.0;
  
  double get userValidityRate => 
      originalUserCount > 0 ? validUserCount / originalUserCount : 0.0;

  bool get isReasonablyValid => messageValidityRate > 0.7 && userValidityRate > 0.7;
  
  Map<String, dynamic> toMap() {
    return {
      'originalMessages': originalMessageCount,
      'validMessages': validMessageCount,
      'originalUsers': originalUserCount,
      'validUsers': validUserCount,
      'messageValidityRate': messageValidityRate,
      'userValidityRate': userValidityRate,
      'isReasonablyValid': isReasonablyValid,
    };
  }
}