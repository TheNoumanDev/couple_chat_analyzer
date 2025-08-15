// ============================================================================
// FILE: features/analysis/analyzers/enhanced/relationship_analyzer.dart
// Relationship Analyzer - Analyzes relationship dynamics and health
// ============================================================================
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../../../shared/domain.dart';
import '../../analysis_models.dart';
import '../base_analyzer.dart';

class RelationshipAnalyzer implements BaseAnalyzer {
  static const int maxAnalysisMessages = 6000; // Limit for performance

  @override
  Future<AnalysisResult> analyze(ChatEntity chat) async {
    debugPrint("💕 RelationshipAnalyzer: Starting analysis");

    try {
      // Limit messages for performance
      final messagesToProcess = chat.messages.length > maxAnalysisMessages
          ? chat.messages.take(maxAnalysisMessages).toList()
          : chat.messages;

      if (messagesToProcess.isEmpty || chat.users.length < 2) {
        return _createEmptyResult('Insufficient data for relationship analysis');
      }

      final userIdToName = {for (var user in chat.users) user.id: user.name};

      // Analyze different relationship aspects
      final healthScore = _calculateRelationshipHealthScore(messagesToProcess, userIdToName);
      final supportPatterns = _analyzeSupportPatterns(messagesToProcess, userIdToName);
      final reciprocityPatterns = _analyzeReciprocityPatterns(messagesToProcess, userIdToName);
      final emotionalDynamics = _analyzeEmotionalDynamics(messagesToProcess, userIdToName);
      final engagementLevels = _analyzeEngagementLevels(messagesToProcess, userIdToName);
      final conflictPatterns = _analyzeConflictPatterns(messagesToProcess, userIdToName);
      final relationshipTrend = _analyzeRelationshipTrend(messagesToProcess, userIdToName);

      final result = {
        'relationshipHealthScore': healthScore,
        'supportPatterns': supportPatterns,
        'reciprocityPatterns': reciprocityPatterns,
        'emotionalDynamics': emotionalDynamics,
        'engagementLevels': engagementLevels,
        'conflictPatterns': conflictPatterns,
        'relationshipTrend': relationshipTrend,
        'overallAssessment': _generateOverallAssessment(healthScore, supportPatterns, reciprocityPatterns),
      };

      debugPrint("✅ RelationshipAnalyzer: Analysis complete");

      return AnalysisResult(
        type: 'relationship_dynamics',
        data: result,
        confidence: _calculateConfidence(messagesToProcess.length, chat.users.length),
        generatedAt: DateTime.now(),
      );

    } catch (e, stackTrace) {
      debugPrint("❌ RelationshipAnalyzer: Error - $e");
      debugPrint("Stack trace: $stackTrace");
      return _createErrorResult(e);
    }
  }

  // ========================================================================
  // RELATIONSHIP HEALTH SCORE
  // ========================================================================

  /// Calculate overall relationship health score (0-100)
  double _calculateRelationshipHealthScore(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    if (messages.length < 50) return 0.0;

    double healthScore = 50.0; // Base score

    try {
      // Factor 1: Message balance between users (30% weight)
      final balanceScore = _calculateMessageBalance(messages, userIdToName);
      healthScore += (balanceScore - 50) * 0.3;

      // Factor 2: Response patterns (25% weight)
      final responseScore = _calculateResponseHealthScore(messages, userIdToName);
      healthScore += (responseScore - 50) * 0.25;

      // Factor 3: Emotional positivity (25% weight)
      final emotionalScore = _calculateEmotionalHealthScore(messages, userIdToName);
      healthScore += (emotionalScore - 50) * 0.25;

      // Factor 4: Engagement consistency (20% weight)
      final engagementScore = _calculateEngagementHealthScore(messages, userIdToName);
      healthScore += (engagementScore - 50) * 0.2;

      return healthScore.clamp(0.0, 100.0);

    } catch (e) {
      debugPrint("Error calculating relationship health: $e");
      return 0.0;
    }
  }

  /// Calculate message balance score
  double _calculateMessageBalance(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final userMessageCounts = <String, int>{};

    for (final message in messages.take(1000)) { // Limit for performance
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      userMessageCounts[userName] = (userMessageCounts[userName] ?? 0) + 1;
    }

    if (userMessageCounts.length < 2) return 0.0;

    final values = userMessageCounts.values.toList();
    final maxMessages = values.reduce(math.max);
    final minMessages = values.reduce(math.min);

    final balance = minMessages / maxMessages;
    return (balance * 100).clamp(0.0, 100.0);
  }

  /// Calculate response health score
  double _calculateResponseHealthScore(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    int totalResponses = 0;
    int quickResponses = 0;
    int mutualResponses = 0;

    for (int i = 1; i < messages.length; i++) {
      final currentMsg = messages[i];
      final previousMsg = messages[i - 1];

      if (currentMsg.senderId != previousMsg.senderId) {
        totalResponses++;
        
        final responseTime = currentMsg.timestamp.difference(previousMsg.timestamp);
        if (responseTime.inHours < 2) {
          quickResponses++;
        }

        // Check for mutual engagement (both users responding to each other)
        if (i > 1 && messages[i - 2].senderId == currentMsg.senderId) {
          mutualResponses++;
        }
      }
    }

    if (totalResponses == 0) return 0.0;

    final quickResponseRate = quickResponses / totalResponses;
    final mutualEngagementRate = mutualResponses / totalResponses;

    return ((quickResponseRate * 50) + (mutualEngagementRate * 50)).clamp(0.0, 100.0);
  }

  /// Calculate emotional health score
  double _calculateEmotionalHealthScore(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    int positiveMessages = 0;
    int negativeMessages = 0;
    int totalAnalyzed = 0;

    final positiveWords = ['love', 'happy', 'great', 'awesome', 'good', 'nice', 'thanks', 'lol', 'haha'];
    final negativeWords = ['sad', 'bad', 'terrible', 'awful', 'hate', 'angry', 'mad', 'upset'];

    for (final message in messages.take(1000)) { // Limit for performance
      final content = message.content.toLowerCase();
      bool hasPositive = positiveWords.any((word) => content.contains(word));
      bool hasNegative = negativeWords.any((word) => content.contains(word));

      if (hasPositive || hasNegative) {
        totalAnalyzed++;
        if (hasPositive && !hasNegative) {
          positiveMessages++;
        } else if (hasNegative && !hasPositive) {
          negativeMessages++;
        }
      }
    }

    if (totalAnalyzed == 0) return 50.0; // Neutral if no emotional indicators

    final positivityRate = positiveMessages / totalAnalyzed;
    return (positivityRate * 100).clamp(0.0, 100.0);
  }

  /// Calculate engagement health score
  num _calculateEngagementHealthScore(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    // Analyze engagement over time periods
    final timeSpan = messages.last.timestamp.difference(messages.first.timestamp);
    if (timeSpan.inDays < 7) return 50.0; // Not enough time to analyze trends

    final weeklyEngagement = <int, int>{};
    final startDate = messages.first.timestamp;

    for (final message in messages) {
      final weekNumber = message.timestamp.difference(startDate).inDays ~/ 7;
      weeklyEngagement[weekNumber] = (weeklyEngagement[weekNumber] ?? 0) + 1;
    }

    if (weeklyEngagement.length < 2) return 50.0;

    // Calculate engagement consistency
    final weeklyValues = weeklyEngagement.values.toList();
    final avgEngagement = weeklyValues.reduce((a, b) => a + b) / weeklyValues.length;
    
    double varianceSum = 0;
    for (final value in weeklyValues) {
      varianceSum += math.pow(value - avgEngagement, 2);
    }
    
    final variance = varianceSum / weeklyValues.length;
    final consistency = math.max(0, 100 - (variance / avgEngagement * 10));

    return consistency.clamp(0.0, 100.0);
  }

  // ========================================================================
  // SUPPORT PATTERN ANALYSIS
  // ========================================================================

  /// Analyze support patterns between users
  Map<String, dynamic> _analyzeSupportPatterns(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, int>> userSupport = {};

    // Initialize support tracking
    for (final userName in userIdToName.values) {
      userSupport[userName] = {
        'support_given': 0,
        'support_received': 0,
        'encouragement_given': 0,
        'questions_asked': 0,
        'help_offered': 0,
      };
    }

    // Keywords for different types of support
    final supportWords = ['help', 'support', 'there for you', 'understand', 'care'];
    final encouragementWords = ['you can do it', 'believe in you', 'proud of you', 'amazing', 'awesome'];
    final questionWords = ['how are you', 'how do you feel', 'what happened', 'are you okay'];
    final helpWords = ['let me help', 'can i help', 'need help', 'here to help'];

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final content = message.content.toLowerCase();

      if (userSupport.containsKey(userName)) {
        // Check for support language
        if (supportWords.any((word) => content.contains(word))) {
          userSupport[userName]!['support_given'] = userSupport[userName]!['support_given']! + 1;
        }

        // Check for encouragement
        if (encouragementWords.any((word) => content.contains(word))) {
          userSupport[userName]!['encouragement_given'] = userSupport[userName]!['encouragement_given']! + 1;
        }

        // Check for caring questions
        if (questionWords.any((word) => content.contains(word))) {
          userSupport[userName]!['questions_asked'] = userSupport[userName]!['questions_asked']! + 1;
        }

        // Check for help offers
        if (helpWords.any((word) => content.contains(word))) {
          userSupport[userName]!['help_offered'] = userSupport[userName]!['help_offered']! + 1;
        }

        // Track support received (previous message was supportive to this user)
        if (i > 0) {
          final prevMessage = messages[i - 1];
          if (prevMessage.senderId != message.senderId) {
            final prevContent = prevMessage.content.toLowerCase();
            if (supportWords.any((word) => prevContent.contains(word)) ||
                encouragementWords.any((word) => prevContent.contains(word))) {
              userSupport[userName]!['support_received'] = userSupport[userName]!['support_received']! + 1;
            }
          }
        }
      }
    }

    // Calculate support patterns
    final Map<String, Map<String, dynamic>> supportPatterns = {};

    for (final entry in userSupport.entries) {
      final userName = entry.key;
      final stats = entry.value;
      
      final totalGiven = stats['support_given']! + 
                        stats['encouragement_given']! + 
                        stats['help_offered']!;
      
      final supportType = _determineSupportType(stats);

      supportPatterns[userName] = {
        'supportType': supportType,
        'totalSupportGiven': totalGiven,
        'totalSupportReceived': stats['support_received']!,
        'supportBalance': _calculateSupportBalance(totalGiven, stats['support_received']!),
        'encouragementGiven': stats['encouragement_given']!,
        'questionsAsked': stats['questions_asked']!,
        'helpOffered': stats['help_offered']!,
      };
    }

    return supportPatterns;
  }

  /// Determine support type based on patterns
  String _determineSupportType(Map<String, int> stats) {
    final support = stats['support_given']!;
    final encouragement = stats['encouragement_given']!;
    final questions = stats['questions_asked']!;
    final help = stats['help_offered']!;

    if (encouragement > support && encouragement > help) return 'Cheerleader 📣';
    if (help > support && help > encouragement) return 'Helper 🤝';
    if (questions > support) return 'Caring Listener 👂';
    if (support > 0) return 'Emotional Supporter 💙';
    return 'Neutral 😐';
  }

  /// Calculate support balance score
  String _calculateSupportBalance(int given, int received) {
    if (given == 0 && received == 0) return 'No Data';
    if (given > received * 2) return 'Mostly Giving 💝';
    if (received > given * 2) return 'Mostly Receiving 🎁';
    return 'Balanced Exchange ⚖️';
  }

  // ========================================================================
  // RECIPROCITY PATTERN ANALYSIS
  // ========================================================================

  /// Analyze reciprocity patterns in the relationship
  Map<String, dynamic> _analyzeReciprocityPatterns(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, int>> userResponses = {};
    final Map<String, int> totalMessages = {};

    // Initialize maps
    for (final userId in userIdToName.keys) {
      final userName = userIdToName[userId]!;
      userResponses[userName] = {};
      totalMessages[userName] = 0;
    }

    // Analyze who responds to whom
    for (int i = 1; i < messages.length; i++) {
      final currentMsg = messages[i];
      final previousMsg = messages[i - 1];

      if (currentMsg.senderId == previousMsg.senderId) continue;

      final responderName = userIdToName[currentMsg.senderId] ?? 'Unknown';
      final originalSenderName = userIdToName[previousMsg.senderId] ?? 'Unknown';

      // Check reasonable response time (within 2 hours)
      final timeDiff = currentMsg.timestamp.difference(previousMsg.timestamp);
      if (timeDiff.inHours > 2) continue;

      userResponses[responderName]![originalSenderName] =
          (userResponses[responderName]![originalSenderName] ?? 0) + 1;
    }

    // Count total messages per user
    for (final message in messages) {
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      totalMessages[userName] = (totalMessages[userName] ?? 0) + 1;
    }

    // Calculate reciprocity scores
    final Map<String, Map<String, dynamic>> reciprocityScores = {};

    for (final responder in userResponses.keys) {
      if (totalMessages[responder] == 0) continue;

      final responses = userResponses[responder]!;
      final totalResponses = responses.values.fold(0, (sum, count) => sum + count);

      // Calculate response rate
      final messagesFromOthers = totalMessages.entries
          .where((entry) => entry.key != responder)
          .fold(0, (sum, entry) => sum + entry.value);

      final responseRate = messagesFromOthers > 0
          ? (totalResponses / messagesFromOthers) * 100
          : 0.0;

      // Find who they respond to most
      String mostRespondedTo = 'None';
      int maxResponses = 0;

      for (final entry in responses.entries) {
        if (entry.value > maxResponses) {
          maxResponses = entry.value;
          mostRespondedTo = entry.key;
        }
      }

      reciprocityScores[responder] = {
        'responseRate': responseRate.toStringAsFixed(1),
        'totalResponses': totalResponses,
        'mostRespondedTo': mostRespondedTo,
        'maxResponses': maxResponses,
        'reciprocityLevel': _determineReciprocityLevel(responseRate),
        'responsesBreakdown': responses,
      };
    }

    return reciprocityScores;
  }

  /// Determine reciprocity level based on response rate
  String _determineReciprocityLevel(double responseRate) {
    if (responseRate > 80) return 'Highly Reciprocal 🔄';
    if (responseRate > 60) return 'Good Reciprocity 👍';
    if (responseRate > 40) return 'Moderate Reciprocity ⚖️';
    if (responseRate > 20) return 'Low Reciprocity 📉';
    return 'Minimal Reciprocity 😶';
  }

  // ========================================================================
  // EMOTIONAL DYNAMICS ANALYSIS
  // ========================================================================

  /// Analyze emotional dynamics in the relationship
  Map<String, dynamic> _analyzeEmotionalDynamics(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, int>> emotionalPatterns = {};

    // Emotion categories
    final positiveWords = ['love', 'happy', 'great', 'awesome', 'good', 'nice', 'thanks', 'lol', 'haha', 'excited'];
    final negativeWords = ['sad', 'bad', 'terrible', 'awful', 'hate', 'angry', 'mad', 'upset', 'disappointed'];
    final supportiveWords = ['sorry', 'hope', 'there for you', 'understand', 'care', 'support'];

    for (final message in messages.take(1500)) { // Limit for performance
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final content = message.content.toLowerCase();

      emotionalPatterns.putIfAbsent(userName, () => {
        'positive': 0,
        'negative': 0,
        'supportive': 0,
        'neutral': 0,
      });

      bool hasEmotion = false;

      if (positiveWords.any((word) => content.contains(word))) {
        emotionalPatterns[userName]!['positive'] = emotionalPatterns[userName]!['positive']! + 1;
        hasEmotion = true;
      }

      if (negativeWords.any((word) => content.contains(word))) {
        emotionalPatterns[userName]!['negative'] = emotionalPatterns[userName]!['negative']! + 1;
        hasEmotion = true;
      }

      if (supportiveWords.any((word) => content.contains(word))) {
        emotionalPatterns[userName]!['supportive'] = emotionalPatterns[userName]!['supportive']! + 1;
        hasEmotion = true;
      }

      if (!hasEmotion) {
        emotionalPatterns[userName]!['neutral'] = emotionalPatterns[userName]!['neutral']! + 1;
      }
    }

    // Calculate emotional profiles
    final Map<String, Map<String, dynamic>> emotionalProfiles = {};

    for (final entry in emotionalPatterns.entries) {
      final userName = entry.key;
      final patterns = entry.value;

      final total = patterns.values.reduce((a, b) => a + b);
      if (total == 0) continue;

      final positivePercent = (patterns['positive']! / total) * 100;
      final negativePercent = (patterns['negative']! / total) * 100;
      final supportivePercent = (patterns['supportive']! / total) * 100;

      String emotionalType = _determineEmotionalType(positivePercent, negativePercent, supportivePercent);

      emotionalProfiles[userName] = {
        'emotionalType': emotionalType,
        'positivePercentage': positivePercent.toStringAsFixed(1),
        'negativePercentage': negativePercent.toStringAsFixed(1),
        'supportivePercentage': supportivePercent.toStringAsFixed(1),
        'totalEmotionalMessages': total - patterns['neutral']!,
        'emotionalBalance': _calculateEmotionalBalance(positivePercent, negativePercent),
      };
    }

    return emotionalProfiles;
  }

  /// Determine emotional type based on percentages
  String _determineEmotionalType(double positive, double negative, double supportive) {
    if (supportive > 25) return 'Supportive Soul 💙';
    if (positive > 40) return 'Positive Vibes ✨';
    if (negative > 30) return 'Expressive 😤';
    if (positive > negative) return 'Generally Positive 😊';
    if (negative > positive) return 'Sometimes Negative 😔';
    return 'Emotionally Neutral 😐';
  }

  /// Calculate emotional balance
  String _calculateEmotionalBalance(double positive, double negative) {
    final ratio = positive / (negative + 1); // Add 1 to avoid division by zero
    if (ratio > 3) return 'Very Positive ⬆️';
    if (ratio > 1.5) return 'Mostly Positive ➡️';
    if (ratio > 0.7) return 'Balanced ⚖️';
    if (ratio > 0.3) return 'Mostly Negative ⬇️';
    return 'Very Negative ⬇️⬇️';
  }

  // ========================================================================
  // ENGAGEMENT LEVEL ANALYSIS
  // ========================================================================

  /// Analyze engagement levels over time
  Map<String, dynamic> _analyzeEngagementLevels(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    // Divide timeline into segments for trend analysis
    final timeSpan = messages.last.timestamp.difference(messages.first.timestamp);
    if (timeSpan.inDays < 7) {
      return {'message': 'Not enough time span for engagement analysis'};
    }

    final segmentDays = math.max(7, timeSpan.inDays ~/ 10); // At least weekly segments
    final Map<int, Map<String, int>> segmentActivity = {};

    final startTime = messages.first.timestamp;
    for (final message in messages) {
      final daysSinceStart = message.timestamp.difference(startTime).inDays;
      final segment = daysSinceStart ~/ segmentDays;
      final userName = userIdToName[message.senderId] ?? 'Unknown';

      segmentActivity.putIfAbsent(segment, () => {});
      segmentActivity[segment]![userName] = (segmentActivity[segment]![userName] ?? 0) + 1;
    }

    // Calculate engagement trends
    final Map<String, Map<String, dynamic>> engagementTrends = {};
    
    for (final userName in userIdToName.values) {
      final userSegments = <int, int>{};
      
      for (final entry in segmentActivity.entries) {
        userSegments[entry.key] = entry.value[userName] ?? 0;
      }

      if (userSegments.length < 3) continue;

      // Calculate trend
      final segments = userSegments.keys.toList()..sort();
      final firstHalf = segments.take(segments.length ~/ 2);
      final secondHalf = segments.skip(segments.length ~/ 2);

      final firstHalfAvg = firstHalf.isEmpty ? 0.0 :
          firstHalf.map((s) => userSegments[s]!).reduce((a, b) => a + b) / firstHalf.length;
      final secondHalfAvg = secondHalf.isEmpty ? 0.0 :
          secondHalf.map((s) => userSegments[s]!).reduce((a, b) => a + b) / secondHalf.length;

      final trendPercentage = firstHalfAvg > 0 
          ? ((secondHalfAvg - firstHalfAvg) / firstHalfAvg) * 100
          : 0.0;

      String trendType = _determineTrendType(trendPercentage);

      engagementTrends[userName] = {
        'trendType': trendType,
        'trendPercentage': trendPercentage.toStringAsFixed(1),
        'earlyEngagement': firstHalfAvg.round(),
        'recentEngagement': secondHalfAvg.round(),
        'totalSegments': segments.length,
      };
    }

    return engagementTrends;
  }

  /// Determine trend type based on percentage change
  String _determineTrendType(double percentage) {
    if (percentage > 50) return 'Strongly Increasing 📈📈';
    if (percentage > 20) return 'Increasing 📈';
    if (percentage > 10) return 'Slightly Increasing ↗️';
    if (percentage > -10) return 'Stable ➡️';
    if (percentage > -20) return 'Slightly Decreasing ↘️';
    if (percentage > -50) return 'Decreasing 📉';
    return 'Strongly Decreasing 📉📉';
  }

  // ========================================================================
  // CONFLICT PATTERN ANALYSIS
  // ========================================================================

  /// Analyze potential conflict patterns
  Map<String, dynamic> _analyzeConflictPatterns(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final conflictIndicators = ['but', 'however', 'disagree', 'wrong', 'no way', 'actually', 'really?'];
    final resolutionIndicators = ['sorry', 'apologize', 'understand', 'you\'re right', 'my bad'];

    int potentialConflicts = 0;
    int resolutions = 0;
    final Map<String, int> userConflictInvolvement = {};

    for (int i = 1; i < messages.length; i++) {
      final message = messages[i];
      final prevMessage = messages[i - 1];
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final content = message.content.toLowerCase();

      // Check for conflict indicators (especially in response to different user)
      if (message.senderId != prevMessage.senderId &&
          conflictIndicators.any((indicator) => content.contains(indicator))) {
        potentialConflicts++;
        userConflictInvolvement[userName] = (userConflictInvolvement[userName] ?? 0) + 1;
      }

      // Check for resolution indicators
      if (resolutionIndicators.any((indicator) => content.contains(indicator))) {
        resolutions++;
      }
    }

    final conflictResolutionRatio = potentialConflicts > 0 ? resolutions / potentialConflicts : 0.0;

    return {
      'potentialConflicts': potentialConflicts,
      'resolutions': resolutions,
      'conflictResolutionRatio': conflictResolutionRatio.toStringAsFixed(2),
      'conflictResolutionHealth': _determineConflictHealth(conflictResolutionRatio),
      'userConflictInvolvement': userConflictInvolvement,
      'overallConflictLevel': _determineConflictLevel(potentialConflicts, messages.length),
    };
  }

  /// Determine conflict resolution health
  String _determineConflictHealth(double ratio) {
    if (ratio > 0.8) return 'Excellent Resolution 🤝';
    if (ratio > 0.6) return 'Good Resolution 👍';
    if (ratio > 0.4) return 'Moderate Resolution ⚖️';
    if (ratio > 0.2) return 'Poor Resolution 😔';
    return 'Very Poor Resolution ❌';
  }

  /// Determine overall conflict level
  String _determineConflictLevel(int conflicts, int totalMessages) {
    final conflictRate = conflicts / totalMessages;
    if (conflictRate > 0.1) return 'High Conflict 🔥';
    if (conflictRate > 0.05) return 'Moderate Conflict ⚠️';
    if (conflictRate > 0.02) return 'Low Conflict 🟡';
    return 'Minimal Conflict 🟢';
  }

  // ========================================================================
  // RELATIONSHIP TREND ANALYSIS
  // ========================================================================

  /// Analyze overall relationship trend
  Map<String, dynamic> _analyzeRelationshipTrend(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    // Divide into quarters for trend analysis
    final quarterSize = messages.length ~/ 4;
    if (quarterSize < 10) {
      return {'trend': 'Insufficient data for trend analysis'};
    }

    final quarters = [
      messages.take(quarterSize).toList(),
      messages.skip(quarterSize).take(quarterSize).toList(),
      messages.skip(quarterSize * 2).take(quarterSize).toList(),
      messages.skip(quarterSize * 3).toList(),
    ];

    final quarterHealthScores = <double>[];

    for (final quarter in quarters) {
      if (quarter.isNotEmpty) {
        final healthScore = _calculateRelationshipHealthScore(quarter, userIdToName);
        quarterHealthScores.add(healthScore);
      }
    }

    if (quarterHealthScores.length < 2) {
      return {'trend': 'Insufficient data for trend analysis'};
    }

    // Calculate trend
    final firstHalfAvg = quarterHealthScores.take(2).reduce((a, b) => a + b) / 2;
    final secondHalfAvg = quarterHealthScores.skip(2).reduce((a, b) => a + b) / quarterHealthScores.skip(2).length;
    
    final trendChange = secondHalfAvg - firstHalfAvg;
    final trendPercentage = (trendChange / firstHalfAvg) * 100;

    String overallTrend = _determineOverallTrend(trendPercentage);

    return {
      'overallTrend': overallTrend,
      'trendPercentage': trendPercentage.toStringAsFixed(1),
      'initialHealth': firstHalfAvg.toStringAsFixed(1),
      'currentHealth': secondHalfAvg.toStringAsFixed(1),
      'quarterlyScores': quarterHealthScores.map((s) => s.toStringAsFixed(1)).toList(),
      'trendDirection': trendChange > 0 ? 'Improving' : trendChange < 0 ? 'Declining' : 'Stable',
    };
  }

  /// Determine overall relationship trend
  String _determineOverallTrend(double percentage) {
    if (percentage > 20) return 'Significantly Improving 💕';
    if (percentage > 10) return 'Improving 📈';
    if (percentage > 5) return 'Slightly Improving ↗️';
    if (percentage > -5) return 'Stable 🤝';
    if (percentage > -10) return 'Slightly Declining ↘️';
    if (percentage > -20) return 'Declining 📉';
    return 'Significantly Declining 💔';
  }

  // ========================================================================
  // OVERALL ASSESSMENT
  // ========================================================================

  /// Generate overall relationship assessment
  Map<String, dynamic> _generateOverallAssessment(
    double healthScore,
    Map<String, dynamic> supportPatterns,
    Map<String, dynamic> reciprocityPatterns,
  ) {
    // Determine overall relationship status
    String relationshipStatus = _determineRelationshipStatus(healthScore);
    
    // Key strengths and areas for improvement
    final strengths = <String>[];
    final improvements = <String>[];

    if (healthScore > 70) {
      strengths.add('Strong overall relationship health');
    } else if (healthScore < 40) {
      improvements.add('Focus on improving overall communication balance');
    }

    // Analyze support patterns
    final supportTypes = supportPatterns.values
        .map((pattern) => pattern['supportType'] as String?)
        .where((type) => type != null && type != 'Neutral 😐')
        .toList();

    if (supportTypes.isNotEmpty) {
      strengths.add('Good emotional support present');
    } else {
      improvements.add('Consider expressing more emotional support');
    }

    // Analyze reciprocity
    final reciprocityLevels = reciprocityPatterns.values
        .map((pattern) => pattern['reciprocityLevel'] as String?)
        .where((level) => level != null)
        .toList();

    final goodReciprocity = reciprocityLevels
        .where((level) => level!.contains('Good') || level.contains('Highly'))
        .length;

    if (goodReciprocity > 0) {
      strengths.add('Balanced communication patterns');
    } else {
      improvements.add('Work on more balanced conversation flow');
    }

    return {
      'relationshipStatus': relationshipStatus,
      'healthScore': healthScore.toStringAsFixed(1),
      'keyStrengths': strengths,
      'areasForImprovement': improvements,
      'overallAssessment': _generateAssessmentSummary(healthScore, strengths.length, improvements.length),
    };
  }

  /// Determine relationship status based on health score
  String _determineRelationshipStatus(double healthScore) {
    if (healthScore > 85) return 'Excellent Relationship 💕';
    if (healthScore > 70) return 'Strong Relationship 💪';
    if (healthScore > 55) return 'Good Relationship 👍';
    if (healthScore > 40) return 'Developing Relationship 🌱';
    if (healthScore > 25) return 'Challenging Relationship ⚠️';
    return 'Difficult Relationship 😔';
  }

  /// Generate assessment summary
  String _generateAssessmentSummary(double healthScore, int strengths, int improvements) {
    if (healthScore > 70 && strengths > improvements) {
      return 'This appears to be a healthy, well-balanced relationship with strong communication patterns.';
    } else if (healthScore > 50) {
      return 'This relationship shows positive signs but has room for growth in some areas.';
    } else if (improvements > strengths) {
      return 'This relationship would benefit from focusing on improved communication and mutual support.';
    } else {
      return 'This relationship analysis suggests mixed patterns that could benefit from attention and care.';
    }
  }

  // ========================================================================
  // HELPER METHODS
  // ========================================================================

  double _calculateConfidence(int messageCount, int userCount) {
    if (messageCount < 50 || userCount < 2) return 0.2;
    if (messageCount < 200) return 0.5;
    if (messageCount < 500) return 0.7;
    if (userCount < 3) return 0.8;
    return 0.95;
  }

  AnalysisResult _createEmptyResult(String message) {
    return AnalysisResult(
      type: 'relationship_dynamics',
      data: {
        'message': message,
        'relationshipHealthScore': 0.0,
        'supportPatterns': {},
        'reciprocityPatterns': {},
      },
      confidence: 0.0,
      generatedAt: DateTime.now(),
    );
  }

  AnalysisResult _createErrorResult(dynamic error) {
    return AnalysisResult(
      type: 'relationship_dynamics',
      data: {
        'error': true,
        'message': 'Relationship analysis failed: ${error.toString()}',
        'relationshipHealthScore': 0.0,
      },
      confidence: 0.0,
      generatedAt: DateTime.now(),
    );
  }
}