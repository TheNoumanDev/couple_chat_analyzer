import 'package:flutter/foundation.dart';
import '../../../shared/domain.dart';
import 'base_analyzer.dart';

class MessageAnalyzer implements BasicAnalyzer {
  @override
  Future<Map<String, dynamic>> analyze(ChatEntity chat) async {
    debugPrint("MessageAnalyzer: Starting message analysis");

    // Filter out system messages and system users
    final realUsers = chat.users.where((user) => user.id != "System").toList();
    final realMessages = chat.messages.where((msg) => 
        msg.senderId != "System" && 
        !msg.content.toLowerCase().contains('created group') &&
        !msg.content.toLowerCase().contains('added') &&
        !msg.content.toLowerCase().contains('left')
    ).toList();

    if (realUsers.isEmpty || realMessages.isEmpty) {
      debugPrint("MessageAnalyzer: No real users or messages found");
      return {
        'summary': {
          'totalMessages': 0,
          'totalUsers': 0,
          'dateRange': 'No data',
          'avgMessagesPerDay': '0',
          'totalMedia': 0,
          'durationDays': 0,
        },
        'messagesByUser': [],
      };
    }

    // Initialize detailed counters for all users
    final Map<String, int> messageCountPerUserName = {};
    final Map<String, int> wordCountPerUser = {};
    final Map<String, int> letterCountPerUser = {};
    final Map<String, int> mediaCountPerUser = {};
    final Map<String, int> emojiCountPerUser = {};
    final Map<String, DateTime> firstMessagePerUser = {};
    final Map<String, DateTime> lastMessagePerUser = {};
    // NEW: Store actual message content
    final Map<String, String> firstMessageContentPerUser = {};
    final Map<String, String> lastMessageContentPerUser = {};

    final emojiRegExp = RegExp(
      r'[\u{1F600}-\u{1F64F}|\u{1F300}-\u{1F5FF}|\u{1F680}-\u{1F6FF}|\u{2600}-\u{26FF}|\u{2700}-\u{27BF}]',
      unicode: true,
    );

    // Initialize all users
    for (final user in realUsers) {
      messageCountPerUserName[user.name] = 0;
      wordCountPerUser[user.name] = 0;
      letterCountPerUser[user.name] = 0;
      mediaCountPerUser[user.name] = 0;
      emojiCountPerUser[user.name] = 0;
    }

    // Process all messages with detailed statistics
    for (final message in realMessages) {
      final user = realUsers.firstWhere((u) => u.id == message.senderId, orElse: () => realUsers.first);
      final userName = user.name;

      messageCountPerUserName[userName] = (messageCountPerUserName[userName] ?? 0) + 1;

      // Track first and last message times AND CONTENT
      if (!firstMessagePerUser.containsKey(userName) || 
          message.timestamp.isBefore(firstMessagePerUser[userName]!)) {
        firstMessagePerUser[userName] = message.timestamp;
        firstMessageContentPerUser[userName] = message.content; // Store content
      }
      if (!lastMessagePerUser.containsKey(userName) || 
          message.timestamp.isAfter(lastMessagePerUser[userName]!)) {
        lastMessagePerUser[userName] = message.timestamp;
        lastMessageContentPerUser[userName] = message.content; // Store content
      }

      // Count detailed statistics
      if (message.type == MessageType.text) {
        // Word count
        final words = message.content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
        wordCountPerUser[userName] = (wordCountPerUser[userName] ?? 0) + words;
        
        // Character count
        letterCountPerUser[userName] = (letterCountPerUser[userName] ?? 0) + message.content.length;
        
        // Emoji count
        final emojiMatches = emojiRegExp.allMatches(message.content);
        emojiCountPerUser[userName] = (emojiCountPerUser[userName] ?? 0) + emojiMatches.length;
      } else {
        // Media count
        mediaCountPerUser[userName] = (mediaCountPerUser[userName] ?? 0) + 1;
      }
    }

    // Calculate total messages (excluding system)
    final int totalMessages = realMessages.length;

    // Create user stats with ALL statistics INCLUDING MESSAGE CONTENT
    final List<Map<String, dynamic>> userStats = [];
    for (final user in realUsers) {
      final messageCount = messageCountPerUserName[user.name] ?? 0;
      final percentage = totalMessages > 0
          ? (messageCount / totalMessages * 100).toStringAsFixed(1)
          : '0';
      
      // Get dates and content
      final firstMessage = firstMessagePerUser[user.name];
      final lastMessage = lastMessagePerUser[user.name];
      final firstContent = firstMessageContentPerUser[user.name];
      final lastContent = lastMessageContentPerUser[user.name];
      
      userStats.add({
        'userId': user.id,
        'name': user.name,
        'messageCount': messageCount,
        'percentage': double.parse(percentage),
        // Include detailed statistics
        'wordCount': wordCountPerUser[user.name] ?? 0,
        'letterCount': letterCountPerUser[user.name] ?? 0,
        'mediaCount': mediaCountPerUser[user.name] ?? 0,
        'emojiCount': emojiCountPerUser[user.name] ?? 0,
        // Date and time info
        'firstMessageDate': firstMessage != null ? _formatDate(firstMessage) : 'No data',
        'firstMessageTime': firstMessage != null ? _formatTime(firstMessage) : 'No data',
        'lastMessageDate': lastMessage != null ? _formatDate(lastMessage) : 'No data',
        'lastMessageTime': lastMessage != null ? _formatTime(lastMessage) : 'No data',
        // NEW: Include actual message content
        'firstMessageContent': firstContent != null ? _truncateMessage(firstContent) : 'No message',
        'lastMessageContent': lastContent != null ? _truncateMessage(lastContent) : 'No message',
        'firstMessageFullContent': firstContent, // Full content for detailed view
        'lastMessageFullContent': lastContent,   // Full content for detailed view
        // Raw timestamps for debugging
        'firstMessageTimestamp': firstMessage,
        'lastMessageTimestamp': lastMessage,
      });
    }

    // Sort users by message count
    userStats.sort((a, b) => b['messageCount'].compareTo(a['messageCount']));

    // Calculate date range
    final firstDate = chat.firstMessageDate;
    final lastDate = chat.lastMessageDate;
    final dateRange = '${_formatDate(firstDate)} - ${_formatDate(lastDate)}';

    // Calculate duration in days
    final duration = lastDate.difference(firstDate).inDays + 1;

    // Calculate average messages per day
    final avgMessagesPerDay =
        duration > 0 ? (totalMessages / duration).toStringAsFixed(1) : '0';

    // Count media messages (excluding system)
    final mediaCount =
        realMessages.where((m) => m.type != MessageType.text).length;

    debugPrint("MessageAnalyzer: Analysis complete. Real messages: $totalMessages, Real users: ${realUsers.length}");
    
    // DEBUG: Print first/last message info for each user
    for (final user in userStats) {
      debugPrint("User ${user['name']}: first='${user['firstMessageContent']}', last='${user['lastMessageContent']}'");
    }

    return {
      'summary': {
        'totalMessages': totalMessages,
        'totalUsers': realUsers.length,
        'dateRange': dateRange,
        'avgMessagesPerDay': avgMessagesPerDay,
        'totalMedia': mediaCount,
        'durationDays': duration,
      },
      'messagesByUser': userStats,
    };
  }

  // Date formatting
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Time formatting
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
  }

  // NEW: Truncate message content for display
  String _truncateMessage(String content) {
    if (content.isEmpty) return 'Empty message';
    
    // Handle media messages
    if (content.contains('<Media omitted>') || 
        content.contains('image omitted') || 
        content.contains('video omitted') ||
        content.contains('audio omitted') ||
        content.contains('document omitted')) {
      return '📎 Media message';
    }
    
    // Truncate long messages
    if (content.length <= 50) {
      return content;
    }
    
    return '${content.substring(0, 47)}...';
  }
}
