// ============================================================================
// COMPLETE FIXED CONTENT ANALYZER - Enhanced data output structure
// File: lib/features/analysis/analyzers/content_analyzer.dart
// ============================================================================

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
    debugPrint("📊 ContentAnalyzer: Starting content analysis");

    // Filter out system messages
    final realMessages = chat.messages
        .where((msg) =>
            msg.senderId != "System" &&
            !_isSystemMessage(msg.content))
        .toList();

    debugPrint("📊 ContentAnalyzer: Processing ${realMessages.length} real messages");

    // Initialize counters - use a mutable object to track totals
    final totals = {
      'words': 0,
      'characters': 0,
      'emojis': 0,
      'urls': 0,
      'media': 0,
    };

    final Map<String, int> emojiCounts = {};
    final Map<String, int> domainCounts = {};
    final Map<String, Map<String, int>> domainCountsByUser = {};
    final Map<String, int> messageLengthDistribution = {
      'short': 0,
      'medium': 0,
      'long': 0,
    };

    // Initialize user-specific counters
    for (final user in chat.users) {
      if (user.id != "System") {
        domainCountsByUser[user.id] = {};
      }
    }

    // Process each message
    for (final message in realMessages) {
      _processMessage(message, totals, emojiCounts, domainCounts, 
                     domainCountsByUser, messageLengthDistribution);
    }

    // Calculate averages
    final avgWordsPerMessage = realMessages.isNotEmpty ? 
        (totals['words']! / realMessages.length) : 0.0;
    final avgCharsPerMessage = realMessages.isNotEmpty ? 
        (totals['characters']! / realMessages.length) : 0.0;

    // Get top emojis (sorted by count)
    final topEmojis = emojiCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Get top domains (sorted by count)
    final topDomains = domainCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    debugPrint("📊 ContentAnalyzer Results:");
    debugPrint("  - Total words: ${totals['words']}");
    debugPrint("  - Total emojis: ${totals['emojis']}");
    debugPrint("  - Total media: ${totals['media']}");
    debugPrint("  - Top emojis count: ${topEmojis.length}");
    debugPrint("  - Message length distribution: $messageLengthDistribution");
    debugPrint("  - Top domains count: ${topDomains.length}");

    // Return the complete content analysis data
    final contentAnalysisData = {
      'totalWords': totals['words']!,
      'totalCharacters': totals['characters']!,
      'totalEmojis': totals['emojis']!,
      'totalUrls': totals['urls']!,
      'totalMedia': totals['media']!,
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
      'domainsByUser': domainCountsByUser,
    };

    debugPrint("✅ ContentAnalyzer: Analysis complete, returning data with ${contentAnalysisData.keys.length} keys");
    
    return {
      'contentAnalysis': contentAnalysisData,
    };
  }

  void _processMessage(
    MessageEntity message,
    Map<String, int> totals,
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
      totals['words'] = totals['words']! + words;
      totals['characters'] = totals['characters']! + content.length;

      // Message length distribution
      String lengthCategory;
      if (content.length <= 20) {
        lengthCategory = 'short';
      } else if (content.length <= 100) {
        lengthCategory = 'medium';
      } else {
        lengthCategory = 'long';
      }
      messageLengthDistribution[lengthCategory] = 
          (messageLengthDistribution[lengthCategory] ?? 0) + 1;

      // Count emojis
      final emojiMatches = emojiRegExp.allMatches(content);
      totals['emojis'] = totals['emojis']! + emojiMatches.length;

      for (final match in emojiMatches) {
        final emoji = match.group(0)!;
        emojiCounts[emoji] = (emojiCounts[emoji] ?? 0) + 1;
      }
    } else {
      // Handle media messages
      totals['media'] = totals['media']! + 1;
    }

    // Process URLs and extract domains
    final urls = urlRegExp.allMatches(content).map((m) => m.group(0)!).toList();
    totals['urls'] = totals['urls']! + urls.length;

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
        debugPrint("⚠️ Error parsing URL: $url - $e");
      }
    }
  }

  /// Check if a message is a system message
  bool _isSystemMessage(String content) {
    const systemMessagePatterns = [
      'created group',
      'added',
      'left',
      'changed the subject',
      'security code changed',
      'joined using',
      'removed ',
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

    final lowerContent = content.toLowerCase();
    for (final pattern in systemMessagePatterns) {
      if (lowerContent.contains(pattern)) {
        return true;
      }
    }
    return false;
  }
}