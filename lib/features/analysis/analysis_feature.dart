// features/analysis/analysis_feature.dart - PART 1
// Consolidated: analysis_bloc.dart + analysis_event.dart + analysis_state.dart + analyze_chat_usecase.dart + all analyzers

import 'dart:async';
import 'package:chatreport/features/analysis/enhanced_analyzers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../shared/domain.dart';

// ============================================================================
// ANALYSIS EVENTS
// ============================================================================
abstract class AnalysisEvent extends Equatable {
  const AnalysisEvent();

  @override
  List<Object?> get props => [];
}

class AnalyzeChatEvent extends AnalysisEvent {
  final String chatId;

  const AnalyzeChatEvent(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

// ============================================================================
// ANALYSIS STATES
// ============================================================================
abstract class AnalysisState extends Equatable {
  const AnalysisState();

  @override
  List<Object?> get props => [];
}

class AnalysisInitial extends AnalysisState {}

class AnalysisLoading extends AnalysisState {}

class AnalysisSuccess extends AnalysisState {
  final String chatId;
  final Map<String, dynamic> results;

  const AnalysisSuccess(this.chatId, this.results);

  @override
  List<Object?> get props => [chatId, results];
}

class AnalysisError extends AnalysisState {
  final String message;

  const AnalysisError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// ANALYZE CHAT USE CASE
// ============================================================================
class AnalyzeChatUseCase {
  final ChatRepository chatRepository;
  final AnalysisRepository analysisRepository;
  final MessageAnalyzer messageAnalyzer;
  final TimeAnalyzer timeAnalyzer;
  final UserAnalyzer userAnalyzer;
  final ContentAnalyzer contentAnalyzer;
  
  // Add the new enhanced analyzers
  final ConversationDynamicsAnalyzer conversationDynamicsAnalyzer;
  final BehaviorPatternAnalyzer behaviorPatternAnalyzer;
  final RelationshipAnalyzer relationshipAnalyzer;
  final ContentIntelligenceAnalyzer contentIntelligenceAnalyzer;
  final TemporalInsightAnalyzer temporalInsightAnalyzer;

  AnalyzeChatUseCase({
    required this.chatRepository,
    required this.analysisRepository,
    required this.messageAnalyzer,
    required this.timeAnalyzer,
    required this.userAnalyzer,
    required this.contentAnalyzer,
    // Add these required parameters
    required this.conversationDynamicsAnalyzer,
    required this.behaviorPatternAnalyzer,
    required this.relationshipAnalyzer,
    required this.contentIntelligenceAnalyzer,
    required this.temporalInsightAnalyzer,
  });

  Future<Map<String, dynamic>> call(String chatId) async {
    debugPrint("AnalyzeChatUseCase: Starting enhanced analysis for chat ID: $chatId");

    // Check if analysis already exists
    final existingResults = await analysisRepository.getAnalysisResults(chatId);
    if (existingResults.isNotEmpty) {
      debugPrint("AnalyzeChatUseCase: Using existing analysis results");
      return existingResults;
    }

    // Get chat data
    final chat = await chatRepository.getChatById(chatId);
    if (chat == null) {
      debugPrint("AnalyzeChatUseCase: Chat not found for ID: $chatId");
      throw Exception('Chat not found');
    }

    debugPrint("AnalyzeChatUseCase: Found chat with ${chat.messages.length} messages and ${chat.users.length} users");

    // For large chats, consider using compute for heavy operations
    if (chat.messages.length > 10000) {
      debugPrint("Large chat detected, using optimized analysis");
      return await _performOptimizedAnalysis(chat, chatId);
    } else {
      return await _performEnhancedAnalysis(chat, chatId);
    }
  }

  // Enhanced analysis with all new analyzers
  Future<Map<String, dynamic>> _performEnhancedAnalysis(
      ChatEntity chat, String chatId) async {
    try {
      debugPrint("AnalyzeChatUseCase: Running basic analyzers");
      final messageResults = await messageAnalyzer.analyze(chat);
      final timeResults = await timeAnalyzer.analyze(chat);
      final userResults = await userAnalyzer.analyze(chat);
      final contentResults = await contentAnalyzer.analyze(chat);

      debugPrint("AnalyzeChatUseCase: Running enhanced analyzers");
      
      // Run all enhanced analyzers
      final conversationResults = await conversationDynamicsAnalyzer.analyze(chat);
      final behaviorResults = await behaviorPatternAnalyzer.analyze(chat);
      final relationshipResults = await relationshipAnalyzer.analyze(chat);
      final contentIntelligenceResults = await contentIntelligenceAnalyzer.analyze(chat);
      final temporalResults = await temporalInsightAnalyzer.analyze(chat);

      // Combine all results
      final combinedResults = {
        ...messageResults,
        ...timeResults,
        ...userResults,
        ...contentResults,
        ...conversationResults,
        ...behaviorResults,
        ...relationshipResults,
        ...contentIntelligenceResults,
        ...temporalResults,
      };

      debugPrint("AnalyzeChatUseCase: Enhanced analysis complete with keys: ${combinedResults.keys}");

      // Save results
      await analysisRepository.saveAnalysisResults(chatId, combinedResults);

      return combinedResults;
    } catch (e) {
      debugPrint("AnalyzeChatUseCase: Error during enhanced analysis: $e");
      return _generateErrorResults(chat, e);
    }
  }

  // Optimized analysis for large chats
  Future<Map<String, dynamic>> _performOptimizedAnalysis(
      ChatEntity chat, String chatId) async {
    try {
      // Process in batches to avoid memory issues
      const batchSize = 5000;
      final batches = <List<MessageEntity>>[];

      for (int i = 0; i < chat.messages.length; i += batchSize) {
        final end = (i + batchSize < chat.messages.length)
            ? i + batchSize
            : chat.messages.length;
        batches.add(chat.messages.sublist(i, end));
      }

      debugPrint("Processing ${batches.length} batches of messages");

      // Run analyzers with progress tracking
      final results = <String, dynamic>{};

      // Message analysis
      debugPrint("Running optimized message analysis");
      results.addAll(await messageAnalyzer.analyze(chat));

      // Time analysis (can be memory intensive, so batch it)
      debugPrint("Running optimized time analysis");
      results.addAll(await _analyzeTimeInBatches(chat));

      // User analysis
      debugPrint("Running optimized user analysis");
      results.addAll(await userAnalyzer.analyze(chat));

      // Content analysis (most memory intensive)
      debugPrint("Running optimized content analysis");
      results.addAll(await _analyzeContentInBatches(chat));

      // Save results
      await analysisRepository.saveAnalysisResults(chatId, results);

      return results;
    } catch (e) {
      debugPrint("Error in optimized analysis: $e");
      return _generateErrorResults(chat, e);
    }
  }

  // Batched time analysis for large chats
  Future<Map<String, dynamic>> _analyzeTimeInBatches(ChatEntity chat) async {
    final Map<int, int> hourCounts = {};
    final Map<String, int> dayOfWeekCounts = {
      'Monday': 0,
      'Tuesday': 0,
      'Wednesday': 0,
      'Thursday': 0,
      'Friday': 0,
      'Saturday': 0,
      'Sunday': 0,
    };
    final Map<String, int> dayMessageCounts = {};

    const batchSize = 5000;

    for (int i = 0; i < chat.messages.length; i += batchSize) {
      final end = (i + batchSize < chat.messages.length)
          ? i + batchSize
          : chat.messages.length;
      final batch = chat.messages.sublist(i, end);

      for (final message in batch) {
        final timestamp = message.timestamp;

        // Hour analysis
        final hour = timestamp.hour;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;

        // Day of week analysis
        final dayNames = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ];
        final dayOfWeek = dayNames[timestamp.weekday - 1];
        dayOfWeekCounts[dayOfWeek] = (dayOfWeekCounts[dayOfWeek] ?? 0) + 1;

        // Daily message counts
        final date =
            '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
        dayMessageCounts[date] = (dayMessageCounts[date] ?? 0) + 1;
      }

      // Allow other operations to run
      await Future.delayed(const Duration(milliseconds: 1));
    }

    // Format results
    final Map<String, int> formattedHourCounts = {};
    for (int i = 0; i < 24; i++) {
      final key = i.toString().padLeft(2, '0');
      formattedHourCounts[key] = hourCounts[i] ?? 0;
    }

    // Find most active day and hour
    String mostActiveDay = 'None';
    int mostActiveDayCount = 0;
    dayOfWeekCounts.forEach((day, count) {
      if (count > mostActiveDayCount) {
        mostActiveDay = day;
        mostActiveDayCount = count;
      }
    });

    String mostActiveHour = 'None';
    int mostActiveHourCount = 0;
    formattedHourCounts.forEach((hour, count) {
      if (count > mostActiveHourCount) {
        mostActiveHour = hour;
        mostActiveHourCount = count;
      }
    });

    // Get top days
    final List<MapEntry<String, int>> topDays = dayMessageCounts.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<Map<String, dynamic>> topDaysList =
        topDays.take(10).map((entry) {
      return {
        'date': entry.key,
        'count': entry.value,
      };
    }).toList();

    return {
      'timeAnalysis': {
        'hourOfDay': formattedHourCounts,
        'dayOfWeek': dayOfWeekCounts,
        'mostActiveDay': {
          'day': mostActiveDay,
          'count': mostActiveDayCount,
        },
        'mostActiveHour': {
          'hour': mostActiveHour,
          'count': mostActiveHourCount,
        },
        'topDays': topDaysList,
      }
    };
  }

  // Batched content analysis for large chats
  Future<Map<String, dynamic>> _analyzeContentInBatches(ChatEntity chat) async {
    final Map<String, int> wordCounts = {};
    final Map<String, int> emojiCounts = {};
    final Map<String, int> domainCounts = {};

    const batchSize = 2000; // Smaller batch for content analysis

    for (int i = 0; i < chat.messages.length; i += batchSize) {
      final end = (i + batchSize < chat.messages.length)
          ? i + batchSize
          : chat.messages.length;
      final batch = chat.messages.sublist(i, end);

      for (final message in batch) {
        if (message.type == MessageType.text) {
          _processTextMessageBatch(
              message, wordCounts, emojiCounts, domainCounts);
        }
      }

      // Allow UI to remain responsive
      await Future.delayed(const Duration(milliseconds: 5));
    }

    // Get top results
    final sortedWords = wordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topWords = sortedWords
        .where((entry) => entry.key.length > 3 && !_isCommonWord(entry.key))
        .take(50)
        .map((entry) => {'word': entry.key, 'count': entry.value})
        .toList();

    final sortedEmojis = emojiCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEmojis = sortedEmojis
        .take(30)
        .map((entry) => {'emoji': entry.key, 'count': entry.value})
        .toList();

    final sortedDomains = domainCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topDomains = sortedDomains
        .take(20)
        .map((entry) => {'domain': entry.key, 'count': entry.value})
        .toList();

    return {
      'contentAnalysis': {
        'topWords': topWords,
        'topEmojis': topEmojis,
        'topDomains': topDomains,
      }
    };
  }

  // Helper function for batch text processing
  void _processTextMessageBatch(
      MessageEntity message,
      Map<String, int> wordCounts,
      Map<String, int> emojiCounts,
      Map<String, int> domainCounts) {
    final content = message.content;

    // Process words
    final words = content
        .split(RegExp(r'\s+'))
        .map((word) =>
            word.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase())
        .where((word) => word.isNotEmpty);

    for (final word in words) {
      wordCounts[word] = (wordCounts[word] ?? 0) + 1;
    }

    // Process emojis
    final emojiRegExp = RegExp(
      r'[\u{1F600}-\u{1F64F}|\u{1F300}-\u{1F5FF}|\u{1F680}-\u{1F6FF}|\u{2600}-\u{26FF}|\u{2700}-\u{27BF}]',
      unicode: true,
    );

    final emojis = emojiRegExp.allMatches(content).map((m) => m.group(0)!);

    for (final emoji in emojis) {
      emojiCounts[emoji] = (emojiCounts[emoji] ?? 0) + 1;
    }

    // Process URLs and extract domains
    final urlRegExp = RegExp(
      r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
    );

    final urls = urlRegExp.allMatches(content).map((m) => m.group(0)!);

    for (final url in urls) {
      try {
        final uri = Uri.parse(url);
        final domain = uri.host;

        if (domain.isNotEmpty) {
          domainCounts[domain] = (domainCounts[domain] ?? 0) + 1;
        }
      } catch (e) {
        // Skip invalid URLs gracefully
        debugPrint("ContentAnalyzer: Failed to parse URL: $url");
      }
    }
  }

  // Helper function to check common words
  bool _isCommonWord(String word) {
    const commonWords = {
      'the',
      'be',
      'to',
      'of',
      'and',
      'a',
      'in',
      'that',
      'have',
      'i',
      'it',
      'for',
      'not',
      'on',
      'with',
      'he',
      'as',
      'you',
      'do',
      'at',
      'this',
      'but',
      'his',
      'by',
      'from',
      'they',
      'we',
      'say',
      'her',
      'she',
      'or',
      'an',
      'will',
      'my',
      'one',
      'all',
      'would',
      'there',
      'their',
      'what',
      'so',
      'up',
      'out',
      'if',
      'about',
      'who',
      'get',
      'which',
      'go',
      'me',
      'when',
      'make',
      'can',
      'like',
      'time',
      'no',
      'just',
      'him',
      'know',
      'take',
    };
    return commonWords.contains(word.toLowerCase());
  }

  // Generate error results when analysis fails
  Map<String, dynamic> _generateErrorResults(ChatEntity chat, dynamic error) {
    return {
      'error': error.toString(),
      'summary': {
        'totalMessages': chat.messages.length,
        'totalParticipants': chat.users.length,
        'dateRange':
            "${chat.firstMessageDate.toString().split(' ')[0]} - ${chat.lastMessageDate.toString().split(' ')[0]}",
        'avgMessagesPerDay': 0,
        'totalMedia':
            chat.messages.where((m) => m.type != MessageType.text).length,
        'durationDays':
            chat.lastMessageDate.difference(chat.firstMessageDate).inDays + 1,
      }
    };
  }
}

// ============================================================================
// BASE ANALYZER
// ============================================================================
abstract class BaseAnalyzer {
  Future<Map<String, dynamic>> analyze(ChatEntity chat);
}

// ============================================================================
// MESSAGE ANALYZER
// ============================================================================
class MessageAnalyzer implements BaseAnalyzer {
  // Fixed MessageAnalyzer.analyze method - uses names instead of IDs
  @override
  Future<Map<String, dynamic>> analyze(ChatEntity chat) async {
    debugPrint("MessageAnalyzer: Analyzing ${chat.messages.length} messages");

    // Filter out system messages and users
    final realMessages = chat.messages
        .where((msg) =>
            msg.senderId != "System" &&
            !msg.content.toLowerCase().contains('created group') &&
            !msg.content.toLowerCase().contains('added') &&
            !msg.content.toLowerCase().contains('left') &&
            !msg.content.toLowerCase().contains('changed the subject') &&
            !msg.content.toLowerCase().contains('security code changed') &&
            !msg.content.toLowerCase().contains('joined using') &&
            !msg.content.toLowerCase().contains('removed ') &&
            !msg.content.toLowerCase().contains('changed this group') &&
            !msg.content
                .toLowerCase()
                .contains('messages and calls are end-to-end encrypted'))
        .toList();

    final realUsers = chat.users
        .where((user) =>
            user.id != "System" && user.name.toLowerCase() != "system")
        .toList();

    // Create a map from user ID to user name for easy lookup
    final Map<String, String> userIdToName = {};
    for (final user in realUsers) {
      userIdToName[user.id] = user.name;
    }

    // Calculate message counts per real user using NAMES
    final Map<String, int> messageCountPerUserName = {};
    for (final user in realUsers) {
      messageCountPerUserName[user.name] = 0;
    }

    for (final message in realMessages) {
      final userName = userIdToName[message.senderId];
      if (userName != null && messageCountPerUserName.containsKey(userName)) {
        messageCountPerUserName[userName] =
            (messageCountPerUserName[userName] ?? 0) + 1;
      }
    }

    // Calculate total messages (excluding system)
    final int totalMessages = realMessages.length;

    // Create user stats with percentages using NAMES
    final List<Map<String, dynamic>> userStats = [];
    for (final user in realUsers) {
      final messageCount = messageCountPerUserName[user.name] ?? 0;
      final percentage = totalMessages > 0
          ? (messageCount / totalMessages * 100).toStringAsFixed(1)
          : '0';
      userStats.add({
        'userId': user.id,
        'name': user.name,
        'messageCount': messageCount,
        'percentage': double.parse(percentage),
      });
    }

    // Sort users by message count
    userStats.sort((a, b) => b['messageCount'].compareTo(a['messageCount']));

    // Calculate date range
    final firstDate = chat.firstMessageDate;
    final lastDate = chat.lastMessageDate;
    final dateRange = '${_formatDate(firstDate)} - ${_formatDate(lastDate)}';

    // Calculate duration in days
    final duration = lastDate.difference(firstDate).inDays + 1;

    // Calculate average messages per day
    final avgMessagesPerDay =
        duration > 0 ? (totalMessages / duration).toStringAsFixed(1) : '0';

    // Count media messages (excluding system)
    final mediaCount =
        realMessages.where((m) => m.type != MessageType.text).length;

    debugPrint(
        "MessageAnalyzer: Analysis complete. ${userStats.length} real users, $totalMessages real messages");
    debugPrint(
        "MessageAnalyzer: User names: ${userStats.map((u) => u['name']).join(', ')}");

    return {
      'messageCount': {
        'total': totalMessages,
        'perUser': messageCountPerUserName, // This now uses names as keys
      },
      'userStats': userStats,
      'summary': {
        'totalMessages': totalMessages,
        'totalParticipants': realUsers.length,
        'dateRange': dateRange,
        'durationDays': duration,
        'avgMessagesPerDay': double.parse(avgMessagesPerDay),
        'totalMedia': mediaCount,
      },
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// features/analysis/analysis_feature.dart - PART 2
// Time Analyzer and User Analyzer

// ============================================================================
// TIME ANALYZER
// ============================================================================
class TimeAnalyzer implements BaseAnalyzer {
  @override
  Future<Map<String, dynamic>> analyze(ChatEntity chat) async {
    final messages = chat.messages;

    // Initialize counters
    final Map<int, int> hourCounts = {};
    final Map<int, int> dayCounts = {};
    final Map<int, int> monthCounts = {};
    final Map<String, int> monthYearCounts = {};

    // Days of week (1 = Monday, 7 = Sunday)
    final Map<int, String> daysOfWeek = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };

    final Map<String, int> dayOfWeekCounts = {
      'Monday': 0,
      'Tuesday': 0,
      'Wednesday': 0,
      'Thursday': 0,
      'Friday': 0,
      'Saturday': 0,
      'Sunday': 0,
    };

    // Analyze messages
    for (final message in messages) {
      final timestamp = message.timestamp;

      // Hour of day (0-23)
      final hour = timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;

      // Day of month (1-31)
      final day = timestamp.day;
      dayCounts[day] = (dayCounts[day] ?? 0) + 1;

      // Month (1-12)
      final month = timestamp.month;
      monthCounts[month] = (monthCounts[month] ?? 0) + 1;

      // Month-Year combination (YYYY-MM)
      final monthYear =
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
      monthYearCounts[monthYear] = (monthYearCounts[monthYear] ?? 0) + 1;

      // Day of week (1 = Monday, 7 = Sunday)
      final dayOfWeek = timestamp.weekday;
      dayOfWeekCounts[daysOfWeek[dayOfWeek]!] =
          (dayOfWeekCounts[daysOfWeek[dayOfWeek]!] ?? 0) + 1;
    }

    // Format hour data for 0-23 range (with leading zeros)
    final Map<String, int> formattedHourCounts = {};
    for (int i = 0; i < 24; i++) {
      final key = i.toString().padLeft(2, '0');
      formattedHourCounts[key] = hourCounts[i] ?? 0;
    }

    // Find the most active day of week
    String mostActiveDay = 'None';
    int mostActiveDayCount = 0;
    dayOfWeekCounts.forEach((day, count) {
      if (count > mostActiveDayCount) {
        mostActiveDay = day;
        mostActiveDayCount = count;
      }
    });

    // Find the most active hour
    String mostActiveHour = 'None';
    int mostActiveHourCount = 0;
    formattedHourCounts.forEach((hour, count) {
      if (count > mostActiveHourCount) {
        mostActiveHour = hour;
        mostActiveHourCount = count;
      }
    });

    // Find days with most messages (top 10)
    final Map<String, int> dayMessageCounts = {};
    for (final message in messages) {
      final date =
          '${message.timestamp.year}-${message.timestamp.month.toString().padLeft(2, '0')}-${message.timestamp.day.toString().padLeft(2, '0')}';
      dayMessageCounts[date] = (dayMessageCounts[date] ?? 0) + 1;
    }

    final List<MapEntry<String, int>> topDays = dayMessageCounts.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<Map<String, dynamic>> topDaysList =
        topDays.take(10).map((entry) {
      return {
        'date': entry.key,
        'count': entry.value,
      };
    }).toList();

    return {
      'timeAnalysis': {
        'hourOfDay': formattedHourCounts,
        'dayOfWeek': dayOfWeekCounts,
        'monthCounts': monthCounts,
        'monthYearCounts': monthYearCounts,
        'mostActiveDay': {
          'day': mostActiveDay,
          'count': mostActiveDayCount,
        },
        'mostActiveHour': {
          'hour': mostActiveHour,
          'count': mostActiveHourCount,
        },
        'topDays': topDaysList,
      }
    };
  }
}

// ============================================================================
// USER ANALYZER
// ============================================================================
class UserAnalyzer implements BaseAnalyzer {
  // Fixed UserAnalyzer - completely removes system user and messages
  @override
  Future<Map<String, dynamic>> analyze(ChatEntity chat) async {
    // Only filter obvious system messages
    final systemMessagePatterns = [
      'created group',
      ' added ',
      ' left',
      'changed the subject',
      'security code changed',
      'joined using',
      'removed ',
      'changed this group',
      'messages and calls are end-to-end encrypted',
    ];

    // Filter out system messages but keep real user messages
    final realMessages = chat.messages.where((msg) {
      // Filter by sender ID - only obvious system senders
      if (msg.senderId == "System") {
        return false;
      }

      // Filter by content patterns - only obvious system messages
      final content = msg.content.toLowerCase();
      for (final pattern in systemMessagePatterns) {
        if (content.contains(pattern)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Filter out system users - only obvious system users
    final realUsers = chat.users.where((user) {
      // Only filter obvious system users
      if (user.id == "System" || user.name.toLowerCase() == "system") {
        return false;
      }

      return true; // Keep all other users
    }).toList();

    debugPrint(
        "UserAnalyzer: Found ${realUsers.length} real users from ${chat.users.length} total");
    debugPrint(
        "UserAnalyzer: Real users: ${realUsers.map((u) => '${u.name} (${u.id.substring(0, 8)}...)').join(', ')}");

    // Initialize user tracking maps for all real users
    Map<String, int> messageCounts = {};
    Map<String, int> wordCounts = {};
    Map<String, int> letterCounts = {};
    Map<String, int> mediaCounts = {};
    Map<String, int> emojiCounts = {};
    Map<String, List<int>> responseTimes = {};

    // Initialize maps for real users
    for (final user in realUsers) {
      messageCounts[user.id] = 0;
      wordCounts[user.id] = 0;
      letterCounts[user.id] = 0;
      mediaCounts[user.id] = 0;
      emojiCounts[user.id] = 0;
      responseTimes[user.id] = [];
    }

    // Track conversation patterns
    Map<String, int> conversationStarters = {};
    Map<String, int> conversationEnders = {};

    const int conversationGapThreshold = 60;

    String? lastSender;
    DateTime? lastMessageTime;

    // Sort messages by timestamp
    final sortedMessages = [...realMessages]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    debugPrint(
        "UserAnalyzer: Processing ${sortedMessages.length} real messages");

    // Process each message
    for (int i = 0; i < sortedMessages.length; i++) {
      final message = sortedMessages[i];
      final senderId = message.senderId;

      // Only process if we have this user in our map
      if (messageCounts.containsKey(senderId)) {
        // Count messages per user
        messageCounts[senderId] = (messageCounts[senderId] ?? 0) + 1;

        // Count words
        final words = message.content.split(RegExp(r'\s+'));
        wordCounts[senderId] = (wordCounts[senderId] ?? 0) + words.length;

        // Count characters
        letterCounts[senderId] =
            (letterCounts[senderId] ?? 0) + message.content.length;

        // Count media messages
        if (message.type != MessageType.text) {
          mediaCounts[senderId] = (mediaCounts[senderId] ?? 0) + 1;
        }

        // Count emojis
        final emojiCount = RegExp(r'[\u{1F600}-\u{1F64F}]', unicode: true)
            .allMatches(message.content)
            .length;
        emojiCounts[senderId] = (emojiCounts[senderId] ?? 0) + emojiCount;

        // Calculate response times
        if (lastSender != null &&
            lastMessageTime != null &&
            lastSender != senderId) {
          final responseTime =
              message.timestamp.difference(lastMessageTime!).inSeconds;
          if (responseTime < 86400) {
            // Less than 24 hours
            responseTimes[senderId]?.add(responseTime);
          }
        }

        // Track conversation starters
        if (lastMessageTime == null ||
            message.timestamp.difference(lastMessageTime!).inMinutes >
                conversationGapThreshold) {
          conversationStarters[senderId] =
              (conversationStarters[senderId] ?? 0) + 1;
        }

        // Track conversation enders
        if (i < sortedMessages.length - 1) {
          final nextMessage = sortedMessages[i + 1];
          if (nextMessage.timestamp.difference(message.timestamp).inMinutes >
              conversationGapThreshold) {
            conversationEnders[senderId] =
                (conversationEnders[senderId] ?? 0) + 1;
          }
        } else {
          conversationEnders[senderId] =
              (conversationEnders[senderId] ?? 0) + 1;
        }

        lastSender = senderId;
        lastMessageTime = message.timestamp;
      }
    }

    // Calculate averages
    Map<String, double> avgResponseTimes = {};
    Map<String, double> avgMessageLength = {};

    for (final userId in messageCounts.keys) {
      // Average response time
      final times = responseTimes[userId] ?? [];
      if (times.isNotEmpty) {
        avgResponseTimes[userId] = times.reduce((a, b) => a + b) / times.length;
      } else {
        avgResponseTimes[userId] = 0;
      }

      // Average message length
      final count = messageCounts[userId] ?? 1;
      final letters = letterCounts[userId] ?? 0;
      avgMessageLength[userId] = count > 0 ? letters / count : 0;
    }

    // Create user statistics for ALL real users (even if they have 0 messages)
    List<Map<String, dynamic>> userStats = [];
    for (final user in realUsers) {
      userStats.add({
        'userId': user.id,
        'name': user.name,
        'messageCount': messageCounts[user.id] ?? 0,
        'wordCount': wordCounts[user.id] ?? 0,
        'letterCount': letterCounts[user.id] ?? 0,
        'mediaCount': mediaCounts[user.id] ?? 0,
        'emojiCount': emojiCounts[user.id] ?? 0,
        'avgMessageLength': avgMessageLength[user.id] ?? 0,
        'avgResponseTimeSeconds': avgResponseTimes[user.id] ?? 0,
        'conversationStarts': conversationStarters[user.id] ?? 0,
        'conversationEnds': conversationEnders[user.id] ?? 0,
      });
    }

    // Sort by message count
    userStats.sort((a, b) => b['messageCount'].compareTo(a['messageCount']));

    debugPrint("UserAnalyzer: Final user stats: ${userStats.length} users");
    for (final user in userStats) {
      debugPrint("  - ${user['name']}: ${user['messageCount']} messages");
    }

    // Find key users
    final mostTalkative = userStats.isNotEmpty ? userStats.first : null;
    final leastTalkative = userStats.length > 1 ? userStats.last : null;

    final activeResponders =
        userStats.where((user) => user['avgResponseTimeSeconds'] > 0).toList();
    activeResponders.sort((a, b) =>
        a['avgResponseTimeSeconds'].compareTo(b['avgResponseTimeSeconds']));

    final fastestResponder =
        activeResponders.isNotEmpty ? activeResponders.first : null;
    final slowestResponder =
        activeResponders.length > 1 ? activeResponders.last : null;

    return {
      'userAnalysis': {
        'userData': userStats,
        'mostTalkative': mostTalkative,
        'leastTalkative': leastTalkative,
        'fastestResponder': fastestResponder,
        'slowestResponder': slowestResponder,
      }
    };
  }
}

// features/analysis/analysis_feature.dart - PART 3
// Content Analyzer and Analysis BLoC

// ============================================================================
// CONTENT ANALYZER
// ============================================================================
// Fixed ContentAnalyzer - Count ALL words without filtering
class ContentAnalyzer implements BaseAnalyzer {
  final RegExp emojiRegExp = RegExp(
    r'[\u{1F600}-\u{1F64F}|\u{1F300}-\u{1F5FF}|\u{1F680}-\u{1F6FF}|\u{2600}-\u{26FF}|\u{2700}-\u{27BF}]',
    unicode: true,
  );

  final RegExp urlRegExp = RegExp(
    r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
  );

  @override
  Future<Map<String, dynamic>> analyze(ChatEntity chat) async {
    // Filter out system messages
    final realMessages = chat.messages
        .where((msg) =>
            msg.senderId != "System" &&
            msg.type == MessageType.text &&
            !msg.content.toLowerCase().contains('created group') &&
            !msg.content.toLowerCase().contains('added') &&
            !msg.content.toLowerCase().contains('left'))
        .toList();

    // Create a comprehensive word counter - NO FILTERING, COUNT ALL WORDS
    final Map<String, int> allWordCounts = {};
    final Map<String, int> emojiCounts = {};
    final Map<String, int> domainCounts = {};

    // Per-user content counters
    final Map<String, Map<String, int>> wordCountsByUser = {};
    final Map<String, Map<String, int>> emojiCountsByUser = {};
    final Map<String, Map<String, int>> domainCountsByUser = {};

    // Initialize user maps (excluding System)
    for (final user in chat.users.where((u) => u.id != "System")) {
      wordCountsByUser[user.id] = {};
      emojiCountsByUser[user.id] = {};
      domainCountsByUser[user.id] = {};
    }

    // Process each text message
    for (final message in realMessages) {
      _processAllWordsInMessage(
        message,
        allWordCounts,
        wordCountsByUser,
        emojiCounts,
        emojiCountsByUser,
        domainCounts,
        domainCountsByUser,
      );
    }

    // Convert word counts to list and sort by count (highest first)
    final List<Map<String, dynamic>> allWordsRanked = allWordCounts.entries
        .where((entry) =>
            entry.key.isNotEmpty &&
            entry.key.length > 1) // Only remove empty and single character
        .map((entry) => {
              'word': entry.key,
              'count': entry.value,
              'percentage': ((entry.value / realMessages.length) * 100)
                  .toStringAsFixed(2),
            })
        .toList();

    // Sort by count (descending)
    allWordsRanked.sort((a, b) => b['count'].compareTo(a['count']));

    // Get top words for display (top 100)
    final topWords = allWordsRanked.take(100).toList();

    // Sort and get top emojis
    final sortedEmojis = emojiCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEmojis = sortedEmojis
        .take(50)
        .map((entry) => {'emoji': entry.key, 'count': entry.value})
        .toList();

    // Sort and get top domains
    final sortedDomains = domainCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topDomains = sortedDomains
        .take(20)
        .map((entry) => {'domain': entry.key, 'count': entry.value})
        .toList();

    // Generate per-user statistics
    final List<Map<String, dynamic>> userWordStats = [];
    final List<Map<String, dynamic>> userEmojiStats = [];
    final List<Map<String, dynamic>> userDomainStats = [];

    for (final user in chat.users.where((u) => u.id != "System")) {
      final userWords = wordCountsByUser[user.id] ?? {};
      final userEmojis = emojiCountsByUser[user.id] ?? {};
      final userDomains = domainCountsByUser[user.id] ?? {};

      // Get top words for this user
      final sortedUserWords = userWords.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topUserWords = sortedUserWords
          .take(10)
          .map((entry) => {'word': entry.key, 'count': entry.value})
          .toList();

      // Get top emojis for this user
      final sortedUserEmojis = userEmojis.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topUserEmojis = sortedUserEmojis
          .take(10)
          .map((entry) => {'emoji': entry.key, 'count': entry.value})
          .toList();

      // Get top domains for this user
      final sortedUserDomains = userDomains.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topUserDomains = sortedUserDomains
          .take(5)
          .map((entry) => {'domain': entry.key, 'count': entry.value})
          .toList();

      // Add user statistics
      userWordStats.add({
        'userId': user.id,
        'name': user.name,
        'topWords': topUserWords,
        'totalWords': userWords.values.fold(0, (sum, count) => sum + count),
        'uniqueWords': userWords.length,
      });

      userEmojiStats.add({
        'userId': user.id,
        'name': user.name,
        'topEmojis': topUserEmojis,
        'totalEmojis': userEmojis.values.fold(0, (sum, count) => sum + count),
      });

      userDomainStats.add({
        'userId': user.id,
        'name': user.name,
        'topDomains': topUserDomains,
        'totalDomains': userDomains.values.fold(0, (sum, count) => sum + count),
      });
    }

    return {
      'contentAnalysis': {
        'allWordsRanked': allWordsRanked, // Complete ranked list of ALL words
        'topWords': topWords,
        'topEmojis': topEmojis,
        'topDomains': topDomains,
        'totalUniqueWords': allWordCounts.length,
        'totalWords': allWordCounts.values.fold(0, (sum, count) => sum + count),
        'totalEmojis': emojiCounts.values.fold(0, (sum, count) => sum + count),
        'totalDomains': domainCounts.length,
        'userWordStats': userWordStats,
        'userEmojiStats': userEmojiStats,
        'userDomainStats': userDomainStats,
      }
    };
  }

  void _processAllWordsInMessage(
    MessageEntity message,
    Map<String, int> allWordCounts,
    Map<String, Map<String, int>> wordCountsByUser,
    Map<String, int> emojiCounts,
    Map<String, Map<String, int>> emojiCountsByUser,
    Map<String, int> domainCounts,
    Map<String, Map<String, int>> domainCountsByUser,
  ) {
    final content = message.content;
    final senderId = message.senderId;

    // Process ALL words - minimal cleaning, just split by spaces
    final words = content
        .toLowerCase() // Convert to lowercase for consistency
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF\u0900-\u097F]'),
            ' ') // Keep letters, numbers, spaces, Arabic/Urdu/Hindi
        .split(RegExp(r'\s+')) // Split by whitespace
        .where((word) => word.trim().isNotEmpty) // Remove empty strings
        .map((word) => word.trim()) // Trim whitespace
        .toList();

    // Count EVERY word without any filtering
    for (final word in words) {
      if (word.isNotEmpty) {
        // Count in global map
        allWordCounts[word] = (allWordCounts[word] ?? 0) + 1;

        // Count per user
        if (wordCountsByUser.containsKey(senderId)) {
          wordCountsByUser[senderId]![word] =
              (wordCountsByUser[senderId]![word] ?? 0) + 1;
        }
      }
    }

    // Process emojis
    final emojis =
        emojiRegExp.allMatches(content).map((m) => m.group(0)!).toList();

    for (final emoji in emojis) {
      emojiCounts[emoji] = (emojiCounts[emoji] ?? 0) + 1;
      if (emojiCountsByUser.containsKey(senderId)) {
        emojiCountsByUser[senderId]![emoji] =
            (emojiCountsByUser[senderId]![emoji] ?? 0) + 1;
      }
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

// ============================================================================
// ANALYSIS BLOC
// ============================================================================
class AnalysisBloc extends Bloc<AnalysisEvent, AnalysisState> {
  final AnalyzeChatUseCase analyzeChatUseCase;

  AnalysisBloc({
    required this.analyzeChatUseCase,
  }) : super(AnalysisInitial()) {
    on<AnalyzeChatEvent>(_onAnalyzeChat);
  }

  /// Handle chat analysis event
  Future<void> _onAnalyzeChat(
      AnalyzeChatEvent event, Emitter<AnalysisState> emit) async {
    debugPrint("AnalysisBloc: Starting analysis for chat ID: ${event.chatId}");
    emit(AnalysisLoading());

    try {
      debugPrint("AnalysisBloc: Calling analyzeChatUseCase");
      final results = await analyzeChatUseCase(event.chatId);

      // Debug log the results structure
      debugPrint(
          "AnalysisBloc: Analysis completed with result keys: ${results.keys.toList()}");

      // Validate results
      if (results.isEmpty) {
        debugPrint("AnalysisBloc: Empty results returned");
        emit(AnalysisError("No analysis results available"));
        return;
      }

      // Check for error in results
      if (results.containsKey('error')) {
        debugPrint(
            "AnalysisBloc: Error in analysis results: ${results['error']}");
        emit(AnalysisError("Analysis failed: ${results['error']}"));
        return;
      }

      // Ensure we have essential data
      if (!results.containsKey('summary')) {
        debugPrint("AnalysisBloc: Missing summary in results");
        emit(AnalysisError("Analysis incomplete: Missing summary data"));
        return;
      }

      debugPrint("AnalysisBloc: Emitting AnalysisSuccess state");
      emit(AnalysisSuccess(event.chatId, results));
    } catch (e, stackTrace) {
      debugPrint("AnalysisBloc: Analysis failed with error: $e");
      debugPrint("AnalysisBloc: Stack trace: $stackTrace");
      emit(AnalysisError("Analysis failed: ${e.toString()}"));
    }
  }
}
