// lib/features/analysis/analyzers/enhanced/content_intelligence_analyzer.dart

import 'package:flutter/foundation.dart';
import '../../../../shared/domain.dart';

class ContentIntelligenceAnalyzer {
  Future<Map<String, dynamic>> analyze(ChatEntity chat) async {
    try {
      debugPrint("ContentIntelligenceAnalyzer: Starting analysis");

      // Limit messages for performance
      final textMessages = chat.messages
          .where((m) => m.type == MessageType.text)
          .take(3000)
          .toList();

      final userIdToName = {for (var user in chat.users) user.id: user.name};

      // Vocabulary complexity analysis (simplified)
      final vocabularyComplexity =
          _analyzeVocabularyComplexity(textMessages, userIdToName);

      debugPrint("ContentIntelligenceAnalyzer: Analysis complete");

      return {
        'contentIntelligence': {
          'vocabularyComplexity': vocabularyComplexity,
          'communicationIntelligence': {},
          'topicEvolution': [],
        }
      };
    } catch (e) {
      debugPrint("ContentIntelligenceAnalyzer: Error - $e");
      return {
        'contentIntelligence': {
          'vocabularyComplexity': {},
          'communicationIntelligence': {},
          'topicEvolution': [],
        }
      };
    }
  }

  Map<String, dynamic> _analyzeVocabularyComplexity(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    final complexity = <String, dynamic>{};

    try {
      final userVocab = <String, Set<String>>{};
      final userWordCounts = <String, int>{};

      // Initialize tracking
      for (final userName in userIdToName.values) {
        userVocab[userName] = <String>{};
        userWordCounts[userName] = 0;
      }

      // Analyze vocabulary
      for (final message in messages) {
        final userName = userIdToName[message.senderId] ?? 'Unknown';

        if (userVocab.containsKey(userName)) {
          final words = message.content
              .toLowerCase()
              .replaceAll(RegExp(r'[^\w\s]'), ' ')
              .split(RegExp(r'\s+'))
              .where((word) => word.length > 3)
              .take(20); // Limit words per message

          for (final word in words) {
            userVocab[userName]!.add(word);
            userWordCounts[userName] = userWordCounts[userName]! + 1;
          }
        }
      }

      // Calculate complexity scores
      for (final entry in userVocab.entries) {
        final userName = entry.key;
        final uniqueWords = entry.value.length;
        final totalWords = userWordCounts[userName] ?? 1;

        // Simple complexity calculation
        final complexityScore =
            ((uniqueWords / totalWords) * 100).clamp(0.0, 100.0);

        String vocabularyType = 'Average Vocabulary';
        if (complexityScore > 80) {
          vocabularyType = 'Rich Vocabulary';
        } else if (complexityScore > 60) {
          vocabularyType = 'Good Vocabulary';
        } else if (complexityScore < 30) {
          vocabularyType = 'Simple Vocabulary';
        }

        complexity[userName] = {
          'uniqueWords': uniqueWords,
          'totalWords': totalWords,
          'complexityScore': complexityScore.round(),
          'vocabularyType': vocabularyType,
        };
      }
    } catch (e) {
      debugPrint("Error analyzing vocabulary complexity: $e");
    }

    return complexity;
  }
}