// ============================================================================
// FILE: features/analysis/analyzers/enhanced/behavior_pattern_analyzer.dart
// Behavior Pattern Analyzer - Fixed type issues
// ============================================================================
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../../../shared/domain.dart';
import '../../analysis_models.dart';
import '../base_analyzer.dart';

class BehaviorPatternAnalyzer implements EnhancedAnalyzer {
  static const int maxAnalysisMessages = 8000; // Limit for performance

  @override
  Future<AnalysisResult> analyze(ChatEntity chat) async {
    debugPrint("🧠 BehaviorPatternAnalyzer: Starting analysis");

    try {
      // Limit messages for performance
      final messagesToProcess = chat.messages.length > maxAnalysisMessages
          ? chat.messages.take(maxAnalysisMessages).toList()
          : chat.messages;

      if (messagesToProcess.isEmpty) {
        return _createEmptyResult();
      }

      final userIdToName = {for (var user in chat.users) user.id: user.name};

      // Analyze different behavior patterns
      final communicationStyles = _analyzeCommunicationStyles(messagesToProcess, userIdToName);
      final timePersonalities = _analyzeTimePersonalities(messagesToProcess, userIdToName);
      final consistencyPatterns = _analyzeConsistencyPatterns(messagesToProcess, userIdToName);
      final energyLevels = _analyzeEnergyLevels(messagesToProcess, userIdToName);
      final reactivePatterns = _analyzeReactivePatterns(messagesToProcess, userIdToName);
      final compatibilityScore = _calculateCompatibilityScore(messagesToProcess, userIdToName);

      final result = {
        'communicationStyles': communicationStyles,
        'timePersonalities': timePersonalities,
        'consistencyPatterns': consistencyPatterns,
        'energyLevels': energyLevels,
        'reactivePatterns': reactivePatterns,
        'compatibilityScore': compatibilityScore.round(), // Convert to int
        'behaviorSummary': _generateBehaviorSummary(communicationStyles, timePersonalities, energyLevels),
      };

      debugPrint("✅ BehaviorPatternAnalyzer: Analysis complete");

      return AnalysisResult(
        type: 'behavior_patterns',
        data: result,
        confidence: _calculateConfidence(messagesToProcess.length, userIdToName.length),
        generatedAt: DateTime.now(),
      );

    } catch (e, stackTrace) {
      debugPrint("❌ BehaviorPatternAnalyzer: Error - $e");
      debugPrint("Stack trace: $stackTrace");
      return _createErrorResult(e);
    }
  }

  // ========================================================================
  // COMMUNICATION STYLE ANALYSIS
  // ========================================================================

  /// Analyze communication styles for each user
  Map<String, dynamic> _analyzeCommunicationStyles(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, dynamic>> userStyles = {};

    // Initialize user stats
    for (final userName in userIdToName.values) {
      userStyles[userName] = {
        'totalMessages': 0,
        'totalWords': 0,
        'totalCharacters': 0,
        'avgMessageLength': 0.0,
        'emojiCount': 0,
        'exclamationCount': 0,
        'questionCount': 0,
        'capsWordsCount': 0,
        'longMessages': 0,
        'shortMessages': 0,
      };
    }

    final emojiRegex = RegExp(r'[\u{1F600}-\u{1F64F}]', unicode: true);

    // Analyze each message
    for (final message in messages.take(2000)) { // Limit for performance
      final userName = userIdToName[message.senderId] ?? 'Unknown';

      if (userStyles.containsKey(userName)) {
        final stats = userStyles[userName]!;
        final content = message.content;

        stats['totalMessages'] = (stats['totalMessages'] as int) + 1;
        stats['totalCharacters'] = (stats['totalCharacters'] as int) + content.length;

        final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        stats['totalWords'] = (stats['totalWords'] as int) + words.length;

        // Count emojis
        final emojiCount = emojiRegex.allMatches(content).length;
        stats['emojiCount'] = (stats['emojiCount'] as int) + emojiCount;

        // Count exclamations and questions
        stats['exclamationCount'] = (stats['exclamationCount'] as int) + content.split('!').length - 1;
        stats['questionCount'] = (stats['questionCount'] as int) + content.split('?').length - 1;

        // Count CAPS words
        final capsWords = words.where((word) => word.length > 1 && word == word.toUpperCase()).length;
        stats['capsWordsCount'] = (stats['capsWordsCount'] as int) + capsWords;

        // Message length categorization
        if (content.length > 100) {
          stats['longMessages'] = (stats['longMessages'] as int) + 1;
        } else if (content.length < 20) {
          stats['shortMessages'] = (stats['shortMessages'] as int) + 1;
        }
      }
    }

    // Calculate communication styles
    final Map<String, Map<String, dynamic>> communicationStyles = {};

    for (final entry in userStyles.entries) {
      final userName = entry.key;
      final stats = entry.value;
      final totalMessages = stats['totalMessages'] as int;

      if (totalMessages > 0) {
        final avgMessageLength = (stats['totalCharacters'] as int) / totalMessages;
        final avgWordsPerMessage = (stats['totalWords'] as int) / totalMessages;
        final emojiRate = (stats['emojiCount'] as int) / totalMessages;
        final exclamationRate = (stats['exclamationCount'] as int) / totalMessages;
        final questionRate = (stats['questionCount'] as int) / totalMessages;
        final capsRate = (stats['capsWordsCount'] as int) / (stats['totalWords'] as int);

        // Determine communication style
        String styleType = _determineCommunicationStyle(
          avgMessageLength,
          emojiRate,
          exclamationRate,
          questionRate,
          capsRate,
        );

        communicationStyles[userName] = {
          'styleType': styleType,
          'avgMessageLength': avgMessageLength.round(),
          'avgWordsPerMessage': avgWordsPerMessage.toStringAsFixed(1),
          'emojiRate': emojiRate.toStringAsFixed(2),
          'exclamationRate': exclamationRate.toStringAsFixed(2),
          'questionRate': questionRate.toStringAsFixed(2),
          'capsPercentage': (capsRate * 100).toStringAsFixed(1),
          'longMessagePercentage': ((stats['longMessages'] as int) / totalMessages * 100).toStringAsFixed(1),
          'shortMessagePercentage': ((stats['shortMessages'] as int) / totalMessages * 100).toStringAsFixed(1),
        };
      }
    }

    return communicationStyles;
  }

  /// Determine communication style based on metrics
  String _determineCommunicationStyle(
    double avgLength,
    double emojiRate,
    double exclamationRate,
    double questionRate,
    double capsRate,
  ) {
    if (emojiRate > 1.0) return 'Emoji Enthusiast 😍';
    if (exclamationRate > 0.5) return 'Excitable Communicator! 🎉';
    if (questionRate > 0.3) return 'Curious Questioner 🤔';
    if (capsRate > 0.05) return 'EMPHATIC SPEAKER 📢';
    if (avgLength > 150) return 'Detailed Storyteller 📚';
    if (avgLength < 25) return 'Concise Communicator 💬';
    return 'Balanced Communicator 📝';
  }

  // ========================================================================
  // TIME PERSONALITY ANALYSIS
  // ========================================================================

  /// Analyze time-based behavior patterns
  Map<String, dynamic> _analyzeTimePersonalities(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, List<int>> userHours = {};
    final Map<String, Map<int, int>> userDayActivity = {};

    // Collect hour data for each user
    for (final message in messages) {
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final hour = message.timestamp.hour;
      final weekday = message.timestamp.weekday;

      userHours.putIfAbsent(userName, () => []);
      userHours[userName]!.add(hour);

      userDayActivity.putIfAbsent(userName, () => {});
      userDayActivity[userName]![weekday] = (userDayActivity[userName]![weekday] ?? 0) + 1;
    }

    final Map<String, Map<String, dynamic>> timePersonalities = {};

    for (final entry in userHours.entries) {
      final userName = entry.key;
      final hours = entry.value;

      if (hours.isEmpty) continue;

      // Calculate time statistics
      final nightMessages = hours.where((h) => h >= 22 || h <= 6).length;
      final morningMessages = hours.where((h) => h >= 6 && h <= 10).length;
      final afternoonMessages = hours.where((h) => h >= 12 && h <= 17).length;
      final eveningMessages = hours.where((h) => h >= 18 && h <= 22).length;
      final totalMessages = hours.length;

      // Determine personality type
      String personality = _determineTimePersonality(
        nightMessages / totalMessages,
        morningMessages / totalMessages,
        afternoonMessages / totalMessages,
        eveningMessages / totalMessages,
      );

      // Find peak activity hours
      final hourCounts = <int, int>{};
      for (final hour in hours) {
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }

      final peakHour = hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      // Analyze weekend vs weekday behavior
      final dayActivity = userDayActivity[userName] ?? {};
      final weekendMessages = (dayActivity[6] ?? 0) + (dayActivity[7] ?? 0);
      final weekdayMessages = totalMessages - weekendMessages;
      final weekendPercentage = totalMessages > 0 ? (weekendMessages / totalMessages) * 100 : 0.0;

      timePersonalities[userName] = {
        'personality': personality,
        'peakHour': '$peakHour:00',
        'nightPercentage': ((nightMessages / totalMessages) * 100).toStringAsFixed(1),
        'morningPercentage': ((morningMessages / totalMessages) * 100).toStringAsFixed(1),
        'afternoonPercentage': ((afternoonMessages / totalMessages) * 100).toStringAsFixed(1),
        'eveningPercentage': ((eveningMessages / totalMessages) * 100).toStringAsFixed(1),
        'weekendPercentage': weekendPercentage.toStringAsFixed(1),
        'weekendBehavior': _determineWeekendBehavior(weekendPercentage),
        'totalMessages': totalMessages,
      };
    }

    return timePersonalities;
  }

  /// Determine time personality based on activity patterns
  String _determineTimePersonality(
    double nightRatio,
    double morningRatio,
    double afternoonRatio,
    double eveningRatio,
  ) {
    if (nightRatio > 0.3) return 'Night Owl 🦉';
    if (morningRatio > 0.4) return 'Early Bird 🐦';
    if (afternoonRatio > 0.5) return 'Afternoon Person ☀️';
    if (eveningRatio > 0.4) return 'Evening Person 🌅';
    return 'Flexible Timer ⏰';
  }

  /// Determine weekend behavior pattern
  String _determineWeekendBehavior(double weekendPercentage) {
    if (weekendPercentage > 35) return 'Weekend Warrior 🎉';
    if (weekendPercentage < 20) return 'Weekday Focused 💼';
    return 'Balanced Schedule ⚖️';
  }

  // ========================================================================
  // CONSISTENCY PATTERN ANALYSIS
  // ========================================================================

  /// Analyze consistency patterns in user behavior
  Map<String, dynamic> _analyzeConsistencyPatterns(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, List<DateTime>> userDates = {};

    // Group messages by user and date
    for (final message in messages) {
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final date = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );

      userDates.putIfAbsent(userName, () => []);
      if (!userDates[userName]!.any((d) => d.isAtSameMomentAs(date))) {
        userDates[userName]!.add(date);
      }
    }

    final Map<String, Map<String, dynamic>> consistencyScores = {};

    for (final entry in userDates.entries) {
      final userName = entry.key;
      final dates = entry.value..sort();

      if (dates.length < 3) continue;

      // Calculate gaps between active days
      final gaps = <int>[];
      for (int i = 1; i < dates.length; i++) {
        final gap = dates[i].difference(dates[i - 1]).inDays;
        gaps.add(gap);
      }

      final avgGap = gaps.reduce((a, b) => a + b) / gaps.length;
      final maxGap = gaps.reduce(math.max);
      final minGap = gaps.reduce(math.min);

      // Calculate consistency score
      final variance = gaps.map((g) => math.pow(g - avgGap, 2)).reduce((a, b) => a + b) / gaps.length;
      final consistencyScore = math.max(0, 100 - (variance * 2)).toDouble(); // Convert to double

      String consistencyType = _determineConsistencyType(consistencyScore);

      consistencyScores[userName] = {
        'score': consistencyScore.toStringAsFixed(1),
        'type': consistencyType,
        'averageGap': avgGap.toStringAsFixed(1),
        'maxGap': maxGap,
        'minGap': minGap,
        'activeDays': dates.length,
      };
    }

    return consistencyScores;
  }

  /// Determine consistency type based on score
  String _determineConsistencyType(double score) {
    if (score > 80) return 'Very Consistent 📅';
    if (score > 60) return 'Moderately Consistent 📊';
    if (score > 40) return 'Somewhat Sporadic 📈';
    return 'Very Sporadic 🎲';
  }

  // ========================================================================
  // ENERGY LEVEL ANALYSIS
  // ========================================================================

  /// Analyze energy levels in communication
  Map<String, dynamic> _analyzeEnergyLevels(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, List<Map<String, dynamic>>> userMessageData = {};

    // Collect message characteristics for each user
    for (final message in messages.take(1500)) { // Limit for performance
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final content = message.content;

      userMessageData.putIfAbsent(userName, () => []);

      final exclamationCount = content.split('!').length - 1;
      final capsCount = content.split('').where((c) => c == c.toUpperCase() && c != c.toLowerCase()).length;
      final questionCount = content.split('?').length - 1;

      userMessageData[userName]!.add({
        'length': content.length,
        'exclamations': exclamationCount,
        'caps': capsCount,
        'questions': questionCount,
      });
    }

    final Map<String, Map<String, dynamic>> energyLevels = {};

    for (final entry in userMessageData.entries) {
      final userName = entry.key;
      final messageData = entry.value;

      if (messageData.isEmpty) continue;

      // Calculate energy indicators
      final avgLength = messageData.map((m) => m['length'] as int).reduce((a, b) => a + b) / messageData.length;
      final avgExclamations = messageData.map((m) => m['exclamations'] as int).reduce((a, b) => a + b) / messageData.length;
      final avgCaps = messageData.map((m) => m['caps'] as int).reduce((a, b) => a + b) / messageData.length;
      final avgQuestions = messageData.map((m) => m['questions'] as int).reduce((a, b) => a + b) / messageData.length;

      // Calculate energy score
      double energyScore = 50; // Base score
      energyScore += avgExclamations * 10; // Excitement
      energyScore += (avgCaps / avgLength) * 20; // CAPS usage
      energyScore += avgQuestions * 5; // Curiosity
      energyScore += math.min(20, avgLength / 10); // Verbosity

      energyScore = math.min(100, energyScore);

      String energyType = _determineEnergyType(energyScore);

      energyLevels[userName] = {
        'energyScore': energyScore.toStringAsFixed(1),
        'energyType': energyType,
        'avgMessageLength': avgLength.toStringAsFixed(1),
        'exclamationsPerMessage': avgExclamations.toStringAsFixed(2),
        'questionsPerMessage': avgQuestions.toStringAsFixed(2),
        'capsPercentage': ((avgCaps / avgLength) * 100).toStringAsFixed(1),
      };
    }

    return energyLevels;
  }

  /// Determine energy type based on score
  String _determineEnergyType(double score) {
    if (score > 80) return 'High Energy ⚡';
    if (score > 60) return 'Good Energy 🔋';
    if (score > 40) return 'Moderate Energy 🔘';
    return 'Calm Energy 😌';
  }

  // ========================================================================
  // REACTIVE PATTERN ANALYSIS
  // ========================================================================

  /// Analyze how users react to different situations
  Map<String, dynamic> _analyzeReactivePatterns(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, int>> userReactions = {};

    // Initialize user reaction tracking
    for (final userName in userIdToName.values) {
      userReactions[userName] = {
        'agreement': 0,
        'disagreement': 0,
        'support': 0,
        'excitement': 0,
        'concern': 0,
        'totalReactions': 0,
      };
    }

    // Analyze reactions in message content
    for (final message in messages.take(1000)) { // Limit for performance
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final content = message.content.toLowerCase();

      if (userReactions.containsKey(userName)) {
        final reactions = userReactions[userName]!;

        // Check for agreement patterns
        if (_containsAgreementWords(content)) {
          reactions['agreement'] = reactions['agreement']! + 1;
          reactions['totalReactions'] = reactions['totalReactions']! + 1;
        }

        // Check for disagreement patterns
        if (_containsDisagreementWords(content)) {
          reactions['disagreement'] = reactions['disagreement']! + 1;
          reactions['totalReactions'] = reactions['totalReactions']! + 1;
        }

        // Check for support patterns
        if (_containsSupportWords(content)) {
          reactions['support'] = reactions['support']! + 1;
          reactions['totalReactions'] = reactions['totalReactions']! + 1;
        }

        // Check for excitement patterns
        if (_containsExcitementWords(content)) {
          reactions['excitement'] = reactions['excitement']! + 1;
          reactions['totalReactions'] = reactions['totalReactions']! + 1;
        }

        // Check for concern patterns
        if (_containsConcernWords(content)) {
          reactions['concern'] = reactions['concern']! + 1;
          reactions['totalReactions'] = reactions['totalReactions']! + 1;
        }
      }
    }

    // Calculate reaction patterns
    final Map<String, Map<String, dynamic>> reactionPatterns = {};

    for (final entry in userReactions.entries) {
      final userName = entry.key;
      final reactions = entry.value;
      final totalReactions = reactions['totalReactions']!;

      if (totalReactions > 0) {
        final dominantReaction = reactions.entries
            .where((e) => e.key != 'totalReactions')
            .reduce((a, b) => a.value > b.value ? a : b);

        reactionPatterns[userName] = {
          'dominantReaction': _formatReactionType(dominantReaction.key),
          'agreementPercentage': ((reactions['agreement']! / totalReactions) * 100).toStringAsFixed(1),
          'disagreementPercentage': ((reactions['disagreement']! / totalReactions) * 100).toStringAsFixed(1),
          'supportPercentage': ((reactions['support']! / totalReactions) * 100).toStringAsFixed(1),
          'excitementPercentage': ((reactions['excitement']! / totalReactions) * 100).toStringAsFixed(1),
          'concernPercentage': ((reactions['concern']! / totalReactions) * 100).toStringAsFixed(1),
          'totalReactions': totalReactions,
        };
      }
    }

    return reactionPatterns;
  }

  // ========================================================================
  // COMPATIBILITY SCORE
  // ========================================================================

  /// Calculate overall compatibility score between users
  double _calculateCompatibilityScore(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    if (messages.length < 100 || userIdToName.length < 2) return 0.0;

    // Simple compatibility based on response patterns and message balance
    final userMessageCounts = <String, int>{};

    for (final message in messages.take(1000)) { // Limit for performance
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      userMessageCounts[userName] = (userMessageCounts[userName] ?? 0) + 1;
    }

    if (userMessageCounts.length < 2) return 0.0;

    // Calculate balance between users
    final values = userMessageCounts.values.toList();
    final maxMessages = values.reduce(math.max);
    final minMessages = values.reduce(math.min);

    final balance = minMessages / maxMessages;
    return (balance * 100).clamp(0.0, 100.0);
  }

  // ========================================================================
  // SUMMARY GENERATION
  // ========================================================================

  /// Generate overall behavior summary
  Map<String, dynamic> _generateBehaviorSummary(
    Map<String, dynamic> communicationStyles,
    Map<String, dynamic> timePersonalities,
    Map<String, dynamic> energyLevels,
  ) {
    final summary = <String, dynamic>{};
    
    // Find most common patterns
    final allStyles = communicationStyles.values
        .map((style) => style['styleType'] as String?)
        .where((style) => style != null)
        .toList();

    final allPersonalities = timePersonalities.values
        .map((personality) => personality['personality'] as String?)
        .where((personality) => personality != null)
        .toList();

    final allEnergyTypes = energyLevels.values
        .map((energy) => energy['energyType'] as String?)
        .where((energy) => energy != null)
        .toList();

    summary['mostCommonCommunicationStyle'] = _findMostCommon(allStyles);
    summary['mostCommonTimePersonality'] = _findMostCommon(allPersonalities);
    summary['mostCommonEnergyLevel'] = _findMostCommon(allEnergyTypes);
    summary['totalUsersAnalyzed'] = communicationStyles.length;

    return summary;
  }

  // ========================================================================
  // HELPER METHODS
  // ========================================================================

  bool _containsAgreementWords(String content) {
    const agreementWords = ['yes', 'yeah', 'true', 'right', 'exactly', 'agree', 'correct'];
    return agreementWords.any((word) => content.contains(word));
  }

  bool _containsDisagreementWords(String content) {
    const disagreementWords = ['no', 'nope', 'wrong', 'disagree', 'false', 'not really'];
    return disagreementWords.any((word) => content.contains(word));
  }

  bool _containsSupportWords(String content) {
    const supportWords = ['support', 'help', 'there for you', 'understand', 'care', 'sorry'];
    return supportWords.any((word) => content.contains(word));
  }

  bool _containsExcitementWords(String content) {
    const excitementWords = ['awesome', 'amazing', 'great', 'fantastic', 'wow', 'love'];
    return excitementWords.any((word) => content.contains(word));
  }

  bool _containsConcernWords(String content) {
    const concernWords = ['worried', 'concerned', 'problem', 'issue', 'trouble', 'wrong'];
    return concernWords.any((word) => content.contains(word));
  }

  String _formatReactionType(String type) {
    switch (type) {
      case 'agreement': return 'Agreeable 👍';
      case 'disagreement': return 'Challenger 🤨';
      case 'support': return 'Supportive 🤗';
      case 'excitement': return 'Enthusiastic 🎉';
      case 'concern': return 'Thoughtful 🤔';
      default: return 'Neutral 😐';
    }
  }

  String? _findMostCommon(List<String?> items) {
    if (items.isEmpty) return null;
    
    final counts = <String, int>{};
    for (final item in items) {
      if (item != null) {
        counts[item] = (counts[item] ?? 0) + 1;
      }
    }
    
    if (counts.isEmpty) return null;
    
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  double _calculateConfidence(int messageCount, int userCount) {
    if (messageCount < 50 || userCount < 2) return 0.3;
    if (messageCount < 200) return 0.6;
    if (messageCount < 500) return 0.8;
    return 0.95;
  }

  AnalysisResult _createEmptyResult() {
    return AnalysisResult(
      type: 'behavior_patterns',
      data: {
        'message': 'Insufficient data for behavior analysis',
        'communicationStyles': {},
        'timePersonalities': {},
        'compatibilityScore': 0,
      },
      confidence: 0.0,
      generatedAt: DateTime.now(),
    );
  }

  AnalysisResult _createErrorResult(dynamic error) {
    return AnalysisResult(
      type: 'behavior_patterns',
      data: {
        'error': true,
        'message': 'Behavior analysis failed: ${error.toString()}',
        'communicationStyles': {},
        'compatibilityScore': 0,
      },
      confidence: 0.0,
      generatedAt: DateTime.now(),
    );
  }
}