import 'package:flutter/material.dart';

/// Communication insights section widget.
class CommunicationInsightsSection extends StatelessWidget {
  final Map<String, dynamic> contentAnalysis;
  final Map<String, dynamic> timeAnalysis;

  const CommunicationInsightsSection({
    Key? key,
    required this.contentAnalysis,
    required this.timeAnalysis,
  }) : super(key: key);

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
                const Icon(Icons.forum, color: Colors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Communication Insights',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightItem(
              context,
              'Message Frequency',
              _getMessageFrequencyInsight(),
              Icons.speed,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              context,
              'Communication Style',
              _getCommunicationStyleInsight(),
              Icons.chat_bubble_outline,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              context,
              'Activity Pattern',
              _getActivityPatternInsight(),
              Icons.timeline,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMessageFrequencyInsight() {
    final avgWords = double.tryParse(
            contentAnalysis['avgWordsPerMessage']?.toString() ?? '0') ?? 0;

    if (avgWords > 10) {
      return 'Detailed communicators - messages tend to be longer and more descriptive.';
    } else if (avgWords > 5) {
      return 'Balanced communication style with moderate message lengths.';
    } else {
      return 'Concise communicators - prefer short, quick messages.';
    }
  }

  String _getCommunicationStyleInsight() {
    final totalEmojis = contentAnalysis['totalEmojis'] as int? ?? 0;
    final totalWords = contentAnalysis['totalWords'] as int? ?? 0;

    if (totalWords == 0) return 'Limited conversation data available.';

    final emojiRatio = totalEmojis / totalWords;

    if (emojiRatio > 0.1) {
      return 'Highly expressive communication with frequent emoji usage.';
    } else if (emojiRatio > 0.05) {
      return 'Moderately expressive with balanced emoji usage.';
    } else {
      return 'Text-focused communication with minimal emoji usage.';
    }
  }

  String _getActivityPatternInsight() {
    final peakHour = _extractPeakHour();

    if (peakHour.contains('morning') || peakHour.contains('AM')) {
      return 'Early birds - most active during morning hours.';
    } else if (peakHour.contains('evening') || peakHour.contains('PM')) {
      return 'Night owls - peak activity in evening hours.';
    } else {
      return 'Distributed activity throughout the day.';
    }
  }

  String _extractPeakHour() {
    if (timeAnalysis.containsKey('peakHour')) {
      final peakHour = timeAnalysis['peakHour'];
      if (peakHour is Map) {
        return peakHour['timeRange']?.toString() ?? 'Not Available';
      }
      return peakHour.toString();
    }
    return 'Not Available';
  }
}
