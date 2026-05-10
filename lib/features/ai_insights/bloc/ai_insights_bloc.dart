// ============================================================================
// FILE: features/ai_insights/bloc/ai_insights_bloc.dart
// BLoC for AI Insights state management
// ============================================================================
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../analysis/analysis_models.dart';
import '../models/llm_models.dart';
import '../services/ai_insights_service.dart';

// ============================================================================
// EVENTS
// ============================================================================

abstract class AIInsightsEvent extends Equatable {
  const AIInsightsEvent();

  @override
  List<Object?> get props => [];
}

/// Configure the AI service with an API key
class ConfigureAIEvent extends AIInsightsEvent {
  final String apiKey;
  final LLMProviderType providerType;

  const ConfigureAIEvent({
    required this.apiKey,
    this.providerType = LLMProviderType.deepseek,
  });

  @override
  List<Object?> get props => [apiKey, providerType];
}

/// Generate AI insights for a chat analysis
class GenerateInsightsEvent extends AIInsightsEvent {
  final ChatAnalysisResult analysisResult;
  final bool forceRefresh;

  const GenerateInsightsEvent({
    required this.analysisResult,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [analysisResult.chatId, forceRefresh];
}

/// Clear cached insights
class ClearInsightsCacheEvent extends AIInsightsEvent {
  final String? chatId;

  const ClearInsightsCacheEvent({this.chatId});

  @override
  List<Object?> get props => [chatId];
}

/// Validate the API key
class ValidateApiKeyEvent extends AIInsightsEvent {
  const ValidateApiKeyEvent();
}

// ============================================================================
// STATES
// ============================================================================

abstract class AIInsightsState extends Equatable {
  const AIInsightsState();

  @override
  List<Object?> get props => [];
}

/// Initial state - not configured
class AIInsightsInitial extends AIInsightsState {
  const AIInsightsInitial();
}

/// Service is configured and ready
class AIInsightsConfigured extends AIInsightsState {
  final String providerName;
  final bool isApiKeyValid;

  const AIInsightsConfigured({
    required this.providerName,
    this.isApiKeyValid = true,
  });

  @override
  List<Object?> get props => [providerName, isApiKeyValid];
}

/// Loading insights
class AIInsightsLoading extends AIInsightsState {
  final String chatId;
  final String message;

  const AIInsightsLoading({
    required this.chatId,
    this.message = 'Generating AI insights...',
  });

  @override
  List<Object?> get props => [chatId, message];
}

/// Insights generated successfully
class AIInsightsSuccess extends AIInsightsState {
  final AIInsights insights;
  final double estimatedCost;

  const AIInsightsSuccess({
    required this.insights,
    this.estimatedCost = 0.0,
  });

  @override
  List<Object?> get props => [insights.chatId, insights.generatedAt];
}

/// Error state
class AIInsightsError extends AIInsightsState {
  final String message;
  final bool canRetry;

  const AIInsightsError({
    required this.message,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, canRetry];
}

// ============================================================================
// BLOC
// ============================================================================

class AIInsightsBloc extends Bloc<AIInsightsEvent, AIInsightsState> {
  final AIInsightsService _service;

  AIInsightsBloc({
    required AIInsightsService service,
  })  : _service = service,
        super(const AIInsightsInitial()) {
    on<ConfigureAIEvent>(_onConfigure);
    on<GenerateInsightsEvent>(_onGenerateInsights);
    on<ClearInsightsCacheEvent>(_onClearCache);
    on<ValidateApiKeyEvent>(_onValidateApiKey);
  }

  bool get isConfigured => _service.isConfigured;
  String get providerName => _service.providerName;

  Future<void> _onConfigure(
    ConfigureAIEvent event,
    Emitter<AIInsightsState> emit,
  ) async {
    debugPrint('AIInsightsBloc: Configuring with ${event.providerType}');

    _service.configure(
      apiKey: event.apiKey,
      providerType: event.providerType,
    );

    // Validate the API key
    final isValid = await _service.validateApiKey();

    emit(AIInsightsConfigured(
      providerName: _service.providerName,
      isApiKeyValid: isValid,
    ));
  }

  Future<void> _onGenerateInsights(
    GenerateInsightsEvent event,
    Emitter<AIInsightsState> emit,
  ) async {
    final chatId = event.analysisResult.chatId;

    // Check for cached insights first
    if (!event.forceRefresh) {
      final cached = _service.getCachedInsights(chatId);
      if (cached != null) {
        debugPrint('AIInsightsBloc: Returning cached insights');
        emit(AIInsightsSuccess(insights: cached));
        return;
      }
    }

    // Check if configured
    if (!_service.isConfigured) {
      emit(const AIInsightsError(
        message: 'AI service not configured. Please add your API key in settings.',
        canRetry: false,
      ));
      return;
    }

    emit(AIInsightsLoading(chatId: chatId));

    // Estimate cost before generating
    final estimatedCost = _service.estimateCost(event.analysisResult);

    final result = await _service.generateInsights(
      analysisResult: event.analysisResult,
      forceRefresh: event.forceRefresh,
    );

    if (result.isSuccess && result.insights != null) {
      emit(AIInsightsSuccess(
        insights: result.insights!,
        estimatedCost: estimatedCost,
      ));
    } else {
      emit(AIInsightsError(
        message: result.errorMessage ?? 'Unknown error',
      ));
    }
  }

  Future<void> _onClearCache(
    ClearInsightsCacheEvent event,
    Emitter<AIInsightsState> emit,
  ) async {
    _service.clearCache(event.chatId);
    emit(const AIInsightsInitial());
  }

  Future<void> _onValidateApiKey(
    ValidateApiKeyEvent event,
    Emitter<AIInsightsState> emit,
  ) async {
    if (!_service.isConfigured) {
      emit(const AIInsightsError(
        message: 'No API key configured',
        canRetry: false,
      ));
      return;
    }

    final isValid = await _service.validateApiKey();

    emit(AIInsightsConfigured(
      providerName: _service.providerName,
      isApiKeyValid: isValid,
    ));
  }
}
