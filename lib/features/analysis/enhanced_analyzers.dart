// lib/features/analysis/enhanced_analyzers.dart
// ConversationDynamicsAnalyzer - Reveals who initiates, ends, and drives conversations

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../../shared/domain.dart';

class ConversationDynamicsAnalyzer {
  static const int conversationGapMinutes = 30; // Gap that defines new conversation
  static const int rapidFireSeconds = 10; // Quick response threshold

  Future<Map<String, dynamic>> analyze(ChatEntity chat) async {
    debugPrint("🔄 Analyzing conversation dynamics...");
    
    final messages = chat.messages
        .where((msg) => msg.senderId != "System")
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (messages.isEmpty) return _emptyResults();

    // Identify separate conversations based on time gaps
    final conversations = _identifyConversations(messages);
    
    // Analyze who starts and ends conversations
    final initiationPatterns = _analyzeInitiationPatterns(conversations, chat.users);
    
    // Analyze conversation lengths and patterns
    final conversationStats = _analyzeConversationStats(conversations);
    
    // Analyze dialog flow patterns (rapid-fire vs thoughtful)
    final dialogFlows = _analyzeDialogFlows(conversations);
    
    // Analyze rapid-fire exchanges
    final rapidFire = _analyzeRapidFireExchanges(messages);

    return {
      'conversationDynamics': {
        'totalConversations': conversations.length,
        'averageConversationLength': conversationStats['avgLength'],
        'longestConversation': conversationStats['longest'],
        'shortestConversation': conversationStats['shortest'],
        'conversationInitiators': initiationPatterns['initiators'],
        'conversationEnders': initiationPatterns['enders'],
        'dialogFlowTypes': dialogFlows,
        'rapidFireStats': rapidFire,
        'conversationHealthScore': _calculateHealthScore(initiationPatterns, dialogFlows),
      }
    };
  }

  List<List<MessageEntity>> _identifyConversations(List<MessageEntity> messages) {
    final conversations = <List<MessageEntity>>[];
    List<MessageEntity> currentConversation = [];

    for (int i = 0; i < messages.length; i++) {
      if (currentConversation.isEmpty) {
        currentConversation.add(messages[i]);
      } else {
        final timeDiff = messages[i].timestamp.difference(currentConversation.last.timestamp);
        
        if (timeDiff.inMinutes > conversationGapMinutes) {
          // End current conversation, start new one
          if (currentConversation.isNotEmpty) {
            conversations.add(List.from(currentConversation));
          }
          currentConversation = [messages[i]];
        } else {
          currentConversation.add(messages[i]);
        }
      }
    }
    
    // Add the last conversation
    if (currentConversation.isNotEmpty) {
      conversations.add(currentConversation);
    }
    
    return conversations;
  }

  Map<String, dynamic> _analyzeInitiationPatterns(
      List<List<MessageEntity>> conversations, List<UserEntity> users) {
    
    final userIdToName = {for (var user in users) user.id: user.name};
    final Map<String, int> initiators = {};
    final Map<String, int> enders = {};

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
      }
    }

    // Convert to sorted lists
    final sortedInitiators = initiators.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final sortedEnders = enders.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'initiators': sortedInitiators.map((e) => {
        'name': e.key,
        'count': e.value,
        'percentage': ((e.value / conversations.length) * 100).toStringAsFixed(1)
      }).toList(),
      'enders': sortedEnders.map((e) => {
        'name': e.key,
        'count': e.value,
        'percentage': ((e.value / conversations.length) * 100).toStringAsFixed(1)
      }).toList(),
    };
  }

  Map<String, dynamic> _analyzeConversationStats(List<List<MessageEntity>> conversations) {
    if (conversations.isEmpty) return {'avgLength': 0, 'longest': 0, 'shortest': 0};

    final lengths = conversations.map((conv) => conv.length).toList();
    final avgLength = lengths.reduce((a, b) => a + b) / lengths.length;
    final longest = lengths.reduce(math.max);
    final shortest = lengths.reduce(math.min);

    return {
      'avgLength': avgLength.toStringAsFixed(1),
      'longest': longest,
      'shortest': shortest,
    };
  }

  Map<String, dynamic> _analyzeDialogFlows(List<List<MessageEntity>> conversations) {
    int rapidFireConversations = 0;
    int balancedConversations = 0;
    int monologueConversations = 0;
    
    final Map<String, int> flowPatterns = {};

    for (final conversation in conversations) {
      if (conversation.length < 3) continue;

      // Analyze the flow pattern
      final pattern = _getFlowPattern(conversation);
      flowPatterns[pattern] = (flowPatterns[pattern] ?? 0) + 1;

      // Categorize conversation type
      final avgGapSeconds = _getAverageResponseGap(conversation);
      final senderVariety = conversation.map((m) => m.senderId).toSet().length;
      
      if (avgGapSeconds < rapidFireSeconds) {
        rapidFireConversations++;
      } else if (senderVariety > 1 && _isBalanced(conversation)) {
        balancedConversations++;
      } else {
        monologueConversations++;
      }
    }

    return {
      'rapidFire': rapidFireConversations,
      'balanced': balancedConversations,
      'monologue': monologueConversations,
      'flowPatterns': flowPatterns,
    };
  }

  String _getFlowPattern(List<MessageEntity> conversation) {
    if (conversation.length < 3) return 'short';
    
    final senders = conversation.map((m) => m.senderId).toList();
    final pattern = StringBuffer();
    
    String? lastSender;
    int consecutiveCount = 0;
    
    for (final sender in senders) {
      if (sender == lastSender) {
        consecutiveCount++;
      } else {
        if (consecutiveCount > 0) {
          pattern.write(consecutiveCount > 2 ? 'M' : 'S'); // M=Multiple, S=Single
        }
        consecutiveCount = 1;
        lastSender = sender;
      }
    }
    
    if (consecutiveCount > 0) {
      pattern.write(consecutiveCount > 2 ? 'M' : 'S');
    }
    
    final patternStr = pattern.toString();
    
    // Classify patterns
    if (patternStr.contains('SSSSS')) return 'rapid-alternating';
    if (patternStr.contains('MMM')) return 'burst-heavy';
    if (patternStr == 'MM' || patternStr == 'M') return 'monologue';
    return 'mixed';
  }

  double _getAverageResponseGap(List<MessageEntity> conversation) {
    if (conversation.length < 2) return 0;
    
    final gaps = <int>[];
    for (int i = 1; i < conversation.length; i++) {
      final gap = conversation[i].timestamp.difference(conversation[i-1].timestamp).inSeconds;
      gaps.add(gap);
    }
    
    return gaps.isEmpty ? 0 : gaps.reduce((a, b) => a + b) / gaps.length;
  }

  bool _isBalanced(List<MessageEntity> conversation) {
    final senderCounts = <String, int>{};
    for (final msg in conversation) {
      senderCounts[msg.senderId] = (senderCounts[msg.senderId] ?? 0) + 1;
    }
    
    if (senderCounts.length < 2) return false;
    
    final counts = senderCounts.values.toList()..sort();
    final ratio = counts.last / counts.first;
    
    return ratio < 3.0; // Less than 3:1 ratio is considered balanced
  }

  Map<String, dynamic> _analyzeRapidFireExchanges(List<MessageEntity> messages) {
    int rapidFireCount = 0;
    int totalRapidMessages = 0;
    
    for (int i = 1; i < messages.length; i++) {
      final gap = messages[i].timestamp.difference(messages[i-1].timestamp).inSeconds;
      if (gap <= rapidFireSeconds && messages[i].senderId != messages[i-1].senderId) {
        rapidFireCount++;
        totalRapidMessages++;
      }
    }
    
    return {
      'rapidExchanges': rapidFireCount,
      'totalRapidMessages': totalRapidMessages,
      'rapidFirePercentage': messages.isEmpty ? 0 : 
          ((totalRapidMessages / messages.length) * 100).toStringAsFixed(1),
    };
  }

  double _calculateHealthScore(Map<String, dynamic> initiation, Map<String, dynamic> flows) {
    // Score based on balanced initiation and conversation variety
    double score = 50.0; // Base score
    
    // Check initiation balance
    final initiators = initiation['initiators'] as List;
    if (initiators.length >= 2) {
      final topPercent = double.parse(initiators[0]['percentage']);
      if (topPercent < 70) score += 20; // Balanced initiation
      if (topPercent < 60) score += 10; // Very balanced
    }
    
    // Check conversation variety
    final flowTypes = flows['flowPatterns'] as Map<String, int>;
    if (flowTypes.length > 2) score += 20; // Good variety
    
    return math.min(100.0, score);
  }

  Map<String, dynamic> _emptyResults() {
    return {
      'conversationDynamics': {
        'totalConversations': 0,
        'averageConversationLength': '0',
        'conversationInitiators': [],
        'conversationEnders': [],
        'dialogFlowTypes': {},
        'rapidFireStats': {},
        'conversationHealthScore': 0.0,
      }
    };
  }
}

// Add this class to lib/features/analysis/enhanced_analyzers.dart

class BehaviorPatternAnalyzer {
  Future<Map<String, dynamic>> analyze(ChatEntity chat) async {
    debugPrint("🧠 Analyzing behavior patterns...");
    
    final messages = chat.messages
        .where((msg) => msg.senderId != "System")
        .toList();

    if (messages.isEmpty) return _emptyResults();

    final userIdToName = {for (var user in chat.users) user.id: user.name};
    
    // Analyze time-based behavior patterns
    final timePersonalities = _analyzeTimePersonalities(messages, userIdToName);
    
    // Analyze communication consistency
    final consistencyScores = _analyzeConsistency(messages, userIdToName);
    
    // Analyze weekend vs weekday behavior
    final weekendPatterns = _analyzeWeekendBehavior(messages, userIdToName);
    
    // Analyze energy levels through message characteristics
    final energyLevels = _analyzeEnergyLevels(messages, userIdToName);
    
    // Analyze seasonal patterns if chat spans enough time
    final seasonalPatterns = _analyzeSeasonalPatterns(messages, userIdToName);
    
    // Analyze punctuation personality
    final punctuationStyles = _analyzePunctuationPersonality(messages, userIdToName);

    return {
      'behaviorPatterns': {
        'timePersonalities': timePersonalities,
        'consistencyScores': consistencyScores,
        'weekendVsWeekday': weekendPatterns,
        'energyLevels': energyLevels,
        'seasonalPatterns': seasonalPatterns,
        'punctuationStyles': punctuationStyles,
        'compatibilityScore': _calculateCompatibilityScore(timePersonalities, energyLevels),
      }
    };
  }

  Map<String, dynamic> _analyzeTimePersonalities(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    final Map<String, List<int>> userHours = {};
    
    // Collect hour data for each user
    for (final message in messages) {
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      userHours.putIfAbsent(userName, () => []);
      userHours[userName]!.add(message.timestamp.hour);
    }
    
    final Map<String, Map<String, dynamic>> personalities = {};
    
    for (final entry in userHours.entries) {
      final userName = entry.key;
      final hours = entry.value;
      
      if (hours.isEmpty) continue;
      
      // Calculate statistics
      final avgHour = hours.reduce((a, b) => a + b) / hours.length;
      final nightMessages = hours.where((h) => h >= 22 || h <= 6).length;
      final morningMessages = hours.where((h) => h >= 6 && h <= 10).length;
      final afternoonMessages = hours.where((h) => h >= 12 && h <= 17).length;
      final eveningMessages = hours.where((h) => h >= 18 && h <= 22).length;
      
      final totalMessages = hours.length;
      
      // Determine personality type
      String personality = 'Normal';
      if (nightMessages / totalMessages > 0.3) {
        personality = 'Night Owl 🦉';
      } else if (morningMessages / totalMessages > 0.4) {
        personality = 'Early Bird 🐦';
      } else if (afternoonMessages / totalMessages > 0.5) {
        personality = 'Afternoon Person ☀️';
      } else if (eveningMessages / totalMessages > 0.4) {
        personality = 'Evening Person 🌅';
      }
      
      // Find peak activity hours
      final hourCounts = <int, int>{};
      for (final hour in hours) {
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }
      
      final peakHour = hourCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      personalities[userName] = {
        'personality': personality,
        'averageHour': avgHour.toStringAsFixed(1),
        'peakHour': '$peakHour:00',
        'nightPercentage': ((nightMessages / totalMessages) * 100).toStringAsFixed(1),
        'morningPercentage': ((morningMessages / totalMessages) * 100).toStringAsFixed(1),
        'afternoonPercentage': ((afternoonMessages / totalMessages) * 100).toStringAsFixed(1),
        'eveningPercentage': ((eveningMessages / totalMessages) * 100).toStringAsFixed(1),
        'totalMessages': totalMessages,
      };
    }
    
    return personalities;
  }

  Map<String, dynamic> _analyzeConsistency(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    final Map<String, List<DateTime>> userDates = {};
    
    // Group messages by user and date
    for (final message in messages) {
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final date = DateTime(message.timestamp.year, message.timestamp.month, message.timestamp.day);
      
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
        final gap = dates[i].difference(dates[i-1]).inDays;
        gaps.add(gap);
      }
      
      final avgGap = gaps.reduce((a, b) => a + b) / gaps.length;
      final maxGap = gaps.reduce(math.max);
      final minGap = gaps.reduce(math.min);
      
      // Calculate consistency score (lower gap variance = higher consistency)
      final variance = gaps.map((g) => math.pow(g - avgGap, 2)).reduce((a, b) => a + b) / gaps.length;
      final consistencyScore = math.max(0, 100 - (variance * 2)); // Scale to 0-100
      
      String consistencyType = 'Regular';
      if (consistencyScore > 80) {
        consistencyType = 'Very Consistent 📅';
      } else if (consistencyScore > 60) {
        consistencyType = 'Moderately Consistent 📊';
      } else if (consistencyScore > 40) {
        consistencyType = 'Somewhat Sporadic 📈';
      } else {
        consistencyType = 'Very Sporadic 🎲';
      }
      
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

  Map<String, dynamic> _analyzeWeekendBehavior(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    final Map<String, Map<String, int>> userDayStats = {};
    
    for (final message in messages) {
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final isWeekend = message.timestamp.weekday >= 6; // Saturday = 6, Sunday = 7
      
      userDayStats.putIfAbsent(userName, () => {'weekday': 0, 'weekend': 0});
      
      if (isWeekend) {
        userDayStats[userName]!['weekend'] = userDayStats[userName]!['weekend']! + 1;
      } else {
        userDayStats[userName]!['weekday'] = userDayStats[userName]!['weekday']! + 1;
      }
    }
    
    final Map<String, Map<String, dynamic>> weekendPatterns = {};
    
    for (final entry in userDayStats.entries) {
      final userName = entry.key;
      final stats = entry.value;
      
      final weekdayCount = stats['weekday']!;
      final weekendCount = stats['weekend']!;
      final total = weekdayCount + weekendCount;
      
      if (total == 0) continue;
      
      final weekendPercentage = (weekendCount / total) * 100;
      
      String pattern = 'Balanced';
      if (weekendPercentage > 35) {
        pattern = 'Weekend Warrior 🎉';
      } else if (weekendPercentage < 20) {
        pattern = 'Weekday Focused 💼';
      }
      
      weekendPatterns[userName] = {
        'pattern': pattern,
        'weekendPercentage': weekendPercentage.toStringAsFixed(1),
        'weekdayCount': weekdayCount,
        'weekendCount': weekendCount,
      };
    }
    
    return weekendPatterns;
  }

  Map<String, dynamic> _analyzeEnergyLevels(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    final Map<String, List<Map<String, dynamic>>> userMessageData = {};
    
    // Collect message characteristics for each user
    for (final message in messages) {
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      
      userMessageData.putIfAbsent(userName, () => []);
      
      final content = message.content;
      final exclamationCount = content.split('!').length - 1;
      final capsCount = content.split('').where((c) => c == c.toUpperCase() && c != c.toLowerCase()).length;
      final questionCount = content.split('?').length - 1;
      
      userMessageData[userName]!.add({
        'length': content.length,
        'exclamations': exclamationCount,
        'caps': capsCount,
        'questions': questionCount,
        'hour': message.timestamp.hour,
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
      
      String energyType = 'Moderate Energy';
      if (energyScore > 80) {
        energyType = 'High Energy ⚡';
      } else if (energyScore > 60) {
        energyType = 'Good Energy 🔋';
      } else if (energyScore < 40) {
        energyType = 'Calm Energy 😌';
      }
      
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

  Map<String, dynamic> _analyzeSeasonalPatterns(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    if (messages.isEmpty) return {};
    
    final firstDate = messages.first.timestamp;
    final lastDate = messages.last.timestamp;
    final daySpan = lastDate.difference(firstDate).inDays;
    
    // Only analyze if we have enough data (at least 90 days)
    if (daySpan < 90) {
      return {'message': 'Not enough data for seasonal analysis (need 90+ days)'};
    }
    
    final Map<String, Map<int, int>> userMonthStats = {};
    
    for (final message in messages) {
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final month = message.timestamp.month;
      
      userMonthStats.putIfAbsent(userName, () => {});
      userMonthStats[userName]![month] = (userMonthStats[userName]![month] ?? 0) + 1;
    }
    
    final Map<String, Map<String, dynamic>> seasonalPatterns = {};
    final monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    for (final entry in userMonthStats.entries) {
      final userName = entry.key;
      final monthStats = entry.value;
      
      if (monthStats.isEmpty) continue;
      
      // Find peak and low months
      final sortedMonths = monthStats.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final peakMonth = sortedMonths.first;
      final lowMonth = sortedMonths.last;
      
      seasonalPatterns[userName] = {
        'peakMonth': monthNames[peakMonth.key],
        'peakCount': peakMonth.value,
        'lowMonth': monthNames[lowMonth.key],
        'lowCount': lowMonth.value,
        'monthlyStats': {for (var e in monthStats.entries) monthNames[e.key]: e.value},
      };
    }
    
    return seasonalPatterns;
  }

  Map<String, dynamic> _analyzePunctuationPersonality(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    final Map<String, Map<String, int>> userPunctuation = {};
    
    for (final message in messages) {
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final content = message.content;
      
      userPunctuation.putIfAbsent(userName, () => {
        'periods': 0,
        'exclamations': 0,
        'questions': 0,
        'ellipsis': 0,
        'totalMessages': 0,
      });
      
      userPunctuation[userName]!['periods'] = userPunctuation[userName]!['periods']! + (content.split('.').length - 1);
      userPunctuation[userName]!['exclamations'] = userPunctuation[userName]!['exclamations']! + (content.split('!').length - 1);
      userPunctuation[userName]!['questions'] = userPunctuation[userName]!['questions']! + (content.split('?').length - 1);
      userPunctuation[userName]!['ellipsis'] = userPunctuation[userName]!['ellipsis']! + content.split('...').length - 1;
      userPunctuation[userName]!['totalMessages'] = userPunctuation[userName]!['totalMessages']! + 1;
    }
    
    final Map<String, Map<String, dynamic>> personalities = {};
    
    for (final entry in userPunctuation.entries) {
      final userName = entry.key;
      final stats = entry.value;
      final totalMessages = stats['totalMessages']!;
      
      if (totalMessages == 0) continue;
      
      final exclamationRatio = stats['exclamations']! / totalMessages;
      final questionRatio = stats['questions']! / totalMessages;
      final ellipsisRatio = stats['ellipsis']! / totalMessages;
      
      String personality = 'Neutral';
      if (exclamationRatio > 0.5) {
        personality = 'Enthusiastic! 🎉';
      } else if (questionRatio > 0.3) {
        personality = 'Curious? 🤔';
      } else if (ellipsisRatio > 0.2) {
        personality = 'Thoughtful... 💭';
      } else if (exclamationRatio < 0.1 && questionRatio < 0.1) {
        personality = 'Straightforward. 📝';
      }
      
      personalities[userName] = {
        'personality': personality,
        'exclamationsPerMessage': exclamationRatio.toStringAsFixed(2),
        'questionsPerMessage': questionRatio.toStringAsFixed(2),
        'ellipsisPerMessage': ellipsisRatio.toStringAsFixed(2),
      };
    }
    
    return personalities;
  }

  double _calculateCompatibilityScore(
      Map<String, dynamic> timePersonalities, 
      Map<String, dynamic> energyLevels) {
    
    if (timePersonalities.length < 2 || energyLevels.length < 2) {
      return 50.0; // Neutral score for single user
    }
    
    double score = 50.0;
    
    // Check time compatibility
    final personalities = timePersonalities.values.toList();
    final energies = energyLevels.values.toList();
    
    // If both are night owls or both are early birds = +20
    final timeTypes = personalities.map((p) => p['personality'].toString()).toList();
    if (timeTypes.every((t) => t.contains('Night Owl')) ||
        timeTypes.every((t) => t.contains('Early Bird'))) {
      score += 20;
    }
    
    // Check energy level compatibility
    final energyScores = energies.map((e) => double.parse(e['energyScore'])).toList();
    final energyDiff = (energyScores.first - energyScores.last).abs();
    
    if (energyDiff < 20) score += 20; // Similar energy levels
    if (energyDiff < 10) score += 10; // Very similar energy levels
    
    return math.min(100.0, score);
  }

  Map<String, dynamic> _emptyResults() {
    return {
      'behaviorPatterns': {
        'timePersonalities': {},
        'consistencyScores': {},
        'weekendVsWeekday': {},
        'energyLevels': {},
        'seasonalPatterns': {},
        'punctuationStyles': {},
        'compatibilityScore': 0.0,
      }
    };
  }
}

// Add this class to lib/features/analysis/enhanced_analyzers.dart

class RelationshipAnalyzer {
  Future<Map<String, dynamic>> analyze(ChatEntity chat) async {
    debugPrint("💕 Analyzing relationship dynamics...");
    
    final messages = chat.messages
        .where((msg) => msg.senderId != "System")
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (messages.isEmpty) return _emptyResults();

    final userIdToName = {for (var user in chat.users) user.id: user.name};
    
    // Analyze communication reciprocity (who responds to whom)
    final reciprocityPatterns = _analyzeReciprocity(messages, userIdToName);
    
    // Analyze conversation balance (one-sided vs mutual)
    final balanceAnalysis = _analyzeConversationBalance(messages, userIdToName);
    
    // Analyze response patterns (who responds more/less)
    final responsePatterns = _analyzeResponsePatterns(messages, userIdToName);
    
    // Analyze support patterns (who asks questions vs who helps)
    final supportPatterns = _analyzeSupportPatterns(messages, userIdToName);
    
    // Analyze topic control (who changes subjects)
    final topicControl = _analyzeTopicControl(messages, userIdToName);
    
    // Analyze emotional dynamics through message patterns
    final emotionalDynamics = _analyzeEmotionalDynamics(messages, userIdToName);
    
    // Calculate overall relationship health score
    final healthScore = _calculateRelationshipHealth(
      reciprocityPatterns, balanceAnalysis, responsePatterns);

    return {
      'relationshipDynamics': {
        'reciprocityPatterns': reciprocityPatterns,
        'conversationBalance': balanceAnalysis,
        'responsePatterns': responsePatterns,
        'supportPatterns': supportPatterns,
        'topicControl': topicControl,
        'emotionalDynamics': emotionalDynamics,
        'relationshipHealthScore': healthScore,
      }
    };
  }

  Map<String, dynamic> _analyzeReciprocity(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    final Map<String, Map<String, int>> userResponses = {};
    final Map<String, int> totalMessages = {};
    
    // Initialize maps
    for (final userId in userIdToName.keys) {
      final userName = userIdToName[userId]!;
      userResponses[userName] = {};
      totalMessages[userName] = 0;
    }
    
    // Analyze who responds to whom (based on consecutive messages)
    for (int i = 1; i < messages.length; i++) {
      final currentMsg = messages[i];
      final previousMsg = messages[i - 1];
      
      // Skip if same sender (not a response)
      if (currentMsg.senderId == previousMsg.senderId) continue;
      
      final responderName = userIdToName[currentMsg.senderId] ?? 'Unknown';
      final originalSenderName = userIdToName[previousMsg.senderId] ?? 'Unknown';
      
      // Check if it's a reasonable response time (within 2 hours)
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
      
      // Calculate response rate (responses given / total messages received from others)
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
        'responsesBreakdown': responses,
      };
    }
    
    return reciprocityScores;
  }

  Map<String, dynamic> _analyzeConversationBalance(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    // Identify conversation threads (messages within 30 minutes)
    final conversations = <List<MessageEntity>>[];
    List<MessageEntity> currentConv = [];
    
    for (int i = 0; i < messages.length; i++) {
      if (currentConv.isEmpty) {
        currentConv.add(messages[i]);
      } else {
        final timeDiff = messages[i].timestamp.difference(currentConv.last.timestamp);
        if (timeDiff.inMinutes > 30) {
          if (currentConv.length > 1) conversations.add(List.from(currentConv));
          currentConv = [messages[i]];
        } else {
          currentConv.add(messages[i]);
        }
      }
    }
    if (currentConv.length > 1) conversations.add(currentConv);
    
    // Analyze balance in each conversation
    int balancedConversations = 0;
    int oneSidedConversations = 0;
    final Map<String, int> dominantSpeaker = {};
    
    for (final conv in conversations) {
      final userMessageCounts = <String, int>{};
      
      for (final msg in conv) {
        final userName = userIdToName[msg.senderId] ?? 'Unknown';
        userMessageCounts[userName] = (userMessageCounts[userName] ?? 0) + 1;
      }
      
      if (userMessageCounts.length < 2) continue;
      
      // Calculate balance ratio
      final counts = userMessageCounts.values.toList()..sort((a, b) => b.compareTo(a));
      final balanceRatio = counts.first / counts.last;
      
      if (balanceRatio <= 2.0) {
        balancedConversations++;
      } else {
        oneSidedConversations++;
        
        // Find who dominates
        final dominant = userMessageCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        dominantSpeaker[dominant] = (dominantSpeaker[dominant] ?? 0) + 1;
      }
    }
    
    final totalAnalyzedConversations = balancedConversations + oneSidedConversations;
    final balancePercentage = totalAnalyzedConversations > 0 
        ? (balancedConversations / totalAnalyzedConversations) * 100 
        : 0.0;
    
    // Determine balance type
    String balanceType = 'Balanced Communication 🤝';
    if (balancePercentage < 30) {
      balanceType = 'Often One-sided 📢';
    } else if (balancePercentage < 60) {
      balanceType = 'Moderately Balanced ⚖️';
    }
    
    return {
      'balanceType': balanceType,
      'balancePercentage': balancePercentage.toStringAsFixed(1),
      'balancedConversations': balancedConversations,
      'oneSidedConversations': oneSidedConversations,
      'dominantSpeakers': dominantSpeaker,
    };
  }

  Map<String, dynamic> _analyzeResponsePatterns(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    final Map<String, List<Duration>> userResponseTimes = {};
    final Map<String, int> userResponses = {};
    final Map<String, int> userIgnored = {};
    
    for (int i = 1; i < messages.length; i++) {
      final currentMsg = messages[i];
      final previousMsg = messages[i - 1];
      
      // Skip if same sender
      if (currentMsg.senderId == previousMsg.senderId) continue;
      
      final responderName = userIdToName[currentMsg.senderId] ?? 'Unknown';
      final originalSenderName = userIdToName[previousMsg.senderId] ?? 'Unknown';
      
      final responseTime = currentMsg.timestamp.difference(previousMsg.timestamp);
      
      // Only count as response if within reasonable time (24 hours)
      if (responseTime.inHours <= 24) {
        userResponseTimes.putIfAbsent(responderName, () => []);
        userResponseTimes[responderName]!.add(responseTime);
        
        userResponses[responderName] = (userResponses[responderName] ?? 0) + 1;
      } else {
        // Might be ignored
        userIgnored[originalSenderName] = (userIgnored[originalSenderName] ?? 0) + 1;
      }
    }
    
    final Map<String, Map<String, dynamic>> responseProfiles = {};
    
    for (final userName in userIdToName.values) {
      final responseTimes = userResponseTimes[userName] ?? [];
      final responseCount = userResponses[userName] ?? 0;
      final ignoredCount = userIgnored[userName] ?? 0;
      
      if (responseTimes.isEmpty) {
        responseProfiles[userName] = {
          'profile': 'Silent Type 🤐',
          'avgResponseTime': 'N/A',
          'responseCount': 0,
          'responsiveness': 'Low',
        };
        continue;
      }
      
      // Calculate average response time
      final avgSeconds = responseTimes
          .map((d) => d.inSeconds)
          .reduce((a, b) => a + b) / responseTimes.length;
      
      final avgDuration = Duration(seconds: avgSeconds.round());
      
      // Categorize response speed
      String profile = 'Normal Responder 💬';
      String responsiveness = 'Moderate';
      
      if (avgDuration.inMinutes < 5) {
        profile = 'Lightning Fast ⚡';
        responsiveness = 'Very High';
      } else if (avgDuration.inMinutes < 30) {
        profile = 'Quick Responder 🏃';
        responsiveness = 'High';
      } else if (avgDuration.inHours < 2) {
        profile = 'Steady Responder 🚶';
        responsiveness = 'Good';
      } else if (avgDuration.inHours < 12) {
        profile = 'Thoughtful Responder 🤔';
        responsiveness = 'Moderate';  
      } else {
        profile = 'Takes Their Time ⏰';
        responsiveness = 'Low';
      }
      
      responseProfiles[userName] = {
        'profile': profile,
        'avgResponseTime': _formatDuration(avgDuration),
        'responseCount': responseCount,
        'responsiveness': responsiveness,
        'fastestResponse': _formatDuration(responseTimes.reduce((a, b) => a < b ? a : b)),
        'slowestResponse': _formatDuration(responseTimes.reduce((a, b) => a > b ? a : b)),
      };
    }
    
    return responseProfiles;
  }

  Map<String, dynamic> _analyzeSupportPatterns(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    final Map<String, int> questionAskers = {};
    final Map<String, int> helpProviders = {};
    final Map<String, int> supportGivers = {};
    final Map<String, int> encouragers = {};
    
    // Keywords that indicate different support types
    final helpKeywords = ['how', 'help', 'can you', 'please', 'need', 'problem'];
    final supportKeywords = ['sorry', 'there for you', 'support', 'understand', 'feel'];
    final encouragementKeywords = ['great', 'awesome', 'good job', 'well done', 'proud', 'amazing'];
    
    for (final message in messages) {
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final content = message.content.toLowerCase();
      
      // Count questions (messages ending with ?)
      if (content.endsWith('?') || content.contains('?')) {
        questionAskers[userName] = (questionAskers[userName] ?? 0) + 1;
      }
      
      // Check for help-related content
      if (helpKeywords.any((keyword) => content.contains(keyword))) {
        helpProviders[userName] = (helpProviders[userName] ?? 0) + 1;
      }
      
      // Check for emotional support
      if (supportKeywords.any((keyword) => content.contains(keyword))) {
        supportGivers[userName] = (supportGivers[userName] ?? 0) + 1;
      }
      
      // Check for encouragement
      if (encouragementKeywords.any((keyword) => content.contains(keyword))) {
        encouragers[userName] = (encouragers[userName] ?? 0) + 1;
      }
    }
    
    // Create support profiles
    final Map<String, Map<String, dynamic>> supportProfiles = {};
    
    for (final userName in userIdToName.values) {
      final questions = questionAskers[userName] ?? 0;
      final helpGiven = helpProviders[userName] ?? 0;
      final supportGiven = supportGivers[userName] ?? 0;
      final encouragementGiven = encouragers[userName] ?? 0;
      
      final totalSupportive = helpGiven + supportGiven + encouragementGiven;
      
      String supportType = 'Neutral';
      if (questions > totalSupportive * 2) {
        supportType = 'Question Asker 🤔';
      } else if (helpGiven > questions && helpGiven > supportGiven) {
        supportType = 'Problem Solver 🔧';
      } else if (supportGiven > helpGiven && supportGiven > encouragementGiven) {
        supportType = 'Emotional Supporter 💙';
      } else if (encouragementGiven > helpGiven && encouragementGiven > supportGiven) {
        supportType = 'Cheerleader 📣';
      } else if (totalSupportive > questions) {
        supportType = 'Helper 🤝';
      }
      
      supportProfiles[userName] = {
        'supportType': supportType,
        'questionsAsked': questions,
        'helpProvided': helpGiven,
        'emotionalSupport': supportGiven,
        'encouragement': encouragementGiven,
        'supportScore': totalSupportive,
      };
    }
    
    return supportProfiles;
  }

  Map<String, dynamic> _analyzeTopicControl(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    final Map<String, int> topicShifts = {};
    final Map<String, int> conversationStarters = {};
    
    // Simple topic shift detection (very basic - could be enhanced)
    final topicWords = ['anyway', 'btw', 'by the way', 'speaking of', 'oh', 'also', 'but'];
    
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final content = message.content.toLowerCase();
      
      // Check for topic shift indicators
      if (topicWords.any((word) => content.startsWith(word) || content.contains(' $word '))) {
        topicShifts[userName] = (topicShifts[userName] ?? 0) + 1;
      }
      
      // Check if this starts a new conversation (after long gap)
      if (i == 0 || (i > 0 && 
          message.timestamp.difference(messages[i-1].timestamp).inHours > 2)) {
        conversationStarters[userName] = (conversationStarters[userName] ?? 0) + 1;
      }
    }
    
    final Map<String, Map<String, dynamic>> topicControl = {};
    
    for (final userName in userIdToName.values) {
      final shifts = topicShifts[userName] ?? 0;
      final starts = conversationStarters[userName] ?? 0;
      final controlScore = shifts + (starts * 2); // Weight conversation starts more
      
      String controlType = 'Follower';
      if (controlScore > 10) {
        controlType = 'Topic Leader 🎯';
      } else if (controlScore > 5) {
        controlType = 'Active Participant 💬';
      } else if (starts > shifts) {
        controlType = 'Conversation Starter 🚀';
      }
      
      topicControl[userName] = {
        'controlType': controlType,
        'topicShifts': shifts,
        'conversationStarts': starts,
        'controlScore': controlScore,
      };
    }
    
    return topicControl;
  }

  Map<String, dynamic> _analyzeEmotionalDynamics(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    final Map<String, Map<String, int>> emotionalPatterns = {};
    
    // Simple emotion detection based on patterns
    final positiveWords = ['love', 'happy', 'great', 'awesome', 'good', 'nice', 'thanks', 'lol', 'haha'];
    final negativeWords = ['sad', 'bad', 'terrible', 'awful', 'hate', 'angry', 'mad', 'upset'];
    final supportiveWords = ['sorry', 'hope', 'there for you', 'understand', 'care'];
    
    for (final message in messages) {
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
    
    final Map<String, Map<String, dynamic>> emotionalProfiles = {};
    
    for (final entry in emotionalPatterns.entries) {
      final userName = entry.key;
      final patterns = entry.value;
      
      final total = patterns.values.reduce((a, b) => a + b);
      if (total == 0) continue;
      
      final positivePercent = (patterns['positive']! / total) * 100;
      final negativePercent = (patterns['negative']! / total) * 100;
      final supportivePercent = (patterns['supportive']! / total) * 100;
      
      String emotionalType = 'Neutral';
      if (positivePercent > 30) {
        emotionalType = 'Positive Vibes ✨';
      } else if (supportivePercent > 20) {
        emotionalType = 'Supportive Soul 💙';
      } else if (negativePercent > 20) {
        emotionalType = 'Expressive 😤';
      } else if (positivePercent > negativePercent) {
        emotionalType = 'Generally Positive 😊';
      }
      
      emotionalProfiles[userName] = {
        'emotionalType': emotionalType,
        'positivePercentage': positivePercent.toStringAsFixed(1),
        'negativePercentage': negativePercent.toStringAsFixed(1),
        'supportivePercentage': supportivePercent.toStringAsFixed(1),
        'totalEmotionalMessages': total - patterns['neutral']!,
      };
    }
    
    return emotionalProfiles;
  }

  double _calculateRelationshipHealth(
      Map<String, dynamic> reciprocity,
      Map<String, dynamic> balance,
      Map<String, dynamic> responses) {
    
    double score = 50.0; // Base score
    
    // Check reciprocity balance
    if (reciprocity.isNotEmpty) {
      final responseRates = reciprocity.values
          .map((user) => double.tryParse(user['responseRate']) ?? 0.0)
          .toList();
      
      if (responseRates.isNotEmpty) {
        final avgResponseRate = responseRates.reduce((a, b) => a + b) / responseRates.length;
        if (avgResponseRate > 50) score += 20; // Good reciprocity
        if (avgResponseRate > 70) score += 10; // Excellent reciprocity
      }
    }
    
    // Check conversation balance
    final balancePercentage = double.tryParse(balance['balancePercentage'] ?? '0') ?? 0.0;
    if (balancePercentage > 60) score += 15; // Well balanced
    if (balancePercentage > 80) score += 10; // Very balanced
    
    // Check response patterns diversity
    if (responses.length > 1) {
      score += 15; // Multiple people responding
    }
    
    return math.min(100.0, score);
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  Map<String, dynamic> _emptyResults() {
    return {
      'relationshipDynamics': {
        'reciprocityPatterns': {},
        'conversationBalance': {},
        'responsePatterns': {},
        'supportPatterns': {},
        'topicControl': {},
        'emotionalDynamics': {},
        'relationshipHealthScore': 0.0,
      }
    };
  }
}

// Add this class to lib/features/analysis/enhanced_analyzers.dart

class ContentIntelligenceAnalyzer {
  Future<Map<String, dynamic>> analyze(ChatEntity chat) async {
    debugPrint("🧠 Analyzing content intelligence patterns...");
    
    final messages = chat.messages
        .where((msg) => msg.senderId != "System" && msg.type == MessageType.text)
        .toList();

    if (messages.isEmpty) return _emptyResults();

    final userIdToName = {for (var user in chat.users) user.id: user.name};
    
    // Analyze question vs statement patterns
    final questionStatementPatterns = _analyzeQuestionStatementPatterns(messages, userIdToName);
    
    // Analyze communication style (caps, punctuation, etc.)
    final communicationStyles = _analyzeCommunicationStyles(messages, userIdToName);
    
    // Analyze vocabulary complexity and richness
    final vocabularyAnalysis = _analyzeVocabularyComplexity(messages, userIdToName);
    
    // Analyze language patterns and preferences
    final languagePatterns = _analyzeLanguagePatterns(messages, userIdToName);
    
    // Analyze link sharing and information sharing behavior
    final informationSharing = _analyzeInformationSharing(messages, userIdToName);
    
    // Analyze conversation thread patterns
    final threadPatterns = _analyzeConversationThreads(messages, userIdToName);
    
    // Calculate overall communication intelligence score
    final intelligenceScores = _calculateIntelligenceScores(
      vocabularyAnalysis, questionStatementPatterns, informationSharing);

    return {
      'contentIntelligence': {
        'questionStatementPatterns': questionStatementPatterns,
        'communicationStyles': communicationStyles,
        'vocabularyAnalysis': vocabularyAnalysis,
        'languagePatterns': languagePatterns,
        'informationSharing': informationSharing,
        'threadPatterns': threadPatterns,
        'intelligenceScores': intelligenceScores,
      }
    };
  }

  Map<String, dynamic> _analyzeQuestionStatementPatterns(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    final Map<String, Map<String, int>> userPatterns = {};
    
    // Question words and patterns
    final questionStarters = ['what', 'how', 'when', 'where', 'why', 'who', 'which', 'can', 'could', 'would', 'should', 'do', 'does', 'did', 'is', 'are', 'was', 'were'];
    
    for (final message in messages) {
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final content = message.content.toLowerCase().trim();
      
      userPatterns.putIfAbsent(userName, () => {
        'questions': 0,
        'statements': 0,
        'exclamations': 0,
        'commands': 0,
        'total': 0,
      });
      
      userPatterns[userName]!['total'] = userPatterns[userName]!['total']! + 1;
      
      if (content.endsWith('?') || content.contains('?')) {
        userPatterns[userName]!['questions'] = userPatterns[userName]!['questions']! + 1;
      } else if (content.endsWith('!') || content.contains('!')) {
        userPatterns[userName]!['exclamations'] = userPatterns[userName]!['exclamations']! + 1;
      } else if (questionStarters.any((starter) => content.startsWith(starter))) {
        // Implicit questions
        userPatterns[userName]!['questions'] = userPatterns[userName]!['questions']! + 1;
      } else if (_isCommand(content)) {
        userPatterns[userName]!['commands'] = userPatterns[userName]!['commands']! + 1;
      } else {
        userPatterns[userName]!['statements'] = userPatterns[userName]!['statements']! + 1;
      }
    }
    
    final Map<String, Map<String, dynamic>> communicationProfiles = {};
    
    for (final entry in userPatterns.entries) {
      final userName = entry.key;
      final patterns = entry.value;
      final total = patterns['total']!;
      
      if (total == 0) continue;
      
      final questionPercent = (patterns['questions']! / total) * 100;
      final statementPercent = (patterns['statements']! / total) * 100;
      final exclamationPercent = (patterns['exclamations']! / total) * 100;
      final commandPercent = (patterns['commands']! / total) * 100;
      
      // Determine communication type
      String communicationType = 'Balanced Communicator 💬';
      if (questionPercent > 40) {
        communicationType = 'Curious Explorer 🤔';
      } else if (statementPercent > 60) {
        communicationType = 'Information Sharer 📝';
      } else if (exclamationPercent > 30) {
        communicationType = 'Enthusiastic Expresser 🎉';
      } else if (commandPercent > 20) {
        communicationType = 'Action Oriented 🎯';
      } else if (questionPercent > 25 && statementPercent > 35) {
        communicationType = 'Thoughtful Conversationalist 💭';
      }
      
      communicationProfiles[userName] = {
        'type': communicationType,
        'questionPercentage': questionPercent.toStringAsFixed(1),
        'statementPercentage': statementPercent.toStringAsFixed(1),
        'exclamationPercentage': exclamationPercent.toStringAsFixed(1),
        'commandPercentage': commandPercent.toStringAsFixed(1),
        'totalMessages': total,
      };
    }
    
    return communicationProfiles;
  }

  bool _isCommand(String content) {
    final commandWords = ['go', 'come', 'stop', 'wait', 'look', 'check', 'try', 'get', 'take', 'give', 'send', 'call', 'text'];
    final words = content.split(' ');
    return words.isNotEmpty && commandWords.contains(words.first);
  }

  Map<String, dynamic> _analyzeCommunicationStyles(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    final Map<String, Map<String, dynamic>> userStyles = {};
    
    for (final message in messages) {
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final content = message.content;
      
      userStyles.putIfAbsent(userName, () => {
        'totalChars': 0,
        'totalMessages': 0,
        'capsCount': 0,
        'exclamationCount': 0,
        'ellipsisCount': 0,
        'emojiCount': 0,
        'abbreviationCount': 0,
        'longMessages': 0,
        'shortMessages': 0,
      });
      
      final style = userStyles[userName]!;
      style['totalChars'] = (style['totalChars'] as int) + content.length;
      style['totalMessages'] = (style['totalMessages'] as int) + 1;
      
      // Count CAPS usage
      final capsChars = content.split('').where((c) => c == c.toUpperCase() && c != c.toLowerCase()).length;
      style['capsCount'] = (style['capsCount'] as int) + capsChars;
      
      // Count punctuation
      style['exclamationCount'] = (style['exclamationCount'] as int) + (content.split('!').length - 1);
      style['ellipsisCount'] = (style['ellipsisCount'] as int) + (content.split('...').length - 1);
      
      // Count emojis (basic pattern)
      final emojiPattern = RegExp(r'[\u{1F600}-\u{1F64F}|\u{1F300}-\u{1F5FF}|\u{1F680}-\u{1F6FF}|\u{2600}-\u{26FF}|\u{2700}-\u{27BF}]', unicode: true);
      style['emojiCount'] = (style['emojiCount'] as int) + emojiPattern.allMatches(content).length;
      
      // Count abbreviations (basic detection)
      final abbreviations = ['lol', 'omg', 'btw', 'fyi', 'imo', 'tbh', 'ngl', 'rn', 'bc', 'u', 'ur', 'n'];
      final lowerContent = content.toLowerCase();
      for (final abbr in abbreviations) {
        if (lowerContent.contains(abbr)) {
          style['abbreviationCount'] = (style['abbreviationCount'] as int) + 1;
          break; // Count once per message
        }
      }
      
      // Message length categorization
      if (content.length > 100) {
        style['longMessages'] = (style['longMessages'] as int) + 1;
      } else if (content.length < 20) {
        style['shortMessages'] = (style['shortMessages'] as int) + 1;
      }
    }
    
    final Map<String, Map<String, dynamic>> styleProfiles = {};
    
    for (final entry in userStyles.entries) {
      final userName = entry.key;
      final style = entry.value;
      final totalMessages = style['totalMessages'] as int;
      final totalChars = style['totalChars'] as int;
      
      if (totalMessages == 0) continue;
      
      final avgMessageLength = totalChars / totalMessages;
      final capsPercentage = totalChars > 0 ? ((style['capsCount'] as int) / totalChars) * 100 : 0.0;
      final emojiPerMessage = (style['emojiCount'] as int) / totalMessages;
      final exclamationPerMessage = (style['exclamationCount'] as int) / totalMessages;
      
      // Determine style type
      String styleType = 'Standard Writer 📝';
      if (capsPercentage > 15) {
        styleType = 'CAPS ENTHUSIAST 📢';
      } else if (emojiPerMessage > 1) {
        styleType = 'Emoji Lover 😍';
      } else if (exclamationPerMessage > 0.5) {
        styleType = 'Excitement Master! 🎉';
      } else if (avgMessageLength > 150) {
        styleType = 'Detailed Storyteller 📚';
      } else if (avgMessageLength < 25) {
        styleType = 'Concise Communicator 💬';
      } else if ((style['abbreviationCount'] as int) / totalMessages > 0.3) {
        styleType = 'Abbreviation Expert 📱';
      } else if ((style['ellipsisCount'] as int) / totalMessages > 0.2) {
        styleType = 'Thoughtful Pauser... 💭';
      }
      
      styleProfiles[userName] = {
        'styleType': styleType,
        'avgMessageLength': avgMessageLength.toStringAsFixed(1),
        'capsPercentage': capsPercentage.toStringAsFixed(1),
        'emojisPerMessage': emojiPerMessage.toStringAsFixed(2),
        'exclamationsPerMessage': exclamationPerMessage.toStringAsFixed(2),
        'longMessagePercentage': ((style['longMessages'] as int) / totalMessages * 100).toStringAsFixed(1),
        'shortMessagePercentage': ((style['shortMessages'] as int) / totalMessages * 100).toStringAsFixed(1),
      };
    }
    
    return styleProfiles;
  }

  Map<String, dynamic> _analyzeVocabularyComplexity(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    final Map<String, Set<String>> userVocabulary = {};
    final Map<String, List<int>> userWordLengths = {};
    final Map<String, int> userTotalWords = {};
    
    // Common words to filter out for complexity analysis
    final commonWords = {
      'the', 'be', 'to', 'of', 'and', 'a', 'in', 'that', 'have', 'i', 'it', 'for', 
      'not', 'on', 'with', 'he', 'as', 'you', 'do', 'at', 'this', 'but', 'his', 
      'by', 'from', 'they', 'we', 'say', 'her', 'she', 'or', 'an', 'will', 'my',
      'one', 'all', 'would', 'there', 'their', 'what', 'so', 'up', 'out', 'if',
      'about', 'who', 'get', 'which', 'go', 'me', 'when', 'make', 'can', 'like',
      'time', 'no', 'just', 'him', 'know', 'take', 'people', 'into', 'year',
      'your', 'good', 'some', 'could', 'them', 'see', 'other', 'than', 'then',
      'now', 'look', 'only', 'come', 'its', 'also', 'back', 'after', 'use',
      'two', 'how', 'our', 'work', 'first', 'well', 'way', 'even', 'new',
      'want', 'because', 'any', 'these', 'give', 'day', 'most', 'us'
    };
    
    for (final message in messages) {
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final content = message.content.toLowerCase();
      
      // Extract words (remove punctuation)
      final words = content
          .replaceAll(RegExp(r'[^\w\s]'), ' ')
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty && word.length > 1)
          .toList();
      
      userVocabulary.putIfAbsent(userName, () => <String>{});
      userWordLengths.putIfAbsent(userName, () => []);
      userTotalWords.putIfAbsent(userName, () => 0);
      
      for (final word in words) {
        userVocabulary[userName]!.add(word);
        userWordLengths[userName]!.add(word.length);
        userTotalWords[userName] = userTotalWords[userName]! + 1;
      }
    }
    
    final Map<String, Map<String, dynamic>> vocabularyProfiles = {};
    
    for (final userName in userIdToName.values) {
      final vocabulary = userVocabulary[userName] ?? <String>{};
      final wordLengths = userWordLengths[userName] ?? [];
      final totalWords = userTotalWords[userName] ?? 0;
      
      if (totalWords == 0) continue;
      
      // Calculate vocabulary richness
      final uniqueWords = vocabulary.length;
      final vocabularyRichness = uniqueWords / totalWords; // Type-Token Ratio
      
      // Calculate average word length
      final avgWordLength = wordLengths.isEmpty ? 0.0 : 
          wordLengths.reduce((a, b) => a + b) / wordLengths.length;
      
      // Count complex words (>6 letters, not common)
      final complexWords = vocabulary
          .where((word) => word.length > 6 && !commonWords.contains(word))
          .length;
      
      final complexWordRatio = uniqueWords > 0 ? complexWords / uniqueWords : 0.0;
      
      // Calculate complexity score
      double complexityScore = 0;
      complexityScore += vocabularyRichness * 100; // Vocabulary diversity
      complexityScore += avgWordLength * 10; // Word length
      complexityScore += complexWordRatio * 50; // Complex word usage
      
      complexityScore = math.min(100, complexityScore);
      
      // Determine vocabulary type
      String vocabularyType = 'Standard Vocabulary 📝';
      if (complexityScore > 80) {
        vocabularyType = 'Sophisticated Speaker 🎓';
      } else if (complexityScore > 65) {
        vocabularyType = 'Articulate Communicator 💬';
      } else if (complexityScore > 50) {
        vocabularyType = 'Clear Expresser 🗣️';
      } else if (vocabularyRichness > 0.6) {
        vocabularyType = 'Varied Vocabulary 📚';
      } else if (avgWordLength < 4) {
        vocabularyType = 'Simple & Direct 🎯';
      }
      
      vocabularyProfiles[userName] = {
        'vocabularyType': vocabularyType,
        'complexityScore': complexityScore.toStringAsFixed(1),
        'uniqueWords': uniqueWords,
        'totalWords': totalWords,
        'vocabularyRichness': (vocabularyRichness * 100).toStringAsFixed(1),
        'avgWordLength': avgWordLength.toStringAsFixed(1),
        'complexWords': complexWords,
        'complexWordPercentage': (complexWordRatio * 100).toStringAsFixed(1),
      };
    }
    
    return vocabularyProfiles;
  }

  Map<String, dynamic> _analyzeLanguagePatterns(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    final Map<String, Map<String, int>> userPatterns = {};
    
    // Language pattern indicators
    final formalWords = ['however', 'therefore', 'furthermore', 'moreover', 'nevertheless', 'consequently'];
    final casualWords = ['yeah', 'yep', 'nah', 'gonna', 'wanna', 'kinda', 'sorta'];
    final fillerWords = ['like', 'um', 'uh', 'you know', 'i mean', 'basically', 'actually'];
    final intensifiers = ['very', 'really', 'extremely', 'totally', 'absolutely', 'definitely'];
    
    for (final message in messages) {
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final content = message.content.toLowerCase();
      
      userPatterns.putIfAbsent(userName, () => {
        'formal': 0,
        'casual': 0,
        'filler': 0,
        'intensifier': 0,
        'totalMessages': 0,
      });
      
      userPatterns[userName]!['totalMessages'] = userPatterns[userName]!['totalMessages']! + 1;
      
      // Check for formal language
      if (formalWords.any((word) => content.contains(word))) {
        userPatterns[userName]!['formal'] = userPatterns[userName]!['formal']! + 1;
      }
      
      // Check for casual language
      if (casualWords.any((word) => content.contains(word))) {
        userPatterns[userName]!['casual'] = userPatterns[userName]!['casual']! + 1;
      }
      
      // Check for filler words
      if (fillerWords.any((word) => content.contains(word))) {
        userPatterns[userName]!['filler'] = userPatterns[userName]!['filler']! + 1;
      }
      
      // Check for intensifiers
      if (intensifiers.any((word) => content.contains(word))) {
        userPatterns[userName]!['intensifier'] = userPatterns[userName]!['intensifier']! + 1;
      }
    }
    
    final Map<String, Map<String, dynamic>> languageProfiles = {};
    
    for (final entry in userPatterns.entries) {
      final userName = entry.key;
      final patterns = entry.value;
      final totalMessages = patterns['totalMessages']!;
      
      if (totalMessages == 0) continue;
      
      final formalPercent = (patterns['formal']! / totalMessages) * 100;
      final casualPercent = (patterns['casual']! / totalMessages) * 100;
      final fillerPercent = (patterns['filler']! / totalMessages) * 100;
      final intensifierPercent = (patterns['intensifier']! / totalMessages) * 100;
      
      // Determine language style
      String languageStyle = 'Neutral Style 💬';
      if (formalPercent > 20) {
        languageStyle = 'Formal Speaker 🎩';
      } else if (casualPercent > 30) {
        languageStyle = 'Casual Chatter 😎';
      } else if (fillerPercent > 25) {
        languageStyle = 'Conversational Speaker 🗣️';
      } else if (intensifierPercent > 20) {
        languageStyle = 'Emphatic Communicator 💪';
      } else if (formalPercent + casualPercent < 10) {
        languageStyle = 'Straightforward Speaker 🎯';
      }
      
      languageProfiles[userName] = {
        'languageStyle': languageStyle,
        'formalPercentage': formalPercent.toStringAsFixed(1),
        'casualPercentage': casualPercent.toStringAsFixed(1),
        'fillerPercentage': fillerPercent.toStringAsFixed(1),
        'intensifierPercentage': intensifierPercent.toStringAsFixed(1),
      };
    }
    
    return languageProfiles;
  }

  Map<String, dynamic> _analyzeInformationSharing(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    final Map<String, Map<String, int>> userSharing = {};
    
    final urlPattern = RegExp(r'https?://[^\s]+');
    
    for (final message in messages) {
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final content = message.content;
      
      userSharing.putIfAbsent(userName, () => {
        'links': 0,
        'numbers': 0,
        'dates': 0,
        'locations': 0,
        'totalMessages': 0,
      });
      
      userSharing[userName]!['totalMessages'] = userSharing[userName]!['totalMessages']! + 1;
      
      // Count links
      if (urlPattern.hasMatch(content)) {
        userSharing[userName]!['links'] = userSharing[userName]!['links']! + 1;
      }
      
      // Count numbers (phone numbers, addresses, etc.)
      if (RegExp(r'\b\d{3,}\b').hasMatch(content)) {
        userSharing[userName]!['numbers'] = userSharing[userName]!['numbers']! + 1;
      }
      
      // Count dates
      if (RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b').hasMatch(content)) {
        userSharing[userName]!['dates'] = userSharing[userName]!['dates']! + 1;
      }
      
      // Count location references
      final locationWords = ['at', 'in', 'near', 'address', 'street', 'road', 'avenue'];
      if (locationWords.any((word) => content.toLowerCase().contains(word))) {
        userSharing[userName]!['locations'] = userSharing[userName]!['locations']! + 1;
      }
    }
    
    final Map<String, Map<String, dynamic>> sharingProfiles = {};
    
    for (final entry in userSharing.entries) {
      final userName = entry.key;
      final sharing = entry.value;
      final totalMessages = sharing['totalMessages']!;
      
      if (totalMessages == 0) continue;
      
      final totalInfoShared = sharing['links']! + sharing['numbers']! + 
                             sharing['dates']! + sharing['locations']!;
      
      final infoSharingRate = (totalInfoShared / totalMessages) * 100;
      
      String sharingType = 'Standard Communicator 💬';
      if (infoSharingRate > 25) {
        sharingType = 'Information Hub 📡';
      } else if (sharing['links']! > sharing['numbers']! && sharing['links']! > 3) {
        sharingType = 'Link Sharer 🔗';
      } else if (sharing['numbers']! > 5) {
        sharingType = 'Detail Provider 📊';
      } else if (infoSharingRate > 10) {
        sharingType = 'Helpful Informer ℹ️';
      } else if (infoSharingRate < 5) {
        sharingType = 'Conversational Focused 💭';
      }
      
      sharingProfiles[userName] = {
        'sharingType': sharingType,
        'infoSharingRate': infoSharingRate.toStringAsFixed(1),
        'linksShared': sharing['links']!,
        'numbersShared': sharing['numbers']!,
        'datesShared': sharing['dates']!,
        'locationsShared': sharing['locations']!,
        'totalInfoShared': totalInfoShared,
      };
    }
    
    return sharingProfiles;
  }

  Map<String, dynamic> _analyzeConversationThreads(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    final Map<String, Map<String, int>> userThreadBehavior = {};
    
    // Analyze message clustering and thread continuation
    for (int i = 1; i < messages.length; i++) {
      final currentMsg = messages[i];
      final previousMsg = messages[i - 1];
      
      final currentUser = userIdToName[currentMsg.senderId] ?? 'Unknown';
      final previousUser = userIdToName[previousMsg.senderId] ?? 'Unknown';
      
      userThreadBehavior.putIfAbsent(currentUser, () => {
        'continues': 0,  // Continues own thread
        'responds': 0,   // Responds to others
        'interrupts': 0, // Changes topic/interrupts
        'totalMessages': 0,
      });
      
      userThreadBehavior[currentUser]!['totalMessages'] = 
          userThreadBehavior[currentUser]!['totalMessages']! + 1;
      
      final timeDiff = currentMsg.timestamp.difference(previousMsg.timestamp);
      
      if (currentUser == previousUser && timeDiff.inMinutes < 15) {
        // Continuing own thread
        userThreadBehavior[currentUser]!['continues'] = 
            userThreadBehavior[currentUser]!['continues']! + 1;
      } else if (currentUser != previousUser && timeDiff.inMinutes < 30) {
        // Responding to someone else
        userThreadBehavior[currentUser]!['responds'] = 
            userThreadBehavior[currentUser]!['responds']! + 1;
      } else if (timeDiff.inHours > 1) {
        // Possible topic change/interruption
        userThreadBehavior[currentUser]!['interrupts'] = 
            userThreadBehavior[currentUser]!['interrupts']! + 1;
      }
    }
    
    final Map<String, Map<String, dynamic>> threadProfiles = {};
    
    for (final entry in userThreadBehavior.entries) {
      final userName = entry.key;
      final behavior = entry.value;
      final totalMessages = behavior['totalMessages']!;
      
      if (totalMessages == 0) continue;
      
      final continuesPercent = (behavior['continues']! / totalMessages) * 100;
      final respondsPercent = (behavior['responds']! / totalMessages) * 100;
      final interruptsPercent = (behavior['interrupts']! / totalMessages) * 100;
      
      String threadType = 'Balanced Participant 💬';
      if (continuesPercent > 40) {
        threadType = 'Thread Builder 🧵';
      } else if (respondsPercent > 50) {
        threadType = 'Active Responder 🔄';
      } else if (interruptsPercent > 20) {
        threadType = 'Topic Changer 🔀';
      } else if (respondsPercent > continuesPercent) {
        threadType = 'Supportive Contributor 🤝';
      }
      
      threadProfiles[userName] = {
        'threadType': threadType,
        'continuesPercentage': continuesPercent.toStringAsFixed(1),
        'respondsPercentage': respondsPercent.toStringAsFixed(1),
        'interruptsPercentage': interruptsPercent.toStringAsFixed(1),
      };
    }
    
    return threadProfiles;
  }

  Map<String, dynamic> _calculateIntelligenceScores(
      Map<String, dynamic> vocabulary,
      Map<String, dynamic> questionStatement,
      Map<String, dynamic> infoSharing) {
    
    final Map<String, Map<String, dynamic>> intelligenceScores = {};
    
    // Get all unique users from all analyses
    final allUsers = <String>{};
    allUsers.addAll(vocabulary.keys.cast<String>());
    allUsers.addAll(questionStatement.keys.cast<String>());
    allUsers.addAll(infoSharing.keys.cast<String>());
    
    for (final userName in allUsers) {
      double totalScore = 50.0; // Base score
      
      // Vocabulary complexity contribution (40% weight)
      if (vocabulary.containsKey(userName)) {
        final vocabScore = double.tryParse(vocabulary[userName]['complexityScore'] ?? '50') ?? 50.0;
        totalScore += (vocabScore - 50) * 0.4;
      }
      
      // Question asking contribution (30% weight) - curiosity indicates intelligence
      if (questionStatement.containsKey(userName)) {
        final questionPercent = double.tryParse(questionStatement[userName]['questionPercentage'] ?? '0') ?? 0.0;
        if (questionPercent > 20) totalScore += 15; // Bonus for being curious
        if (questionPercent > 35) totalScore += 10; // Extra bonus for high curiosity
      }
      
      // Information sharing contribution (30% weight)
      if (infoSharing.containsKey(userName)) {
        final infoRate = double.tryParse(infoSharing[userName]['infoSharingRate'] ?? '0') ?? 0.0;
        if (infoRate > 15) totalScore += 10; // Bonus for sharing information
        if (infoRate > 25) totalScore += 10; // Extra bonus for high info sharing
      }
      
      // Cap the score at 100
      totalScore = math.min(100.0, totalScore);
      
      // Determine intelligence type
      String intelligenceType = 'Balanced Intelligence 🧠';
      if (totalScore > 85) {
        intelligenceType = 'Highly Intelligent 🎓';
      } else if (totalScore > 75) {
        intelligenceType = 'Very Smart 💡';
      } else if (totalScore > 65) {
        intelligenceType = 'Above Average 📈';
      } else if (totalScore > 55) {
        intelligenceType = 'Good Thinker 🤔';
      } else if (totalScore < 45) {
        intelligenceType = 'Simple Communicator 💬';
      }
      
      intelligenceScores[userName] = {
        'intelligenceType': intelligenceType,
        'overallScore': totalScore.toStringAsFixed(1),
        'vocabContribution': vocabulary.containsKey(userName) 
            ? double.tryParse(vocabulary[userName]['complexityScore'] ?? '50')?.toStringAsFixed(1) ?? '50.0'
            : '50.0',
        'curiosityContribution': questionStatement.containsKey(userName)
            ? questionStatement[userName]['questionPercentage']
            : '0.0',
        'infoSharingContribution': infoSharing.containsKey(userName)
            ? infoSharing[userName]['infoSharingRate']
            : '0.0',
      };
    }
    
    return intelligenceScores;
  }

  Map<String, dynamic> _emptyResults() {
    return {
      'contentIntelligence': {
        'questionStatementPatterns': {},
        'communicationStyles': {},
        'vocabularyAnalysis': {},
        'languagePatterns': {},
        'informationSharing': {},
        'threadPatterns': {},
        'intelligenceScores': {},
      }
    };
  }
}

// Add this class to lib/features/analysis/enhanced_analyzers.dart

class TemporalInsightAnalyzer {
  Future<Map<String, dynamic>> analyze(ChatEntity chat) async {
    debugPrint("⏰ Analyzing temporal insights and evolution patterns...");
    
    final messages = chat.messages
        .where((msg) => msg.senderId != "System")
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (messages.isEmpty) return _emptyResults();

    final userIdToName = {for (var user in chat.users) user.id: user.name};
    
    // Check if we have enough temporal data (at least 30 days)
    final timeSpan = messages.last.timestamp.difference(messages.first.timestamp);
    if (timeSpan.inDays < 30) {
      return _insufficientDataResults(timeSpan.inDays);
    }
    
    // Analyze response time evolution over time
    final responseTimeEvolution = _analyzeResponseTimeEvolution(messages, userIdToName);
    
    // Analyze communication intensity waves (busy vs quiet periods)
    final intensityWaves = _analyzeIntensityWaves(messages, userIdToName);
    
    // Analyze relationship evolution (getting closer/distant over time)
    final relationshipEvolution = _analyzeRelationshipEvolution(messages, userIdToName);
    
    // Analyze topic evolution and trends
    final topicEvolution = _analyzeTopicEvolution(messages, userIdToName);
    
    // Analyze communication pattern changes
    final patternChanges = _analyzePatternChanges(messages, userIdToName);
    
    // Analyze peak activity correlation (do users come online together?)
    final activityCorrelation = _analyzeActivityCorrelation(messages, userIdToName);
    
    // Create evolution timeline
    final evolutionTimeline = _createEvolutionTimeline(messages, userIdToName);
    
    // Calculate overall evolution trends
    final overallTrends = _calculateOverallTrends(
        responseTimeEvolution, intensityWaves, relationshipEvolution);

    return {
      'temporalInsights': {
        'timeSpanDays': timeSpan.inDays,
        'responseTimeEvolution': responseTimeEvolution,
        'intensityWaves': intensityWaves,
        'relationshipEvolution': relationshipEvolution,
        'topicEvolution': topicEvolution,
        'patternChanges': patternChanges,
        'activityCorrelation': activityCorrelation,
        'evolutionTimeline': evolutionTimeline,
        'overallTrends': overallTrends,
      }
    };
  }

  Map<String, dynamic> _analyzeResponseTimeEvolution(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    // Divide time period into segments (weeks or months depending on duration)
    final timeSpan = messages.last.timestamp.difference(messages.first.timestamp);
    final segmentDays = timeSpan.inDays > 365 ? 30 : 7; // Monthly or weekly segments
    
    final Map<String, List<Map<String, dynamic>>> userResponseTrends = {};
    
    for (int i = 1; i < messages.length; i++) {
      final currentMsg = messages[i];
      final previousMsg = messages[i - 1];
      
      // Skip if same sender or too long gap
      if (currentMsg.senderId == previousMsg.senderId) continue;
      
      final responseTime = currentMsg.timestamp.difference(previousMsg.timestamp);
      if (responseTime.inHours > 24) continue; // Skip if too long to be a response
      
      final responderName = userIdToName[currentMsg.senderId] ?? 'Unknown';
      final segmentStart = messages.first.timestamp;
      final daysSinceStart = currentMsg.timestamp.difference(segmentStart).inDays;
      final segment = daysSinceStart ~/ segmentDays;
      
      userResponseTrends.putIfAbsent(responderName, () => []);
      
      // Find or create segment
      Map<String, dynamic>? segmentData;
      for (final s in userResponseTrends[responderName]!) {
        if (s['segment'] == segment) {
          segmentData = s;
          break;
        }
      }
      
      if (segmentData == null) {
        segmentData = {
          'segment': segment,
          'responseTimes': <int>[],
          'count': 0,
        };
        userResponseTrends[responderName]!.add(segmentData);
      }
      
      segmentData['responseTimes'].add(responseTime.inSeconds);
      segmentData['count'] = segmentData['count'] + 1;
    }
    
    // Calculate trends for each user
    final Map<String, Map<String, dynamic>> evolutionResults = {};
    
    for (final entry in userResponseTrends.entries) {
      final userName = entry.key;
      final trends = entry.value;
      
      if (trends.length < 3) continue; // Need at least 3 segments for trend
      
      // Calculate average response time for each segment
      final List<double> avgResponseTimes = [];
      final List<int> segments = [];
      
      for (final segment in trends) {
        final responseTimes = segment['responseTimes'] as List<int>;
        if (responseTimes.isNotEmpty) {
          final avg = responseTimes.reduce((a, b) => a + b) / responseTimes.length;
          avgResponseTimes.add(avg);
          segments.add(segment['segment']);
        }
      }
      
      if (avgResponseTimes.length < 3) continue;
      
      // Calculate trend (getting faster or slower?)
      final firstHalf = avgResponseTimes.take(avgResponseTimes.length ~/ 2).toList();
      final secondHalf = avgResponseTimes.skip(avgResponseTimes.length ~/ 2).toList();
      
      final firstHalfAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final secondHalfAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
      
      final percentChange = ((secondHalfAvg - firstHalfAvg) / firstHalfAvg) * 100;
      
      String trendType = 'Stable Response Time ⏸️';
      if (percentChange < -20) {
        trendType = 'Getting Much Faster ⚡⚡';
      } else if (percentChange < -10) {
        trendType = 'Getting Faster ⚡';
      } else if (percentChange > 20) {
        trendType = 'Getting Much Slower 🐌🐌';
      } else if (percentChange > 10) {
        trendType = 'Getting Slower 🐌';
      } else if (percentChange.abs() < 5) {
        trendType = 'Very Consistent ⏰';
      }
      
      evolutionResults[userName] = {
        'trendType': trendType,
        'percentChange': percentChange.toStringAsFixed(1),
        'initialAvgSeconds': firstHalfAvg.toInt(),
        'recentAvgSeconds': secondHalfAvg.toInt(),
        'dataPoints': avgResponseTimes.length,
        'timelineData': List.generate(avgResponseTimes.length, (i) => {
          'segment': segments[i],
          'avgResponseTime': avgResponseTimes[i].toInt(),
        }),
      };
    }
    
    return evolutionResults;
  }

  Map<String, dynamic> _analyzeIntensityWaves(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    // Group messages by day
    final Map<String, int> dailyMessageCounts = {};
    final Map<String, Map<String, int>> userDailyCounts = {};
    
    for (final message in messages) {
      final dateKey = '${message.timestamp.year}-${message.timestamp.month.toString().padLeft(2, '0')}-${message.timestamp.day.toString().padLeft(2, '0')}';
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      
      dailyMessageCounts[dateKey] = (dailyMessageCounts[dateKey] ?? 0) + 1;
      
      userDailyCounts.putIfAbsent(userName, () => {});
      userDailyCounts[userName]![dateKey] = (userDailyCounts[userName]![dateKey] ?? 0) + 1;
    }
    
    // Find intensity waves (periods of high/low activity)
    final sortedDates = dailyMessageCounts.keys.toList()..sort();
    final dailyCounts = sortedDates.map((date) => dailyMessageCounts[date]!).toList();
    
    if (dailyCounts.length < 7) {
      return {'message': 'Not enough data for intensity wave analysis'};
    }
    
    // Calculate rolling 7-day average
    final List<double> rollingAverages = [];
    for (int i = 6; i < dailyCounts.length; i++) {
      final weekData = dailyCounts.sublist(i - 6, i + 1);
      final avg = weekData.reduce((a, b) => a + b) / weekData.length;
      rollingAverages.add(avg);
    }
    
    // Find peaks and valleys
    final List<Map<String, dynamic>> peaks = [];
    final List<Map<String, dynamic>> valleys = [];
    
    for (int i = 1; i < rollingAverages.length - 1; i++) {
      final current = rollingAverages[i];
      final previous = rollingAverages[i - 1];
      final next = rollingAverages[i + 1];
      
      if (current > previous && current > next && current > rollingAverages.reduce((a, b) => a + b) / rollingAverages.length * 1.5) {
        peaks.add({
          'date': sortedDates[i + 6],
          'intensity': current.toInt(),
          'type': 'peak',
        });
      } else if (current < previous && current < next && current < rollingAverages.reduce((a, b) => a + b) / rollingAverages.length * 0.5) {
        valleys.add({
          'date': sortedDates[i + 6],
          'intensity': current.toInt(),
          'type': 'valley',
        });
      }
    }
    
    // Analyze user activity patterns during intense periods
    final Map<String, Map<String, dynamic>> userIntensityPatterns = {};
    
    for (final userName in userIdToName.values) {
      int peakActivity = 0;
      int valleyActivity = 0;
      int totalPeakDays = 0;
      int totalValleyDays = 0;
      
      for (final peak in peaks) {
        final dateKey = peak['date'] as String;
        peakActivity += userDailyCounts[userName]?[dateKey] ?? 0;
        totalPeakDays++;
      }
      
      for (final valley in valleys) {
        final dateKey = valley['date'] as String;
        valleyActivity += userDailyCounts[userName]?[dateKey] ?? 0;
        totalValleyDays++;
      }
      
      final avgPeakActivity = totalPeakDays > 0 ? peakActivity / totalPeakDays : 0.0;
      final avgValleyActivity = totalValleyDays > 0 ? valleyActivity / totalValleyDays : 0.0;
      
      String intensityType = 'Steady Contributor 📊';
      if (avgPeakActivity > avgValleyActivity * 3) {
        intensityType = 'Wave Rider 🌊';
      } else if (avgPeakActivity > avgValleyActivity * 2) {
        intensityType = 'Peak Performer 📈';
      } else if (avgPeakActivity < avgValleyActivity * 0.5) {
        intensityType = 'Quiet During Storms 😌';
      } else if ((avgPeakActivity - avgValleyActivity).abs() < 1) {
        intensityType = 'Consistent Communicator ⏰';
      }
      
      userIntensityPatterns[userName] = {
        'intensityType': intensityType,
        'avgPeakActivity': avgPeakActivity.toStringAsFixed(1),
        'avgValleyActivity': avgValleyActivity.toStringAsFixed(1),
        'peakToValleyRatio': avgValleyActivity > 0 ? (avgPeakActivity / avgValleyActivity).toStringAsFixed(1) : 'N/A',
      };
    }
    
    return {
      'totalPeaks': peaks.length,
      'totalValleys': valleys.length,
      'peaks': peaks.take(5).toList(), // Top 5 peaks
      'valleys': valleys.take(5).toList(), // Top 5 valleys
      'userIntensityPatterns': userIntensityPatterns,
      'avgDailyMessages': (dailyCounts.reduce((a, b) => a + b) / dailyCounts.length).toStringAsFixed(1),
    };
  }

  Map<String, dynamic> _analyzeRelationshipEvolution(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    // Divide timeline into quarters for relationship analysis
    final timeSpan = messages.last.timestamp.difference(messages.first.timestamp);
    final quarterDuration = Duration(days: timeSpan.inDays ~/ 4);
    
    final List<Map<String, dynamic>> quarterlyAnalysis = [];
    
    for (int quarter = 0; quarter < 4; quarter++) {
      final startTime = messages.first.timestamp.add(Duration(days: quarter * quarterDuration.inDays));
      final endTime = quarter == 3 ? messages.last.timestamp : 
          messages.first.timestamp.add(Duration(days: (quarter + 1) * quarterDuration.inDays));
      
      final quarterMessages = messages.where((msg) => 
          msg.timestamp.isAfter(startTime) && msg.timestamp.isBefore(endTime)).toList();
      
      if (quarterMessages.isEmpty) continue;
      
      // Calculate metrics for this quarter
      final Map<String, int> userMessageCounts = {};
      final Map<String, List<int>> userResponseTimes = {};
      final Map<String, int> userQuestions = {};
      final Map<String, int> userSupport = {};
      
      for (int i = 0; i < quarterMessages.length; i++) {
        final msg = quarterMessages[i];
        final userName = userIdToName[msg.senderId] ?? 'Unknown';
        
        userMessageCounts[userName] = (userMessageCounts[userName] ?? 0) + 1;
        
        // Count questions
        if (msg.content.contains('?')) {
          userQuestions[userName] = (userQuestions[userName] ?? 0) + 1;
        }
        
        // Count supportive messages
        final supportWords = ['thanks', 'sorry', 'help', 'love', 'care', 'support'];
        if (supportWords.any((word) => msg.content.toLowerCase().contains(word))) {
          userSupport[userName] = (userSupport[userName] ?? 0) + 1;
        }
        
        // Response times
        if (i > 0 && quarterMessages[i-1].senderId != msg.senderId) {
          final responseTime = msg.timestamp.difference(quarterMessages[i-1].timestamp);
          if (responseTime.inHours < 2) {
            userResponseTimes.putIfAbsent(userName, () => []);
            userResponseTimes[userName]!.add(responseTime.inSeconds);
          }
        }
      }
      
      // Calculate quarter metrics
      final totalMessages = quarterMessages.length;
      final totalUsers = userMessageCounts.length;
      final avgMessagesPerUser = totalUsers > 0 ? totalMessages / totalUsers : 0.0;
      
      // Calculate engagement score (questions + support + response speed)
      double engagementScore = 50.0;
      
      final totalQuestions = userQuestions.values.fold(0, (sum, count) => sum + count);
      final totalSupport = userSupport.values.fold(0, (sum, count) => sum + count);
      
      engagementScore += (totalQuestions / totalMessages) * 30; // Question engagement
      engagementScore += (totalSupport / totalMessages) * 20; // Emotional engagement
      
      // Response time factor
      final allResponseTimes = userResponseTimes.values.expand((times) => times).toList();
      if (allResponseTimes.isNotEmpty) {
        final avgResponseTime = allResponseTimes.reduce((a, b) => a + b) / allResponseTimes.length;
        if (avgResponseTime < 300) engagementScore += 10; // Fast responses
        if (avgResponseTime < 60) engagementScore += 10; // Very fast responses
      }
      
      engagementScore = math.min(100.0, engagementScore);
      
      quarterlyAnalysis.add({
        'quarter': quarter + 1,
        'period': '${_formatDate(startTime)} - ${_formatDate(endTime)}',
        'totalMessages': totalMessages,
        'avgMessagesPerUser': avgMessagesPerUser.toStringAsFixed(1),
        'engagementScore': engagementScore.toStringAsFixed(1),
        'totalQuestions': totalQuestions,
        'totalSupport': totalSupport,
        'avgResponseTimeSeconds': allResponseTimes.isNotEmpty ? 
            (allResponseTimes.reduce((a, b) => a + b) / allResponseTimes.length).toInt() : 0,
      });
    }
    
    // Calculate overall relationship trajectory
    if (quarterlyAnalysis.length >= 2) {
      final firstQuarter = quarterlyAnalysis.first;
      final lastQuarter = quarterlyAnalysis.last;
      
      final engagementChange = double.parse(lastQuarter['engagementScore']) - 
                             double.parse(firstQuarter['engagementScore']);
      
      String relationshipTrend = 'Stable Relationship 🤝';
      if (engagementChange > 15) {
        relationshipTrend = 'Growing Closer 💕';
      } else if (engagementChange > 8) {
        relationshipTrend = 'Getting More Engaged 📈';
      } else if (engagementChange < -15) {
        relationshipTrend = 'Growing Apart 📉';
      } else if (engagementChange < -8) {
        relationshipTrend = 'Less Engaged 😐';
      } else if (engagementChange.abs() < 5) {
        relationshipTrend = 'Very Stable Bond 🔗';
      }
      
      return {
        'relationshipTrend': relationshipTrend,
        'engagementChange': engagementChange.toStringAsFixed(1),
        'quarterlyData': quarterlyAnalysis,
        'initialEngagement': firstQuarter['engagementScore'],
        'currentEngagement': lastQuarter['engagementScore'],
      };
    }
    
    return {
      'relationshipTrend': 'Insufficient data for trend analysis',
      'quarterlyData': quarterlyAnalysis,
    };
  }

  Map<String, dynamic> _analyzeTopicEvolution(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    // Simple topic detection based on common word patterns
    final topicKeywords = {
      'work': ['work', 'job', 'office', 'meeting', 'boss', 'project', 'deadline'],
      'family': ['family', 'mom', 'dad', 'sister', 'brother', 'parents', 'kids'],
      'food': ['food', 'eat', 'lunch', 'dinner', 'restaurant', 'cooking', 'hungry'],
      'travel': ['travel', 'trip', 'vacation', 'flight', 'hotel', 'visit'],
      'health': ['doctor', 'sick', 'hospital', 'medicine', 'health', 'exercise'],
      'entertainment': ['movie', 'music', 'game', 'watch', 'show', 'party'],
      'technology': ['phone', 'computer', 'app', 'internet', 'tech', 'device'],
      'emotions': ['happy', 'sad', 'angry', 'excited', 'worried', 'love', 'hate'],
    };
    
    // Divide timeline into months for topic analysis
    final Map<String, Map<String, int>> monthlyTopics = {};
    
    for (final message in messages) {
      final monthKey = '${message.timestamp.year}-${message.timestamp.month.toString().padLeft(2, '0')}';
      final content = message.content.toLowerCase();
      
      monthlyTopics.putIfAbsent(monthKey, () => {});
      
      for (final topic in topicKeywords.keys) {
        final keywords = topicKeywords[topic]!;
        if (keywords.any((keyword) => content.contains(keyword))) {
          monthlyTopics[monthKey]![topic] = (monthlyTopics[monthKey]![topic] ?? 0) + 1;
          break; // Only count one topic per message
        }
      }
    }
    
    // Find trending topics
    final sortedMonths = monthlyTopics.keys.toList()..sort();
    if (sortedMonths.length < 3) {
      return {'message': 'Not enough data for topic evolution analysis'};
    }
    
    final Map<String, String> topicTrends = {};
    
    for (final topic in topicKeywords.keys) {
      final firstHalfMonths = sortedMonths.take(sortedMonths.length ~/ 2);
      final secondHalfMonths = sortedMonths.skip(sortedMonths.length ~/ 2);
      
      final firstHalfCount = firstHalfMonths
          .map((month) => monthlyTopics[month]![topic] ?? 0)
          .fold(0, (sum, count) => sum + count);
      
      final secondHalfCount = secondHalfMonths
          .map((month) => monthlyTopics[month]![topic] ?? 0)
          .fold(0, (sum, count) => sum + count);
      
      if (firstHalfCount == 0 && secondHalfCount == 0) continue;
      
      if (secondHalfCount > firstHalfCount * 2) {
        topicTrends[topic] = 'Rising 📈';
      } else if (firstHalfCount > secondHalfCount * 2) {
        topicTrends[topic] = 'Declining 📉';
      } else {
        topicTrends[topic] = 'Stable ⏸️';
      }
    }
    
    return {
      'topicTrends': topicTrends,
      'monthlyBreakdown': monthlyTopics,
      'totalMonthsAnalyzed': sortedMonths.length,
    };
  }

  Map<String, dynamic> _analyzePatternChanges(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    // Compare first and last quarters for pattern changes
    final quarterSize = messages.length ~/ 4;
    final earlyMessages = messages.take(quarterSize).toList();
    final recentMessages = messages.skip(messages.length - quarterSize).toList();
    
    final earlyPatterns = _analyzeQuarterPatterns(earlyMessages, userIdToName);
    final recentPatterns = _analyzeQuarterPatterns(recentMessages, userIdToName);
    
    final Map<String, Map<String, dynamic>> patternChanges = {};
    
    for (final userName in userIdToName.values) {
      if (!earlyPatterns.containsKey(userName) || !recentPatterns.containsKey(userName)) continue;
      
      final early = earlyPatterns[userName]!;
      final recent = recentPatterns[userName]!;
      
      final List<String> changes = [];
      
      // Check message length change
      final lengthChange = recent['avgLength']! - early['avgLength']!;
      if (lengthChange > 20) {
        changes.add('Getting more verbose 📝');
      } else if (lengthChange < -20) {
        changes.add('Getting more concise ✂️');
      }
      
      // Check emoji usage change
      final emojiChange = recent['emojiRate']! - early['emojiRate']!;
      if (emojiChange > 0.5) {
        changes.add('Using more emojis 😊');
      } else if (emojiChange < -0.5) {
        changes.add('Using fewer emojis 😐');
      }
      
      // Check question asking change
      final questionChange = recent['questionRate']! - early['questionRate']!;
      if (questionChange > 0.2) {
        changes.add('Asking more questions 🤔');
      } else if (questionChange < -0.2) {
        changes.add('Asking fewer questions 📝');
      }
      
      patternChanges[userName] = {
        'changes': changes,
        'earlyPeriod': early,
        'recentPeriod': recent,
        'totalChanges': changes.length,
      };
    }
    
    return patternChanges;
  }

  Map<String, Map<String, double>> _analyzeQuarterPatterns(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    final Map<String, Map<String, double>> patterns = {};
    
    for (final message in messages) {
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final content = message.content;
      
      patterns.putIfAbsent(userName, () => {
        'avgLength': 0.0,
        'emojiRate': 0.0,
        'questionRate': 0.0,
        'messageCount': 0.0,
      });
      
      patterns[userName]!['messageCount'] = patterns[userName]!['messageCount']! + 1;
      patterns[userName]!['avgLength'] = patterns[userName]!['avgLength']! + content.length;
      
      if (content.contains('?')) {
        patterns[userName]!['questionRate'] = patterns[userName]!['questionRate']! + 1;
      }
      
      final emojiCount = RegExp(r'[\u{1F600}-\u{1F64F}]', unicode: true).allMatches(content).length;
      patterns[userName]!['emojiRate'] = patterns[userName]!['emojiRate']! + emojiCount;
    }
    
    // Calculate averages
    for (final entry in patterns.entries) {
      final data = entry.value;
      final messageCount = data['messageCount']!;
      
      if (messageCount > 0) {
        data['avgLength'] = data['avgLength']! / messageCount;
        data['emojiRate'] = data['emojiRate']! / messageCount;
        data['questionRate'] = data['questionRate']! / messageCount;
      }
    }
    
    return patterns;
  }

  Map<String, dynamic> _analyzeActivityCorrelation(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    if (userIdToName.length < 2) {
      return {'message': 'Need at least 2 users for correlation analysis'};
    }
    
    // Group messages by hour for each user
    final Map<String, Map<int, int>> userHourlyActivity = {};
    
    for (final message in messages) {
      final userName = userIdToName[message.senderId] ?? 'Unknown';
      final hour = message.timestamp.hour;
      
      userHourlyActivity.putIfAbsent(userName, () => {});
      userHourlyActivity[userName]![hour] = (userHourlyActivity[userName]![hour] ?? 0) + 1;
    }
    
    // Calculate correlation between users
    final userNames = userHourlyActivity.keys.toList();
    final Map<String, double> correlations = {};
    
    for (int i = 0; i < userNames.length; i++) {
      for (int j = i + 1; j < userNames.length; j++) {
        final user1 = userNames[i];
        final user2 = userNames[j];
        
        final correlation = _calculateHourlyCorrelation(
            userHourlyActivity[user1]!, userHourlyActivity[user2]!);
        
        correlations['$user1 & $user2'] = correlation;
      }
    }
    
    // Find the highest correlation
    final sortedCorrelations = correlations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    String correlationType = 'Independent Schedules 🕐';
    if (sortedCorrelations.isNotEmpty) {
      final highestCorr = sortedCorrelations.first.value;
      if (highestCorr > 0.7) {
        correlationType = 'Synchronized Schedules 🤝';
      } else if (highestCorr > 0.5) {
        correlationType = 'Often Online Together 👥';
      } else if (highestCorr > 0.3) {
        correlationType = 'Sometimes Aligned ⏰';
      }
    }
    
    return {
      'correlationType': correlationType,
      'correlations': correlations,
      'highestCorrelation': sortedCorrelations.isNotEmpty ? 
          sortedCorrelations.first.value.toStringAsFixed(2) : '0.00',
      'bestSyncedPair': sortedCorrelations.isNotEmpty ? 
          sortedCorrelations.first.key : 'None',
    };
  }

  double _calculateHourlyCorrelation(Map<int, int> user1Activity, Map<int, int> user2Activity) {
    final List<double> user1Values = [];
    final List<double> user2Values = [];
    
    for (int hour = 0; hour < 24; hour++) {
      user1Values.add((user1Activity[hour] ?? 0).toDouble());
      user2Values.add((user2Activity[hour] ?? 0).toDouble());
    }
    
    // Calculate Pearson correlation coefficient
    final n = user1Values.length.toDouble();
    final sum1 = user1Values.reduce((a, b) => a + b);
    final sum2 = user2Values.reduce((a, b) => a + b);
    final sum1Sq = user1Values.map((x) => x * x).reduce((a, b) => a + b);
    final sum2Sq = user2Values.map((x) => x * x).reduce((a, b) => a + b);
    final pSum = List.generate(user1Values.length, (i) => user1Values[i] * user2Values[i])
        .reduce((a, b) => a + b);
    
    final num = pSum - (sum1 * sum2 / n);
    final den = math.sqrt((sum1Sq - sum1 * sum1 / n) * (sum2Sq - sum2 * sum2 / n));
    
    return den == 0 ? 0.0 : num / den;
  }

  Map<String, dynamic> _createEvolutionTimeline(
      List<MessageEntity> messages, Map<String, String> userIdToName) {
    
    final timeSpan = messages.last.timestamp.difference(messages.first.timestamp);
    final milestones = <Map<String, dynamic>>[];
    
    // Major milestones based on message count thresholds
    final messageCounts = [100, 500, 1000, 2500, 5000, 10000];
    int currentCount = 0;
    
    for (int i = 0; i < messages.length; i++) {
      currentCount++;
      
      if (messageCounts.contains(currentCount)) {
        final date = messages[i].timestamp;
        final daysSinceStart = date.difference(messages.first.timestamp).inDays;
        
        milestones.add({
          'milestone': '${currentCount} Messages',
          'date': _formatDate(date),
          'daysSinceStart': daysSinceStart,
          'description': 'Reached $currentCount total messages',
        });
      }
    }
    
    // Activity milestones (busiest days, quiet periods)
    final Map<String, int> dailyCounts = {};
    for (final message in messages) {
      final dateKey = _formatDate(message.timestamp);
      dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
    }
    
    final sortedDays = dailyCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sortedDays.isNotEmpty) {
      final busiestDay = sortedDays.first;
      milestones.add({
        'milestone': 'Busiest Day',
        'date': busiestDay.key,
        'daysSinceStart': DateTime.parse(busiestDay.key).difference(messages.first.timestamp).inDays,
        'description': '${busiestDay.value} messages in one day',
      });
    }
    
    // Sort milestones by date
    milestones.sort((a, b) => a['daysSinceStart'].compareTo(b['daysSinceStart']));
    
    return {
      'totalTimeSpanDays': timeSpan.inDays,
      'milestones': milestones,
      'startDate': _formatDate(messages.first.timestamp),
      'endDate': _formatDate(messages.last.timestamp),
    };
  }

  Map<String, dynamic> _calculateOverallTrends(
      Map<String, dynamic> responseEvolution,
      Map<String, dynamic> intensityWaves,
      Map<String, dynamic> relationshipEvolution) {
    
    final trends = <String>[];
    
    // Analyze response time trends
    if (responseEvolution.isNotEmpty) {
      final users = responseEvolution.keys.toList();
      int fasterUsers = 0;
      int slowerUsers = 0;
      
      for (final user in users) {
        final userData = responseEvolution[user] as Map<String, dynamic>;
        final change = double.tryParse(userData['percentChange'] ?? '0') ?? 0.0;
        
        if (change < -10) fasterUsers++;
        if (change > 10) slowerUsers++;
      }
      
      if (fasterUsers > slowerUsers) {
        trends.add('Response times getting faster overall ⚡');
      } else if (slowerUsers > fasterUsers) {
        trends.add('Response times getting slower overall 🐌');
      } else {
        trends.add('Response times remain stable ⏰');
      }
    }
    
    // Analyze relationship trends
    if (relationshipEvolution.containsKey('relationshipTrend')) {
      final trend = relationshipEvolution['relationshipTrend'] as String;
      trends.add('Relationship: $trend');
    }
    
    // Analyze intensity patterns
    if (intensityWaves.containsKey('totalPeaks')) {
      final peaks = intensityWaves['totalPeaks'] as int;
      final valleys = intensityWaves['totalValleys'] as int;
      
      if (peaks > valleys) {
        trends.add('More high-energy periods than quiet ones 📈');
      } else if (valleys > peaks) {
        trends.add('More quiet periods than high-energy ones 📉');
      } else {
        trends.add('Balanced mix of busy and quiet periods ⚖️');
      }
    }
    
    // Overall evolution summary
    String overallEvolution = 'Stable Evolution 🤝';
    if (trends.any((t) => t.contains('faster') || t.contains('Growing Closer'))) {
      overallEvolution = 'Positive Evolution 📈';
    } else if (trends.any((t) => t.contains('slower') || t.contains('Growing Apart'))) {
      overallEvolution = 'Concerning Changes 📉';
    } else if (trends.any((t) => t.contains('stable') || t.contains('Stable'))) {
      overallEvolution = 'Very Stable Relationship 🔗';
    }
    
    return {
      'overallEvolution': overallEvolution,
      'keyTrends': trends,
      'evolutionScore': _calculateEvolutionScore(trends),
    };
  }

  double _calculateEvolutionScore(List<String> trends) {
    double score = 50.0; // Base score
    
    for (final trend in trends) {
      if (trend.contains('faster') || trend.contains('Growing Closer')) {
        score += 15;
      } else if (trend.contains('slower') || trend.contains('Growing Apart')) {
        score -= 15;
      } else if (trend.contains('stable') || trend.contains('Stable')) {
        score += 5;
      }
    }
    
    return math.min(100.0, math.max(0.0, score));
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _insufficientDataResults(int days) {
    return {
      'temporalInsights': {
        'message': 'Insufficient data for temporal analysis (only $days days). Need at least 30 days.',
        'timeSpanDays': days,
        'recommendation': 'Come back when you have more chat history!',
      }
    };
  }

  Map<String, dynamic> _emptyResults() {
    return {
      'temporalInsights': {
        'message': 'No messages available for temporal analysis',
        'timeSpanDays': 0,
      }
    };
  }
}