import 'package:flutter/foundation.dart';
import '../../../shared/domain.dart';
import 'base_analyzer.dart';

class UserAnalyzer implements BasicAnalyzer {
  final RegExp emojiRegExp = RegExp(
    r'[\u{1F600}-\u{1F64F}|\u{1F300}-\u{1F5FF}|\u{1F680}-\u{1F6FF}|\u{2600}-\u{26FF}|\u{2700}-\u{27BF}]',
    unicode: true,
  );

  @override
  Future<Map<String, dynamic>> analyze(ChatEntity chat) async {
    debugPrint("UserAnalyzer: Starting user analysis");

    // Filter out system messages
    final realUsers = chat.users.where((user) => user.id != "System").toList();
    final realMessages = chat.messages
        .where((msg) =>
            msg.senderId != "System" &&
            !msg.content.toLowerCase().contains('created group') &&
            !msg.content.toLowerCase().contains('added') &&
            !msg.content.toLowerCase().contains('left'))
        .toList();

    if (realUsers.isEmpty || realMessages.isEmpty) {
      debugPrint("UserAnalyzer: No real users or messages found");
      return {'userAnalysis': {}};
    }

    // Initialize counters
    final Map<String, int> messageCounts = {};
    final Map<String, int> wordCounts = {};
    final Map<String, int> letterCounts = {};
    final Map<String, int> mediaCounts = {};
    final Map<String, int> emojiCounts = {};
    final Map<String, double> avgMessageLength = {};
    final Map<String, int> avgResponseTimes = {};
    final Map<String, int> conversationStarters = {};
    final Map<String, int> conversationEnders = {};
    final Map<String, DateTime> firstMessageTimes = {};
    final Map<String, DateTime> lastMessageTimes = {};

    // Initialize all users with zero counts
    for (final user in realUsers) {
      messageCounts[user.id] = 0;
      wordCounts[user.id] = 0;
      letterCounts[user.id] = 0;
      mediaCounts[user.id] = 0;
      emojiCounts[user.id] = 0;
      avgResponseTimes[user.id] = 0;
      conversationStarters[user.id] = 0;
      conversationEnders[user.id] = 0;
    }

    // Process messages
    for (final message in realMessages) {
      final userId = message.senderId;
      
      if (!messageCounts.containsKey(userId)) continue;

      messageCounts[userId] = (messageCounts[userId] ?? 0) + 1;

      // Track first and last message times
      if (!firstMessageTimes.containsKey(userId) || message.timestamp.isBefore(firstMessageTimes[userId]!)) {
        firstMessageTimes[userId] = message.timestamp;
      }
      if (!lastMessageTimes.containsKey(userId) || message.timestamp.isAfter(lastMessageTimes[userId]!)) {
        lastMessageTimes[userId] = message.timestamp;
      }

      if (message.type == MessageType.text) {
        final words = message.content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
        wordCounts[userId] = (wordCounts[userId] ?? 0) + words;
        letterCounts[userId] = (letterCounts[userId] ?? 0) + message.content.length;

        // Count emojis
        final emojiMatches = emojiRegExp.allMatches(message.content);
        emojiCounts[userId] = (emojiCounts[userId] ?? 0) + emojiMatches.length;
      } else {
        mediaCounts[userId] = (mediaCounts[userId] ?? 0) + 1;
      }
    }

    // Calculate response times (simplified)
    for (int i = 1; i < realMessages.length; i++) {
      final currentMessage = realMessages[i];
      final previousMessage = realMessages[i - 1];

      if (currentMessage.senderId != previousMessage.senderId) {
        final timeDiff = currentMessage.timestamp.difference(previousMessage.timestamp).inMinutes;
        if (timeDiff > 0 && timeDiff < 1440) { // Less than 24 hours
          final currentUserId = currentMessage.senderId;
          if (avgResponseTimes.containsKey(currentUserId)) {
            final current = avgResponseTimes[currentUserId] ?? 0;
            avgResponseTimes[currentUserId] = ((current + timeDiff) / 2).round();
          }
        }
      }
    }

    // Calculate average message length
    for (final userId in messageCounts.keys) {
      final count = messageCounts[userId] ?? 1;
      final letters = letterCounts[userId] ?? 0;
      avgMessageLength[userId] = count > 0 ? letters / count : 0;
    }

    // Create user statistics for ALL real users (even if they have 0 messages)
    List<Map<String, dynamic>> userStats = [];
    for (final user in realUsers) {
      final firstMessage = firstMessageTimes[user.id];
      final lastMessage = lastMessageTimes[user.id];
      
      userStats.add({
        'userId': user.id,
        'name': user.name,
        'messageCount': messageCounts[user.id] ?? 0,
        'wordCount': wordCounts[user.id] ?? 0,
        'letterCount': letterCounts[user.id] ?? 0,
        'mediaCount': mediaCounts[user.id] ?? 0,
        'emojiCount': emojiCounts[user.id] ?? 0,
        'avgMessageLength': avgMessageLength[user.id] ?? 0,
        'avgResponseTimeSeconds': (avgResponseTimes[user.id] ?? 0) * 60, // Convert to seconds
        'conversationStarts': conversationStarters[user.id] ?? 0,
        'conversationEnds': conversationEnders[user.id] ?? 0,
        'percentage': _calculatePercentage(messageCounts[user.id] ?? 0, realMessages.length),
        'firstMessageDate': firstMessage != null ? _formatDate(firstMessage) : null,
        'firstMessageTime': firstMessage != null ? _formatTime(firstMessage) : null,
        'firstMessageTimestamp': firstMessage,
        'lastMessageDate': lastMessage != null ? _formatDate(lastMessage) : null,
        'lastMessageTime': lastMessage != null ? _formatTime(lastMessage) : null,
        'lastMessageTimestamp': lastMessage,
      });
    }

    // Sort by message count
    userStats.sort((a, b) => b['messageCount'].compareTo(a['messageCount']));

    debugPrint("UserAnalyzer: Final user stats: ${userStats.length} users");
    for (final user in userStats) {
      debugPrint("  - ${user['name']}: ${user['messageCount']} messages, ${user['wordCount']} words");
    }

    // Find key users
    final mostTalkative = userStats.isNotEmpty ? userStats.first : null;
    final leastTalkative = userStats.length > 1 ? userStats.last : null;

    final activeResponders = userStats.where((user) => user['avgResponseTimeSeconds'] > 0).toList();
    activeResponders.sort((a, b) => a['avgResponseTimeSeconds'].compareTo(b['avgResponseTimeSeconds']));

    final fastestResponder = activeResponders.isNotEmpty ? activeResponders.first : null;
    final slowestResponder = activeResponders.length > 1 ? activeResponders.last : null;

    return {
      'userAnalysis': {
        'userData': userStats,
        'mostTalkative': mostTalkative,
        'leastTalkative': leastTalkative,
        'fastestResponder': fastestResponder,
        'slowestResponder': slowestResponder,
      }
    };
  }

  double _calculatePercentage(int userMessages, int totalMessages) {
    if (totalMessages == 0) return 0.0;
    return (userMessages / totalMessages) * 100;
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '${displayHour.toString()}:${minute.toString().padLeft(2, '0')} $period';
  }
}