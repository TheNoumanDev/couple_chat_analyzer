import 'package:flutter/material.dart';
import 'safe_type_converter.dart';

class RelationshipAnalysisWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const RelationshipAnalysisWidget({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use safe conversion methods
    final relationshipHealthScore = SafeTypeConverter.safeInt(data['relationshipHealthScore']);
    final supportPatterns = SafeTypeConverter.convertToStringMap(data['supportPatterns']);
    final relationshipTrend = SafeTypeConverter.safeString(data['relationshipTrend'], defaultValue: 'Stable');
    final engagementScore = SafeTypeConverter.safeInt(data['engagementScore']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Relationship Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Relationship Metrics
            Row(
              children: [
                Expanded(
                  child: _buildRelationshipMetric(
                    context,
                    'Health Score',
                    '$relationshipHealthScore/100',
                    Icons.health_and_safety,
                    _getHealthColor(relationshipHealthScore),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRelationshipMetric(
                    context,
                    'Engagement',
                    '$engagementScore/100',
                    Icons.trending_up,
                    _getEngagementColor(engagementScore),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Relationship Trend
            _buildTrendIndicator(context, relationshipTrend),

            const SizedBox(height: 16),

            // Support Patterns
            if (supportPatterns.isNotEmpty)
              _buildSupportPatterns(context, supportPatterns)
            else
              Text(
                'Relationship analysis shows communication health, engagement levels, and relationship dynamics over time.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationshipMetric(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

  Widget _buildTrendIndicator(BuildContext context, String trend) {
    IconData trendIcon;
    Color trendColor;

    if (trend.contains('Growing') || trend.contains('Improving')) {
      trendIcon = Icons.trending_up;
      trendColor = Colors.green;
    } else if (trend.contains('Declining') || trend.contains('Apart')) {
      trendIcon = Icons.trending_down;
      trendColor = Colors.red;
    } else {
      trendIcon = Icons.trending_flat;
      trendColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(trendIcon, color: trendColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relationship Trend',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  trend,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: trendColor,
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

  Widget _buildSupportPatterns(BuildContext context, Map<String, dynamic> supportPatterns) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support Patterns',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Analysis shows how participants support each other through questions, help, and emotional support.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Color _getHealthColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.amber;
    return Colors.red;
  }

  Color _getEngagementColor(int score) {
    if (score >= 80) return Colors.blue;
    if (score >= 60) return Colors.indigo;
    if (score >= 40) return Colors.purple;
    return Colors.grey;
  }
}
