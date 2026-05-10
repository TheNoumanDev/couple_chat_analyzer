// ============================================================================
// FILE: features/ai_insights/providers/deepseek_provider.dart
// DeepSeek V3.2 LLM Provider implementation
// ============================================================================
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/llm_models.dart';
import 'llm_provider.dart';

/// DeepSeek V3.2 LLM Provider
///
/// Pricing (as of 2025):
/// - Input: $0.14 / 1M tokens (cache hit: $0.014)
/// - Output: $0.28 / 1M tokens
///
/// Features:
/// - 128K context window
/// - GPT-4 level quality
/// - OpenAI-compatible API
class DeepSeekProvider implements LLMProvider {
  final LLMConfig config;
  final http.Client _client;

  DeepSeekProvider({
    required this.config,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  String get name => 'DeepSeek V3.2';

  @override
  bool get isConfigured => config.apiKey.isNotEmpty;

  @override
  Future<LLMResponse> complete(LLMRequest request) async {
    if (!isConfigured) {
      return LLMResponse.error('API key not configured');
    }

    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client.post(
        Uri.parse('${config.baseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.apiKey}',
        },
        body: jsonEncode(request.toApiPayload()),
      );

      stopwatch.stop();

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return LLMResponse.fromApiResponse(json, stopwatch.elapsed);
      } else {
        final error = _parseError(response);
        debugPrint('DeepSeekProvider: API error: $error');
        return LLMResponse.error(error);
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint('DeepSeekProvider: Exception: $e');
      return LLMResponse.error('Network error: $e');
    }
  }

  @override
  Future<AIInsights> generateInsights({
    required String chatId,
    required String statsContext,
  }) async {
    final systemPrompt = _buildSystemPrompt();
    final userPrompt = _buildUserPrompt(statsContext);

    final request = LLMRequest(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      config: config,
    );

    debugPrint('DeepSeekProvider: Generating insights for chat: $chatId');
    final response = await complete(request);

    if (response.isError) {
      debugPrint('DeepSeekProvider: Error generating insights: ${response.content}');
      return AIInsights.empty(chatId);
    }

    debugPrint('DeepSeekProvider: Received response (${response.totalTokens} tokens)');
    return _parseInsightsResponse(chatId, response);
  }

  @override
  Future<bool> validateApiKey() async {
    if (!isConfigured) return false;

    try {
      // Make a minimal request to validate the API key
      final response = await _client.post(
        Uri.parse('${config.baseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.apiKey}',
        },
        body: jsonEncode({
          'model': config.model,
          'messages': [
            {'role': 'user', 'content': 'Hi'}
          ],
          'max_tokens': 5,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('DeepSeekProvider: API key validation failed: $e');
      return false;
    }
  }

  @override
  double estimateCost({
    required int inputTokens,
    required int outputTokens,
  }) {
    // DeepSeek V3.2 pricing (USD per 1M tokens)
    const inputPrice = 0.14;
    const outputPrice = 0.28;

    return (inputTokens * inputPrice / 1000000) +
        (outputTokens * outputPrice / 1000000);
  }

  // ============================================================================
  // PROMPT BUILDING
  // ============================================================================

  String _buildSystemPrompt() {
    return '''You are an expert relationship analyst and communication coach. Analyze chat statistics and provide warm, narrative-style insights about communication patterns and relationship dynamics.

IMPORTANT RULES:
- Write in flowing, narrative prose - NOT bullet points with numbers
- Use descriptive language instead of raw statistics (say "responds quickly" not "responds in 2.3 minutes")
- Use letter grades (A+, A, A-, B+, B, B-, C+, C, D, F) for the report card
- Be warm, supportive, and constructive
- Focus on observations and patterns, not judgments
- All descriptions should be readable stories, not data dumps

Your response MUST be valid JSON with this exact structure:
{
  "personalityTags": [
    {
      "userName": "string",
      "tag": "string (2-4 words, creative and memorable)",
      "description": "string (1 warm sentence explaining the tag)",
      "confidence": number (0.0-1.0),
      "category": "communication|emotional|social|intellectual"
    }
  ],
  "relationshipSummary": {
    "overallHealth": "Thriving|Healthy|Stable|Needs Attention|Concerning",
    "trend": "Improving|Stable|Declining",
    "dynamicDescription": "string (2-3 flowing sentences, NO statistics)",
    "positivePatterns": ["string (narrative observations)"],
    "concernPatterns": ["string (gentle suggestions)"],
    "healthScore": number (0.0-1.0)
  },
  "communicationInsights": [
    {
      "title": "string (3-5 words)",
      "description": "string (1-2 narrative sentences, NO raw numbers)",
      "category": "positive|neutral|improvement"
    }
  ],
  "reportCard": {
    "communication": "A|A-|B+|B|B-|C+|C|D|F",
    "emotionalConnection": "A|A-|B+|B|B-|C+|C|D|F",
    "balance": "A|A-|B+|B|B-|C+|C|D|F",
    "support": "A|A-|B+|B|B-|C+|C|D|F",
    "growth": "A|A-|B+|B|B-|C+|C|D|F",
    "overall": "A|A-|B+|B|B-|C+|C|D|F"
  },
  "loveLanguages": {
    "userName1": "Words of Affirmation|Quality Time|Acts of Service|Receiving Gifts|Physical Touch",
    "userName2": "..."
  },
  "humorPlayfulness": "string (1-2 sentences about the fun/playful aspects of conversations)",
  "vulnerabilityLevel": "string (1-2 sentences about emotional openness and depth)",
  "supportPatterns": "string (1-2 sentences about how they support each other)",
  "uniqueQuirks": ["string (special patterns, inside jokes, or unique communication habits)"],
  "conflictStyle": "string (1-2 sentences about how they handle disagreements)",
  "peakConnectionTimes": "string (when they seem most in sync, described narratively)",
  "appreciationFrequency": "string (how often and how they express gratitude)",
  "growthTimeline": "string (2-3 sentences about how the relationship has evolved)",
  "compatibilityNarrative": "string (2-3 sentences about how well their styles mesh)",
  "conversationInitiators": "string (who starts which types of conversations)",
  "energyMatching": "string (do they match each other's energy levels)",
  "strengthAreas": ["string (1 warm sentence each, NO statistics)"],
  "growthAreas": ["string (1 gentle, actionable suggestion each, NO statistics)"],
  "overallNarrative": "string (3-4 sentences telling the story of this relationship)"
}

Remember: Write like you're describing friends to someone, not generating a data report. Make it feel personal and insightful.''';
  }

  String _buildUserPrompt(String statsContext) {
    return '''Analyze the following chat statistics and provide insights:

$statsContext

Based on this data, generate comprehensive AI insights following the JSON structure specified. Focus on:
1. Individual personality traits evident from communication patterns
2. Relationship dynamics and health indicators
3. Communication strengths and areas for growth
4. Specific, data-driven observations''';
  }

  // ============================================================================
  // RESPONSE PARSING
  // ============================================================================

  AIInsights _parseInsightsResponse(String chatId, LLMResponse response) {
    try {
      // Log raw response for debugging
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🤖 RAW DEEPSEEK RESPONSE:');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint(response.content);
      debugPrint('═══════════════════════════════════════════════════════════');

      // Extract JSON from response (handle markdown code blocks)
      String jsonStr = response.content.trim();

      // Remove markdown code blocks if present
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      } else if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      final insights = AIInsights(
        chatId: chatId,
        generatedAt: DateTime.now(),
        personalityTags: _parsePersonalityTags(json['personalityTags']),
        relationshipSummary: RelationshipSummary.fromJson(
            json['relationshipSummary'] ?? {}),
        communicationInsights: _parseCommunicationInsights(
            json['communicationInsights']),
        strengthAreas: List<String>.from(json['strengthAreas'] ?? []),
        growthAreas: List<String>.from(json['growthAreas'] ?? []),
        overallNarrative: json['overallNarrative'] ?? '',
        tokensUsed: response.totalTokens,
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

      // Log parsed data for debugging
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('📊 PARSED AI INSIGHTS:');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🏷️ Personality Tags (${insights.personalityTags.length}):');
      for (final tag in insights.personalityTags) {
        debugPrint('   - ${tag.userName}: "${tag.tag}" (${tag.category}, ${(tag.confidence * 100).toInt()}%)');
        debugPrint('     ${tag.description}');
      }
      debugPrint('');
      debugPrint('💕 Relationship Summary:');
      debugPrint('   Health: ${insights.relationshipSummary.overallHealth} (${(insights.relationshipSummary.healthScore * 100).toInt()}%)');
      debugPrint('   Trend: ${insights.relationshipSummary.trend}');
      debugPrint('   ${insights.relationshipSummary.dynamicDescription}');
      debugPrint('   Positive: ${insights.relationshipSummary.positivePatterns.join(", ")}');
      debugPrint('   Concerns: ${insights.relationshipSummary.concernPatterns.join(", ")}');
      debugPrint('');
      debugPrint('💬 Communication Insights (${insights.communicationInsights.length}):');
      for (final insight in insights.communicationInsights) {
        debugPrint('   [${insight.category}] ${insight.title}: ${insight.description}');
      }
      debugPrint('');
      debugPrint('💪 Strengths: ${insights.strengthAreas.join(" | ")}');
      debugPrint('🌱 Growth: ${insights.growthAreas.join(" | ")}');
      debugPrint('');
      debugPrint('📝 Narrative: ${insights.overallNarrative}');
      debugPrint('═══════════════════════════════════════════════════════════');

      return insights;
    } catch (e) {
      debugPrint('DeepSeekProvider: Error parsing insights: $e');
      debugPrint('DeepSeekProvider: Raw response: ${response.content}');

      // Return a fallback with the raw narrative
      return AIInsights(
        chatId: chatId,
        generatedAt: DateTime.now(),
        personalityTags: [],
        relationshipSummary: RelationshipSummary.empty(),
        communicationInsights: [],
        strengthAreas: [],
        growthAreas: [],
        overallNarrative: response.content,
        tokensUsed: response.totalTokens,
      );
    }
  }

  List<PersonalityTag> _parsePersonalityTags(dynamic json) {
    if (json == null || json is! List) return [];
    return json
        .map((t) => PersonalityTag.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  List<CommunicationInsight> _parseCommunicationInsights(dynamic json) {
    if (json == null || json is! List) return [];
    return json
        .map((i) => CommunicationInsight.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  String _parseError(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      return error?['message'] ?? 'Unknown API error (${response.statusCode})';
    } catch (e) {
      return 'API error: ${response.statusCode}';
    }
  }
}
