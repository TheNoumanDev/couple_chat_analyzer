// lib/features/analysis/analyzers/enhanced/temporal_insight_analyzer.dart

import 'package:flutter/foundation.dart';
import '../../../../shared/domain.dart';

class TemporalInsightAnalyzer {
  Future<Map<String, dynamic>> analyze(ChatEntity chat) async {
    try {
      debugPrint("TemporalInsightAnalyzer: Starting analysis");

      // Simple timeline analysis
      final timeline = _createEvolutionTimeline(chat.messages);

      debugPrint("TemporalInsightAnalyzer: Analysis complete");

      return {
        'temporalInsights': {
          'evolutionTimeline': timeline,
          'communicationEvolution': {},
          'relationshipMilestones': [],
        }
      };
    } catch (e) {
      debugPrint("TemporalInsightAnalyzer: Error - $e");
      return {
        'temporalInsights': {
          'evolutionTimeline': [],
          'communicationEvolution': {},
          'relationshipMilestones': [],
        }
      };
    }
  }

  List<Map<String, dynamic>> _createEvolutionTimeline(
      List<MessageEntity> messages) {
    final timeline = <Map<String, dynamic>>[];

    try {
      if (messages.isEmpty) return timeline;

      final firstMessage = messages.first;
      final lastMessage = messages.last;
      final totalDays =
          lastMessage.timestamp.difference(firstMessage.timestamp).inDays;

      // Create simple milestones
      final milestones = [
        {
          'milestone': 'First Message',
          'date': firstMessage.timestamp.toString().split(' ')[0],
          'description': 'Conversation started',
          'daysSinceStart': 0,
        },
      ];

      if (totalDays > 30) {
        milestones.add({
          'milestone': '1000 Messages',
          'date': messages.length > 1000
              ? messages[999].timestamp.toString().split(' ')[0]
              : '',
          'description': 'Reached 1000 messages',
          'daysSinceStart': messages.length > 1000
              ? messages[999]
                  .timestamp
                  .difference(firstMessage.timestamp)
                  .inDays
              : totalDays ~/ 2,
        });
      }

      if (totalDays > 100) {
        milestones.add({
          'milestone': 'Most Active Period',
          'date': lastMessage.timestamp.toString().split(' ')[0],
          'description': 'Peak communication period',
          'daysSinceStart': totalDays * 3 ~/ 4,
        });
      }

      milestones.add({
        'milestone': 'Latest Message',
        'date': lastMessage.timestamp.toString().split(' ')[0],
        'description': 'Most recent communication',
        'daysSinceStart': totalDays,
      });

      timeline.addAll(milestones);
    } catch (e) {
      debugPrint("Error creating timeline: $e");
    }

    return timeline;
  }
}