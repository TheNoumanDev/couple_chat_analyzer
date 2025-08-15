// ============================================================================
// FILE: features/analysis/analyzers/enhanced/conversation_dynamics_analyzer.dart
// Conversation Dynamics Analyzer - Reveals conversation flow patterns
// ============================================================================
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../../../shared/domain.dart';
import '../../analysis_models.dart';
import '../base_analyzer.dart';

class ConversationDynamicsAnalyzer implements BaseAnalyzer {
  static const int conversationGapMinutes = 30; // Gap that defines new conversation
  static const int rapidFireSeconds = 10; // Quick response threshold
  static const int maxAnalysisMessages = 10000; // Limit for performance

  @override
  Future<AnalysisResult> analyze(ChatEntity chat) async {
    debugPrint("🗣️ ConversationDynamicsAnalyzer: Starting analysis");

    try {
      // Limit messages for performance
      final messagesToProcess = chat.messages.length > maxAnalysisMessages
          ? chat.messages.take(maxAnalysisMessages).toList()
          : chat.messages;

      if (messagesToProcess.isEmpty) {
        return _createEmptyResult();
      }

      final userIdToName = {for (var user in chat.users) user.id: user.name};
      
      // Group messages into conversations
      final conversations = _groupMessagesIntoConversations(messagesToProcess);
      debugPrint("📊 Found ${conversations.length} conversations");

      // Analyze different aspects of conversation dynamics
      final initiationPatterns = _analyzeInitiationPatterns(conversations, userIdToName);
      final flowPatterns = _analyzeConversationFlow(conversations, userIdToName);
      final responsePatterns = _analyzeResponsePatterns(messagesToProcess, userIdToName);
      final healthScore = _calculateConversationHealthScore(conversations, userIdToName);

      final result = {
        'totalConversations': conversations.length,
        'averageConversationLength': _calculateAverageConversationLength(conversations),
        'conversationHealthScore': healthScore,
        'initiationPatterns': initiationPatterns,
        'flowPatterns': flowPatterns,
        'responsePatterns': responsePatterns,
        'conversationStats': _getConversationStatistics(conversations),
      };

      debugPrint("✅ ConversationDynamicsAnalyzer: Analysis complete");

      return AnalysisResult(
        type: 'conversation_dynamics',
        data: result,
        confidence: _calculateConfidence(conversations.length, messagesToProcess.length),
        generatedAt: DateTime.now(),
      );

    } catch (e, stackTrace) {
      debugPrint("❌ ConversationDynamicsAnalyzer: Error - $e");
      debugPrint("Stack trace: $stackTrace");
      return _createErrorResult(e);
    }
  }

  // ========================================================================
  // CONVERSATION GROUPING
  // ========================================================================

  /// Group messages into separate conversations based on time gaps
  List<List<MessageEntity>> _groupMessagesIntoConversations(List<MessageEntity> messages) {
    final conversations = <List<MessageEntity>>[];
    
    if (messages.isEmpty) return conversations;

    // Sort messages by timestamp
    final sortedMessages = [...messages]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    List<MessageEntity> currentConversation = [];

    for (int i = 0; i < sortedMessages.length; i++) {
      if (currentConversation.isEmpty) {
        currentConversation = [sortedMessages[i]];
      } else {
        final timeDiff = sortedMessages[i]
            .timestamp
            .difference(currentConversation.last.timestamp);

        if (timeDiff.inMinutes > conversationGapMinutes) {
          // End current conversation, start new one
          if (currentConversation.isNotEmpty) {
            conversations.add(List.from(currentConversation));
          }
          currentConversation = [sortedMessages[i]];
        } else {
          currentConversation.add(sortedMessages[i]);
        }
      }
    }

    // Add the last conversation
    if (currentConversation.isNotEmpty) {
      conversations.add(currentConversation);
    }

    return conversations;
  }

  // ========================================================================
  // INITIATION PATTERN ANALYSIS
  // ========================================================================

  /// Analyze who initiates and ends conversations
  Map<String, dynamic> _analyzeInitiationPatterns(
    List<List<MessageEntity>> conversations,
    Map<String, String> userIdToName,
  ) {
    final Map<String, int> initiators = {};
    final Map<String, int> enders = {};
    final Map<String, int> conversationCounts = {};

    for (final conversation in conversations) {
      if (conversation.isNotEmpty) {
        // First message = conversation initiator
        final firstSender = conversation.first.senderId;
        final initiatorName = userIdToName[firstSender] ?? 'Unknown';
        initiators[initiatorName] = (initiators[initiatorName] ?? 0) + 1;

        // Last message = conversation ender
        final lastSender = conversation.last.senderId;
        final enderName = userIdToName[lastSender] ?? 'Unknown';
        enders[enderName] = (enders[enderName] ?? 0) + 1;

        // Count total conversations per user
        for (final message in conversation) {
          final userName = userIdToName[message.senderId] ?? 'Unknown';
          conversationCounts[userName] = (conversationCounts[userName] ?? 0) + 1;
        }
      }
    }

    // Calculate initiation and ending rates
    final Map<String, Map<String, dynamic>> userPatterns = {};
    
    for (final userName in userIdToName.values) {
      final totalConversations = conversationCounts[userName] ?? 0;
      final initiations = initiators[userName] ?? 0;
      final endings = enders[userName] ?? 0;

      if (totalConversations > 0) {
        userPatterns[userName] = {
          'initiationCount': initiations,
          'endingCount': endings,
          'initiationRate': (initiations / conversations.length * 100).round(),
          'endingRate': (endings / conversations.length * 100).round(),
          'conversationParticipation': totalConversations,
        };
      }
    }

    return {
      'userPatterns': userPatterns,
      'totalConversations': conversations.length,
      'mostActiveInitiator': _findMostActive(initiators),
      'mostActiveEnder': _findMostActive(enders),
    };
  }

  // ========================================================================
  // CONVERSATION FLOW ANALYSIS
  // ========================================================================

  /// Analyze conversation flow patterns
  Map<String, dynamic> _analyzeConversationFlow(
    List<List<MessageEntity>> conversations,
    Map<String, String> userIdToName,
  ) {
    int rapidFireConversations = 0;
    int balancedConversations = 0;
    int monologueConversations = 0;
    final Map<String, int> flowTypes = {};

    for (final conversation in conversations) {
      if (conversation.length < 2) continue;

      final flowType = _analyzeIndividualConversationFlow(conversation, userIdToName);
      flowTypes[flowType] = (flowTypes[flowType] ?? 0) + 1;

      // Categorize conversation types
      switch (flowType) {
        case 'rapid_exchange':
          rapidFireConversations++;
          break;
        case 'balanced_dialogue':
          balancedConversations++;
          break;
        case 'monologue':
          monologueConversations++;
          break;
      }
    }

    return {
      'rapidFireConversations': rapidFireConversations,
      'balancedConversations': balancedConversations,
      'monologueConversations': monologueConversations,
      'flowTypeDistribution': flowTypes,
      'totalAnalyzed': conversations.length,
    };
  }

  /// Analyze flow pattern of individual conversation
  String _analyzeIndividualConversationFlow(
    List<MessageEntity> conversation,
    Map<String, String> userIdToName,
  ) {
    if (conversation.length < 2) return 'single_message';

    // Analyze sender diversity
    final senders = conversation.map((m) => m.senderId).toSet();
    if (senders.length == 1) return 'monologue';

    // Analyze response times
    final responseTimes = <Duration>[];
    for (int i = 1; i < conversation.length; i++) {
      if (conversation[i].senderId != conversation[i - 1].senderId) {
        final responseTime = conversation[i].timestamp
            .difference(conversation[i - 1].timestamp);
        responseTimes.add(responseTime);
      }
    }

    if (responseTimes.isNotEmpty) {
      final avgResponseTime = responseTimes
          .map((d) => d.inSeconds)
          .reduce((a, b) => a + b) / responseTimes.length;

      if (avgResponseTime < rapidFireSeconds) {
        return 'rapid_exchange';
      }
    }

    // Check balance between participants
    final senderCounts = <String, int>{};
    for (final message in conversation) {
      senderCounts[message.senderId] = (senderCounts[message.senderId] ?? 0) + 1;
    }

    final counts = senderCounts.values.toList()..sort();
    if (counts.length >= 2) {
      final balance = counts.first / counts.last;
      if (balance > 0.3) { // Relatively balanced
        return 'balanced_dialogue';
      }
    }

    return 'uneven_dialogue';
  }

  // ========================================================================
  // RESPONSE PATTERN ANALYSIS
  // ========================================================================

  /// Analyze response patterns between users
  Map<String, dynamic> _analyzeResponsePatterns(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, List<Duration>> userResponseTimes = {};
    final Map<String, int> responsesCounts = {};

    for (int i = 1; i < messages.length; i++) {
      final currentMsg = messages[i];
      final previousMsg = messages[i - 1];

      // Skip if same sender
      if (currentMsg.senderId == previousMsg.senderId) continue;

      final responderName = userIdToName[currentMsg.senderId] ?? 'Unknown';
      final responseTime = currentMsg.timestamp.difference(previousMsg.timestamp);

      // Only count reasonable response times (within 24 hours)
      if (responseTime.inHours <= 24) {
        userResponseTimes.putIfAbsent(responderName, () => []);
        userResponseTimes[responderName]!.add(responseTime);
        responsesCounts[responderName] = (responsesCounts[responderName] ?? 0) + 1;
      }
    }

    // Calculate response statistics for each user
    final Map<String, Map<String, dynamic>> responseStats = {};
    
    for (final entry in userResponseTimes.entries) {
      final userName = entry.key;
      final times = entry.value;
      
      if (times.isEmpty) continue;

      final avgResponseTime = times
          .map((d) => d.inSeconds)
          .reduce((a, b) => a + b) / times.length;

      final fastestResponse = times.reduce((a, b) => a < b ? a : b);
      final slowestResponse = times.reduce((a, b) => a > b ? a : b);

      responseStats[userName] = {
        'averageResponseTimeSeconds': avgResponseTime.round(),
        'fastestResponseSeconds': fastestResponse.inSeconds,
        'slowestResponseSeconds': slowestResponse.inSeconds,
        'totalResponses': times.length,
        'responseSpeedCategory': _categorizeResponseSpeed(avgResponseTime),
      };
    }

    return responseStats;
  }

  // ========================================================================
  // HEALTH SCORE CALCULATION
  // ========================================================================

  /// Calculate overall conversation health score
  double _calculateConversationHealthScore(
    List<List<MessageEntity>> conversations,
    Map<String, String> userIdToName,
  ) {
    if (conversations.isEmpty) return 0.0;

    double totalScore = 0.0;
    int validConversations = 0;

    for (final conversation in conversations.take(100)) { // Limit for performance
      final score = _calculateIndividualConversationHealth(conversation, userIdToName);
      if (score > 0) {
        totalScore += score;
        validConversations++;
      }
    }

    return validConversations > 0 ? totalScore / validConversations : 0.0;
  }

  /// Calculate health score for individual conversation
  double _calculateIndividualConversationHealth(
    List<MessageEntity> conversation,
    Map<String, String> userIdToName,
  ) {
    if (conversation.length < 2) return 0.0;

    double score = 50.0; // Base score

    // Factor 1: Participant balance
    final senderCounts = <String, int>{};
    for (final message in conversation) {
      senderCounts[message.senderId] = (senderCounts[message.senderId] ?? 0) + 1;
    }

    if (senderCounts.length > 1) {
      final counts = senderCounts.values.toList();
      final maxCount = counts.reduce(math.max);
      final minCount = counts.reduce(math.min);
      final balance = minCount / maxCount;
      score += balance * 30; // Up to 30 points for balance
    }

    // Factor 2: Conversation length (engagement)
    if (conversation.length > 5) score += 10;
    if (conversation.length > 10) score += 10;

    // Factor 3: Response timing
    final responseTimes = <Duration>[];
    for (int i = 1; i < conversation.length; i++) {
      if (conversation[i].senderId != conversation[i - 1].senderId) {
        responseTimes.add(conversation[i].timestamp
            .difference(conversation[i - 1].timestamp));
      }
    }

    if (responseTimes.isNotEmpty) {
      final avgResponseMinutes = responseTimes
          .map((d) => d.inMinutes)
          .reduce((a, b) => a + b) / responseTimes.length;

      if (avgResponseMinutes < 60) score += 10; // Quick responses
    }

    return math.min(100.0, score);
  }

  // ========================================================================
  // HELPER METHODS
  // ========================================================================

  /// Calculate average conversation length
  double _calculateAverageConversationLength(List<List<MessageEntity>> conversations) {
    if (conversations.isEmpty) return 0.0;
    
    final totalMessages = conversations
        .map((conv) => conv.length)
        .reduce((a, b) => a + b);
    
    return totalMessages / conversations.length;
  }

  /// Get conversation statistics
  Map<String, dynamic> _getConversationStatistics(List<List<MessageEntity>> conversations) {
    if (conversations.isEmpty) {
      return {
        'shortest': 0,
        'longest': 0,
        'median': 0,
        'totalMessages': 0,
      };
    }

    final lengths = conversations.map((conv) => conv.length).toList()..sort();
    
    return {
      'shortest': lengths.first,
      'longest': lengths.last,
      'median': lengths[lengths.length ~/ 2],
      'totalMessages': lengths.reduce((a, b) => a + b),
    };
  }

  /// Find most active user from a count map
  String? _findMostActive(Map<String, int> counts) {
    if (counts.isEmpty) return null;
    
    return counts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Categorize response speed
  String _categorizeResponseSpeed(double avgResponseTimeSeconds) {
    if (avgResponseTimeSeconds < 60) return 'Lightning Fast ⚡';
    if (avgResponseTimeSeconds < 300) return 'Very Quick 🏃';
    if (avgResponseTimeSeconds < 1800) return 'Quick 💬';
    if (avgResponseTimeSeconds < 3600) return 'Moderate ⏰';
    if (avgResponseTimeSeconds < 14400) return 'Slow 🐌';
    return 'Very Slow 🦥';
  }

  /// Calculate confidence score based on data quality
  double _calculateConfidence(int conversationCount, int messageCount) {
    if (messageCount < 10) return 0.1;
    if (messageCount < 50) return 0.3;
    if (messageCount < 100) return 0.5;
    if (conversationCount < 5) return 0.6;
    if (conversationCount < 20) return 0.8;
    return 0.95;
  }

  /// Create empty result for when no data is available
  AnalysisResult _createEmptyResult() {
    return AnalysisResult(
      type: 'conversation_dynamics',
      data: {
        'totalConversations': 0,
        'averageConversationLength': 0.0,
        'conversationHealthScore': 0.0,
        'message': 'No conversations found to analyze',
      },
      confidence: 0.0,
      generatedAt: DateTime.now(),
    );
  }

  /// Create error result
  AnalysisResult _createErrorResult(dynamic error) {
    return AnalysisResult(
      type: 'conversation_dynamics',
      data: {
        'error': true,
        'message': 'Analysis failed: ${error.toString()}',
        'totalConversations': 0,
        'conversationHealthScore': 0.0,
      },
      confidence: 0.0,
      generatedAt: DateTime.now(),
    );
  }
}