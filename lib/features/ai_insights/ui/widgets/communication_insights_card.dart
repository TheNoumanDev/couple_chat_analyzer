// ============================================================================
// FILE: features/ai_insights/ui/widgets/communication_insights_card.dart
// Communication insights display widget
// ============================================================================
import 'package:flutter/material.dart';
import '../../models/llm_models.dart';

class CommunicationInsightsCard extends StatelessWidget {
  final List<CommunicationInsight> insights;

  const CommunicationInsightsCard({
    super.key,
    required this.insights,
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
                const Icon(Icons.insights, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Communication Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => _buildInsightItem(context, insight)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(BuildContext context, CommunicationInsight insight) {
    final color = _getCategoryColor(insight.category);
    final icon = _getCategoryIcon(insight.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'improvement':
        return Colors.orange;
      case 'neutral':
      default:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'positive':
        return Icons.thumb_up_outlined;
      case 'improvement':
        return Icons.tips_and_updates_outlined;
      case 'neutral':
      default:
        return Icons.lightbulb_outline;
    }
  }
}
