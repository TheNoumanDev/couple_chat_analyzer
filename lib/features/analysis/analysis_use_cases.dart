// ============================================================================
// FILE: features/analysis/analysis_use_cases.dart
// ============================================================================
import 'package:flutter/foundation.dart';
import '../../shared/domain.dart';
import 'analyzers/message_analyzer.dart';
import 'analyzers/time_analyzer.dart';
import 'analyzers/user_analyzer.dart';
import 'analyzers/content_analyzer.dart';
import 'enhanced_analyzers.dart';

class AnalyzeChatUseCase {
  final ChatRepository chatRepository;
  final AnalysisRepository analysisRepository;
  final MessageAnalyzer messageAnalyzer;
  final TimeAnalyzer timeAnalyzer;
  final UserAnalyzer userAnalyzer;
  final ContentAnalyzer contentAnalyzer;
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
    required this.conversationDynamicsAnalyzer,
    required this.behaviorPatternAnalyzer,
    required this.relationshipAnalyzer,
    required this.contentIntelligenceAnalyzer,
    required this.temporalInsightAnalyzer,
  });

  Future<Map<String, dynamic>> call(String chatId) async {
    try {
      debugPrint("AnalyzeChatUseCase: Starting enhanced analysis for chat: $chatId");

      // Check if we already have analysis results
      final existingResults = await analysisRepository.getAnalysisResults(chatId);
      if (existingResults != null && existingResults.isNotEmpty) {
        debugPrint("AnalyzeChatUseCase: Using existing analysis results");
        return existingResults;
      }

      // Get chat data
      final chat = await chatRepository.getChatById(chatId);
      if (chat == null) {
        throw Exception("Chat not found: $chatId");
      }

      debugPrint("AnalyzeChatUseCase: Chat found with ${chat.messages.length} messages");

      // Check if chat is too large for full analysis
      if (chat.messages.length > 50000) {
        debugPrint("AnalyzeChatUseCase: Large chat detected, using optimized analysis");
        return await _performOptimizedAnalysis(chat, chatId);
      }

      // Run all analyzers
      final messageResults = await messageAnalyzer.analyze(chat);
      final timeResults = await timeAnalyzer.analyze(chat);
      final userResults = await userAnalyzer.analyze(chat);
      final contentResults = await contentAnalyzer.analyze(chat);

      // Enhanced analyzers
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
      
      // Try to get chat for error results, but handle if it fails
      try {
        final chat = await chatRepository.getChatById(chatId);
        if (chat != null) {
          return _generateErrorResults(chat, e);
        }
      } catch (chatError) {
        debugPrint("AnalyzeChatUseCase: Could not get chat for error results: $chatError");
      }
      
      // Return minimal error results if we can't get the chat
      return _generateMinimalErrorResults(chatId, e);
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

      debugPrint("AnalyzeChatUseCase: Processing ${batches.length} batches");

      // Run core analyzers only for large chats
      final messageResults = await messageAnalyzer.analyze(chat);
      final timeResults = await timeAnalyzer.analyze(chat);
      final userResults = await userAnalyzer.analyze(chat);

      final combinedResults = {
        ...messageResults,
        ...timeResults,
        ...userResults,
        'optimized': true,
        'batchCount': batches.length,
      };

      await analysisRepository.saveAnalysisResults(chatId, combinedResults);
      return combinedResults;
    } catch (e) {
      return _generateErrorResults(chat, e);
    }
  }

  Map<String, dynamic> _generateErrorResults(ChatEntity chat, dynamic error) {
    return {
      'error': true,
      'errorMessage': error.toString(),
      'summary': {
        'totalMessages': chat.messages.length,
        'totalUsers': chat.users.length,
        'dateRange': "${chat.firstMessageDate.toString().split(' ')[0]} - ${chat.lastMessageDate.toString().split(' ')[0]}",
        'avgMessagesPerDay': 0,
        'totalMedia': 0,
        'durationDays': chat.lastMessageDate.difference(chat.firstMessageDate).inDays + 1,
        'status': 'Analysis failed',
      }
    };
  }

  Map<String, dynamic> _generateMinimalErrorResults(String chatId, dynamic error) {
    return {
      'error': true,
      'errorMessage': error.toString(),
      'summary': {
        'totalMessages': 0,
        'totalUsers': 0,
        'dateRange': 'Unknown',
        'avgMessagesPerDay': 0,
        'totalMedia': 0,
        'durationDays': 0,
        'status': 'Analysis failed - could not load chat',
      }
    };
  }
}