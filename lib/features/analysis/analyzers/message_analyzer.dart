import 'package:flutter/foundation.dart';
import '../../../shared/domain.dart';
import 'base_analyzer.dart';

class MessageAnalyzer implements BaseAnalyzer {
  // Fixed MessageAnalyzer.analyze method - uses names instead of IDs
  @override
  Future<Map<String, dynamic>> analyze(ChatEntity chat) async {
    debugPrint("MessageAnalyzer: Analyzing ${chat.messages.length} messages");

    // Filter out system messages and users
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

    final realUsers = chat.users
        .where((user) =>
            user.id != "System" && user.name.toLowerCase() != "system")
        .toList();

    // Create a map from user ID to user name for easy lookup
    final Map<String, String> userIdToName = {};
    for (final user in realUsers) {
      userIdToName[user.id] = user.name;
    }

    // Calculate message counts per real user using NAMES
    final Map<String, int> messageCountPerUserName = {};
    for (final user in realUsers) {
      messageCountPerUserName[user.name] = 0;
    }

    for (final message in realMessages) {
      final userName = userIdToName[message.senderId];
      if (userName != null && messageCountPerUserName.containsKey(userName)) {
        messageCountPerUserName[userName] =
            (messageCountPerUserName[userName] ?? 0) + 1;
      }
    }

    // Calculate total messages (excluding system)
    final int totalMessages = realMessages.length;

    // Create user stats with percentages using NAMES
    final List<Map<String, dynamic>> userStats = [];
    for (final user in realUsers) {
      final messageCount = messageCountPerUserName[user.name] ?? 0;
      final percentage = totalMessages > 0
          ? (messageCount / totalMessages * 100).toStringAsFixed(1)
          : '0';
      userStats.add({
        'userId': user.id,
        'name': user.name,
        'messageCount': messageCount,
        'percentage': double.parse(percentage),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}