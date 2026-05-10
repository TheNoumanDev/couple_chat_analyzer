// ============================================================================
// FILE: features/analysis/services/stats_aggregator.dart
// StatsAggregator - Collects and normalizes analyzer outputs for LLM consumption
// ============================================================================
import 'package:flutter/foundation.dart';
import '../analysis_models.dart';

/// Aggregates analysis results from all analyzers into a structured format
/// suitable for LLM consumption. This prepares the data for DeepSeek API calls.
class StatsAggregator {
  /// Maximum character limit for LLM context (DeepSeek V3.2 supports 128K)
  static const int maxContextLength = 100000;

  /// Aggregate all analysis results into a structured summary for LLM
  Map<String, dynamic> aggregate(ChatAnalysisResult analysisResult) {
    debugPrint("StatsAggregator: Aggregating ${analysisResult.results.length} analysis types");

    final aggregated = <String, dynamic>{
      'chatId': analysisResult.chatId,
      'generatedAt': analysisResult.generatedAt.toIso8601String(),
      'overview': _extractOverview(analysisResult),
      'userProfiles': _extractUserProfiles(analysisResult),
      'communicationPatterns': _extractCommunicationPatterns(analysisResult),
      'emotionalDynamics': _extractEmotionalDynamics(analysisResult),
      'relationshipHealth': _extractRelationshipHealth(analysisResult),
      'personalityInsights': _extractPersonalityInsights(analysisResult),
      'temporalPatterns': _extractTemporalPatterns(analysisResult),
    };

    return aggregated;
  }

  /// Create a concise prompt-ready summary for LLM
  String createLLMPromptContext(ChatAnalysisResult analysisResult) {
    final aggregated = aggregate(analysisResult);
    final buffer = StringBuffer();

    buffer.writeln('# Chat Analysis Summary');
    buffer.writeln();

    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('📤 STATS CONTEXT BEING SENT TO LLM:');
    debugPrint('═══════════════════════════════════════════════════════════');

    // Overview section
    final overview = aggregated['overview'] as Map<String, dynamic>? ?? {};
    buffer.writeln('## Overview');
    buffer.writeln('- Total Messages: ${overview['totalMessages'] ?? 'N/A'}');
    buffer.writeln('- Total Users: ${overview['totalUsers'] ?? 'N/A'}');
    buffer.writeln('- Duration: ${overview['durationDays'] ?? 'N/A'} days');
    buffer.writeln('- Date Range: ${overview['dateRange'] ?? 'N/A'}');
    buffer.writeln('- Average Messages/Day: ${_formatNumber(overview['avgMessagesPerDay'])}');
    buffer.writeln();

    // User profiles
    final userProfiles = aggregated['userProfiles'] as Map<String, dynamic>? ?? {};
    if (userProfiles.isNotEmpty) {
      buffer.writeln('## User Profiles');
      for (final entry in userProfiles.entries) {
        final profile = entry.value as Map<String, dynamic>? ?? {};
        buffer.writeln('### ${entry.key}');
        buffer.writeln('- Messages: ${profile['messageCount'] ?? 'N/A'}');
        buffer.writeln('- Avg Length: ${_formatNumber(profile['avgMessageLength'])} chars');
        buffer.writeln('- Emoji Usage: ${_formatPercent(profile['emojiRate'])}');
        buffer.writeln('- Media Shared: ${profile['mediaCount'] ?? 'N/A'}');
        buffer.writeln('- Communication Style: ${profile['communicationStyle'] ?? 'N/A'}');
        buffer.writeln();
      }
    }

    // Communication patterns
    final patterns = aggregated['communicationPatterns'] as Map<String, dynamic>? ?? {};
    if (patterns.isNotEmpty) {
      buffer.writeln('## Communication Patterns');
      buffer.writeln('- Avg Response Time: ${patterns['avgResponseTime'] ?? 'N/A'}');
      buffer.writeln('- Conversation Count: ${patterns['conversationCount'] ?? 'N/A'}');
      buffer.writeln('- Question Rate: ${_formatPercent(patterns['questionRate'])}');
      buffer.writeln('- Exclamation Rate: ${_formatPercent(patterns['exclamationRate'])}');
      buffer.writeln();
    }

    // Emotional dynamics
    final emotional = aggregated['emotionalDynamics'] as Map<String, dynamic>? ?? {};
    if (emotional.isNotEmpty) {
      buffer.writeln('## Emotional Dynamics');
      buffer.writeln('- Overall Sentiment: ${emotional['overallSentiment'] ?? 'N/A'}');
      buffer.writeln('- Empathy Score: ${_formatNumber(emotional['empathyScore'])}');
      buffer.writeln('- Emotional Reciprocity: ${_formatNumber(emotional['emotionalReciprocity'])}');
      buffer.writeln('- Emotional Volatility: ${_formatNumber(emotional['emotionalVolatility'])}');
      buffer.writeln();
    }

    // Relationship health
    final relationship = aggregated['relationshipHealth'] as Map<String, dynamic>? ?? {};
    if (relationship.isNotEmpty) {
      buffer.writeln('## Relationship Dynamics');
      buffer.writeln('- Relationship Trend: ${relationship['trend'] ?? 'N/A'}');
      buffer.writeln('- Balance Score: ${_formatNumber(relationship['balanceScore'])}');
      buffer.writeln('- Engagement Level: ${relationship['engagementLevel'] ?? 'N/A'}');
      buffer.writeln('- Bonding Language: ${_formatPercent(relationship['bondingLanguageRate'])}');
      buffer.writeln();
    }

    // Personality insights
    final personality = aggregated['personalityInsights'] as Map<String, dynamic>? ?? {};
    if (personality.isNotEmpty) {
      buffer.writeln('## Personality Insights');
      for (final entry in personality.entries) {
        final traits = entry.value as Map<String, dynamic>? ?? {};
        buffer.writeln('### ${entry.key}');
        buffer.writeln('- MBTI Profile: ${traits['mbtiProfile'] ?? 'N/A'}');
        buffer.writeln('- Extraversion: ${_formatNumber(traits['extraversion'])}');
        buffer.writeln('- Openness: ${_formatNumber(traits['openness'])}');
        buffer.writeln('- Conscientiousness: ${_formatNumber(traits['conscientiousness'])}');
        buffer.writeln();
      }
    }

    // Temporal patterns
    final temporal = aggregated['temporalPatterns'] as Map<String, dynamic>? ?? {};
    if (temporal.isNotEmpty) {
      buffer.writeln('## Temporal Patterns');
      buffer.writeln('- Peak Hours: ${temporal['peakHours'] ?? 'N/A'}');
      buffer.writeln('- Most Active Day: ${temporal['mostActiveDay'] ?? 'N/A'}');
      buffer.writeln('- Activity Trend: ${temporal['activityTrend'] ?? 'N/A'}');
      buffer.writeln();
    }

    final result = buffer.toString();

    // Log the context being sent
    debugPrint(result);
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('📊 Context length: ${result.length} chars');
    debugPrint('═══════════════════════════════════════════════════════════');

    // Truncate if exceeds max length
    if (result.length > maxContextLength) {
      debugPrint("StatsAggregator: Truncating context from ${result.length} to $maxContextLength chars");
      return result.substring(0, maxContextLength);
    }

    return result;
  }

  // ============================================================================
  // EXTRACTION METHODS
  // ============================================================================

  Map<String, dynamic> _extractOverview(ChatAnalysisResult result) {
    final messages = result.results['messages']?.data ?? {};
    final time = result.results['time']?.data ?? {};
    final users = result.results['users']?.data ?? {};

    // Safe extraction - try multiple possible locations
    final summary = _safeMap(messages['summary']).isNotEmpty
        ? _safeMap(messages['summary'])
        : _safeMap(time['summary']).isNotEmpty
            ? _safeMap(time['summary'])
            : _safeMap(users['summary']);

    return {
      'totalMessages': summary['totalMessages'] ?? messages['totalMessages'],
      'totalUsers': summary['totalUsers'] ?? users['totalUsers'],
      'durationDays': summary['durationDays'] ?? time['durationDays'],
      'dateRange': summary['dateRange'] ?? time['dateRange'],
      'avgMessagesPerDay': summary['avgMessagesPerDay'] ?? time['avgMessagesPerDay'],
      'totalMedia': summary['totalMedia'] ?? messages['totalMedia'],
    };
  }

  Map<String, dynamic> _extractUserProfiles(ChatAnalysisResult result) {
    final users = result.results['users']?.data ?? {};
    final linguistic = result.results['linguistic']?.data ?? {};
    final behavioral = result.results['behaviorPatterns']?.data ?? {};

    final profiles = <String, dynamic>{};

    // Get userAnalysis which contains userData list
    final userAnalysisRaw = users['userAnalysis'];

    // First try to get userData list (the actual list of all users)
    List<dynamic>? userDataList;
    if (userAnalysisRaw is Map<String, dynamic>) {
      userDataList = userAnalysisRaw['userData'] as List<dynamic>?;
    }

    if (userDataList != null && userDataList.isNotEmpty) {
      // Extract from userData list - this has actual usernames
      for (final userObj in userDataList) {
        if (userObj is Map<String, dynamic>) {
          final rawName = userObj['name'] as String? ??
                          userObj['userName'] as String? ??
                          userObj['userId'] as String? ??
                          'Unknown';
          // Strip emojis from username for LLM compatibility
          final userName = _stripEmojis(rawName);
          profiles[userName] = {
            'messageCount': userObj['messageCount'],
            'avgMessageLength': userObj['avgMessageLength'],
            'wordCount': userObj['wordCount'],
            'emojiCount': userObj['emojiCount'],
            'mediaCount': userObj['mediaCount'],
            'percentage': userObj['percentage'],
            'avgResponseTime': userObj['avgResponseTimeSeconds'],
          };
        }
      }
    } else if (userAnalysisRaw is List) {
      // Fallback: It's directly a list of user objects
      for (final userObj in userAnalysisRaw) {
        if (userObj is Map<String, dynamic>) {
          final rawName = userObj['userName'] as String? ??
                          userObj['name'] as String? ??
                          userObj['user'] as String? ??
                          'Unknown';
          final userName = _stripEmojis(rawName);
          profiles[userName] = {
            'messageCount': userObj['messageCount'] ?? userObj['totalMessages'],
            'avgMessageLength': userObj['avgMessageLength'] ?? userObj['averageLength'],
            'wordCount': userObj['wordCount'] ?? userObj['totalWords'],
            'emojiCount': userObj['emojiCount'],
            'mediaCount': userObj['mediaCount'],
          };
        }
      }
    }

    // Add linguistic data if available - match by stripping emojis from source names
    final vocabularyRaw = linguistic['vocabulary'];
    if (vocabularyRaw is Map<String, dynamic>) {
      for (final entry in vocabularyRaw.entries) {
        final strippedKey = _stripEmojis(entry.key);
        if (profiles.containsKey(strippedKey) && entry.value is Map<String, dynamic>) {
          final vocab = entry.value as Map<String, dynamic>;
          (profiles[strippedKey] as Map<String, dynamic>)['vocabularyRichness'] = vocab['ttr'] ?? vocab['richness'];
        }
      }
    } else if (vocabularyRaw is List) {
      for (final vocabItem in vocabularyRaw) {
        if (vocabItem is Map<String, dynamic>) {
          final rawName = vocabItem['userName'] ?? vocabItem['user'] ?? vocabItem['name'];
          if (rawName != null) {
            final strippedName = _stripEmojis(rawName.toString());
            if (profiles.containsKey(strippedName)) {
              (profiles[strippedName] as Map<String, dynamic>)['vocabularyRichness'] = vocabItem['ttr'] ?? vocabItem['richness'];
            }
          }
        }
      }
    }

    // Add communication style data - match by stripping emojis from source names
    final stylesRaw = behavioral['communicationStyles'];
    if (stylesRaw is Map<String, dynamic>) {
      for (final entry in stylesRaw.entries) {
        final strippedKey = _stripEmojis(entry.key);
        if (profiles.containsKey(strippedKey)) {
          final style = entry.value;
          if (style is Map<String, dynamic>) {
            (profiles[strippedKey] as Map<String, dynamic>)['communicationStyle'] = style['style'] ?? style['type'];
          } else if (style is String) {
            (profiles[strippedKey] as Map<String, dynamic>)['communicationStyle'] = style;
          }
        }
      }
    } else if (stylesRaw is List) {
      for (final styleItem in stylesRaw) {
        if (styleItem is Map<String, dynamic>) {
          final rawName = styleItem['userName'] ?? styleItem['user'] ?? styleItem['name'];
          if (rawName != null) {
            final strippedName = _stripEmojis(rawName.toString());
            if (profiles.containsKey(strippedName)) {
              (profiles[strippedName] as Map<String, dynamic>)['communicationStyle'] = styleItem['style'] ?? styleItem['type'];
            }
          }
        }
      }
    }

    debugPrint('StatsAggregator: Extracted ${profiles.length} user profiles: ${profiles.keys.join(", ")}');
    return profiles;
  }

  Map<String, dynamic> _extractCommunicationPatterns(ChatAnalysisResult result) {
    final dynamics = result.results['conversationDynamics']?.data ?? {};
    final behavioral = result.results['behaviorPatterns']?.data ?? {};

    // Safe extraction with type checking
    final responsePatterns = _safeMap(dynamics['responsePatterns']);
    final flowPatterns = _safeMap(dynamics['flowPatterns']);
    final initiationPatterns = _safeMap(dynamics['initiationPatterns']);
    final conversationStats = _safeMap(dynamics['conversationStats']);

    final extracted = {
      'avgResponseTime': responsePatterns['averageResponseTime'] ?? dynamics['averageResponseTime'],
      'conversationCount': dynamics['totalConversations'] ?? conversationStats['total'],
      'averageConversationLength': dynamics['averageConversationLength'],
      'conversationHealthScore': dynamics['conversationHealthScore'],
      'initiationBalance': initiationPatterns['balance'] ?? initiationPatterns['ratio'],
      'flowScore': flowPatterns['score'] ?? flowPatterns['overall'],
      'dominantSpeaker': initiationPatterns['dominantInitiator'] ?? behavioral['dominantSpeaker'],
    };

    debugPrint('StatsAggregator: Extracted communication patterns: $extracted');
    return extracted;
  }

  Map<String, dynamic> _extractEmotionalDynamics(ChatAnalysisResult result) {
    final emotional = result.results['emotionalIntelligence']?.data ?? {};
    final content = result.results['content']?.data ?? {};
    final relationship = result.results['relationshipDynamics']?.data ?? {};

    // Safe extraction with type checking
    final empathyData = _safeMap(emotional['empathy']);
    final sentimentData = _safeMap(emotional['sentiment']).isNotEmpty
        ? _safeMap(emotional['sentiment'])
        : _safeMap(content['sentiment']);
    final validationData = _safeMap(emotional['validation']);
    final selfDisclosureData = _safeMap(emotional['selfDisclosure']);
    final volatilityData = _safeMap(emotional['volatility']);
    final reciprocityData = _safeMap(emotional['reciprocity']);

    final extracted = {
      'overallSentiment': sentimentData['overall'] ?? sentimentData['dominantSentiment'] ?? sentimentData['average'],
      'sentimentScore': sentimentData['score'] ?? sentimentData['averageScore'],
      'empathyScore': empathyData['overall'] ?? empathyData['score'] ?? emotional['empathyScore'],
      'emotionalReciprocity': reciprocityData['overall'] ?? reciprocityData['score'] ?? emotional['emotionalReciprocity'],
      'emotionalVolatility': volatilityData['overall'] ?? volatilityData['score'] ?? emotional['emotionalVolatility'],
      'selfDisclosure': selfDisclosureData['overall'] ?? selfDisclosureData['level'] ?? emotional['selfDisclosureScore'],
      'validationRate': validationData['rate'] ?? validationData['overall'] ?? emotional['validationRate'],
      'emotionalTone': relationship['emotionalTone'] ?? relationship['emotionalDynamics'],
    };

    debugPrint('StatsAggregator: Extracted emotional dynamics: $extracted');
    return extracted;
  }

  Map<String, dynamic> _extractRelationshipHealth(ChatAnalysisResult result) {
    final relationship = result.results['relationshipDynamics']?.data ?? {};
    final attachment = result.results['attachmentPatterns']?.data ?? {};
    final behavioral = result.results['behaviorPatterns']?.data ?? {};

    // Safe extraction with type checking
    final supportPatterns = _safeMap(relationship['supportPatterns']);
    final reciprocityPatterns = _safeMap(relationship['reciprocityPatterns']);
    final engagementLevels = _safeMap(relationship['engagementLevels']);
    final relationshipTrend = _safeMap(relationship['relationshipTrend']);
    final bondingData = _safeMap(attachment['bonding']);
    final commitmentData = _safeMap(attachment['commitment']);
    final futureData = _safeMap(attachment['futureOrientation']);

    final extracted = {
      'trend': relationshipTrend['direction'] ?? relationshipTrend['overall'] ?? relationship['relationshipTrend'],
      'healthScore': relationship['relationshipHealthScore'],
      'balanceScore': reciprocityPatterns['balance'] ?? behavioral['compatibilityScore'],
      'engagementLevel': engagementLevels['overall'] ?? engagementLevels['average'],
      'supportScore': supportPatterns['overall'] ?? supportPatterns['score'],
      'bondingLanguageRate': bondingData['rate'] ?? bondingData['score'],
      'futureOrientation': futureData['score'] ?? futureData['level'],
      'commitmentSignals': commitmentData['score'] ?? commitmentData['level'],
      'overallAssessment': relationship['overallAssessment'],
    };

    debugPrint('StatsAggregator: Extracted relationship health: $extracted');
    return extracted;
  }

  Map<String, dynamic> _extractPersonalityInsights(ChatAnalysisResult result) {
    final personality = result.results['personalityTraits']?.data ?? {};

    // Safe extraction with type checking
    final extraversionData = _safeMap(personality['extraversion']);
    final thinkingFeelingData = _safeMap(personality['thinkingFeeling']);
    final judgingPerceivingData = _safeMap(personality['judgingPerceiving']);
    final sensingIntuitionData = _safeMap(personality['sensingIntuition']);
    final opennessData = _safeMap(personality['openness']);
    final conscientiousnessData = _safeMap(personality['conscientiousness']);

    final insights = <String, dynamic>{};

    // Get user names from the trait data
    final userNames = extraversionData.keys.where((k) => k != 'overall' && k != 'score').toSet();

    for (final userName in userNames) {
      insights[userName] = {
        'extraversion': extraversionData[userName],
        'thinkingVsFeeling': thinkingFeelingData[userName],
        'judgingVsPerceiving': judgingPerceivingData[userName],
        'sensingVsIntuition': sensingIntuitionData[userName],
        'openness': opennessData[userName],
        'conscientiousness': conscientiousnessData[userName],
      };
    }

    debugPrint('StatsAggregator: Extracted personality for ${insights.keys.join(", ")}');
    return insights;
  }

  Map<String, dynamic> _extractTemporalPatterns(ChatAnalysisResult result) {
    final temporal = result.results['temporalInsights']?.data ?? {};
    final time = result.results['time']?.data ?? {};

    final hourlyDistribution = time['hourlyDistribution'] as List<dynamic>? ?? [];
    final dailyDistribution = time['dailyDistribution'] as List<dynamic>? ?? [];

    // Find peak hours
    String peakHours = 'N/A';
    if (hourlyDistribution.isNotEmpty) {
      final hourCounts = List<int>.from(hourlyDistribution);
      final maxCount = hourCounts.reduce((a, b) => a > b ? a : b);
      final peakHourIndices = <int>[];
      for (int i = 0; i < hourCounts.length; i++) {
        if (hourCounts[i] == maxCount) {
          peakHourIndices.add(i);
        }
      }
      peakHours = peakHourIndices.map((h) => '${h}:00').join(', ');
    }

    // Find most active day
    String mostActiveDay = 'N/A';
    if (dailyDistribution.isNotEmpty) {
      final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      final dayCounts = List<int>.from(dailyDistribution);
      final maxIndex = dayCounts.indexOf(dayCounts.reduce((a, b) => a > b ? a : b));
      if (maxIndex >= 0 && maxIndex < days.length) {
        mostActiveDay = days[maxIndex];
      }
    }

    return {
      'peakHours': peakHours,
      'mostActiveDay': mostActiveDay,
      'activityTrend': temporal['activityTrend'] ?? temporal['trend'],
      'seasonalPattern': temporal['seasonalPattern'],
      'weekendVsWeekday': temporal['weekendVsWeekday'],
      'responseTimeByHour': temporal['responseTimeByHour'],
    };
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Safely extract a Map from dynamic data, returning empty map if not a Map
  Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    } else if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  /// Strip emojis from username for LLM compatibility
  /// LLMs often corrupt emoji characters in JSON responses
  String _stripEmojis(String text) {
    // Comprehensive emoji regex pattern
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}]|'  // Emoticons
      r'[\u{1F300}-\u{1F5FF}]|'  // Misc Symbols and Pictographs
      r'[\u{1F680}-\u{1F6FF}]|'  // Transport and Map
      r'[\u{1F1E0}-\u{1F1FF}]|'  // Flags
      r'[\u{2600}-\u{26FF}]|'    // Misc symbols
      r'[\u{2700}-\u{27BF}]|'    // Dingbats
      r'[\u{FE00}-\u{FE0F}]|'    // Variation Selectors
      r'[\u{1F900}-\u{1F9FF}]|'  // Supplemental Symbols and Pictographs
      r'[\u{1FA00}-\u{1FA6F}]|'  // Chess Symbols
      r'[\u{1FA70}-\u{1FAFF}]|'  // Symbols and Pictographs Extended-A
      r'[\u{231A}-\u{231B}]|'    // Watch, Hourglass
      r'[\u{23E9}-\u{23F3}]|'    // Various symbols
      r'[\u{23F8}-\u{23FA}]|'    // Various symbols
      r'[\u{25AA}-\u{25AB}]|'    // Squares
      r'[\u{25B6}]|[\u{25C0}]|'  // Play buttons
      r'[\u{25FB}-\u{25FE}]|'    // Squares
      r'[\u{2614}-\u{2615}]|'    // Umbrella, Hot Beverage
      r'[\u{2648}-\u{2653}]|'    // Zodiac
      r'[\u{267F}]|[\u{2693}]|'  // Wheelchair, Anchor
      r'[\u{26A1}]|[\u{26AA}-\u{26AB}]|'  // High Voltage, Circles
      r'[\u{26BD}-\u{26BE}]|'    // Sports
      r'[\u{26C4}-\u{26C5}]|'    // Snowman, Sun
      r'[\u{26CE}]|[\u{26D4}]|'  // Ophiuchus, No Entry
      r'[\u{26EA}]|[\u{26F2}-\u{26F3}]|'  // Church, Fountain
      r'[\u{26F5}]|[\u{26FA}]|'  // Sailboat, Tent
      r'[\u{26FD}]|[\u{2702}]|'  // Fuel, Scissors
      r'[\u{2705}]|[\u{2708}-\u{270D}]|'  // Check, Airplane
      r'[\u{270F}]|[\u{2712}]|'  // Pencil, Pen
      r'[\u{2714}]|[\u{2716}]|'  // Check, X
      r'[\u{271D}]|[\u{2721}]|'  // Cross, Star
      r'[\u{2728}]|[\u{2733}-\u{2734}]|'  // Sparkles
      r'[\u{2744}]|[\u{2747}]|'  // Snowflake, Sparkle
      r'[\u{274C}]|[\u{274E}]|'  // X marks
      r'[\u{2753}-\u{2755}]|'    // Question marks
      r'[\u{2757}]|[\u{2763}-\u{2764}]|'  // Exclamation, Hearts
      r'[\u{2795}-\u{2797}]|'    // Math symbols
      r'[\u{27A1}]|[\u{27B0}]|'  // Arrows
      r'[\u{27BF}]|[\u{2934}-\u{2935}]|'  // Arrows
      r'[\u{2B05}-\u{2B07}]|'    // Arrows
      r'[\u{2B1B}-\u{2B1C}]|'    // Squares
      r'[\u{2B50}]|[\u{2B55}]|'  // Star, Circle
      r'[\u{3030}]|[\u{303D}]|'  // Wavy Dash
      r'[\u{3297}]|[\u{3299}]',  // Japanese symbols
      unicode: true,
    );
    return text.replaceAll(emojiRegex, '').trim();
  }

  String _formatNumber(dynamic value) {
    if (value == null) return 'N/A';
    if (value is int) return value.toString();
    if (value is double) return value.toStringAsFixed(2);
    return value.toString();
  }

  String _formatPercent(dynamic value) {
    if (value == null) return 'N/A';
    final percentage = (value is num) ? value.toDouble() : 0.0;
    return '${(percentage * 100).toStringAsFixed(1)}%';
  }
}

/// Represents structured stats ready for LLM consumption
class AggregatedStats {
  final String chatId;
  final DateTime generatedAt;
  final Map<String, dynamic> overview;
  final Map<String, dynamic> userProfiles;
  final Map<String, dynamic> communicationPatterns;
  final Map<String, dynamic> emotionalDynamics;
  final Map<String, dynamic> relationshipHealth;
  final Map<String, dynamic> personalityInsights;
  final Map<String, dynamic> temporalPatterns;

  AggregatedStats({
    required this.chatId,
    required this.generatedAt,
    required this.overview,
    required this.userProfiles,
    required this.communicationPatterns,
    required this.emotionalDynamics,
    required this.relationshipHealth,
    required this.personalityInsights,
    required this.temporalPatterns,
  });

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'generatedAt': generatedAt.toIso8601String(),
      'overview': overview,
      'userProfiles': userProfiles,
      'communicationPatterns': communicationPatterns,
      'emotionalDynamics': emotionalDynamics,
      'relationshipHealth': relationshipHealth,
      'personalityInsights': personalityInsights,
      'temporalPatterns': temporalPatterns,
    };
  }

  factory AggregatedStats.fromJson(Map<String, dynamic> json) {
    return AggregatedStats(
      chatId: json['chatId'] ?? '',
      generatedAt: DateTime.parse(json['generatedAt'] ?? DateTime.now().toIso8601String()),
      overview: Map<String, dynamic>.from(json['overview'] ?? {}),
      userProfiles: Map<String, dynamic>.from(json['userProfiles'] ?? {}),
      communicationPatterns: Map<String, dynamic>.from(json['communicationPatterns'] ?? {}),
      emotionalDynamics: Map<String, dynamic>.from(json['emotionalDynamics'] ?? {}),
      relationshipHealth: Map<String, dynamic>.from(json['relationshipHealth'] ?? {}),
      personalityInsights: Map<String, dynamic>.from(json['personalityInsights'] ?? {}),
      temporalPatterns: Map<String, dynamic>.from(json['temporalPatterns'] ?? {}),
    );
  }
}
