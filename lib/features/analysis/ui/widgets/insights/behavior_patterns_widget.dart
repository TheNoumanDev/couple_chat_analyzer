import 'package:flutter/material.dart';
import 'safe_type_converter.dart';

class BehaviorPatternsWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const BehaviorPatternsWidget({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use safe conversion methods
    final compatibilityScore = SafeTypeConverter.safeInt(data['compatibilityScore']);
    final communicationStyles = SafeTypeConverter.convertToStringMap(data['communicationStyles']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Behavior Patterns',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Compatibility Score
            if (compatibilityScore > 0) ...[
              _buildCompatibilityCard(context, compatibilityScore),
              const SizedBox(height: 16),
            ],

            // Communication Styles
            if (communicationStyles.isNotEmpty) ...[
              Text(
                'Communication Styles',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...communicationStyles.entries.map((entry) {
                final userName = entry.key;
                // Use safe conversion for nested style data
                final style = SafeTypeConverter.convertToStringMap(entry.value);
                final styleType = SafeTypeConverter.safeString(style['styleType'], defaultValue: 'Unknown');

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
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
                              styleType,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              Text(
                'Behavior pattern analysis reveals communication styles, response patterns, and compatibility between conversation participants.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilityCard(BuildContext context, int compatibilityScore) {
    Color scoreColor;
    String scoreLabel;
    IconData scoreIcon;

    if (compatibilityScore >= 80) {
      scoreColor = Colors.green;
      scoreLabel = 'Highly Compatible';
      scoreIcon = Icons.favorite;
    } else if (compatibilityScore >= 60) {
      scoreColor = Colors.orange;
      scoreLabel = 'Well Matched';
      scoreIcon = Icons.thumb_up;
    } else if (compatibilityScore >= 40) {
      scoreColor = Colors.amber;
      scoreLabel = 'Moderately Compatible';
      scoreIcon = Icons.sentiment_neutral;
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Different Styles';
      scoreIcon = Icons.psychology;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(scoreIcon, color: scoreColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compatibility Score',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '$compatibilityScore% - $scoreLabel',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
