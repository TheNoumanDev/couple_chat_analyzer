// ============================================================================
// FILE: features/analysis/analyzers/enhanced/personality_trait_analyzer.dart
// Personality Trait Analyzer - MBTI-style trait detection from chat patterns
// ============================================================================
import 'package:flutter/foundation.dart';
import '../../../../shared/domain.dart';
import '../../analysis_models.dart';
import '../base_analyzer.dart';

class PersonalityTraitAnalyzer implements EnhancedAnalyzer {
  static const int maxAnalysisMessages = 5000;

  // Thinking vs Feeling indicators
  static const List<String> _thinkingWords = [
    'because', 'therefore', 'logically', 'reason', 'analyze', 'analysis',
    'fact', 'facts', 'data', 'evidence', 'prove', 'proof',
    'think', 'thought', 'consider', 'conclude', 'conclusion',
    'objective', 'rational', 'logical', 'efficient', 'effective',
    'problem', 'solution', 'solve', 'fix', 'strategy', 'plan',
    'should', 'must', 'need to', 'have to', 'correct', 'wrong',
  ];

  static const List<String> _feelingWords = [
    'feel', 'feeling', 'felt', 'emotion', 'emotional',
    'love', 'hate', 'happy', 'sad', 'excited', 'worried',
    'care', 'caring', 'appreciate', 'grateful', 'thankful',
    'hurt', 'pain', 'joy', 'hope', 'wish', 'dream',
    'heart', 'soul', 'believe', 'believe in', 'trust',
    'support', 'help', 'understand', 'empathy', 'sympathy',
    'kind', 'nice', 'sweet', 'beautiful', 'wonderful',
  ];

  // Judging vs Perceiving indicators
  static const List<String> _judgingWords = [
    'plan', 'planned', 'planning', 'schedule', 'scheduled',
    'organize', 'organized', 'list', 'deadline', 'on time',
    'decide', 'decided', 'decision', 'final', 'done',
    'finish', 'finished', 'complete', 'completed', 'closure',
    'should', 'must', 'need', 'have to', 'supposed to',
    'always', 'never', 'every', 'routine', 'structure',
    'prepare', 'prepared', 'ready', 'certain', 'sure',
  ];

  static const List<String> _perceivingWords = [
    'maybe', 'perhaps', 'possibly', 'might', 'could',
    'flexible', 'spontaneous', 'random', 'whatever', 'whenever',
    'explore', 'discover', 'curious', 'wonder', 'wondering',
    'option', 'options', 'alternative', 'open', 'possibility',
    'depends', 'it depends', 'we will see', 'lets see', "let's see",
    'go with the flow', 'play it by ear', 'wing it',
    'change', 'adapt', 'adjust', 'improvise',
  ];

  // Sensing vs Intuition indicators
  static const List<String> _sensingWords = [
    'see', 'saw', 'look', 'looked', 'watch', 'watched',
    'hear', 'heard', 'sound', 'sounds', 'smell', 'taste', 'touch',
    'detail', 'details', 'specific', 'exactly', 'precise',
    'practical', 'realistic', 'real', 'actual', 'literally',
    'experience', 'experienced', 'hands-on', 'tried',
    'now', 'today', 'yesterday', 'currently', 'present',
    'step by step', 'one at a time', 'focus',
  ];

  static const List<String> _intuitionWords = [
    'imagine', 'imagined', 'vision', 'idea', 'ideas',
    'concept', 'theory', 'abstract', 'meaning', 'pattern',
    'future', 'possibility', 'potential', 'could be', 'might be',
    'insight', 'intuition', 'gut feeling', 'sense',
    'big picture', 'overall', 'general', 'broad',
    'innovative', 'creative', 'unique', 'new', 'novel',
    'symbol', 'metaphor', 'deeper', 'underlying',
  ];

  @override
  Future<AnalysisResult> analyze(ChatEntity chat) async {
    debugPrint("🧬 PersonalityTraitAnalyzer: Starting analysis");

    try {
      final messagesToProcess = chat.messages.length > maxAnalysisMessages
          ? chat.messages.take(maxAnalysisMessages).toList()
          : chat.messages;

      if (messagesToProcess.isEmpty) {
        return _createEmptyResult();
      }

      final userIdToName = {for (var user in chat.users) user.id: user.name};

      // Analyze personality dimensions
      final extraversionAnalysis = _analyzeExtraversion(messagesToProcess, userIdToName);
      final thinkingFeelingAnalysis = _analyzeThinkingFeeling(messagesToProcess, userIdToName);
      final judgingPerceivingAnalysis = _analyzeJudgingPerceiving(messagesToProcess, userIdToName);
      final sensingIntuitionAnalysis = _analyzeSensingIntuition(messagesToProcess, userIdToName);
      final opennessAnalysis = _analyzeOpenness(messagesToProcess, userIdToName);
      final conscientiousnessAnalysis = _analyzeConscientiousness(messagesToProcess, userIdToName);

      // Generate MBTI-style profile
      final mbtiProfile = _generateMBTIProfile(
        extraversionAnalysis,
        sensingIntuitionAnalysis,
        thinkingFeelingAnalysis,
        judgingPerceivingAnalysis,
      );

      final result = {
        'extraversion': extraversionAnalysis,
        'thinkingFeeling': thinkingFeelingAnalysis,
        'judgingPerceiving': judgingPerceivingAnalysis,
        'sensingIntuition': sensingIntuitionAnalysis,
        'openness': opennessAnalysis,
        'conscientiousness': conscientiousnessAnalysis,
        'mbtiProfile': mbtiProfile,
        'summary': _generatePersonalitySummary(mbtiProfile, opennessAnalysis, conscientiousnessAnalysis),
      };

      debugPrint("✅ PersonalityTraitAnalyzer: Analysis complete");

      return AnalysisResult(
        type: 'personality_traits',
        data: result,
        confidence: _calculateConfidence(messagesToProcess.length, userIdToName.length),
        generatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      debugPrint("❌ PersonalityTraitAnalyzer: Error - $e");
      debugPrint("Stack trace: $stackTrace");
      return _createErrorResult(e);
    }
  }

  // ========================================================================
  // EXTRAVERSION VS INTROVERSION
  // ========================================================================

  Map<String, dynamic> _analyzeExtraversion(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, dynamic>> userData = {};

    for (final userName in userIdToName.values) {
      userData[userName] = {
        'totalMessages': 0,
        'totalWords': 0,
        'initiationCount': 0,
        'quickResponses': 0, // Responses under 5 minutes
        'exclamationCount': 0,
        'questionCount': 0,
      };
    }

    // Sort messages for conversation analysis
    final sortedMessages = List<MessageEntity>.from(messages)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    DateTime? lastMessageTime;
    String? lastSender;

    for (int i = 0; i < sortedMessages.length; i++) {
      final message = sortedMessages[i];
      if (message.type != MessageType.text) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final content = message.content;
      final data = userData[userName]!;

      data['totalMessages'] = (data['totalMessages'] as int) + 1;
      data['totalWords'] = (data['totalWords'] as int) + content.split(RegExp(r'\s+')).length;
      data['exclamationCount'] = (data['exclamationCount'] as int) + '!'.allMatches(content).length;
      data['questionCount'] = (data['questionCount'] as int) + '?'.allMatches(content).length;

      // Check if this is a conversation initiation (gap > 2 hours)
      if (lastMessageTime != null) {
        final gap = message.timestamp.difference(lastMessageTime).inMinutes;
        if (gap > 120) {
          data['initiationCount'] = (data['initiationCount'] as int) + 1;
        }

        // Quick response (under 5 minutes to different sender)
        if (gap < 5 && lastSender != userName) {
          data['quickResponses'] = (data['quickResponses'] as int) + 1;
        }
      }

      lastMessageTime = message.timestamp;
      lastSender = userName;
    }

    // Calculate extraversion scores
    final Map<String, dynamic> result = {};
    final totalMessages = messages.where((m) => m.type == MessageType.text).length;

    for (final entry in userData.entries) {
      final userName = entry.key;
      final data = entry.value;

      final userMessages = data['totalMessages'] as int;
      final userWords = data['totalWords'] as int;
      final initiations = data['initiationCount'] as int;
      final quickResponses = data['quickResponses'] as int;
      final exclamations = data['exclamationCount'] as int;

      if (userMessages == 0) {
        result[userName] = {
          'score': 50,
          'tendency': 'Ambivert',
          'indicators': <String, dynamic>{},
        };
        continue;
      }

      // Calculate extraversion indicators
      final messageShare = totalMessages > 0 ? userMessages / totalMessages : 0.0;
      final avgWordsPerMessage = userWords / userMessages;
      final exclamationRate = exclamations / userMessages;
      final quickResponseRate = userMessages > 1 ? quickResponses / (userMessages - 1) : 0.0;

      // Score calculation (0-100, higher = more extraverted)
      double score = 50.0;

      // High message volume suggests extraversion
      if (messageShare > 0.55) score += 10;
      else if (messageShare < 0.45) score -= 10;

      // Short, frequent messages suggest extraversion
      if (avgWordsPerMessage < 15) score += 8;
      else if (avgWordsPerMessage > 40) score -= 8;

      // High exclamation use suggests extraversion
      if (exclamationRate > 0.3) score += 7;
      else if (exclamationRate < 0.05) score -= 5;

      // Quick responses suggest extraversion
      if (quickResponseRate > 0.3) score += 10;
      else if (quickResponseRate < 0.1) score -= 5;

      // Initiating conversations suggests extraversion
      if (initiations > 5) score += 5;

      score = score.clamp(0.0, 100.0);

      result[userName] = {
        'score': score.round(),
        'tendency': _categorizeExtraversion(score),
        'indicators': {
          'messageShare': double.parse((messageShare * 100).toStringAsFixed(1)),
          'avgWordsPerMessage': avgWordsPerMessage.round(),
          'exclamationRate': double.parse((exclamationRate * 100).toStringAsFixed(1)),
          'quickResponseRate': double.parse((quickResponseRate * 100).toStringAsFixed(1)),
        },
      };
    }

    return result;
  }

  String _categorizeExtraversion(double score) {
    if (score > 70) return 'Extraverted';
    if (score > 55) return 'Slightly Extraverted';
    if (score > 45) return 'Ambivert';
    if (score > 30) return 'Slightly Introverted';
    return 'Introverted';
  }

  // ========================================================================
  // THINKING VS FEELING
  // ========================================================================

  Map<String, dynamic> _analyzeThinkingFeeling(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, dynamic>> userData = {};

    for (final userName in userIdToName.values) {
      userData[userName] = {
        'totalMessages': 0,
        'thinkingCount': 0,
        'feelingCount': 0,
      };
    }

    for (final message in messages) {
      if (message.type != MessageType.text || message.content.isEmpty) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final content = message.content.toLowerCase();
      final data = userData[userName]!;

      data['totalMessages'] = (data['totalMessages'] as int) + 1;

      // Count thinking words
      for (final word in _thinkingWords) {
        if (content.contains(word)) {
          data['thinkingCount'] = (data['thinkingCount'] as int) + 1;
          break;
        }
      }

      // Count feeling words
      for (final word in _feelingWords) {
        if (content.contains(word)) {
          data['feelingCount'] = (data['feelingCount'] as int) + 1;
          break;
        }
      }
    }

    // Calculate T/F scores
    final Map<String, dynamic> result = {};

    for (final entry in userData.entries) {
      final userName = entry.key;
      final data = entry.value;

      final totalMessages = data['totalMessages'] as int;
      final thinkingCount = data['thinkingCount'] as int;
      final feelingCount = data['feelingCount'] as int;

      if (totalMessages == 0) {
        result[userName] = {
          'dimension': 'T/F',
          'score': 50,
          'tendency': 'Balanced',
          'thinkingRate': 0.0,
          'feelingRate': 0.0,
        };
        continue;
      }

      final thinkingRate = thinkingCount / totalMessages;
      final feelingRate = feelingCount / totalMessages;

      // Score: 0 = pure Feeling, 100 = pure Thinking
      double score = 50.0;
      if (thinkingRate + feelingRate > 0) {
        score = (thinkingRate / (thinkingRate + feelingRate)) * 100;
      }

      result[userName] = {
        'dimension': 'T/F',
        'score': score.round(),
        'tendency': _categorizeThinkingFeeling(score),
        'thinkingRate': double.parse((thinkingRate * 100).toStringAsFixed(1)),
        'feelingRate': double.parse((feelingRate * 100).toStringAsFixed(1)),
      };
    }

    return result;
  }

  String _categorizeThinkingFeeling(double score) {
    if (score > 65) return 'Thinking';
    if (score > 55) return 'Slight Thinking';
    if (score > 45) return 'Balanced';
    if (score > 35) return 'Slight Feeling';
    return 'Feeling';
  }

  // ========================================================================
  // JUDGING VS PERCEIVING
  // ========================================================================

  Map<String, dynamic> _analyzeJudgingPerceiving(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, dynamic>> userData = {};

    for (final userName in userIdToName.values) {
      userData[userName] = {
        'totalMessages': 0,
        'judgingCount': 0,
        'perceivingCount': 0,
      };
    }

    for (final message in messages) {
      if (message.type != MessageType.text || message.content.isEmpty) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final content = message.content.toLowerCase();
      final data = userData[userName]!;

      data['totalMessages'] = (data['totalMessages'] as int) + 1;

      for (final word in _judgingWords) {
        if (content.contains(word)) {
          data['judgingCount'] = (data['judgingCount'] as int) + 1;
          break;
        }
      }

      for (final word in _perceivingWords) {
        if (content.contains(word)) {
          data['perceivingCount'] = (data['perceivingCount'] as int) + 1;
          break;
        }
      }
    }

    // Calculate J/P scores
    final Map<String, dynamic> result = {};

    for (final entry in userData.entries) {
      final userName = entry.key;
      final data = entry.value;

      final totalMessages = data['totalMessages'] as int;
      final judgingCount = data['judgingCount'] as int;
      final perceivingCount = data['perceivingCount'] as int;

      if (totalMessages == 0) {
        result[userName] = {
          'dimension': 'J/P',
          'score': 50,
          'tendency': 'Balanced',
          'judgingRate': 0.0,
          'perceivingRate': 0.0,
        };
        continue;
      }

      final judgingRate = judgingCount / totalMessages;
      final perceivingRate = perceivingCount / totalMessages;

      // Score: 0 = pure Perceiving, 100 = pure Judging
      double score = 50.0;
      if (judgingRate + perceivingRate > 0) {
        score = (judgingRate / (judgingRate + perceivingRate)) * 100;
      }

      result[userName] = {
        'dimension': 'J/P',
        'score': score.round(),
        'tendency': _categorizeJudgingPerceiving(score),
        'judgingRate': double.parse((judgingRate * 100).toStringAsFixed(1)),
        'perceivingRate': double.parse((perceivingRate * 100).toStringAsFixed(1)),
      };
    }

    return result;
  }

  String _categorizeJudgingPerceiving(double score) {
    if (score > 65) return 'Judging';
    if (score > 55) return 'Slight Judging';
    if (score > 45) return 'Balanced';
    if (score > 35) return 'Slight Perceiving';
    return 'Perceiving';
  }

  // ========================================================================
  // SENSING VS INTUITION
  // ========================================================================

  Map<String, dynamic> _analyzeSensingIntuition(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, dynamic>> userData = {};

    for (final userName in userIdToName.values) {
      userData[userName] = {
        'totalMessages': 0,
        'sensingCount': 0,
        'intuitionCount': 0,
      };
    }

    for (final message in messages) {
      if (message.type != MessageType.text || message.content.isEmpty) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final content = message.content.toLowerCase();
      final data = userData[userName]!;

      data['totalMessages'] = (data['totalMessages'] as int) + 1;

      for (final word in _sensingWords) {
        if (content.contains(word)) {
          data['sensingCount'] = (data['sensingCount'] as int) + 1;
          break;
        }
      }

      for (final word in _intuitionWords) {
        if (content.contains(word)) {
          data['intuitionCount'] = (data['intuitionCount'] as int) + 1;
          break;
        }
      }
    }

    // Calculate S/N scores
    final Map<String, dynamic> result = {};

    for (final entry in userData.entries) {
      final userName = entry.key;
      final data = entry.value;

      final totalMessages = data['totalMessages'] as int;
      final sensingCount = data['sensingCount'] as int;
      final intuitionCount = data['intuitionCount'] as int;

      if (totalMessages == 0) {
        result[userName] = {
          'dimension': 'S/N',
          'score': 50,
          'tendency': 'Balanced',
          'sensingRate': 0.0,
          'intuitionRate': 0.0,
        };
        continue;
      }

      final sensingRate = sensingCount / totalMessages;
      final intuitionRate = intuitionCount / totalMessages;

      // Score: 0 = pure Intuition, 100 = pure Sensing
      double score = 50.0;
      if (sensingRate + intuitionRate > 0) {
        score = (sensingRate / (sensingRate + intuitionRate)) * 100;
      }

      result[userName] = {
        'dimension': 'S/N',
        'score': score.round(),
        'tendency': _categorizeSensingIntuition(score),
        'sensingRate': double.parse((sensingRate * 100).toStringAsFixed(1)),
        'intuitionRate': double.parse((intuitionRate * 100).toStringAsFixed(1)),
      };
    }

    return result;
  }

  String _categorizeSensingIntuition(double score) {
    if (score > 65) return 'Sensing';
    if (score > 55) return 'Slight Sensing';
    if (score > 45) return 'Balanced';
    if (score > 35) return 'Slight Intuition';
    return 'Intuition';
  }

  // ========================================================================
  // OPENNESS (Big Five)
  // ========================================================================

  Map<String, dynamic> _analyzeOpenness(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final opennessIndicators = [
      'idea', 'ideas', 'creative', 'imagine', 'imagination',
      'curious', 'wonder', 'explore', 'discover', 'new',
      'art', 'music', 'book', 'movie', 'culture',
      'philosophy', 'meaning', 'deep', 'think about',
      'different', 'unique', 'interesting', 'fascinating',
    ];

    final Map<String, Map<String, dynamic>> userData = {};

    for (final userName in userIdToName.values) {
      userData[userName] = {
        'totalMessages': 0,
        'opennessCount': 0,
        'uniqueTopics': <String>{},
      };
    }

    for (final message in messages) {
      if (message.type != MessageType.text || message.content.isEmpty) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final content = message.content.toLowerCase();
      final data = userData[userName]!;

      data['totalMessages'] = (data['totalMessages'] as int) + 1;

      for (final word in opennessIndicators) {
        if (content.contains(word)) {
          data['opennessCount'] = (data['opennessCount'] as int) + 1;
          (data['uniqueTopics'] as Set<String>).add(word);
          break;
        }
      }
    }

    // Calculate openness scores
    final Map<String, dynamic> result = {};

    for (final entry in userData.entries) {
      final userName = entry.key;
      final data = entry.value;

      final totalMessages = data['totalMessages'] as int;
      final opennessCount = data['opennessCount'] as int;
      final uniqueTopics = (data['uniqueTopics'] as Set<String>).length;

      if (totalMessages == 0) {
        result[userName] = {
          'score': 50,
          'category': 'Moderate',
          'rate': 0.0,
        };
        continue;
      }

      final opennessRate = opennessCount / totalMessages;
      final score = ((opennessRate * 50) + (uniqueTopics * 5)).clamp(0.0, 100.0);

      result[userName] = {
        'score': score.round(),
        'category': _categorizeOpenness(score),
        'rate': double.parse((opennessRate * 100).toStringAsFixed(1)),
        'diversityScore': uniqueTopics,
      };
    }

    return result;
  }

  String _categorizeOpenness(double score) {
    if (score > 70) return 'Highly Open';
    if (score > 50) return 'Open';
    if (score > 30) return 'Moderate';
    return 'Traditional';
  }

  // ========================================================================
  // CONSCIENTIOUSNESS (Big Five)
  // ========================================================================

  Map<String, dynamic> _analyzeConscientiousness(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, dynamic>> userData = {};

    for (final userName in userIdToName.values) {
      userData[userName] = {
        'totalMessages': 0,
        'properPunctuation': 0,
        'organizedLanguage': 0, // Plan, schedule, etc.
        'typoIndicators': 0, // Multiple ??? or !!!, missing caps
      };
    }

    final organizedWords = ['plan', 'schedule', 'organize', 'list', 'goal', 'task', 'done', 'finish', 'complete'];

    for (final message in messages) {
      if (message.type != MessageType.text || message.content.isEmpty) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final content = message.content;
      final lowerContent = content.toLowerCase();
      final data = userData[userName]!;

      data['totalMessages'] = (data['totalMessages'] as int) + 1;

      // Check for proper punctuation at end
      if (RegExp(r'[.!?]$').hasMatch(content.trim())) {
        data['properPunctuation'] = (data['properPunctuation'] as int) + 1;
      }

      // Check for organized language
      for (final word in organizedWords) {
        if (lowerContent.contains(word)) {
          data['organizedLanguage'] = (data['organizedLanguage'] as int) + 1;
          break;
        }
      }

      // Check for typo indicators (lack of care)
      if (RegExp(r'[!?]{3,}').hasMatch(content) ||
          (content.length > 20 && content == content.toLowerCase() && !content.contains(RegExp(r'[.!?]')))) {
        data['typoIndicators'] = (data['typoIndicators'] as int) + 1;
      }
    }

    // Calculate conscientiousness scores
    final Map<String, dynamic> result = {};

    for (final entry in userData.entries) {
      final userName = entry.key;
      final data = entry.value;

      final totalMessages = data['totalMessages'] as int;
      final properPunctuation = data['properPunctuation'] as int;
      final organizedLanguage = data['organizedLanguage'] as int;
      final typoIndicators = data['typoIndicators'] as int;

      if (totalMessages == 0) {
        result[userName] = {
          'score': 50,
          'category': 'Moderate',
          'punctuationRate': 0.0,
        };
        continue;
      }

      final punctuationRate = properPunctuation / totalMessages;
      final organizedRate = organizedLanguage / totalMessages;
      final typoRate = typoIndicators / totalMessages;

      double score = 50.0;
      score += punctuationRate * 25;
      score += organizedRate * 15;
      score -= typoRate * 20;
      score = score.clamp(0.0, 100.0);

      result[userName] = {
        'score': score.round(),
        'category': _categorizeConscientiousness(score),
        'punctuationRate': double.parse((punctuationRate * 100).toStringAsFixed(1)),
        'organizedRate': double.parse((organizedRate * 100).toStringAsFixed(1)),
      };
    }

    return result;
  }

  String _categorizeConscientiousness(double score) {
    if (score > 70) return 'Highly Conscientious';
    if (score > 55) return 'Conscientious';
    if (score > 40) return 'Moderate';
    return 'Flexible';
  }

  // ========================================================================
  // MBTI PROFILE GENERATION
  // ========================================================================

  Map<String, dynamic> _generateMBTIProfile(
    Map<String, dynamic> extraversion,
    Map<String, dynamic> sensingIntuition,
    Map<String, dynamic> thinkingFeeling,
    Map<String, dynamic> judgingPerceiving,
  ) {
    final profile = <String, dynamic>{};

    for (final userName in extraversion.keys) {
      final eData = extraversion[userName] as Map<String, dynamic>?;
      final sData = sensingIntuition[userName] as Map<String, dynamic>?;
      final tData = thinkingFeeling[userName] as Map<String, dynamic>?;
      final jData = judgingPerceiving[userName] as Map<String, dynamic>?;

      final eScore = eData?['score'] as int? ?? 50;
      final sScore = sData?['score'] as int? ?? 50;
      final tScore = tData?['score'] as int? ?? 50;
      final jScore = jData?['score'] as int? ?? 50;

      // Generate 4-letter type
      final letter1 = eScore >= 50 ? 'E' : 'I';
      final letter2 = sScore >= 50 ? 'S' : 'N';
      final letter3 = tScore >= 50 ? 'T' : 'F';
      final letter4 = jScore >= 50 ? 'J' : 'P';

      final mbtiType = '$letter1$letter2$letter3$letter4';

      profile[userName] = {
        'type': mbtiType,
        'description': _getMBTIDescription(mbtiType),
        'dimensions': {
          'E/I': {'letter': letter1, 'score': eScore, 'strength': _getDimensionStrength(eScore)},
          'S/N': {'letter': letter2, 'score': sScore, 'strength': _getDimensionStrength(sScore)},
          'T/F': {'letter': letter3, 'score': tScore, 'strength': _getDimensionStrength(tScore)},
          'J/P': {'letter': letter4, 'score': jScore, 'strength': _getDimensionStrength(jScore)},
        },
      };
    }

    return profile;
  }

  String _getDimensionStrength(int score) {
    final deviation = (score - 50).abs();
    if (deviation > 25) return 'Strong';
    if (deviation > 10) return 'Moderate';
    return 'Slight';
  }

  String _getMBTIDescription(String type) {
    const descriptions = {
      'INTJ': 'The Architect - Strategic and independent thinker',
      'INTP': 'The Thinker - Logical and analytical mind',
      'ENTJ': 'The Commander - Bold and decisive leader',
      'ENTP': 'The Debater - Smart and curious explorer',
      'INFJ': 'The Advocate - Insightful and principled idealist',
      'INFP': 'The Mediator - Poetic and kind-hearted dreamer',
      'ENFJ': 'The Protagonist - Charismatic and inspiring leader',
      'ENFP': 'The Campaigner - Enthusiastic and creative spirit',
      'ISTJ': 'The Logistician - Practical and fact-minded',
      'ISFJ': 'The Defender - Dedicated and warm protector',
      'ESTJ': 'The Executive - Organized administrator',
      'ESFJ': 'The Consul - Caring and sociable helper',
      'ISTP': 'The Virtuoso - Bold and practical experimenter',
      'ISFP': 'The Adventurer - Flexible and charming artist',
      'ESTP': 'The Entrepreneur - Smart and energetic perceiver',
      'ESFP': 'The Entertainer - Spontaneous and energetic performer',
    };

    return descriptions[type] ?? 'Unique personality blend';
  }

  // ========================================================================
  // SUMMARY GENERATION
  // ========================================================================

  Map<String, dynamic> _generatePersonalitySummary(
    Map<String, dynamic> mbtiProfile,
    Map<String, dynamic> openness,
    Map<String, dynamic> conscientiousness,
  ) {
    final summary = <String, dynamic>{};

    for (final userName in mbtiProfile.keys) {
      final mbti = mbtiProfile[userName] as Map<String, dynamic>?;
      final open = openness[userName] as Map<String, dynamic>?;
      final consc = conscientiousness[userName] as Map<String, dynamic>?;

      summary[userName] = {
        'mbtiType': mbti?['type'] ?? 'Unknown',
        'description': mbti?['description'] ?? 'Unknown',
        'opennessLevel': open?['category'] ?? 'Unknown',
        'conscientiousnessLevel': consc?['category'] ?? 'Unknown',
        'communicationStyle': _inferCommunicationStyle(mbti),
      };
    }

    return summary;
  }

  String _inferCommunicationStyle(Map<String, dynamic>? mbti) {
    if (mbti == null) return 'Balanced';

    final type = mbti['type'] as String? ?? '';

    if (type.startsWith('E') && type.contains('F')) {
      return 'Warm and Expressive';
    } else if (type.startsWith('E') && type.contains('T')) {
      return 'Direct and Confident';
    } else if (type.startsWith('I') && type.contains('F')) {
      return 'Thoughtful and Caring';
    } else if (type.startsWith('I') && type.contains('T')) {
      return 'Reserved and Analytical';
    }

    return 'Balanced';
  }

  // ========================================================================
  // HELPER METHODS
  // ========================================================================

  double _calculateConfidence(int messageCount, int userCount) {
    if (messageCount < 100 || userCount < 2) return 0.3;
    if (messageCount < 500) return 0.5;
    if (messageCount < 1000) return 0.65;
    if (messageCount < 2000) return 0.8;
    return 0.9;
  }

  AnalysisResult _createEmptyResult() {
    return AnalysisResult(
      type: 'personality_traits',
      data: {
        'extraversion': <String, dynamic>{},
        'thinkingFeeling': <String, dynamic>{},
        'judgingPerceiving': <String, dynamic>{},
        'sensingIntuition': <String, dynamic>{},
        'openness': <String, dynamic>{},
        'conscientiousness': <String, dynamic>{},
        'mbtiProfile': <String, dynamic>{},
        'summary': <String, dynamic>{},
      },
      confidence: 0.0,
      generatedAt: DateTime.now(),
    );
  }

  AnalysisResult _createErrorResult(Object error) {
    return AnalysisResult(
      type: 'personality_traits',
      data: {
        'error': error.toString(),
        'extraversion': <String, dynamic>{},
        'thinkingFeeling': <String, dynamic>{},
        'judgingPerceiving': <String, dynamic>{},
        'sensingIntuition': <String, dynamic>{},
        'openness': <String, dynamic>{},
        'conscientiousness': <String, dynamic>{},
        'mbtiProfile': <String, dynamic>{},
        'summary': <String, dynamic>{},
      },
      confidence: 0.0,
      generatedAt: DateTime.now(),
    );
  }
}
