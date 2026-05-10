// ============================================================================
// FILE: features/ai_insights/services/ai_insights_service.dart
// AI Insights Service - Orchestrates stats aggregation and LLM calls
// ============================================================================
import 'package:flutter/foundation.dart';
import '../../analysis/analysis_models.dart';
import '../../analysis/services/stats_aggregator.dart';
import '../models/llm_models.dart';
import '../providers/llm_provider.dart';
import '../providers/deepseek_provider.dart';

/// Service for generating AI-powered insights from chat analysis
class AIInsightsService {
  final StatsAggregator _statsAggregator;
  LLMProvider? _provider;
  LLMConfig? _config;

  // Cache for generated insights
  final Map<String, AIInsights> _insightsCache = {};

  AIInsightsService({
    required StatsAggregator statsAggregator,
  }) : _statsAggregator = statsAggregator;

  /// Check if the service is configured with an API key
  bool get isConfigured => _provider?.isConfigured ?? false;

  /// Get current provider name
  String get providerName => _provider?.name ?? 'Not configured';

  /// Configure the service with an API key
  void configure({
    required String apiKey,
    LLMProviderType providerType = LLMProviderType.deepseek,
  }) {
    switch (providerType) {
      case LLMProviderType.deepseek:
        _config = LLMConfig.deepseek(apiKey: apiKey);
        _provider = DeepSeekProvider(config: _config!);
        break;
      case LLMProviderType.openai:
        _config = LLMConfig.openai(apiKey: apiKey);
        // OpenAI provider could be added here in future
        _provider = DeepSeekProvider(config: _config!); // Fallback for now
        break;
    }
    debugPrint('AIInsightsService: Configured with ${_provider!.name}');
  }

  /// Validate the configured API key
  Future<bool> validateApiKey() async {
    if (_provider == null) return false;
    return await _provider!.validateApiKey();
  }

  /// Generate AI insights for a chat analysis result
  Future<AIInsightsResult> generateInsights({
    required ChatAnalysisResult analysisResult,
    bool forceRefresh = false,
  }) async {
    final chatId = analysisResult.chatId;

    // Check cache first
    if (!forceRefresh && _insightsCache.containsKey(chatId)) {
      debugPrint('AIInsightsService: Returning cached insights for $chatId');
      return AIInsightsResult.success(_insightsCache[chatId]!);
    }

    // Validate configuration
    if (!isConfigured) {
      return AIInsightsResult.error(
        'AI insights not configured. Please add your API key in settings.',
      );
    }

    try {
      debugPrint('AIInsightsService: Generating insights for $chatId');

      // Step 1: Aggregate stats into LLM-ready format
      final statsContext = _statsAggregator.createLLMPromptContext(analysisResult);
      debugPrint('AIInsightsService: Stats context length: ${statsContext.length}');

      // Step 2: Call LLM provider
      final insights = await _provider!.generateInsights(
        chatId: chatId,
        statsContext: statsContext,
      );

      // Step 3: Cache and return
      _insightsCache[chatId] = insights;

      final cost = _provider!.estimateCost(
        inputTokens: (statsContext.length / 4).round(), // Rough estimate
        outputTokens: insights.tokensUsed,
      );

      debugPrint('AIInsightsService: Insights generated (est. cost: \$${cost.toStringAsFixed(4)})');

      return AIInsightsResult.success(insights);
    } catch (e) {
      debugPrint('AIInsightsService: Error generating insights: $e');
      return AIInsightsResult.error('Failed to generate insights: $e');
    }
  }

  /// Get cached insights for a chat
  AIInsights? getCachedInsights(String chatId) {
    return _insightsCache[chatId];
  }

  /// Clear cached insights
  void clearCache([String? chatId]) {
    if (chatId != null) {
      _insightsCache.remove(chatId);
    } else {
      _insightsCache.clear();
    }
  }

  /// Estimate cost for generating insights
  double estimateCost(ChatAnalysisResult analysisResult) {
    if (_provider == null) return 0.0;

    final statsContext = _statsAggregator.createLLMPromptContext(analysisResult);
    final inputTokens = (statsContext.length / 4).round(); // ~4 chars per token
    const outputTokens = 1500; // Typical response size

    return _provider!.estimateCost(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
    );
  }
}

/// Result wrapper for AI insights generation
class AIInsightsResult {
  final AIInsights? insights;
  final String? errorMessage;
  final bool isSuccess;

  const AIInsightsResult._({
    this.insights,
    this.errorMessage,
    required this.isSuccess,
  });

  factory AIInsightsResult.success(AIInsights insights) {
    return AIInsightsResult._(
      insights: insights,
      isSuccess: true,
    );
  }

  factory AIInsightsResult.error(String message) {
    return AIInsightsResult._(
      errorMessage: message,
      isSuccess: false,
    );
  }
}

/// Supported LLM provider types
enum LLMProviderType {
  deepseek,
  openai,
}
