// ============================================================================
// FILE: features/ai_insights/providers/llm_provider.dart
// Abstract LLM provider interface
// ============================================================================
import '../models/llm_models.dart';

/// Abstract interface for LLM providers
/// Implementations: DeepSeekProvider, OpenAIProvider (future)
abstract class LLMProvider {
  /// Provider name for logging and UI
  String get name;

  /// Check if provider is configured with valid API key
  bool get isConfigured;

  /// Generate chat completion
  Future<LLMResponse> complete(LLMRequest request);

  /// Generate AI insights from aggregated stats
  Future<AIInsights> generateInsights({
    required String chatId,
    required String statsContext,
  });

  /// Validate API key
  Future<bool> validateApiKey();

  /// Get estimated cost for a request (in USD)
  double estimateCost({
    required int inputTokens,
    required int outputTokens,
  });
}
