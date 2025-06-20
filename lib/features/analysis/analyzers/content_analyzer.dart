import 'package:flutter/foundation.dart';
import '../../../shared/domain.dart';
import 'base_analyzer.dart';

class ContentAnalyzer implements BaseAnalyzer {
  final RegExp emojiRegExp = RegExp(
    r'[\u{1F600}-\u{1F64F}|\u{1F300}-\u{1F5FF}|\u{1F680}-\u{1F6FF}|\u{2600}-\u{26FF}|\u{2700}-\u{27BF}]',
    unicode: true,
  );

  final RegExp urlRegExp = RegExp(
    r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
    caseSensitive: false,
  );

  @override
  Future<Map<String, dynamic>> analyze(ChatEntity chat) async {
    debugPrint("ContentAnalyzer: Analyzing content patterns");

    // Filter out system messages
    final realMessages = chat.messages
        .where((msg) =>
            msg.senderId != "System" &&
            !msg.content.toLowerCase().contains('created group') &&
            !msg.content.toLowerCase().contains('added') &&
            !msg.content.toLowerCase().contains('left'))
        .toList();

    // Initialize counters
    int totalWords = 0;
    int totalCharacters = 0;
    int totalEmojis = 0;
    int totalUrls = 0;
    int totalMedia = 0;

    final Map<String, int> emojiCounts = {};
    final Map<String, int> domainCounts = {};
    final Map<String, Map<String, int>> domainCountsByUser = {};
    final Map<String, int> messageLengthDistribution = {};

    // Initialize user-specific counters
    for (final user in chat.users) {
      if (user.id != "System") {
        domainCountsByUser[user.id] = {};
      }
    }

    // Process each message
    for (final message in realMessages) {
      _processMessage(message, totalWords, totalCharacters, totalEmojis, 
                     totalUrls, totalMedia, emojiCounts, domainCounts, 
                     domainCountsByUser, messageLengthDistribution);
    }

    // Calculate averages
    final avgWordsPerMessage = realMessages.isNotEmpty ? totalWords / realMessages.length : 0;
    final avgCharsPerMessage = realMessages.isNotEmpty ? totalCharacters / realMessages.length : 0;

    // Get top emojis
    final topEmojis = emojiCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Get top domains
    final topDomains = domainCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    debugPrint("ContentAnalyzer: Total words: $totalWords, Total emojis: $totalEmojis");

    return {
      'contentAnalysis': {
        'totalWords': totalWords,
        'totalCharacters': totalCharacters,
        'totalEmojis': totalEmojis,
        'totalUrls': totalUrls,
        'totalMedia': totalMedia,
        'avgWordsPerMessage': avgWordsPerMessage.toStringAsFixed(1),
        'avgCharsPerMessage': avgCharsPerMessage.toStringAsFixed(1),
        'topEmojis': topEmojis.take(10).map((e) => {
          'emoji': e.key,
          'count': e.value,
        }).toList(),
        'topDomains': topDomains.take(10).map((e) => {
          'domain': e.key,
          'count': e.value,
        }).toList(),
        'messageLengthDistribution': messageLengthDistribution,
      }
    };
  }

  void _processMessage(
    MessageEntity message,
    int totalWords,
    int totalCharacters,
    int totalEmojis,
    int totalUrls,
    int totalMedia,
    Map<String, int> emojiCounts,
    Map<String, int> domainCounts,
    Map<String, Map<String, int>> domainCountsByUser,
    Map<String, int> messageLengthDistribution,
  ) {
    final content = message.content;
    final senderId = message.senderId;

    if (message.type == MessageType.text) {
      // Count words (all words, no filtering)
      final words = content.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
      totalWords += words;
      totalCharacters += content.length;

      // Message length distribution
      String lengthCategory;
      if (content.length <= 20) {
        lengthCategory = 'short';
      } else if (content.length <= 100) {
        lengthCategory = 'medium';
      } else {
        lengthCategory = 'long';
      }
      messageLengthDistribution[lengthCategory] = (messageLengthDistribution[lengthCategory] ?? 0) + 1;

      // Count emojis
      final emojiMatches = emojiRegExp.allMatches(content);
      totalEmojis += emojiMatches.length;

      for (final match in emojiMatches) {
        final emoji = match.group(0)!;
        emojiCounts[emoji] = (emojiCounts[emoji] ?? 0) + 1;
      }
    } else {
      totalMedia++;
    }

    // Process URLs and extract domains
    final urls = urlRegExp.allMatches(content).map((m) => m.group(0)!).toList();

    for (final url in urls) {
      try {
        final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
        final domain = uri.host;

        if (domain.isNotEmpty) {
          domainCounts[domain] = (domainCounts[domain] ?? 0) + 1;
          if (domainCountsByUser.containsKey(senderId)) {
            domainCountsByUser[senderId]![domain] =
                (domainCountsByUser[senderId]![domain] ?? 0) + 1;
          }
        }
      } catch (e) {
        debugPrint("ContentAnalyzer: Failed to parse URL: $url");
      }
    }
  }
}