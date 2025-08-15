// ============================================================================
// FILE: features/analysis/analysis_use_cases.dart
// Analysis use cases - Fixed with import prefix to resolve conflicts
// ============================================================================
import 'package:flutter/foundation.dart';
import '../../shared/domain.dart' as domain;
import 'analysis_repository.dart' as analysis_repo;
import 'analysis_models.dart';
import 'analyzers/message_analyzer.dart';
import 'analyzers/time_analyzer.dart';
import 'analyzers/user_analyzer.dart';
import 'analyzers/content_analyzer.dart';
import 'analyzers/enhanced/conversation_dynamics_analyzer.dart';
import 'analyzers/enhanced/behavior_pattern_analyzer.dart';
import 'analyzers/enhanced/relationship_analyzer.dart';
import 'analyzers/enhanced/content_intelligence_analyzer.dart';
import 'analyzers/enhanced/temporal_insight_analyzer.dart';

class AnalyzeChatUseCase {
  final domain.ChatRepository chatRepository;
  final analysis_repo.AnalysisRepository analysisRepository;
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

  Future<ChatAnalysisResult> execute({
    required String chatId,
    AnalysisConfig? config,
    bool forceRefresh = false,
  }) async {
    try {
      debugPrint("AnalyzeChatUseCase: Starting enhanced analysis for chat: $chatId");

      config ??= AnalysisConfig.defaultConfig();

      // Check if we already have analysis results and not forcing refresh
      if (!forceRefresh) {
        final existingResults = await analysisRepository.getAnalysisResults(chatId);
        if (existingResults != null) {
          debugPrint("AnalyzeChatUseCase: Using existing analysis results");
          return existingResults;
        }
      }

      // Get chat data
      final chat = await chatRepository.getChatById(chatId);
      if (chat == null) {
        throw Exception("Chat not found: $chatId");
      }

      debugPrint("AnalyzeChatUseCase: Chat found with ${chat.messages.length} messages");

      // Check if chat is too large for full analysis
      if (chat.messages.length > config.maxMessagesToAnalyze) {
        debugPrint("AnalyzeChatUseCase: Large chat detected, using optimized analysis");
        return await _performOptimizedAnalysis(chat, chatId, config);
      }

      // Run all analyzers based on config
      final analysisResults = <String, AnalysisResult>{};

      // Core analyzers
      if (config.includeUserAnalysis) {
        final messageResults = await messageAnalyzer.analyze(chat);
        analysisResults['messages'] = AnalysisResult(
          type: 'messages',
          data: messageResults,
          confidence: 0.95,
          generatedAt: DateTime.now(),
        );
      }

      if (config.includeTimeAnalysis) {
        final timeResults = await timeAnalyzer.analyze(chat);
        analysisResults['time'] = AnalysisResult(
          type: 'time',
          data: timeResults,
          confidence: 0.9,
          generatedAt: DateTime.now(),
        );
      }

      if (config.includeUserAnalysis) {
        final userResults = await userAnalyzer.analyze(chat);
        analysisResults['users'] = AnalysisResult(
          type: 'users',
          data: userResults,
          confidence: 0.95,
          generatedAt: DateTime.now(),
        );
      }

      if (config.includeContentAnalysis) {
        final contentResults = await contentAnalyzer.analyze(chat);
        analysisResults['content'] = AnalysisResult(
          type: 'content',
          data: contentResults,
          confidence: 0.9,
          generatedAt: DateTime.now(),
        );
      }

      // Enhanced analyzers
      if (config.includeConversationDynamics) {
        final conversationResults = await conversationDynamicsAnalyzer.analyze(chat);
        analysisResults['conversationDynamics'] = conversationResults;
      }

      if (config.includeBehaviorAnalysis) {
        final behaviorResults = await behaviorPatternAnalyzer.analyze(chat);
        analysisResults['behaviorPatterns'] = behaviorResults;
      }

      if (config.includeRelationshipAnalysis) {
        final relationshipResults = await relationshipAnalyzer.analyze(chat);
        analysisResults['relationshipDynamics'] = relationshipResults;
      }

      if (config.includeContentIntelligence) {
        final contentIntelligenceResults = await contentIntelligenceAnalyzer.analyze(chat);
        analysisResults['contentIntelligence'] = AnalysisResult(
          type: 'contentIntelligence',
          data: contentIntelligenceResults,
          confidence: 0.85,
          generatedAt: DateTime.now(),
        );
      }

      if (config.includeTemporalInsights) {
        final temporalResults = await temporalInsightAnalyzer.analyze(chat);
        analysisResults['temporalInsights'] = AnalysisResult(
          type: 'temporalInsights',
          data: temporalResults,
          confidence: 0.8,
          generatedAt: DateTime.now(),
        );
      }

      final chatAnalysisResult = ChatAnalysisResult(
        chatId: chatId,
        results: analysisResults,
        generatedAt: DateTime.now(),
      );

      debugPrint("AnalyzeChatUseCase: Enhanced analysis complete with ${analysisResults.length} analysis types");

      // Save results
      await analysisRepository.saveAnalysisResults(chatId, chatAnalysisResult);

      return chatAnalysisResult;
    } catch (e, stackTrace) {
      debugPrint("AnalyzeChatUseCase: Error during enhanced analysis: $e");
      debugPrint("Stack trace: $stackTrace");
      
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

  // Keep backward compatibility with the old call method
  Future<Map<String, dynamic>> call(String chatId) async {
    final result = await execute(chatId: chatId);
    
    // Convert ChatAnalysisResult back to Map for backward compatibility
    final combinedResults = <String, dynamic>{};
    
    for (final entry in result.results.entries) {
      combinedResults.addAll(entry.value.data);
    }
    
    return combinedResults;
  }

  // Optimized analysis for large chats
  Future<ChatAnalysisResult> _performOptimizedAnalysis(
      domain.ChatEntity chat, String chatId, AnalysisConfig config) async {
    try {
      // Process in batches to avoid memory issues
      const batchSize = 5000;
      final batches = <List<domain.MessageEntity>>[];

      for (int i = 0; i < chat.messages.length; i += batchSize) {
        final end = (i + batchSize < chat.messages.length)
            ? i + batchSize
            : chat.messages.length;
        batches.add(chat.messages.sublist(i, end));
      }

      debugPrint("AnalyzeChatUseCase: Processing ${batches.length} batches");

      // Run core analyzers only for large chats
      final analysisResults = <String, AnalysisResult>{};

      final messageResults = await messageAnalyzer.analyze(chat);
      analysisResults['messages'] = AnalysisResult(
        type: 'messages',
        data: messageResults,
        confidence: 0.8,
        generatedAt: DateTime.now(),
      );

      final timeResults = await timeAnalyzer.analyze(chat);
      analysisResults['time'] = AnalysisResult(
        type: 'time',
        data: timeResults,
        confidence: 0.8,
        generatedAt: DateTime.now(),
      );

      final userResults = await userAnalyzer.analyze(chat);
      analysisResults['users'] = AnalysisResult(
        type: 'users',
        data: userResults,
        confidence: 0.8,
        generatedAt: DateTime.now(),
      );

      // Add optimization metadata
      analysisResults['optimization'] = AnalysisResult(
        type: 'optimization',
        data: {
          'optimized': true,
          'batchCount': batches.length,
          'totalMessages': chat.messages.length,
        },
        confidence: 1.0,
        generatedAt: DateTime.now(),
      );

      final chatAnalysisResult = ChatAnalysisResult(
        chatId: chatId,
        results: analysisResults,
        generatedAt: DateTime.now(),
      );

      await analysisRepository.saveAnalysisResults(chatId, chatAnalysisResult);
      return chatAnalysisResult;
    } catch (e) {
      return _generateErrorResults(chat, e);
    }
  }

  ChatAnalysisResult _generateErrorResults(domain.ChatEntity chat, dynamic error) {
    final errorResult = AnalysisResult(
      type: 'error',
      data: {
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
      },
      confidence: 0.0,
      generatedAt: DateTime.now(),
    );

    return ChatAnalysisResult(
      chatId: chat.id,
      results: {'error': errorResult},
      generatedAt: DateTime.now(),
    );
  }

  ChatAnalysisResult _generateMinimalErrorResults(String chatId, dynamic error) {
    final errorResult = AnalysisResult(
      type: 'error',
      data: {
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
      },
      confidence: 0.0,
      generatedAt: DateTime.now(),
    );

    return ChatAnalysisResult(
      chatId: chatId,
      results: {'error': errorResult},
      generatedAt: DateTime.now(),
    );
  }
}