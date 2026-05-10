// ============================================================================
// FILE: features/analysis/analyzers/enhanced/emotional_intelligence_analyzer.dart
// Emotional Intelligence Analyzer - Empathy, self-disclosure, sentiment intensity
// ============================================================================
import 'package:flutter/foundation.dart';
import '../../../../shared/domain.dart';
import '../../analysis_models.dart';
import '../base_analyzer.dart';

class EmotionalIntelligenceAnalyzer implements EnhancedAnalyzer {
  static const int maxAnalysisMessages = 5000;

  // Empathy phrases - showing care for others
  static const List<String> _empathyPhrases = [
    'how are you', 'are you okay', 'are you alright', 'hope you',
    'thinking of you', 'i understand', 'that must be', 'im sorry to hear',
    'feel better', 'take care', 'be careful', 'stay safe', 'miss you',
    'worried about you', 'here for you', 'let me know if', 'can i help',
    'what happened', 'whats wrong', 'are you ok', 'you okay', 'u okay',
    'sending love', 'sending hugs', 'virtual hug', 'praying for',
    'hope everything', 'hope all is', 'checking in', 'just checking',
  ];

  // Self-disclosure phrases - sharing personal feelings
  static const List<String> _selfDisclosurePhrases = [
    'i feel', 'i think', 'i believe', 'honestly', 'to be honest',
    'tbh', 'i love', 'i hate', 'i wish', 'i hope', 'i want',
    'i need', 'im feeling', 'i felt', 'makes me feel', 'made me feel',
    'i was thinking', 'i realize', 'i noticed', 'i admit', 'i confess',
    'in my opinion', 'personally', 'for me', 'my heart', 'my soul',
    'i struggled', 'i worry', 'i fear', 'im scared', 'im afraid',
    'im happy', 'im sad', 'im excited', 'im nervous', 'im anxious',
  ];

  // Validation phrases - affirming others
  static const List<String> _validationPhrases = [
    'i understand', 'that makes sense', 'i get it', 'i see',
    'youre right', 'you are right', 'good point', 'fair point',
    'i agree', 'totally', 'exactly', 'absolutely', 'definitely',
    'of course', 'thats true', 'so true', 'i know right', 'ikr',
    'valid', 'understandable', 'reasonable', 'makes sense',
    'i hear you', 'i feel you', 'same', 'me too', 'relatable',
  ];

  // Positive sentiment words with intensity weights
  static const Map<String, int> _positiveWords = {
    // Mild positive (weight 1-2)
    'good': 2, 'nice': 2, 'okay': 1, 'ok': 1, 'fine': 1, 'alright': 1,
    'cool': 2, 'great': 3, 'thanks': 2, 'thank': 2, 'please': 1,
    // Moderate positive (weight 3-5)
    'happy': 4, 'glad': 3, 'wonderful': 4, 'fantastic': 5, 'excellent': 5,
    'awesome': 5, 'amazing': 5, 'beautiful': 4, 'lovely': 4, 'perfect': 5,
    'love': 5, 'loved': 5, 'loving': 5, 'adore': 5, 'best': 4,
    // Strong positive (weight 6-10)
    'incredible': 7, 'outstanding': 7, 'extraordinary': 8, 'brilliant': 7,
    'magnificent': 8, 'phenomenal': 8, 'exceptional': 7, 'superb': 7,
    'blessed': 6, 'grateful': 6, 'thankful': 6, 'appreciate': 5,
    'excited': 6, 'thrilled': 7, 'ecstatic': 9, 'overjoyed': 8,
  };

  // Negative sentiment words with intensity weights
  static const Map<String, int> _negativeWords = {
    // Mild negative (weight 1-2)
    'bad': 2, 'not good': 2, 'meh': 1, 'eh': 1, 'ugh': 2,
    'annoying': 3, 'boring': 2, 'tired': 2, 'busy': 1,
    // Moderate negative (weight 3-5)
    'sad': 4, 'upset': 4, 'angry': 5, 'mad': 4, 'frustrated': 4,
    'disappointed': 4, 'hurt': 5, 'pain': 4, 'worry': 3, 'worried': 3,
    'stress': 4, 'stressed': 4, 'anxious': 4, 'nervous': 3,
    'hate': 5, 'hated': 5, 'awful': 5, 'terrible': 5, 'horrible': 5,
    // Strong negative (weight 6-10)
    'devastated': 8, 'heartbroken': 8, 'depressed': 7, 'miserable': 7,
    'furious': 8, 'enraged': 9, 'disgusted': 7, 'betrayed': 8,
    'hopeless': 7, 'worthless': 8, 'helpless': 7, 'desperate': 7,
    'crying': 6, 'cried': 6, 'tears': 5, 'sobbing': 7,
  };

  @override
  Future<AnalysisResult> analyze(ChatEntity chat) async {
    debugPrint("💖 EmotionalIntelligenceAnalyzer: Starting analysis");

    try {
      final messagesToProcess = chat.messages.length > maxAnalysisMessages
          ? chat.messages.take(maxAnalysisMessages).toList()
          : chat.messages;

      if (messagesToProcess.isEmpty) {
        return _createEmptyResult();
      }

      final userIdToName = {for (var user in chat.users) user.id: user.name};

      // Analyze emotional intelligence metrics
      final empathyAnalysis = _analyzeEmpathy(messagesToProcess, userIdToName);
      final selfDisclosureAnalysis = _analyzeSelfDisclosure(messagesToProcess, userIdToName);
      final validationAnalysis = _analyzeValidation(messagesToProcess, userIdToName);
      final sentimentAnalysis = _analyzeSentimentIntensity(messagesToProcess, userIdToName);
      final emotionalVolatility = _analyzeEmotionalVolatility(messagesToProcess, userIdToName);
      final emotionalReciprocity = _analyzeEmotionalReciprocity(messagesToProcess, userIdToName);

      final result = {
        'empathy': empathyAnalysis,
        'selfDisclosure': selfDisclosureAnalysis,
        'validation': validationAnalysis,
        'sentiment': sentimentAnalysis,
        'volatility': emotionalVolatility,
        'reciprocity': emotionalReciprocity,
        'summary': _generateEISummary(empathyAnalysis, selfDisclosureAnalysis, validationAnalysis, sentimentAnalysis),
      };

      debugPrint("✅ EmotionalIntelligenceAnalyzer: Analysis complete");

      return AnalysisResult(
        type: 'emotional_intelligence',
        data: result,
        confidence: _calculateConfidence(messagesToProcess.length, userIdToName.length),
        generatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      debugPrint("❌ EmotionalIntelligenceAnalyzer: Error - $e");
      debugPrint("Stack trace: $stackTrace");
      return _createErrorResult(e);
    }
  }

  // ========================================================================
  // EMPATHY ANALYSIS
  // ========================================================================

  Map<String, dynamic> _analyzeEmpathy(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, dynamic>> userEmpathy = {};

    for (final userName in userIdToName.values) {
      userEmpathy[userName] = {
        'totalMessages': 0,
        'empathyCount': 0,
        'empathyPhrases': <String>[],
      };
    }

    for (final message in messages) {
      if (message.type != MessageType.text || message.content.isEmpty) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final content = message.content.toLowerCase();
      final data = userEmpathy[userName]!;

      data['totalMessages'] = (data['totalMessages'] as int) + 1;

      for (final phrase in _empathyPhrases) {
        if (content.contains(phrase)) {
          data['empathyCount'] = (data['empathyCount'] as int) + 1;
          final phrases = data['empathyPhrases'] as List<String>;
          if (!phrases.contains(phrase) && phrases.length < 10) {
            phrases.add(phrase);
          }
          break; // Count once per message
        }
      }
    }

    // Calculate empathy scores
    final Map<String, dynamic> result = {};

    for (final entry in userEmpathy.entries) {
      final userName = entry.key;
      final data = entry.value;

      final totalMessages = data['totalMessages'] as int;
      final empathyCount = data['empathyCount'] as int;

      if (totalMessages == 0) {
        result[userName] = {
          'score': 0,
          'category': 'No Data',
          'rate': 0.0,
          'topPhrases': <String>[],
        };
        continue;
      }

      final empathyRate = empathyCount / totalMessages;
      final score = (empathyRate * 100).clamp(0.0, 100.0);

      result[userName] = {
        'score': score.round(),
        'category': _categorizeEmpathy(empathyRate),
        'rate': double.parse((empathyRate * 100).toStringAsFixed(1)),
        'topPhrases': data['empathyPhrases'],
      };
    }

    return result;
  }

  String _categorizeEmpathy(double rate) {
    if (rate > 0.15) return 'Highly Empathetic';
    if (rate > 0.08) return 'Empathetic';
    if (rate > 0.04) return 'Moderately Empathetic';
    if (rate > 0.02) return 'Somewhat Empathetic';
    return 'Reserved';
  }

  // ========================================================================
  // SELF-DISCLOSURE ANALYSIS
  // ========================================================================

  Map<String, dynamic> _analyzeSelfDisclosure(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, dynamic>> userDisclosure = {};

    for (final userName in userIdToName.values) {
      userDisclosure[userName] = {
        'totalMessages': 0,
        'disclosureCount': 0,
        'emotionalDepth': 0, // Cumulative emotional word intensity
      };
    }

    for (final message in messages) {
      if (message.type != MessageType.text || message.content.isEmpty) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final content = message.content.toLowerCase();
      final data = userDisclosure[userName]!;

      data['totalMessages'] = (data['totalMessages'] as int) + 1;

      // Check for self-disclosure phrases
      for (final phrase in _selfDisclosurePhrases) {
        if (content.contains(phrase)) {
          data['disclosureCount'] = (data['disclosureCount'] as int) + 1;
          break;
        }
      }

      // Calculate emotional depth from positive/negative words
      for (final entry in _positiveWords.entries) {
        if (content.contains(entry.key)) {
          data['emotionalDepth'] = (data['emotionalDepth'] as int) + entry.value;
        }
      }
      for (final entry in _negativeWords.entries) {
        if (content.contains(entry.key)) {
          data['emotionalDepth'] = (data['emotionalDepth'] as int) + entry.value;
        }
      }
    }

    // Calculate disclosure scores
    final Map<String, dynamic> result = {};

    for (final entry in userDisclosure.entries) {
      final userName = entry.key;
      final data = entry.value;

      final totalMessages = data['totalMessages'] as int;
      final disclosureCount = data['disclosureCount'] as int;
      final emotionalDepth = data['emotionalDepth'] as int;

      if (totalMessages == 0) {
        result[userName] = {
          'score': 0,
          'category': 'No Data',
          'rate': 0.0,
          'emotionalDepthScore': 0,
        };
        continue;
      }

      final disclosureRate = disclosureCount / totalMessages;
      final depthPerMessage = emotionalDepth / totalMessages;
      final score = ((disclosureRate * 60) + (depthPerMessage * 4)).clamp(0.0, 100.0);

      result[userName] = {
        'score': score.round(),
        'category': _categorizeSelfDisclosure(score),
        'rate': double.parse((disclosureRate * 100).toStringAsFixed(1)),
        'emotionalDepthScore': depthPerMessage.round(),
      };
    }

    return result;
  }

  String _categorizeSelfDisclosure(double score) {
    if (score > 60) return 'Very Open';
    if (score > 40) return 'Open';
    if (score > 25) return 'Moderate';
    if (score > 10) return 'Reserved';
    return 'Very Private';
  }

  // ========================================================================
  // VALIDATION ANALYSIS
  // ========================================================================

  Map<String, dynamic> _analyzeValidation(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, dynamic>> userValidation = {};

    for (final userName in userIdToName.values) {
      userValidation[userName] = {
        'totalMessages': 0,
        'validationCount': 0,
      };
    }

    for (final message in messages) {
      if (message.type != MessageType.text || message.content.isEmpty) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final content = message.content.toLowerCase();
      final data = userValidation[userName]!;

      data['totalMessages'] = (data['totalMessages'] as int) + 1;

      for (final phrase in _validationPhrases) {
        if (content.contains(phrase)) {
          data['validationCount'] = (data['validationCount'] as int) + 1;
          break;
        }
      }
    }

    // Calculate validation scores
    final Map<String, dynamic> result = {};

    for (final entry in userValidation.entries) {
      final userName = entry.key;
      final data = entry.value;

      final totalMessages = data['totalMessages'] as int;
      final validationCount = data['validationCount'] as int;

      if (totalMessages == 0) {
        result[userName] = {
          'score': 0,
          'category': 'No Data',
          'rate': 0.0,
        };
        continue;
      }

      final validationRate = validationCount / totalMessages;
      final score = (validationRate * 100).clamp(0.0, 100.0);

      result[userName] = {
        'score': score.round(),
        'category': _categorizeValidation(validationRate),
        'rate': double.parse((validationRate * 100).toStringAsFixed(1)),
      };
    }

    return result;
  }

  String _categorizeValidation(double rate) {
    if (rate > 0.20) return 'Highly Validating';
    if (rate > 0.12) return 'Validating';
    if (rate > 0.06) return 'Moderately Validating';
    if (rate > 0.03) return 'Occasionally Validating';
    return 'Neutral';
  }

  // ========================================================================
  // SENTIMENT INTENSITY ANALYSIS
  // ========================================================================

  Map<String, dynamic> _analyzeSentimentIntensity(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, dynamic>> userSentiment = {};

    for (final userName in userIdToName.values) {
      userSentiment[userName] = {
        'totalMessages': 0,
        'positiveScore': 0,
        'negativeScore': 0,
        'neutralCount': 0,
        'sentimentScores': <int>[], // For volatility calculation
      };
    }

    for (final message in messages) {
      if (message.type != MessageType.text || message.content.isEmpty) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final content = message.content.toLowerCase();
      final data = userSentiment[userName]!;

      data['totalMessages'] = (data['totalMessages'] as int) + 1;

      int messagePositive = 0;
      int messageNegative = 0;

      // Calculate positive sentiment
      for (final entry in _positiveWords.entries) {
        if (content.contains(entry.key)) {
          messagePositive += entry.value;
        }
      }

      // Calculate negative sentiment
      for (final entry in _negativeWords.entries) {
        if (content.contains(entry.key)) {
          messageNegative += entry.value;
        }
      }

      data['positiveScore'] = (data['positiveScore'] as int) + messagePositive;
      data['negativeScore'] = (data['negativeScore'] as int) + messageNegative;

      // Track sentiment score for this message (-10 to +10 scale)
      final msgSentiment = (messagePositive - messageNegative).clamp(-10, 10);
      (data['sentimentScores'] as List<int>).add(msgSentiment);

      if (messagePositive == 0 && messageNegative == 0) {
        data['neutralCount'] = (data['neutralCount'] as int) + 1;
      }
    }

    // Calculate sentiment metrics
    final Map<String, dynamic> result = {};

    for (final entry in userSentiment.entries) {
      final userName = entry.key;
      final data = entry.value;

      final totalMessages = data['totalMessages'] as int;
      final positiveScore = data['positiveScore'] as int;
      final negativeScore = data['negativeScore'] as int;
      final neutralCount = data['neutralCount'] as int;

      if (totalMessages == 0) {
        result[userName] = {
          'averageIntensity': 0.0,
          'positivity': 0.0,
          'negativity': 0.0,
          'neutrality': 0.0,
          'category': 'No Data',
          'balance': 'No Data',
        };
        continue;
      }

      final avgPositive = positiveScore / totalMessages;
      final avgNegative = negativeScore / totalMessages;
      final avgIntensity = (avgPositive + avgNegative);
      final neutralRate = neutralCount / totalMessages;

      // Calculate positivity ratio
      final total = positiveScore + negativeScore;
      final positivityRatio = total > 0 ? positiveScore / total : 0.5;

      result[userName] = {
        'averageIntensity': double.parse(avgIntensity.toStringAsFixed(2)),
        'positivity': double.parse((avgPositive * 10).toStringAsFixed(1)),
        'negativity': double.parse((avgNegative * 10).toStringAsFixed(1)),
        'neutrality': double.parse((neutralRate * 100).toStringAsFixed(1)),
        'category': _categorizeSentimentIntensity(avgIntensity),
        'balance': _categorizeSentimentBalance(positivityRatio),
      };
    }

    return result;
  }

  String _categorizeSentimentIntensity(double intensity) {
    if (intensity > 3.0) return 'Highly Expressive';
    if (intensity > 1.5) return 'Expressive';
    if (intensity > 0.5) return 'Moderate';
    if (intensity > 0.2) return 'Reserved';
    return 'Neutral';
  }

  String _categorizeSentimentBalance(double positivityRatio) {
    if (positivityRatio > 0.8) return 'Very Positive';
    if (positivityRatio > 0.6) return 'Mostly Positive';
    if (positivityRatio > 0.4) return 'Balanced';
    if (positivityRatio > 0.2) return 'Mostly Negative';
    return 'Very Negative';
  }

  // ========================================================================
  // EMOTIONAL VOLATILITY ANALYSIS
  // ========================================================================

  Map<String, dynamic> _analyzeEmotionalVolatility(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, List<int>> userSentimentHistory = {};

    for (final userName in userIdToName.values) {
      userSentimentHistory[userName] = [];
    }

    for (final message in messages) {
      if (message.type != MessageType.text || message.content.isEmpty) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final content = message.content.toLowerCase();

      int messagePositive = 0;
      int messageNegative = 0;

      for (final entry in _positiveWords.entries) {
        if (content.contains(entry.key)) {
          messagePositive += entry.value;
        }
      }

      for (final entry in _negativeWords.entries) {
        if (content.contains(entry.key)) {
          messageNegative += entry.value;
        }
      }

      final sentiment = (messagePositive - messageNegative).clamp(-10, 10);
      userSentimentHistory[userName]!.add(sentiment);
    }

    // Calculate volatility (standard deviation of sentiment)
    final Map<String, dynamic> result = {};

    for (final entry in userSentimentHistory.entries) {
      final userName = entry.key;
      final sentiments = entry.value;

      if (sentiments.length < 10) {
        result[userName] = {
          'volatilityScore': 0.0,
          'category': 'Insufficient Data',
          'range': 0,
        };
        continue;
      }

      // Calculate mean
      final mean = sentiments.reduce((a, b) => a + b) / sentiments.length;

      // Calculate variance
      double variance = 0;
      for (final s in sentiments) {
        variance += (s - mean) * (s - mean);
      }
      variance /= sentiments.length;

      // Standard deviation
      final stdDev = variance > 0 ? _sqrt(variance) : 0.0;

      // Range
      final maxSentiment = sentiments.reduce((a, b) => a > b ? a : b);
      final minSentiment = sentiments.reduce((a, b) => a < b ? a : b);
      final range = maxSentiment - minSentiment;

      result[userName] = {
        'volatilityScore': double.parse(stdDev.toStringAsFixed(2)),
        'category': _categorizeVolatility(stdDev),
        'range': range,
        'mean': double.parse(mean.toStringAsFixed(2)),
      };
    }

    return result;
  }

  double _sqrt(double value) {
    if (value <= 0) return 0;
    double guess = value / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + value / guess) / 2;
    }
    return guess;
  }

  String _categorizeVolatility(double stdDev) {
    if (stdDev > 3.0) return 'Highly Volatile';
    if (stdDev > 2.0) return 'Volatile';
    if (stdDev > 1.0) return 'Moderate';
    if (stdDev > 0.5) return 'Stable';
    return 'Very Stable';
  }

  // ========================================================================
  // EMOTIONAL RECIPROCITY ANALYSIS
  // ========================================================================

  Map<String, dynamic> _analyzeEmotionalReciprocity(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    if (userIdToName.length != 2 || messages.length < 20) {
      return {'status': 'Insufficient data for reciprocity analysis'};
    }

    final users = userIdToName.values.toList();
    final user1 = users[0];
    final user2 = users[1];

    int user1Supportive = 0;
    int user2Supportive = 0;
    int user1Empathetic = 0;
    int user2Empathetic = 0;
    int user1Total = 0;
    int user2Total = 0;

    for (final message in messages) {
      if (message.type != MessageType.text) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final content = message.content.toLowerCase();

      bool isEmpathetic = _empathyPhrases.any((p) => content.contains(p));
      bool isSupportive = _validationPhrases.any((p) => content.contains(p));

      if (userName == user1) {
        user1Total++;
        if (isEmpathetic) user1Empathetic++;
        if (isSupportive) user1Supportive++;
      } else {
        user2Total++;
        if (isEmpathetic) user2Empathetic++;
        if (isSupportive) user2Supportive++;
      }
    }

    // Calculate reciprocity balance
    final user1Rate = user1Total > 0 ? (user1Empathetic + user1Supportive) / user1Total : 0.0;
    final user2Rate = user2Total > 0 ? (user2Empathetic + user2Supportive) / user2Total : 0.0;

    final difference = (user1Rate - user2Rate).abs();
    final averageRate = (user1Rate + user2Rate) / 2;

    String balance;
    if (difference < 0.02) {
      balance = 'Highly Balanced';
    } else if (difference < 0.05) {
      balance = 'Balanced';
    } else if (difference < 0.10) {
      balance = 'Slightly Imbalanced';
    } else {
      balance = 'Imbalanced';
    }

    return {
      'balance': balance,
      'overallRate': double.parse((averageRate * 100).toStringAsFixed(1)),
      'details': {
        user1: {
          'empathyRate': user1Total > 0 ? double.parse((user1Empathetic / user1Total * 100).toStringAsFixed(1)) : 0.0,
          'supportRate': user1Total > 0 ? double.parse((user1Supportive / user1Total * 100).toStringAsFixed(1)) : 0.0,
        },
        user2: {
          'empathyRate': user2Total > 0 ? double.parse((user2Empathetic / user2Total * 100).toStringAsFixed(1)) : 0.0,
          'supportRate': user2Total > 0 ? double.parse((user2Supportive / user2Total * 100).toStringAsFixed(1)) : 0.0,
        },
      },
    };
  }

  // ========================================================================
  // SUMMARY GENERATION
  // ========================================================================

  Map<String, dynamic> _generateEISummary(
    Map<String, dynamic> empathy,
    Map<String, dynamic> selfDisclosure,
    Map<String, dynamic> validation,
    Map<String, dynamic> sentiment,
  ) {
    final summary = <String, dynamic>{};

    for (final userName in empathy.keys) {
      final empathyData = empathy[userName] as Map<String, dynamic>?;
      final disclosureData = selfDisclosure[userName] as Map<String, dynamic>?;
      final validationData = validation[userName] as Map<String, dynamic>?;
      final sentimentData = sentiment[userName] as Map<String, dynamic>?;

      // Calculate overall EI score
      final empathyScore = empathyData?['score'] as int? ?? 0;
      final disclosureScore = disclosureData?['score'] as int? ?? 0;
      final validationScore = validationData?['score'] as int? ?? 0;

      final overallScore = ((empathyScore + disclosureScore + validationScore) / 3).round();

      summary[userName] = {
        'overallEIScore': overallScore,
        'category': _categorizeOverallEI(overallScore),
        'emotionalTone': sentimentData?['balance'] ?? 'Unknown',
        'profile': _generateEIProfile(empathyData, disclosureData, validationData),
      };
    }

    return summary;
  }

  String _categorizeOverallEI(int score) {
    if (score > 60) return 'High Emotional Intelligence';
    if (score > 40) return 'Good Emotional Intelligence';
    if (score > 25) return 'Moderate Emotional Intelligence';
    if (score > 10) return 'Developing Emotional Intelligence';
    return 'Reserved Emotional Style';
  }

  String _generateEIProfile(
    Map<String, dynamic>? empathy,
    Map<String, dynamic>? disclosure,
    Map<String, dynamic>? validation,
  ) {
    final empathyScore = empathy?['score'] as int? ?? 0;
    final disclosureScore = disclosure?['score'] as int? ?? 0;
    final validationScore = validation?['score'] as int? ?? 0;

    if (empathyScore > 40 && validationScore > 40) {
      return 'Supportive Listener';
    } else if (disclosureScore > 50 && empathyScore > 30) {
      return 'Open Connector';
    } else if (validationScore > 50) {
      return 'Affirming Responder';
    } else if (empathyScore > 30) {
      return 'Caring Communicator';
    } else if (disclosureScore > 40) {
      return 'Expressive Sharer';
    } else {
      return 'Balanced Communicator';
    }
  }

  // ========================================================================
  // HELPER METHODS
  // ========================================================================

  double _calculateConfidence(int messageCount, int userCount) {
    if (messageCount < 50 || userCount < 2) return 0.3;
    if (messageCount < 200) return 0.5;
    if (messageCount < 500) return 0.7;
    if (messageCount < 1000) return 0.85;
    return 0.95;
  }

  AnalysisResult _createEmptyResult() {
    return AnalysisResult(
      type: 'emotional_intelligence',
      data: {
        'empathy': <String, dynamic>{},
        'selfDisclosure': <String, dynamic>{},
        'validation': <String, dynamic>{},
        'sentiment': <String, dynamic>{},
        'volatility': <String, dynamic>{},
        'reciprocity': <String, dynamic>{},
        'summary': <String, dynamic>{},
      },
      confidence: 0.0,
      generatedAt: DateTime.now(),
    );
  }

  AnalysisResult _createErrorResult(Object error) {
    return AnalysisResult(
      type: 'emotional_intelligence',
      data: {
        'error': error.toString(),
        'empathy': <String, dynamic>{},
        'selfDisclosure': <String, dynamic>{},
        'validation': <String, dynamic>{},
        'sentiment': <String, dynamic>{},
        'volatility': <String, dynamic>{},
        'reciprocity': <String, dynamic>{},
        'summary': <String, dynamic>{},
      },
      confidence: 0.0,
      generatedAt: DateTime.now(),
    );
  }
}
