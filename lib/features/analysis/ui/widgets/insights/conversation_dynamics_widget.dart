import 'package:flutter/material.dart';
import '../chart_constants.dart';
import 'safe_type_converter.dart';

class ConversationDynamicsWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const ConversationDynamicsWidget({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use safe conversion methods
    final totalConversations = SafeTypeConverter.safeInt(data['totalConversations']);
    final healthScore = SafeTypeConverter.safeInt(data['healthScore']);
    final avgConversationLength = SafeTypeConverter.safeInt(data['avgConversationLength']);
    final initiationPatterns = SafeTypeConverter.convertToStringMap(data['initiationPatterns']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Conversation Dynamics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Conversation Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Conversations',
                    totalConversations.toString(),
                    Icons.forum,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Avg Length',
                    '$avgConversationLength messages',
                    Icons.timeline,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Health Score
            _buildHealthScore(context, healthScore),

            const SizedBox(height: 16),

            // Initiation Patterns
            if (initiationPatterns.isNotEmpty)
              _buildInitiationPatterns(context, initiationPatterns),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScore(BuildContext context, int healthScore) {
    Color scoreColor;
    String scoreLabel;

    if (healthScore >= 80) {
      scoreColor = Colors.green;
      scoreLabel = 'Excellent';
    } else if (healthScore >= 60) {
      scoreColor = Colors.orange;
      scoreLabel = 'Good';
    } else if (healthScore >= 40) {
      scoreColor = Colors.amber;
      scoreLabel = 'Fair';
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Needs Improvement';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conversation Health Score',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: healthScore / 100,
                backgroundColor: scoreColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$healthScore/100',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: scoreColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          scoreLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scoreColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInitiationPatterns(BuildContext context, Map<String, dynamic> initiationPatterns) {
    // Use safe conversion for nested maps
    final initiators = SafeTypeConverter.convertToStringMap(initiationPatterns['initiators']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conversation Patterns',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        if (initiators.isNotEmpty) ...[
          Text(
            'Top Initiators:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...initiators.entries.take(ChartConstants.maxInsightItems).map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.play_arrow,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.key}: ${entry.value} conversations',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }),
        ] else ...[
          Text(
            'Conversation pattern analysis provides insights into who typically initiates conversations and how they develop.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}
