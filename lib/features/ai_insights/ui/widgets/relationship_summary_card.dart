// ============================================================================
// FILE: features/ai_insights/ui/widgets/relationship_summary_card.dart
// Relationship summary display widget
// ============================================================================
import 'package:flutter/material.dart';
import '../../models/llm_models.dart';

class RelationshipSummaryCard extends StatelessWidget {
  final RelationshipSummary summary;

  const RelationshipSummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Relationship Dynamics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Health and trend indicators
            Row(
              children: [
                Expanded(
                  child: _buildIndicator(
                    context,
                    'Health',
                    summary.overallHealth,
                    _getHealthColor(summary.overallHealth),
                    Icons.health_and_safety,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildIndicator(
                    context,
                    'Trend',
                    summary.trend,
                    _getTrendColor(summary.trend),
                    _getTrendIcon(summary.trend),
                  ),
                ),
              ],
            ),

            // Health score bar
            if (summary.healthScore > 0) ...[
              const SizedBox(height: 16),
              _buildHealthScoreBar(context),
            ],

            // Description
            if (summary.dynamicDescription.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                summary.dynamicDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],

            // Positive patterns
            if (summary.positivePatterns.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildPatternsList(
                context,
                'Positive Patterns',
                summary.positivePatterns,
                Colors.green,
                Icons.check_circle_outline,
              ),
            ],

            // Concern patterns
            if (summary.concernPatterns.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildPatternsList(
                context,
                'Areas to Watch',
                summary.concernPatterns,
                Colors.orange,
                Icons.info_outline,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Health Score',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            Text(
              '${(summary.healthScore * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(summary.healthScore),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: summary.healthScore,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getScoreColor(summary.healthScore),
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildPatternsList(
    BuildContext context,
    String title,
    List<String> patterns,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
        const SizedBox(height: 8),
        ...patterns.map((pattern) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pattern,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Color _getHealthColor(String health) {
    switch (health.toLowerCase()) {
      case 'thriving':
        return Colors.green;
      case 'healthy':
        return Colors.lightGreen;
      case 'stable':
        return Colors.blue;
      case 'needs attention':
        return Colors.orange;
      case 'concerning':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend.toLowerCase()) {
      case 'improving':
        return Colors.green;
      case 'stable':
        return Colors.blue;
      case 'declining':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend.toLowerCase()) {
      case 'improving':
        return Icons.trending_up;
      case 'stable':
        return Icons.trending_flat;
      case 'declining':
        return Icons.trending_down;
      default:
        return Icons.help_outline;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.lightGreen;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
