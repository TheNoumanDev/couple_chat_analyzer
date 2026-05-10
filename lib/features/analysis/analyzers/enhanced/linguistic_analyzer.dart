// ============================================================================
// FILE: features/analysis/analyzers/enhanced/linguistic_analyzer.dart
// Linguistic Analyzer - Vocabulary richness, formality, sentence complexity
// ============================================================================
import 'package:flutter/foundation.dart';
import '../../../../shared/domain.dart';
import '../../analysis_models.dart';
import '../base_analyzer.dart';

class LinguisticAnalyzer implements EnhancedAnalyzer {
  static const int maxAnalysisMessages = 5000;

  // Common English stopwords to exclude from vocabulary analysis
  static const Set<String> _stopwords = {
    'a', 'an', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
    'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'been',
    'be', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would',
    'could', 'should', 'may', 'might', 'must', 'shall', 'can', 'need',
    'dare', 'ought', 'used', 'it', 'its', 'this', 'that', 'these', 'those',
    'i', 'you', 'he', 'she', 'we', 'they', 'me', 'him', 'her', 'us', 'them',
    'my', 'your', 'his', 'our', 'their', 'mine', 'yours', 'hers', 'ours',
    'what', 'which', 'who', 'whom', 'where', 'when', 'why', 'how',
    'all', 'each', 'every', 'both', 'few', 'more', 'most', 'other', 'some',
    'such', 'no', 'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very',
    'just', 'also', 'now', 'here', 'there', 'then', 'once', 'if',
    'am', 'im', 'ive', 'id', 'ill', 'youre', 'youve', 'youd', 'youll',
    'hes', 'shes', 'weve', 'theyve', 'theyd', 'theyll', 'dont',
    'doesnt', 'didnt', 'wont', 'wouldnt', 'cant', 'couldnt', 'shouldnt',
    'ok', 'okay', 'yeah', 'yes', 'nope', 'yep', 'hmm', 'umm', 'uh',
    'oh', 'ah', 'haha', 'hehe', 'lol', 'lmao', 'omg', 'wtf', 'idk',
  };

  // Contractions indicating informal language
  static const List<String> _contractionPatterns = [
    "don't", "won't", "can't", "isn't", "aren't", "wasn't", "weren't",
    "haven't", "hasn't", "hadn't", "wouldn't", "couldn't", "shouldn't",
    "i'm", "you're", "he's", "she's", "it's", "we're", "they're",
    "i've", "you've", "we've", "they've", "i'd", "you'd", "he'd",
    "she'd", "we'd", "they'd", "i'll", "you'll", "he'll", "she'll",
    "we'll", "they'll", "let's", "that's", "what's", "where's",
    "who's", "how's", "here's", "there's", "gonna", "wanna", "gotta",
    "kinda", "sorta", "dunno", "lemme", "gimme", "y'all", "ain't",
  ];

  @override
  Future<AnalysisResult> analyze(ChatEntity chat) async {
    debugPrint("📚 LinguisticAnalyzer: Starting analysis");

    try {
      final messagesToProcess = chat.messages.length > maxAnalysisMessages
          ? chat.messages.take(maxAnalysisMessages).toList()
          : chat.messages;

      if (messagesToProcess.isEmpty) {
        return _createEmptyResult();
      }

      final userIdToName = {for (var user in chat.users) user.id: user.name};

      // Analyze linguistic patterns for each user
      final vocabularyAnalysis = _analyzeVocabulary(messagesToProcess, userIdToName);
      final formalityAnalysis = _analyzeFormalityLevel(messagesToProcess, userIdToName);
      final complexityAnalysis = _analyzeSentenceComplexity(messagesToProcess, userIdToName);
      final writingPatterns = _analyzeWritingPatterns(messagesToProcess, userIdToName);

      final result = {
        'vocabulary': vocabularyAnalysis,
        'formality': formalityAnalysis,
        'complexity': complexityAnalysis,
        'writingPatterns': writingPatterns,
        'summary': _generateLinguisticSummary(vocabularyAnalysis, formalityAnalysis, complexityAnalysis),
      };

      debugPrint("✅ LinguisticAnalyzer: Analysis complete");

      return AnalysisResult(
        type: 'linguistic',
        data: result,
        confidence: _calculateConfidence(messagesToProcess.length, userIdToName.length),
        generatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      debugPrint("❌ LinguisticAnalyzer: Error - $e");
      debugPrint("Stack trace: $stackTrace");
      return _createErrorResult(e);
    }
  }

  // ========================================================================
  // VOCABULARY ANALYSIS
  // ========================================================================

  Map<String, dynamic> _analyzeVocabulary(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, dynamic>> userVocab = {};

    for (final userName in userIdToName.values) {
      userVocab[userName] = {
        'totalWords': 0,
        'uniqueWords': <String>{},
        'wordLengths': <int>[],
        'topWords': <String, int>{},
      };
    }

    // Process messages
    for (final message in messages) {
      if (message.type != MessageType.text || message.content.isEmpty) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final words = _extractWords(message.content);
      final userData = userVocab[userName]!;

      userData['totalWords'] = (userData['totalWords'] as int) + words.length;

      for (final word in words) {
        final lowerWord = word.toLowerCase();

        // Add to unique words
        (userData['uniqueWords'] as Set<String>).add(lowerWord);

        // Track word length
        (userData['wordLengths'] as List<int>).add(word.length);

        // Track word frequency (excluding stopwords)
        if (!_stopwords.contains(lowerWord) && word.length > 2) {
          final topWords = userData['topWords'] as Map<String, int>;
          topWords[lowerWord] = (topWords[lowerWord] ?? 0) + 1;
        }
      }
    }

    // Calculate metrics
    final Map<String, dynamic> result = {};

    for (final entry in userVocab.entries) {
      final userName = entry.key;
      final data = entry.value;

      final totalWords = data['totalWords'] as int;
      final uniqueWords = data['uniqueWords'] as Set<String>;
      final wordLengths = data['wordLengths'] as List<int>;
      final topWords = data['topWords'] as Map<String, int>;

      if (totalWords == 0) {
        result[userName] = {
          'ttr': 0.0,
          'category': 'No Data',
          'avgWordLength': 0.0,
          'uniqueWordCount': 0,
          'totalWords': 0,
          'topWords': <Map<String, dynamic>>[],
        };
        continue;
      }

      // Type-Token Ratio (vocabulary richness)
      final ttr = uniqueWords.length / totalWords;

      // Average word length
      final avgWordLength = wordLengths.isNotEmpty
          ? wordLengths.reduce((a, b) => a + b) / wordLengths.length
          : 0.0;

      // Get top 10 words
      final sortedWords = topWords.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top10 = sortedWords.take(10).map((e) => {
        'word': e.key,
        'count': e.value,
      }).toList();

      result[userName] = {
        'ttr': double.parse(ttr.toStringAsFixed(3)),
        'category': _categorizeVocabulary(ttr),
        'avgWordLength': double.parse(avgWordLength.toStringAsFixed(1)),
        'uniqueWordCount': uniqueWords.length,
        'totalWords': totalWords,
        'topWords': top10,
      };
    }

    return result;
  }

  String _categorizeVocabulary(double ttr) {
    if (ttr > 0.7) return 'Very Rich Vocabulary';
    if (ttr > 0.5) return 'Rich Vocabulary';
    if (ttr > 0.3) return 'Average Vocabulary';
    if (ttr > 0.15) return 'Limited Vocabulary';
    return 'Repetitive Vocabulary';
  }

  // ========================================================================
  // FORMALITY ANALYSIS
  // ========================================================================

  Map<String, dynamic> _analyzeFormalityLevel(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, dynamic>> userFormality = {};

    for (final userName in userIdToName.values) {
      userFormality[userName] = {
        'totalMessages': 0,
        'contractionCount': 0,
        'slangCount': 0,
        'properPunctuationCount': 0,
        'capsWordsCount': 0,
        'emojiCount': 0,
        'abbreviationCount': 0,
      };
    }

    // Slang and abbreviations
    final slangPatterns = RegExp(
      r'\b(lol|lmao|omg|wtf|idk|brb|ttyl|nvm|tbh|imo|btw|fyi|jk|smh|ikr|ngl|fr|rn|asap)\b',
      caseSensitive: false,
    );

    final emojiPattern = RegExp(
      r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
      unicode: true,
    );

    for (final message in messages) {
      if (message.type != MessageType.text || message.content.isEmpty) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final content = message.content;
      final data = userFormality[userName]!;

      data['totalMessages'] = (data['totalMessages'] as int) + 1;

      // Count contractions
      for (final contraction in _contractionPatterns) {
        if (content.toLowerCase().contains(contraction)) {
          data['contractionCount'] = (data['contractionCount'] as int) + 1;
          break; // Count once per message
        }
      }

      // Count slang
      final slangMatches = slangPatterns.allMatches(content);
      data['slangCount'] = (data['slangCount'] as int) + slangMatches.length;

      // Check proper punctuation (ends with . ! or ?)
      if (RegExp(r'[.!?]$').hasMatch(content.trim())) {
        data['properPunctuationCount'] = (data['properPunctuationCount'] as int) + 1;
      }

      // Count ALL CAPS words
      final words = content.split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.length > 1 && word == word.toUpperCase() && RegExp(r'^[A-Z]+$').hasMatch(word)) {
          data['capsWordsCount'] = (data['capsWordsCount'] as int) + 1;
        }
      }

      // Count emojis
      final emojiMatches = emojiPattern.allMatches(content);
      data['emojiCount'] = (data['emojiCount'] as int) + emojiMatches.length;

      // Count abbreviations
      data['abbreviationCount'] = (data['abbreviationCount'] as int) + slangMatches.length;
    }

    // Calculate formality scores
    final Map<String, dynamic> result = {};

    for (final entry in userFormality.entries) {
      final userName = entry.key;
      final data = entry.value;

      final totalMessages = data['totalMessages'] as int;
      if (totalMessages == 0) {
        result[userName] = {
          'formalityScore': 50,
          'category': 'No Data',
          'details': <String, dynamic>{},
        };
        continue;
      }

      // Calculate formality score (0-100, higher = more formal)
      double score = 50.0; // Start neutral

      // Contractions reduce formality
      final contractionRate = (data['contractionCount'] as int) / totalMessages;
      score -= contractionRate * 15;

      // Slang reduces formality
      final slangRate = (data['slangCount'] as int) / totalMessages;
      score -= slangRate * 20;

      // Proper punctuation increases formality
      final punctuationRate = (data['properPunctuationCount'] as int) / totalMessages;
      score += punctuationRate * 15;

      // ALL CAPS reduces formality
      final capsRate = (data['capsWordsCount'] as int) / totalMessages;
      score -= capsRate * 10;

      // Emojis reduce formality
      final emojiRate = (data['emojiCount'] as int) / totalMessages;
      score -= emojiRate * 5;

      score = score.clamp(0.0, 100.0);

      result[userName] = {
        'formalityScore': score.round(),
        'category': _categorizeFormalityLevel(score),
        'details': {
          'contractionRate': double.parse((contractionRate * 100).toStringAsFixed(1)),
          'slangRate': double.parse((slangRate * 100).toStringAsFixed(1)),
          'punctuationRate': double.parse((punctuationRate * 100).toStringAsFixed(1)),
          'emojiRate': double.parse((emojiRate * 100).toStringAsFixed(1)),
        },
      };
    }

    return result;
  }

  String _categorizeFormalityLevel(double score) {
    if (score > 75) return 'Very Formal';
    if (score > 60) return 'Formal';
    if (score > 40) return 'Casual';
    if (score > 25) return 'Informal';
    return 'Very Informal';
  }

  // ========================================================================
  // SENTENCE COMPLEXITY ANALYSIS
  // ========================================================================

  Map<String, dynamic> _analyzeSentenceComplexity(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, dynamic>> userComplexity = {};

    for (final userName in userIdToName.values) {
      userComplexity[userName] = {
        'totalMessages': 0,
        'totalSentences': 0,
        'totalWords': 0,
        'totalCommas': 0,
        'totalSemicolons': 0,
        'complexSentences': 0, // Sentences with subordinating conjunctions
        'questionCount': 0,
      };
    }

    // Subordinating conjunctions indicate complex sentences
    final subordinatingConjunctions = RegExp(
      r'\b(because|although|though|while|when|whenever|where|wherever|if|unless|until|after|before|since|once|as|whether|that|which|who|whom|whose)\b',
      caseSensitive: false,
    );

    for (final message in messages) {
      if (message.type != MessageType.text || message.content.isEmpty) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final content = message.content;
      final data = userComplexity[userName]!;

      data['totalMessages'] = (data['totalMessages'] as int) + 1;

      // Count sentences (rough estimate)
      final sentences = content.split(RegExp(r'[.!?]+'));
      data['totalSentences'] = (data['totalSentences'] as int) + sentences.length;

      // Count words
      final words = _extractWords(content);
      data['totalWords'] = (data['totalWords'] as int) + words.length;

      // Count commas (indicates clause complexity)
      data['totalCommas'] = (data['totalCommas'] as int) + ','.allMatches(content).length;

      // Count semicolons
      data['totalSemicolons'] = (data['totalSemicolons'] as int) + ';'.allMatches(content).length;

      // Check for complex sentences
      if (subordinatingConjunctions.hasMatch(content)) {
        data['complexSentences'] = (data['complexSentences'] as int) + 1;
      }

      // Count questions
      data['questionCount'] = (data['questionCount'] as int) + '?'.allMatches(content).length;
    }

    // Calculate complexity metrics
    final Map<String, dynamic> result = {};

    for (final entry in userComplexity.entries) {
      final userName = entry.key;
      final data = entry.value;

      final totalMessages = data['totalMessages'] as int;
      final totalSentences = data['totalSentences'] as int;
      final totalWords = data['totalWords'] as int;

      if (totalMessages == 0 || totalSentences == 0) {
        result[userName] = {
          'complexityScore': 0,
          'category': 'No Data',
          'avgWordsPerSentence': 0.0,
          'avgCommasPerMessage': 0.0,
          'complexSentenceRate': 0.0,
        };
        continue;
      }

      final avgWordsPerSentence = totalWords / totalSentences;
      final avgCommasPerMessage = (data['totalCommas'] as int) / totalMessages;
      final complexSentenceRate = (data['complexSentences'] as int) / totalMessages;

      // Calculate complexity score
      double score = 0.0;
      score += (avgWordsPerSentence / 20 * 40).clamp(0.0, 40.0); // Max 40 points
      score += (avgCommasPerMessage * 10).clamp(0.0, 30.0); // Max 30 points
      score += (complexSentenceRate * 30).clamp(0.0, 30.0); // Max 30 points

      result[userName] = {
        'complexityScore': score.round(),
        'category': _categorizeComplexity(score),
        'avgWordsPerSentence': double.parse(avgWordsPerSentence.toStringAsFixed(1)),
        'avgCommasPerMessage': double.parse(avgCommasPerMessage.toStringAsFixed(2)),
        'complexSentenceRate': double.parse((complexSentenceRate * 100).toStringAsFixed(1)),
        'questionRate': double.parse(((data['questionCount'] as int) / totalMessages * 100).toStringAsFixed(1)),
      };
    }

    return result;
  }

  String _categorizeComplexity(double score) {
    if (score > 70) return 'Very Complex';
    if (score > 50) return 'Complex';
    if (score > 30) return 'Moderate';
    if (score > 15) return 'Simple';
    return 'Very Simple';
  }

  // ========================================================================
  // WRITING PATTERNS ANALYSIS
  // ========================================================================

  Map<String, dynamic> _analyzeWritingPatterns(
    List<MessageEntity> messages,
    Map<String, String> userIdToName,
  ) {
    final Map<String, Map<String, dynamic>> userPatterns = {};

    for (final userName in userIdToName.values) {
      userPatterns[userName] = {
        'totalMessages': 0,
        'multipleExclamations': 0, // !! or !!!
        'multipleQuestions': 0, // ?? or ???
        'ellipsis': 0, // ...
        'allCapsMessages': 0,
        'startWithI': 0, // I-focused
        'startWithYou': 0, // You-focused
        'repetitionCount': 0, // Repeated words like "very very"
      };
    }

    final repetitionPattern = RegExp(r'\b(\w+)\s+\1\b', caseSensitive: false);

    for (final message in messages) {
      if (message.type != MessageType.text || message.content.isEmpty) continue;

      final userName = userIdToName[message.senderId];
      if (userName == null) continue;

      final content = message.content;
      final data = userPatterns[userName]!;

      data['totalMessages'] = (data['totalMessages'] as int) + 1;

      // Multiple exclamations
      if (RegExp(r'!{2,}').hasMatch(content)) {
        data['multipleExclamations'] = (data['multipleExclamations'] as int) + 1;
      }

      // Multiple questions
      if (RegExp(r'\?{2,}').hasMatch(content)) {
        data['multipleQuestions'] = (data['multipleQuestions'] as int) + 1;
      }

      // Ellipsis usage
      if (content.contains('...') || content.contains('…')) {
        data['ellipsis'] = (data['ellipsis'] as int) + 1;
      }

      // All caps message
      final wordsOnly = content.replaceAll(RegExp(r'[^a-zA-Z\s]'), '').trim();
      if (wordsOnly.isNotEmpty && wordsOnly == wordsOnly.toUpperCase() && wordsOnly.length > 5) {
        data['allCapsMessages'] = (data['allCapsMessages'] as int) + 1;
      }

      // Starts with I
      if (RegExp(r'^i\s', caseSensitive: false).hasMatch(content.trim())) {
        data['startWithI'] = (data['startWithI'] as int) + 1;
      }

      // Starts with You
      if (RegExp(r'^you\s', caseSensitive: false).hasMatch(content.trim())) {
        data['startWithYou'] = (data['startWithYou'] as int) + 1;
      }

      // Repetition
      final repetitions = repetitionPattern.allMatches(content);
      data['repetitionCount'] = (data['repetitionCount'] as int) + repetitions.length;
    }

    // Calculate pattern metrics
    final Map<String, dynamic> result = {};

    for (final entry in userPatterns.entries) {
      final userName = entry.key;
      final data = entry.value;

      final totalMessages = data['totalMessages'] as int;
      if (totalMessages == 0) {
        result[userName] = {
          'emphasis': 'No Data',
          'focusType': 'No Data',
          'patterns': <String>[],
        };
        continue;
      }

      // Determine emphasis style
      final exclamationRate = (data['multipleExclamations'] as int) / totalMessages;
      final capsRate = (data['allCapsMessages'] as int) / totalMessages;
      String emphasisStyle;
      if (exclamationRate > 0.2 || capsRate > 0.1) {
        emphasisStyle = 'High Emphasis';
      } else if (exclamationRate > 0.1 || capsRate > 0.05) {
        emphasisStyle = 'Moderate Emphasis';
      } else {
        emphasisStyle = 'Low Emphasis';
      }

      // Determine focus type
      final iRate = (data['startWithI'] as int) / totalMessages;
      final youRate = (data['startWithYou'] as int) / totalMessages;
      String focusType;
      if (iRate > youRate * 1.5) {
        focusType = 'Self-Focused';
      } else if (youRate > iRate * 1.5) {
        focusType = 'Other-Focused';
      } else {
        focusType = 'Balanced Focus';
      }

      // Identify notable patterns
      final patterns = <String>[];
      if (exclamationRate > 0.15) patterns.add('Frequent double exclamations');
      if ((data['ellipsis'] as int) / totalMessages > 0.2) patterns.add('Heavy ellipsis user');
      if ((data['multipleQuestions'] as int) / totalMessages > 0.1) patterns.add('Emphatic questioner');
      if ((data['repetitionCount'] as int) / totalMessages > 0.1) patterns.add('Uses word repetition');

      result[userName] = {
        'emphasis': emphasisStyle,
        'focusType': focusType,
        'patterns': patterns,
        'details': {
          'exclamationRate': double.parse((exclamationRate * 100).toStringAsFixed(1)),
          'ellipsisRate': double.parse(((data['ellipsis'] as int) / totalMessages * 100).toStringAsFixed(1)),
          'iFocusRate': double.parse((iRate * 100).toStringAsFixed(1)),
          'youFocusRate': double.parse((youRate * 100).toStringAsFixed(1)),
        },
      };
    }

    return result;
  }

  // ========================================================================
  // HELPER METHODS
  // ========================================================================

  List<String> _extractWords(String content) {
    return content
        .replaceAll(RegExp(r"[^\w\s']"), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && w.length > 1)
        .toList();
  }

  Map<String, dynamic> _generateLinguisticSummary(
    Map<String, dynamic> vocabulary,
    Map<String, dynamic> formality,
    Map<String, dynamic> complexity,
  ) {
    final summary = <String, dynamic>{};

    for (final userName in vocabulary.keys) {
      final vocabData = vocabulary[userName] as Map<String, dynamic>?;
      final formalityData = formality[userName] as Map<String, dynamic>?;
      final complexityData = complexity[userName] as Map<String, dynamic>?;

      summary[userName] = {
        'vocabularyCategory': vocabData?['category'] ?? 'Unknown',
        'formalityCategory': formalityData?['category'] ?? 'Unknown',
        'complexityCategory': complexityData?['category'] ?? 'Unknown',
        'overallProfile': _generateOverallProfile(vocabData, formalityData, complexityData),
      };
    }

    return summary;
  }

  String _generateOverallProfile(
    Map<String, dynamic>? vocab,
    Map<String, dynamic>? formality,
    Map<String, dynamic>? complexity,
  ) {
    final vocabScore = vocab?['ttr'] as double? ?? 0.0;
    final formalityScore = formality?['formalityScore'] as int? ?? 50;
    final complexityScore = complexity?['complexityScore'] as int? ?? 0;

    if (formalityScore > 60 && complexityScore > 50) {
      return 'Academic Writer';
    } else if (formalityScore < 40 && vocabScore > 0.4) {
      return 'Creative Casual';
    } else if (formalityScore < 30 && complexityScore < 30) {
      return 'Quick Texter';
    } else if (vocabScore > 0.5 && complexityScore > 40) {
      return 'Expressive Communicator';
    } else if (formalityScore > 50 && complexityScore < 30) {
      return 'Concise Professional';
    } else {
      return 'Balanced Communicator';
    }
  }

  double _calculateConfidence(int messageCount, int userCount) {
    if (messageCount < 50 || userCount < 2) return 0.3;
    if (messageCount < 200) return 0.5;
    if (messageCount < 500) return 0.7;
    if (messageCount < 1000) return 0.85;
    return 0.95;
  }

  AnalysisResult _createEmptyResult() {
    return AnalysisResult(
      type: 'linguistic',
      data: {
        'vocabulary': <String, dynamic>{},
        'formality': <String, dynamic>{},
        'complexity': <String, dynamic>{},
        'writingPatterns': <String, dynamic>{},
        'summary': <String, dynamic>{},
      },
      confidence: 0.0,
      generatedAt: DateTime.now(),
    );
  }

  AnalysisResult _createErrorResult(Object error) {
    return AnalysisResult(
      type: 'linguistic',
      data: {
        'error': error.toString(),
        'vocabulary': <String, dynamic>{},
        'formality': <String, dynamic>{},
        'complexity': <String, dynamic>{},
        'writingPatterns': <String, dynamic>{},
        'summary': <String, dynamic>{},
      },
      confidence: 0.0,
      generatedAt: DateTime.now(),
    );
  }
}
