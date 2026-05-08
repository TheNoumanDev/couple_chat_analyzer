import 'package:flutter/material.dart';

/// Communication health card section for overview tab.
class HealthCardSection extends StatelessWidget {
  final Map<String, dynamic> conversationDynamics;

  const HealthCardSection({
    Key? key,
    required this.conversationDynamics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check for both possible field names
    int healthScore = 0;
    if (conversationDynamics.containsKey('healthScore')) {
      healthScore = _safeInt(conversationDynamics['healthScore']) ?? 0;
    } else if (conversationDynamics.containsKey('conversationHealthScore')) {
      healthScore = _safeInt(conversationDynamics['conversationHealthScore']) ?? 0;
    }

    if (healthScore == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Communication Health',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.health_and_safety,
                      color: _getHealthColor(healthScore),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Overall Health Score',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getHealthColor(healthScore).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getHealthColor(healthScore).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '$healthScore/100',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getHealthColor(healthScore),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: healthScore / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getHealthColor(healthScore),
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                Text(
                  _getHealthDescription(healthScore),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _buildHealthDetailsRow(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthDetailsRow(BuildContext context) {
    final totalConversations = _safeInt(conversationDynamics['totalConversations']) ?? 0;
    final avgLength = _safeInt(conversationDynamics['averageConversationLength']) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildHealthDetail(
                context,
                'Conversations',
                totalConversations.toString(),
                Icons.chat_bubble_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHealthDetail(
                context,
                'Quality',
                _getQualityLabel(),
                Icons.verified,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildHealthDetail(
                context,
                'Avg Length',
                '${avgLength.toString()} msgs',
                Icons.straighten,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthDetail(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
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

  String _getQualityLabel() {
    final healthScore = _safeInt(conversationDynamics['conversationHealthScore']) ?? 0;
    if (healthScore >= 80) return 'Excellent';
    if (healthScore >= 60) return 'Good';
    if (healthScore >= 40) return 'Fair';
    return 'Needs Work';
  }

  Color _getHealthColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getHealthDescription(int score) {
    if (score >= 80) return 'Excellent communication flow with strong engagement patterns and balanced participation.';
    if (score >= 60) return 'Good conversation patterns with healthy interaction dynamics and room for growth.';
    if (score >= 40) return 'Moderate conversation health showing mixed patterns that could benefit from attention.';
    return 'Communication patterns suggest areas for improvement in engagement and interaction quality.';
  }

  int? _safeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
