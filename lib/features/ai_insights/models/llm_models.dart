// ============================================================================
// FILE: features/ai_insights/models/llm_models.dart
// Models for LLM requests and responses
// ============================================================================

/// Configuration for LLM API requests
class LLMConfig {
  final String apiKey;
  final String baseUrl;
  final String model;
  final double temperature;
  final int maxTokens;
  final double topP;

  const LLMConfig({
    required this.apiKey,
    this.baseUrl = 'https://api.deepseek.com/v1',
    this.model = 'deepseek-chat',
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.topP = 0.95,
  });

  /// DeepSeek V3.2 configuration
  factory LLMConfig.deepseek({required String apiKey}) {
    return LLMConfig(
      apiKey: apiKey,
      baseUrl: 'https://api.deepseek.com/v1',
      model: 'deepseek-chat',
      temperature: 0.7,
      maxTokens: 2048,
    );
  }

  /// OpenAI compatible configuration (for testing or fallback)
  factory LLMConfig.openai({required String apiKey}) {
    return LLMConfig(
      apiKey: apiKey,
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-4o-mini',
      temperature: 0.7,
      maxTokens: 2048,
    );
  }

  Map<String, dynamic> toJson() => {
    'baseUrl': baseUrl,
    'model': model,
    'temperature': temperature,
    'maxTokens': maxTokens,
    'topP': topP,
  };
}

/// Request payload for chat completion
class LLMRequest {
  final String systemPrompt;
  final String userPrompt;
  final LLMConfig config;

  const LLMRequest({
    required this.systemPrompt,
    required this.userPrompt,
    required this.config,
  });

  Map<String, dynamic> toApiPayload() => {
    'model': config.model,
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ],
    'temperature': config.temperature,
    'max_tokens': config.maxTokens,
    'top_p': config.topP,
  };
}

/// Response from LLM API
class LLMResponse {
  final String content;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final String? finishReason;
  final Duration latency;

  const LLMResponse({
    required this.content,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.totalTokens = 0,
    this.finishReason,
    this.latency = Duration.zero,
  });

  factory LLMResponse.fromApiResponse(
    Map<String, dynamic> json,
    Duration latency,
  ) {
    final choices = json['choices'] as List<dynamic>? ?? [];
    final message = choices.isNotEmpty
        ? choices[0]['message'] as Map<String, dynamic>? ?? {}
        : <String, dynamic>{};
    final usage = json['usage'] as Map<String, dynamic>? ?? {};

    return LLMResponse(
      content: message['content'] as String? ?? '',
      promptTokens: usage['prompt_tokens'] as int? ?? 0,
      completionTokens: usage['completion_tokens'] as int? ?? 0,
      totalTokens: usage['total_tokens'] as int? ?? 0,
      finishReason: choices.isNotEmpty
          ? choices[0]['finish_reason'] as String?
          : null,
      latency: latency,
    );
  }

  factory LLMResponse.error(String errorMessage) {
    return LLMResponse(
      content: errorMessage,
      finishReason: 'error',
      latency: Duration.zero,
    );
  }

  bool get isError => finishReason == 'error';
  bool get isComplete => finishReason == 'stop';
}

/// Structured AI insights parsed from LLM response
class AIInsights {
  final String chatId;
  final DateTime generatedAt;
  final List<PersonalityTag> personalityTags;
  final RelationshipSummary relationshipSummary;
  final List<CommunicationInsight> communicationInsights;
  final List<String> strengthAreas;
  final List<String> growthAreas;
  final String overallNarrative;
  final int tokensUsed;

  // New insight categories
  final ReportCard? reportCard;
  final Map<String, String> loveLanguages; // userName -> loveLanguage
  final String humorPlayfulness;
  final String vulnerabilityLevel;
  final String supportPatterns;
  final List<String> uniqueQuirks;
  final String conflictStyle;
  final String peakConnectionTimes;
  final String appreciationFrequency;
  final String growthTimeline;
  final String compatibilityNarrative;
  final String conversationInitiators;
  final String energyMatching;

  const AIInsights({
    required this.chatId,
    required this.generatedAt,
    required this.personalityTags,
    required this.relationshipSummary,
    required this.communicationInsights,
    required this.strengthAreas,
    required this.growthAreas,
    required this.overallNarrative,
    this.tokensUsed = 0,
    this.reportCard,
    this.loveLanguages = const {},
    this.humorPlayfulness = '',
    this.vulnerabilityLevel = '',
    this.supportPatterns = '',
    this.uniqueQuirks = const [],
    this.conflictStyle = '',
    this.peakConnectionTimes = '',
    this.appreciationFrequency = '',
    this.growthTimeline = '',
    this.compatibilityNarrative = '',
    this.conversationInitiators = '',
    this.energyMatching = '',
  });

  Map<String, dynamic> toJson() => {
    'chatId': chatId,
    'generatedAt': generatedAt.toIso8601String(),
    'personalityTags': personalityTags.map((t) => t.toJson()).toList(),
    'relationshipSummary': relationshipSummary.toJson(),
    'communicationInsights': communicationInsights.map((i) => i.toJson()).toList(),
    'strengthAreas': strengthAreas,
    'growthAreas': growthAreas,
    'overallNarrative': overallNarrative,
    'tokensUsed': tokensUsed,
    'reportCard': reportCard?.toJson(),
    'loveLanguages': loveLanguages,
    'humorPlayfulness': humorPlayfulness,
    'vulnerabilityLevel': vulnerabilityLevel,
    'supportPatterns': supportPatterns,
    'uniqueQuirks': uniqueQuirks,
    'conflictStyle': conflictStyle,
    'peakConnectionTimes': peakConnectionTimes,
    'appreciationFrequency': appreciationFrequency,
    'growthTimeline': growthTimeline,
    'compatibilityNarrative': compatibilityNarrative,
    'conversationInitiators': conversationInitiators,
    'energyMatching': energyMatching,
  };

  factory AIInsights.fromJson(Map<String, dynamic> json) {
    return AIInsights(
      chatId: json['chatId'] ?? '',
      generatedAt: DateTime.parse(json['generatedAt'] ?? DateTime.now().toIso8601String()),
      personalityTags: (json['personalityTags'] as List<dynamic>? ?? [])
          .map((t) => PersonalityTag.fromJson(t))
          .toList(),
      relationshipSummary: RelationshipSummary.fromJson(
          json['relationshipSummary'] ?? {}),
      communicationInsights: (json['communicationInsights'] as List<dynamic>? ?? [])
          .map((i) => CommunicationInsight.fromJson(i))
          .toList(),
      strengthAreas: List<String>.from(json['strengthAreas'] ?? []),
      growthAreas: List<String>.from(json['growthAreas'] ?? []),
      overallNarrative: json['overallNarrative'] ?? '',
      tokensUsed: json['tokensUsed'] ?? 0,
      reportCard: json['reportCard'] != null
          ? ReportCard.fromJson(json['reportCard'])
          : null,
      loveLanguages: Map<String, String>.from(json['loveLanguages'] ?? {}),
      humorPlayfulness: json['humorPlayfulness'] ?? '',
      vulnerabilityLevel: json['vulnerabilityLevel'] ?? '',
      supportPatterns: json['supportPatterns'] ?? '',
      uniqueQuirks: List<String>.from(json['uniqueQuirks'] ?? []),
      conflictStyle: json['conflictStyle'] ?? '',
      peakConnectionTimes: json['peakConnectionTimes'] ?? '',
      appreciationFrequency: json['appreciationFrequency'] ?? '',
      growthTimeline: json['growthTimeline'] ?? '',
      compatibilityNarrative: json['compatibilityNarrative'] ?? '',
      conversationInitiators: json['conversationInitiators'] ?? '',
      energyMatching: json['energyMatching'] ?? '',
    );
  }

  factory AIInsights.empty(String chatId) {
    return AIInsights(
      chatId: chatId,
      generatedAt: DateTime.now(),
      personalityTags: [],
      relationshipSummary: RelationshipSummary.empty(),
      communicationInsights: [],
      strengthAreas: [],
      growthAreas: [],
      overallNarrative: '',
    );
  }
}

/// Report card with letter grades for different aspects
class ReportCard {
  final String communication;
  final String emotionalConnection;
  final String balance;
  final String support;
  final String growth;
  final String overall;

  const ReportCard({
    required this.communication,
    required this.emotionalConnection,
    required this.balance,
    required this.support,
    required this.growth,
    required this.overall,
  });

  Map<String, dynamic> toJson() => {
    'communication': communication,
    'emotionalConnection': emotionalConnection,
    'balance': balance,
    'support': support,
    'growth': growth,
    'overall': overall,
  };

  factory ReportCard.fromJson(Map<String, dynamic> json) {
    return ReportCard(
      communication: json['communication'] ?? 'N/A',
      emotionalConnection: json['emotionalConnection'] ?? 'N/A',
      balance: json['balance'] ?? 'N/A',
      support: json['support'] ?? 'N/A',
      growth: json['growth'] ?? 'N/A',
      overall: json['overall'] ?? 'N/A',
    );
  }
}

/// A personality tag for a user
class PersonalityTag {
  final String userName;
  final String tag;
  final String description;
  final double confidence;
  final String category; // e.g., "communication", "emotional", "social"

  const PersonalityTag({
    required this.userName,
    required this.tag,
    required this.description,
    required this.confidence,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'tag': tag,
    'description': description,
    'confidence': confidence,
    'category': category,
  };

  factory PersonalityTag.fromJson(Map<String, dynamic> json) {
    return PersonalityTag(
      userName: json['userName'] ?? '',
      tag: json['tag'] ?? '',
      description: json['description'] ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? 'general',
    );
  }
}

/// Summary of relationship dynamics
class RelationshipSummary {
  final String overallHealth;
  final String trend;
  final String dynamicDescription;
  final List<String> positivePatterns;
  final List<String> concernPatterns;
  final double healthScore;

  const RelationshipSummary({
    required this.overallHealth,
    required this.trend,
    required this.dynamicDescription,
    required this.positivePatterns,
    required this.concernPatterns,
    required this.healthScore,
  });

  Map<String, dynamic> toJson() => {
    'overallHealth': overallHealth,
    'trend': trend,
    'dynamicDescription': dynamicDescription,
    'positivePatterns': positivePatterns,
    'concernPatterns': concernPatterns,
    'healthScore': healthScore,
  };

  factory RelationshipSummary.fromJson(Map<String, dynamic> json) {
    return RelationshipSummary(
      overallHealth: json['overallHealth'] ?? 'Unknown',
      trend: json['trend'] ?? 'Stable',
      dynamicDescription: json['dynamicDescription'] ?? '',
      positivePatterns: List<String>.from(json['positivePatterns'] ?? []),
      concernPatterns: List<String>.from(json['concernPatterns'] ?? []),
      healthScore: (json['healthScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory RelationshipSummary.empty() {
    return const RelationshipSummary(
      overallHealth: 'Not Analyzed',
      trend: 'Unknown',
      dynamicDescription: '',
      positivePatterns: [],
      concernPatterns: [],
      healthScore: 0.0,
    );
  }
}

/// Individual communication insight
class CommunicationInsight {
  final String title;
  final String description;
  final String category; // "positive", "neutral", "improvement"
  final String icon;

  const CommunicationInsight({
    required this.title,
    required this.description,
    required this.category,
    this.icon = 'lightbulb',
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'category': category,
    'icon': icon,
  };

  factory CommunicationInsight.fromJson(Map<String, dynamic> json) {
    return CommunicationInsight(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'neutral',
      icon: json['icon'] ?? 'lightbulb',
    );
  }
}
