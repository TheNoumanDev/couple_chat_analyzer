// ============================================================================
// FILE: features/analysis/analysis_models.dart
// Complete analysis models with missing classes
// ============================================================================
import 'package:equatable/equatable.dart';

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

class StartAnalysisEvent extends AnalysisEvent {
  final String chatId;
  final AnalysisConfig? config;

  const StartAnalysisEvent(this.chatId, {this.config});

  @override
  List<Object?> get props => [chatId, config];
}

class RefreshAnalysisEvent extends AnalysisEvent {
  final String chatId;

  const RefreshAnalysisEvent(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class ClearAnalysisEvent extends AnalysisEvent {}

class UpdateAnalysisConfigEvent extends AnalysisEvent {
  final AnalysisConfig config;

  const UpdateAnalysisConfigEvent(this.config);

  @override
  List<Object?> get props => [config];
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

class AnalysisLoading extends AnalysisState {
  final String message;
  final double? progress;

  const AnalysisLoading({
    this.message = 'Analyzing chat...',
    this.progress,
  });

  @override
  List<Object?> get props => [message, progress];
}

class AnalysisSuccess extends AnalysisState {
  final String chatId;
  final Map<String, dynamic> results;
  final ChatAnalysisResult result;
  final DateTime completedAt;

  const AnalysisSuccess(this.chatId, this.results, {
    required this.result,
    required this.completedAt,
  });

  @override
  List<Object?> get props => [chatId, results, result, completedAt];
}

class AnalysisError extends AnalysisState {
  final String message;
  final String? technicalDetails;
  final bool canRetry;

  const AnalysisError(this.message, {
    this.technicalDetails,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, technicalDetails, canRetry];
}

// ============================================================================
// ANALYSIS RESULT CLASSES
// ============================================================================

class AnalysisResult {
  final String type;
  final Map<String, dynamic> data;
  final double confidence;
  final DateTime generatedAt;

  AnalysisResult({
    required this.type,
    required this.data,
    required this.confidence,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'confidence': confidence,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      type: json['type'] ?? '',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      generatedAt: DateTime.parse(json['generatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ChatAnalysisResult {
  final String chatId;
  final Map<String, AnalysisResult> results;
  final DateTime generatedAt;

  ChatAnalysisResult({
    required this.chatId,
    required this.results,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'results': results.map((key, value) => MapEntry(key, value.toJson())),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory ChatAnalysisResult.fromJson(Map<String, dynamic> json) {
    final resultsMap = <String, AnalysisResult>{};
    final results = json['results'] as Map<String, dynamic>? ?? {};
    
    for (final entry in results.entries) {
      if (entry.value is Map<String, dynamic>) {
        resultsMap[entry.key] = AnalysisResult.fromJson(entry.value);
      }
    }

    return ChatAnalysisResult(
      chatId: json['chatId'] ?? '',
      results: resultsMap,
      generatedAt: DateTime.parse(json['generatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  bool get isEmpty => results.isEmpty;
  bool get isNotEmpty => results.isNotEmpty;
}

class AnalysisConfig {
  final bool includeAdvancedAnalysis;
  final bool includeContentAnalysis;
  final bool includeTimeAnalysis;
  final bool includeUserAnalysis;
  final bool includeRelationshipAnalysis;
  final bool includeBehaviorAnalysis;
  final bool includeConversationDynamics;
  final bool includeContentIntelligence;
  final bool includeTemporalInsights;
  final int maxMessagesToAnalyze;

  const AnalysisConfig({
    this.includeAdvancedAnalysis = true,
    this.includeContentAnalysis = true,
    this.includeTimeAnalysis = true,
    this.includeUserAnalysis = true,
    this.includeRelationshipAnalysis = true,
    this.includeBehaviorAnalysis = true,
    this.includeConversationDynamics = true,
    this.includeContentIntelligence = true,
    this.includeTemporalInsights = true,
    this.maxMessagesToAnalyze = 10000,
  });

  factory AnalysisConfig.defaultConfig() {
    return const AnalysisConfig();
  }

  factory AnalysisConfig.basicConfig() {
    return const AnalysisConfig(
      includeAdvancedAnalysis: false,
      includeRelationshipAnalysis: false,
      includeBehaviorAnalysis: false,
      includeConversationDynamics: false,
      maxMessagesToAnalyze: 5000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'includeAdvancedAnalysis': includeAdvancedAnalysis,
      'includeContentAnalysis': includeContentAnalysis,
      'includeTimeAnalysis': includeTimeAnalysis,
      'includeUserAnalysis': includeUserAnalysis,
      'includeRelationshipAnalysis': includeRelationshipAnalysis,
      'includeBehaviorAnalysis': includeBehaviorAnalysis,
      'includeConversationDynamics': includeConversationDynamics,
      'includeContentIntelligence': includeContentIntelligence,
      'includeTemporalInsights': includeTemporalInsights,
      'maxMessagesToAnalyze': maxMessagesToAnalyze,
    };
  }

  factory AnalysisConfig.fromJson(Map<String, dynamic> json) {
    return AnalysisConfig(
      includeAdvancedAnalysis: json['includeAdvancedAnalysis'] ?? true,
      includeContentAnalysis: json['includeContentAnalysis'] ?? true,
      includeTimeAnalysis: json['includeTimeAnalysis'] ?? true,
      includeUserAnalysis: json['includeUserAnalysis'] ?? true,
      includeRelationshipAnalysis: json['includeRelationshipAnalysis'] ?? true,
      includeBehaviorAnalysis: json['includeBehaviorAnalysis'] ?? true,
      includeConversationDynamics: json['includeConversationDynamics'] ?? true,
      includeContentIntelligence: json['includeContentIntelligence'] ?? true,
      includeTemporalInsights: json['includeTemporalInsights'] ?? true,
      maxMessagesToAnalyze: json['maxMessagesToAnalyze'] ?? 10000,
    );
  }
}