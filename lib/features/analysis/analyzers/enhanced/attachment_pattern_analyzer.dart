// ============================================================================
// FILE: features/analysis/analyzers/enhanced/attachment_pattern_analyzer.dart
// Attachment Pattern Analyzer - Initiation, re-engagement, commitment signals
// ============================================================================
import 'package:flutter/foundation.dart';
import '../../../../shared/domain.dart';
import '../../analysis_models.dart';
import '../base_analyzer.dart';

class AttachmentPatternAnalyzer implements EnhancedAnalyzer {
  static const int maxAnalysisMessages = 6000;
  static const int conversationGapMinutes = 120; // 2 hours = new conversation

  // Future-oriented language indicating commitment
  static const List<String> _futurePhrases = [
    'tomorrow', 'next week', 'next month', 'next year',
    'we should', 'we could', 'lets plan', "let's plan", 'lets go', "let's go",
    'in the future', 'someday', 'one day', 'soon',
    'cant wait', "can't wait", 'looking forward', 'excited for',
    'going to', 'gonna', 'will be', 'planning to',
    'want to', 'wanna', 'would love to', 'hope to',
    'meet up', 'hang out', 'get together', 'see you',
  ];

  // Commitment words indicating dedication
  static const List<String> _commitmentPhrases = [
    'definitely', 'absolutely', 'always', 'forever', 'promise',
    'for sure', 'no matter what', 'i will', 'ill always',
    'never forget', 'never leave', 'always here', 'always there',
    'committed', 'dedicated', 'loyal', 'faithful',
    'count on me', 'trust me', 'believe me', 'i swear',
    'my word', 'pinky promise', 'cross my heart',
  ];

  // Exclusive/bonding language
  static const List<String> _bondingPhrases = [
    'our', 'we', 'us', 'together',
    'only you', 'just you', 'you and me', 'me and you',
    'best friend', 'bff', 'bestie', 'soulmate',
    'special', 'unique', 'different', 'meant to be',
    'inside joke', 'remember when', 'that time when',
    'our thing', 'our place', 'our song',
    'miss you', 'missed you', 'thinking of you', 'thought of you',
  ];

  // Anxious attachment signals
  static const List<String> _anxiousPhrases = [
    'are you there', 'hello', 'helloooo', 'hellooooo',
    'why arent you', "why aren't you", 'why didnt you', "why didn't you",
    'are you ignoring', 'did i do something', 'are you mad',
    'please respond', 'please reply', 'answer me',
    'worried', 'scared', 'nervous', 'anxious',
    'dont leave', "don't leave", 'please stay', 'dont go', "don't go",
  ];

  @override
  Future<AnalysisResult> analyze(ChatEntity chat) async {
    debugPrint("🔗 AttachmentPatternAnalyzer: Starting analysis");

    try {
      final messagesToProcess = chat.messages.length > maxAnalysisMessages
          ? chat.messages.take(maxAnalysisMessages).toList()
          : chat.messages;

      if (messagesToProcess.isEmpty) {
        return _createEmptyResult();
      }

      final userIdToName = {for (var user in chat.users) user.id: user.name};

      // Analyze attachment patterns
      final initiationAnalysis = _analyzeInitiationPatterns(messagesToProcess, userIdToName);
      final reengagementAnalysis = _analyzeReengagementPatterns(messagesToProcess, userIdToName);
      final futureOrientationAnalysis = _analyzeFutureOrientation(messagesToProcess, userIdToName);
      final commitmentAnalysis = _analyzeCommitmentSignals(messagesToProcess, userIdToName);
      final bondingAnalysis = _analyzeBondingLanguage(messagesToProcess, userIdToName);
      final anxietyAnalysis = _analyzeAttachmentAnxiety(messagesToProcess, userIdToName);
      final availabilityAnalysis = _analyzeAvailabilityPatterns(messagesToProcess, userIdToName);

      final result = {
        'initiation': initiationAnalysis,
        'reengagement': reengagementAnalysis,
        'futureOrientation': futureOrientationAnalysis,
        'commitment': commitmentAnalysis,
        'bonding': bondingAnalysis,
        'anxiety': anxietyAnalysis,
        'availability': availabilityAnalysis,
        'summary': _generateAttachmentSummary(
          initiationAnalysis,
          commitmentAnalysis,
          bondingAnalysis,
          anxietyAnalysis,
        ),
      };

      debugPrint("✅ AttachmentPatternAnalyzer: Analysis complete");

      return AnalysisResult(
        type: 'attachment_patterns',
        data: result,
        confidence: _calculateConfidence(messagesToProcess.length, userIdToName.length),
        generatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      debugPrint("❌ AttachmentPatternAnalyzer: Error - $e");
      debugPrint("Stack trace: $stackTrace");
      return _createErrorResult(e);
    }
  }

  // ========================================================================
  // INITIATION PATTERN ANALYSIS
  // ========================================================================

  Map<String, dynamic> _analyzeInitiationPatterns(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, int> conversationStarts = {};
    final Map<String, int> conversationEnds = {};

    for (final userName in userIdToName.values) {
      conversationStarts[userName] = 0;
      conversationEnds[userName] = 0;
    }

    // Sort messages by timestamp
    final sortedMessages = List<MessageEntity>.from(messages)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    String? lastSender;
    DateTime? lastMessageTime;

    for (int i = 0; i < sortedMessages.length; i++) {
      final message = sortedMessages[i];
      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      // Check if this starts a new conversation
      bool isNewConversation = false;
      if (lastMessageTime == null) {
        isNewConversation = true;
      } else {
        final gap = message.timestamp.difference(lastMessageTime).inMinutes;
        if (gap > conversationGapMinutes) {
          isNewConversation = true;

          // Mark the previous conversation ender
          if (lastSender != null) {
            conversationEnds[lastSender] = (conversationEnds[lastSender] ?? 0) + 1;
          }
        }
      }

      if (isNewConversation) {
        conversationStarts[userName] = (conversationStarts[userName] ?? 0) + 1;
      }

      lastSender = userName;
      lastMessageTime = message.timestamp;
    }

    // Mark the final conversation ender
    if (lastSender != null) {
      conversationEnds[lastSender] = (conversationEnds[lastSender] ?? 0) + 1;
    }

    // Calculate totals and rates
    final totalStarts = conversationStarts.values.fold(0, (a, b) => a + b);

    final Map<String, dynamic> result = {};

    for (final userName in userIdToName.values) {
      final starts = conversationStarts[userName] ?? 0;
      final ends = conversationEnds[userName] ?? 0;

      final startRate = totalStarts > 0 ? starts / totalStarts : 0.0;

      result[userName] = {
        'conversationsStarted': starts,
        'conversationsEnded': ends,
        'initiationRate': double.parse((startRate * 100).toStringAsFixed(1)),
        'role': _categorizeInitiationRole(startRate),
      };
    }

    result['totalConversations'] = totalStarts;

    return result;
  }

  String _categorizeInitiationRole(double rate) {
    if (rate > 0.7) return 'Primary Initiator';
    if (rate > 0.55) return 'Frequent Initiator';
    if (rate > 0.45) return 'Balanced';
    if (rate > 0.3) return 'Occasional Initiator';
    return 'Responder';
  }

  // ========================================================================
  // RE-ENGAGEMENT PATTERN ANALYSIS
  // ========================================================================

  Map<String, dynamic> _analyzeReengagementPatterns(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, List<int>> reengagementGaps = {};

    for (final userName in userIdToName.values) {
      reengagementGaps[userName] = [];
    }

    // Sort messages
    final sortedMessages = List<MessageEntity>.from(messages)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    DateTime? lastMessageTime;
    String? lastSender;

    for (final message in sortedMessages) {
      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      if (lastMessageTime != null && lastSender != null) {
        final gap = message.timestamp.difference(lastMessageTime).inMinutes;

        // If there was a significant gap and this user is re-engaging
        if (gap > 60 && userName != lastSender) {
          // This user re-engaged after silence from the other
          reengagementGaps[userName]!.add(gap);
        }
      }

      lastMessageTime = message.timestamp;
      lastSender = userName;
    }

    // Calculate metrics
    final Map<String, dynamic> result = {};

    for (final entry in reengagementGaps.entries) {
      final userName = entry.key;
      final gaps = entry.value;

      if (gaps.isEmpty) {
        result[userName] = {
          'averageReengagementMinutes': 0,
          'reengagementCount': 0,
          'category': 'No Data',
        };
        continue;
      }

      final avgGap = gaps.reduce((a, b) => a + b) / gaps.length;

      result[userName] = {
        'averageReengagementMinutes': avgGap.round(),
        'reengagementCount': gaps.length,
        'category': _categorizeReengagement(avgGap),
      };
    }

    return result;
  }

  String _categorizeReengagement(double avgMinutes) {
    if (avgMinutes < 120) return 'Quick Re-engager';
    if (avgMinutes < 360) return 'Moderate Re-engager';
    if (avgMinutes < 720) return 'Slow Re-engager';
    return 'Passive Re-engager';
  }

  // ========================================================================
  // FUTURE ORIENTATION ANALYSIS
  // ========================================================================

  Map<String, dynamic> _analyzeFutureOrientation(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, dynamic>> userFuture = {};

    for (final userName in userIdToName.values) {
      userFuture[userName] = {
        'totalMessages': 0,
        'futureCount': 0,
        'futurePhrases': <String>[],
      };
    }

    for (final message in messages) {
      if (message.type != MessageType.text || message.content.isEmpty) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final content = message.content.toLowerCase();
      final data = userFuture[userName]!;

      data['totalMessages'] = (data['totalMessages'] as int) + 1;

      for (final phrase in _futurePhrases) {
        if (content.contains(phrase)) {
          data['futureCount'] = (data['futureCount'] as int) + 1;
          final phrases = data['futurePhrases'] as List<String>;
          if (!phrases.contains(phrase) && phrases.length < 5) {
            phrases.add(phrase);
          }
          break;
        }
      }
    }

    // Calculate scores
    final Map<String, dynamic> result = {};

    for (final entry in userFuture.entries) {
      final userName = entry.key;
      final data = entry.value;

      final totalMessages = data['totalMessages'] as int;
      final futureCount = data['futureCount'] as int;

      if (totalMessages == 0) {
        result[userName] = {
          'score': 0,
          'rate': 0.0,
          'category': 'No Data',
          'topPhrases': <String>[],
        };
        continue;
      }

      final futureRate = futureCount / totalMessages;
      final score = (futureRate * 100).clamp(0.0, 100.0);

      result[userName] = {
        'score': score.round(),
        'rate': double.parse((futureRate * 100).toStringAsFixed(1)),
        'category': _categorizeFutureOrientation(futureRate),
        'topPhrases': data['futurePhrases'],
      };
    }

    return result;
  }

  String _categorizeFutureOrientation(double rate) {
    if (rate > 0.10) return 'Highly Future-Oriented';
    if (rate > 0.05) return 'Future-Oriented';
    if (rate > 0.02) return 'Moderate Planner';
    if (rate > 0.01) return 'Occasional Planner';
    return 'Present-Focused';
  }

  // ========================================================================
  // COMMITMENT SIGNAL ANALYSIS
  // ========================================================================

  Map<String, dynamic> _analyzeCommitmentSignals(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, dynamic>> userCommitment = {};

    for (final userName in userIdToName.values) {
      userCommitment[userName] = {
        'totalMessages': 0,
        'commitmentCount': 0,
      };
    }

    for (final message in messages) {
      if (message.type != MessageType.text || message.content.isEmpty) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final content = message.content.toLowerCase();
      final data = userCommitment[userName]!;

      data['totalMessages'] = (data['totalMessages'] as int) + 1;

      for (final phrase in _commitmentPhrases) {
        if (content.contains(phrase)) {
          data['commitmentCount'] = (data['commitmentCount'] as int) + 1;
          break;
        }
      }
    }

    // Calculate scores
    final Map<String, dynamic> result = {};

    for (final entry in userCommitment.entries) {
      final userName = entry.key;
      final data = entry.value;

      final totalMessages = data['totalMessages'] as int;
      final commitmentCount = data['commitmentCount'] as int;

      if (totalMessages == 0) {
        result[userName] = {
          'score': 0,
          'rate': 0.0,
          'category': 'No Data',
        };
        continue;
      }

      final commitmentRate = commitmentCount / totalMessages;
      final score = (commitmentRate * 100).clamp(0.0, 100.0);

      result[userName] = {
        'score': score.round(),
        'rate': double.parse((commitmentRate * 100).toStringAsFixed(1)),
        'category': _categorizeCommitment(commitmentRate),
      };
    }

    return result;
  }

  String _categorizeCommitment(double rate) {
    if (rate > 0.08) return 'Highly Committed';
    if (rate > 0.04) return 'Committed';
    if (rate > 0.02) return 'Moderately Committed';
    if (rate > 0.01) return 'Casual';
    return 'Reserved';
  }

  // ========================================================================
  // BONDING LANGUAGE ANALYSIS
  // ========================================================================

  Map<String, dynamic> _analyzeBondingLanguage(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, dynamic>> userBonding = {};

    for (final userName in userIdToName.values) {
      userBonding[userName] = {
        'totalMessages': 0,
        'bondingCount': 0,
        'weUsCount': 0, // "we" and "us" usage
      };
    }

    final weUsPattern = RegExp(r'\b(we|us|our|ours)\b', caseSensitive: false);

    for (final message in messages) {
      if (message.type != MessageType.text || message.content.isEmpty) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final content = message.content.toLowerCase();
      final data = userBonding[userName]!;

      data['totalMessages'] = (data['totalMessages'] as int) + 1;

      // Count "we/us/our" usage
      final weUsMatches = weUsPattern.allMatches(content);
      data['weUsCount'] = (data['weUsCount'] as int) + weUsMatches.length;

      // Check bonding phrases
      for (final phrase in _bondingPhrases) {
        if (content.contains(phrase)) {
          data['bondingCount'] = (data['bondingCount'] as int) + 1;
          break;
        }
      }
    }

    // Calculate scores
    final Map<String, dynamic> result = {};

    for (final entry in userBonding.entries) {
      final userName = entry.key;
      final data = entry.value;

      final totalMessages = data['totalMessages'] as int;
      final bondingCount = data['bondingCount'] as int;
      final weUsCount = data['weUsCount'] as int;

      if (totalMessages == 0) {
        result[userName] = {
          'score': 0,
          'bondingRate': 0.0,
          'weUsRate': 0.0,
          'category': 'No Data',
        };
        continue;
      }

      final bondingRate = bondingCount / totalMessages;
      final weUsRate = weUsCount / totalMessages;
      final combinedScore = ((bondingRate * 50) + (weUsRate * 10)).clamp(0.0, 100.0);

      result[userName] = {
        'score': combinedScore.round(),
        'bondingRate': double.parse((bondingRate * 100).toStringAsFixed(1)),
        'weUsRate': double.parse((weUsRate * 100).toStringAsFixed(1)),
        'category': _categorizeBonding(combinedScore),
      };
    }

    return result;
  }

  String _categorizeBonding(double score) {
    if (score > 30) return 'Strongly Bonded';
    if (score > 15) return 'Well Bonded';
    if (score > 8) return 'Moderately Bonded';
    if (score > 3) return 'Developing Bond';
    return 'Independent';
  }

  // ========================================================================
  // ATTACHMENT ANXIETY ANALYSIS
  // ========================================================================

  Map<String, dynamic> _analyzeAttachmentAnxiety(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, dynamic>> userAnxiety = {};

    for (final userName in userIdToName.values) {
      userAnxiety[userName] = {
        'totalMessages': 0,
        'anxietyCount': 0,
        'doubleTextCount': 0, // Sending multiple messages without response
      };
    }

    // Sort messages
    final sortedMessages = List<MessageEntity>.from(messages)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    String? lastSender;
    int consecutiveCount = 0;

    for (final message in sortedMessages) {
      if (message.type != MessageType.text) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final content = message.content.toLowerCase();
      final data = userAnxiety[userName]!;

      data['totalMessages'] = (data['totalMessages'] as int) + 1;

      // Check for anxious phrases
      for (final phrase in _anxiousPhrases) {
        if (content.contains(phrase)) {
          data['anxietyCount'] = (data['anxietyCount'] as int) + 1;
          break;
        }
      }

      // Track consecutive messages (double/triple texting)
      if (userName == lastSender) {
        consecutiveCount++;
        if (consecutiveCount >= 3) {
          data['doubleTextCount'] = (data['doubleTextCount'] as int) + 1;
        }
      } else {
        consecutiveCount = 1;
      }

      lastSender = userName;
    }

    // Calculate scores
    final Map<String, dynamic> result = {};

    for (final entry in userAnxiety.entries) {
      final userName = entry.key;
      final data = entry.value;

      final totalMessages = data['totalMessages'] as int;
      final anxietyCount = data['anxietyCount'] as int;
      final doubleTextCount = data['doubleTextCount'] as int;

      if (totalMessages == 0) {
        result[userName] = {
          'score': 0,
          'anxietyRate': 0.0,
          'doubleTextRate': 0.0,
          'category': 'No Data',
        };
        continue;
      }

      final anxietyRate = anxietyCount / totalMessages;
      final doubleTextRate = doubleTextCount / totalMessages;
      final combinedScore = ((anxietyRate * 60) + (doubleTextRate * 40)).clamp(0.0, 100.0);

      result[userName] = {
        'score': combinedScore.round(),
        'anxietyRate': double.parse((anxietyRate * 100).toStringAsFixed(1)),
        'doubleTextRate': double.parse((doubleTextRate * 100).toStringAsFixed(1)),
        'category': _categorizeAnxiety(combinedScore),
      };
    }

    return result;
  }

  String _categorizeAnxiety(double score) {
    if (score > 15) return 'Anxious Attachment';
    if (score > 8) return 'Slightly Anxious';
    if (score > 3) return 'Normal';
    return 'Secure';
  }

  // ========================================================================
  // AVAILABILITY PATTERNS
  // ========================================================================

  Map<String, dynamic> _analyzeAvailabilityPatterns(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, dynamic>> userAvailability = {};

    for (final userName in userIdToName.values) {
      userAvailability[userName] = {
        'responseTimes': <int>[],
        'totalResponses': 0,
      };
    }

    // Sort messages
    final sortedMessages = List<MessageEntity>.from(messages)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (int i = 1; i < sortedMessages.length; i++) {
      final current = sortedMessages[i];
      final previous = sortedMessages[i - 1];

      if (current.senderId == previous.senderId) continue;

      final userName = userIdToName[current.senderId];
      if (userName == null) continue;

      final responseTime = current.timestamp.difference(previous.timestamp).inMinutes;

      // Only count responses within 24 hours
      if (responseTime > 0 && responseTime < 1440) {
        final data = userAvailability[userName]!;
        (data['responseTimes'] as List<int>).add(responseTime);
        data['totalResponses'] = (data['totalResponses'] as int) + 1;
      }
    }

    // Calculate metrics
    final Map<String, dynamic> result = {};

    for (final entry in userAvailability.entries) {
      final userName = entry.key;
      final data = entry.value;

      final responseTimes = data['responseTimes'] as List<int>;
      final totalResponses = data['totalResponses'] as int;

      if (responseTimes.isEmpty) {
        result[userName] = {
          'averageResponseMinutes': 0,
          'medianResponseMinutes': 0,
          'responseCount': 0,
          'category': 'No Data',
        };
        continue;
      }

      final avgResponse = responseTimes.reduce((a, b) => a + b) / responseTimes.length;
      responseTimes.sort();
      final medianResponse = responseTimes[responseTimes.length ~/ 2];

      result[userName] = {
        'averageResponseMinutes': avgResponse.round(),
        'medianResponseMinutes': medianResponse,
        'responseCount': totalResponses,
        'category': _categorizeAvailability(avgResponse),
      };
    }

    return result;
  }

  String _categorizeAvailability(double avgMinutes) {
    if (avgMinutes < 5) return 'Highly Available';
    if (avgMinutes < 30) return 'Very Available';
    if (avgMinutes < 120) return 'Available';
    if (avgMinutes < 360) return 'Moderately Available';
    return 'Less Available';
  }

  // ========================================================================
  // SUMMARY GENERATION
  // ========================================================================

  Map<String, dynamic> _generateAttachmentSummary(
    Map<String, dynamic> initiation,
    Map<String, dynamic> commitment,
    Map<String, dynamic> bonding,
    Map<String, dynamic> anxiety,
  ) {
    final summary = <String, dynamic>{};

    for (final userName in initiation.keys) {
      if (userName == 'totalConversations') continue;

      final initiationData = initiation[userName] as Map<String, dynamic>?;
      final commitmentData = commitment[userName] as Map<String, dynamic>?;
      final bondingData = bonding[userName] as Map<String, dynamic>?;
      final anxietyData = anxiety[userName] as Map<String, dynamic>?;

      final initiationRate = initiationData?['initiationRate'] as double? ?? 0.0;
      final commitmentScore = commitmentData?['score'] as int? ?? 0;
      final bondingScore = bondingData?['score'] as int? ?? 0;
      final anxietyScore = anxietyData?['score'] as int? ?? 0;

      // Determine attachment style
      String attachmentStyle;
      if (anxietyScore > 10) {
        attachmentStyle = 'Anxious';
      } else if (initiationRate < 30 && bondingScore < 10) {
        attachmentStyle = 'Avoidant';
      } else if (bondingScore > 20 && commitmentScore > 3) {
        attachmentStyle = 'Secure';
      } else {
        attachmentStyle = 'Balanced';
      }

      // Calculate overall investment score
      final investmentScore = ((initiationRate * 0.3) + (commitmentScore * 0.4) + (bondingScore * 0.3)).round();

      summary[userName] = {
        'attachmentStyle': attachmentStyle,
        'investmentScore': investmentScore,
        'role': initiationData?['role'] ?? 'Unknown',
        'bondingLevel': bondingData?['category'] ?? 'Unknown',
      };
    }

    return summary;
  }

  // ========================================================================
  // HELPER METHODS
  // ========================================================================

  double _calculateConfidence(int messageCount, int userCount) {
    if (messageCount < 100 || userCount < 2) return 0.3;
    if (messageCount < 500) return 0.5;
    if (messageCount < 1000) return 0.7;
    if (messageCount < 2000) return 0.85;
    return 0.95;
  }

  AnalysisResult _createEmptyResult() {
    return AnalysisResult(
      type: 'attachment_patterns',
      data: {
        'initiation': <String, dynamic>{},
        'reengagement': <String, dynamic>{},
        'futureOrientation': <String, dynamic>{},
        'commitment': <String, dynamic>{},
        'bonding': <String, dynamic>{},
        'anxiety': <String, dynamic>{},
        'availability': <String, dynamic>{},
        'summary': <String, dynamic>{},
      },
      confidence: 0.0,
      generatedAt: DateTime.now(),
    );
  }

  AnalysisResult _createErrorResult(Object error) {
    return AnalysisResult(
      type: 'attachment_patterns',
      data: {
        'error': error.toString(),
        'initiation': <String, dynamic>{},
        'reengagement': <String, dynamic>{},
        'futureOrientation': <String, dynamic>{},
        'commitment': <String, dynamic>{},
        'bonding': <String, dynamic>{},
        'anxiety': <String, dynamic>{},
        'availability': <String, dynamic>{},
        'summary': <String, dynamic>{},
      },
      confidence: 0.0,
      generatedAt: DateTime.now(),
    );
  }
}
