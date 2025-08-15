import 'package:flutter/material.dart';

class ContentIntelligenceWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const ContentIntelligenceWidget({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Fix: Safely convert dynamic data to proper types
    final vocabularyComplexity = _convertToStringMap(data['vocabularyComplexity']) ?? {};
    final communicationIntelligence = _convertToStringMap(data['communicationIntelligence']) ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Content Intelligence',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (vocabularyComplexity.isNotEmpty) ...[
              _buildVocabularySection(context, vocabularyComplexity),
              const SizedBox(height: 16),
            ],
            
            if (communicationIntelligence.isNotEmpty) ...[
              _buildCommunicationIntelligenceSection(context, communicationIntelligence),
            ] else ...[
              Text(
                'Content intelligence analysis provides insights into communication patterns, vocabulary usage, and conversation quality.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to safely convert Map<dynamic, dynamic> to Map<String, dynamic>
  Map<String, dynamic>? _convertToStringMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      try {
        return Map<String, dynamic>.from(data);
      } catch (e) {
        debugPrint('Error converting map: $e');
        return {};
      }
    }
    return {};
  }

  // Helper method to safely convert nested maps
  Map<String, dynamic> _convertNestedMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      try {
        final result = <String, dynamic>{};
        data.forEach((key, value) {
          final stringKey = key.toString();
          if (value is Map) {
            result[stringKey] = Map<String, dynamic>.from(value);
          } else {
            result[stringKey] = value;
          }
        });
        return result;
      } catch (e) {
        debugPrint('Error converting nested map: $e');
        return {};
      }
    }
    return {};
  }

  Widget _buildVocabularySection(BuildContext context, Map<String, dynamic> vocabularyComplexity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vocabulary Analysis',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...vocabularyComplexity.entries.map((entry) {
          final userName = entry.key;
          // Fix: Safely convert the value to Map<String, dynamic>
          final vocab = _convertNestedMap(entry.value);
          final complexityScore = vocab['complexityScore'] as int? ?? 0;
          final vocabularyType = vocab['vocabularyType'] as String? ?? 'Average';
          final uniqueWords = vocab['uniqueWords'] as int? ?? 0;
          final totalWords = vocab['totalWords'] as int? ?? 0;

          // Determine color based on complexity score
          Color scoreColor;
          if (complexityScore >= 30) {
            scoreColor = Colors.green;
          } else if (complexityScore >= 20) {
            scoreColor = Colors.orange;
          } else {
            scoreColor = Colors.red;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: scoreColor.withOpacity(0.2),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$vocabularyType • $uniqueWords unique words',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scoreColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$complexityScore',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCommunicationIntelligenceSection(BuildContext context, Map<String, dynamic> communicationIntelligence) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Communication Intelligence',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Advanced communication analysis including question patterns, information sharing, and conversation threading.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}