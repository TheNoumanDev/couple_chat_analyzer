import 'package:flutter/foundation.dart';
import '../../../shared/domain.dart';
import 'base_analyzer.dart';

class UserAnalyzer implements BaseAnalyzer {
  @override
  Future<Map<String, dynamic>> analyze(ChatEntity chat) async {
    debugPrint("UserAnalyzer: Analyzing ${chat.users.length} users");

    // Filter out system users
    final realUsers = chat.users
        .where((user) =>
            user.id != "System" && user.name.toLowerCase() != "system")
        .toList();

    final realMessages = chat.messages
        .where((msg) =>
            msg.senderId != "System" &&
            !msg.content.toLowerCase().contains('created group') &&
            !msg.content.toLowerCase().contains('added') &&
            !msg.content.toLowerCase().contains('left') &&
            !msg.content.toLowerCase().contains('changed the subject') &&
            !msg.content.toLowerCase().contains('security code changed') &&
            !msg.content.toLowerCase().contains('joined using') &&
            !msg.content.toLowerCase().contains('removed ') &&
            !msg.content.toLowerCase().contains('changed this group') &&
            !msg.content
                .toLowerCase()
                .contains('messages and calls are end-to-end encrypted'))
        .toList();

    debugPrint("UserAnalyzer: Processing ${realMessages.length} real messages from ${realUsers.length} real users");

    // Initialize counters for ALL real users
    final Map<String, int> messageCounts = {};
    final Map<String, int> wordCounts = {};
    final Map<String, int> letterCounts = {};
    final Map<String, int> mediaCounts = {};
    final Map<String, int> emojiCounts = {};
    final Map<String, int> avgResponseTimes = {};
    final Map<String, int> conversationStarters = {};
    final Map<String, int> conversationEnders = {};
    final Map<String, double> avgMessageLength = {};

    // Initialize counters for all real users (even if they have 0 messages)
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
    final emojiRegExp = RegExp(
        r'[\u{1F600}-\u{1F64F}|\u{1F300}-\u{1F5FF}|\u{1F680}-\u{1F6FF}|\u{2600}-\u{26FF}|\u{2700}-\u{27BF}]',
        unicode: true);

    for (final message in realMessages) {
      final userId = message.senderId;

      if (messageCounts.containsKey(userId)) {
        messageCounts[userId] = (messageCounts[userId] ?? 0) + 1;

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
      userStats.add({
        'userId': user.id,
        'name': user.name,
        'messageCount': messageCounts[user.id] ?? 0,
        'wordCount': wordCounts[user.id] ?? 0,
        'letterCount': letterCounts[user.id] ?? 0,
        'mediaCount': mediaCounts[user.id] ?? 0,
        'emojiCount': emojiCounts[user.id] ?? 0,
        'avgMessageLength': avgMessageLength[user.id] ?? 0,
        'avgResponseTimeSeconds': avgResponseTimes[user.id] ?? 0,
        'conversationStarts': conversationStarters[user.id] ?? 0,
        'conversationEnds': conversationEnders[user.id] ?? 0,
      });
    }

    // Sort by message count
    userStats.sort((a, b) => b['messageCount'].compareTo(a['messageCount']));

    debugPrint("UserAnalyzer: Final user stats: ${userStats.length} users");
    for (final user in userStats) {
      debugPrint("  - ${user['name']}: ${user['messageCount']} messages");
    }

    // Find key users
    final mostTalkative = userStats.isNotEmpty ? userStats.first : null;
    final leastTalkative = userStats.length > 1 ? userStats.last : null;

    final activeResponders =
        userStats.where((user) => user['avgResponseTimeSeconds'] > 0).toList();
    activeResponders.sort((a, b) =>
        a['avgResponseTimeSeconds'].compareTo(b['avgResponseTimeSeconds']));

    final fastestResponder =
        activeResponders.isNotEmpty ? activeResponders.first : null;
    final slowestResponder =
        activeResponders.length > 1 ? activeResponders.last : null;

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
}