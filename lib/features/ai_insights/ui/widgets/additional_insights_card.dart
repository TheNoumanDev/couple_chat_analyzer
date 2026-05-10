// ============================================================================
// FILE: features/ai_insights/ui/widgets/additional_insights_card.dart
// Additional insights card showing all new narrative insights
// ============================================================================
import 'package:flutter/material.dart';
import '../../models/llm_models.dart';

class AdditionalInsightsCard extends StatelessWidget {
  final AIInsights insights;

  const AdditionalInsightsCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final sections = <_InsightSection>[];

    // Add love languages section
    if (insights.loveLanguages.isNotEmpty) {
      sections.add(_InsightSection(
        icon: Icons.favorite,
        iconColor: Colors.pink,
        title: 'Love Languages',
        content: _buildLoveLanguagesContent(),
      ));
    }

    // Add other insights
    if (insights.compatibilityNarrative.isNotEmpty) {
      sections.add(_InsightSection(
        icon: Icons.sync_alt,
        iconColor: Colors.purple,
        title: 'Compatibility',
        content: insights.compatibilityNarrative,
      ));
    }

    if (insights.humorPlayfulness.isNotEmpty) {
      sections.add(_InsightSection(
        icon: Icons.emoji_emotions,
        iconColor: Colors.amber,
        title: 'Humor & Playfulness',
        content: insights.humorPlayfulness,
      ));
    }

    if (insights.energyMatching.isNotEmpty) {
      sections.add(_InsightSection(
        icon: Icons.bolt,
        iconColor: Colors.orange,
        title: 'Energy Matching',
        content: insights.energyMatching,
      ));
    }

    if (insights.vulnerabilityLevel.isNotEmpty) {
      sections.add(_InsightSection(
        icon: Icons.shield_outlined,
        iconColor: Colors.teal,
        title: 'Emotional Openness',
        content: insights.vulnerabilityLevel,
      ));
    }

    if (insights.supportPatterns.isNotEmpty) {
      sections.add(_InsightSection(
        icon: Icons.handshake,
        iconColor: Colors.green,
        title: 'Support Patterns',
        content: insights.supportPatterns,
      ));
    }

    if (insights.conflictStyle.isNotEmpty) {
      sections.add(_InsightSection(
        icon: Icons.forum,
        iconColor: Colors.blueGrey,
        title: 'Conflict Style',
        content: insights.conflictStyle,
      ));
    }

    if (insights.peakConnectionTimes.isNotEmpty) {
      sections.add(_InsightSection(
        icon: Icons.schedule,
        iconColor: Colors.indigo,
        title: 'Peak Connection Times',
        content: insights.peakConnectionTimes,
      ));
    }

    if (insights.conversationInitiators.isNotEmpty) {
      sections.add(_InsightSection(
        icon: Icons.play_circle_outline,
        iconColor: Colors.blue,
        title: 'Who Starts Conversations',
        content: insights.conversationInitiators,
      ));
    }

    if (insights.appreciationFrequency.isNotEmpty) {
      sections.add(_InsightSection(
        icon: Icons.thumb_up_outlined,
        iconColor: Colors.deepPurple,
        title: 'Appreciation',
        content: insights.appreciationFrequency,
      ));
    }

    if (insights.growthTimeline.isNotEmpty) {
      sections.add(_InsightSection(
        icon: Icons.timeline,
        iconColor: Colors.cyan,
        title: 'Growth Over Time',
        content: insights.growthTimeline,
      ));
    }

    // Add unique quirks section
    if (insights.uniqueQuirks.isNotEmpty) {
      sections.add(_InsightSection(
        icon: Icons.star,
        iconColor: Colors.amber,
        title: 'Unique Quirks',
        content: insights.uniqueQuirks.join('\n• '),
        isListFormat: true,
      ));
    }

    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Colors.purple[600]),
                const SizedBox(width: 8),
                Text(
                  'Deep Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sections.map((section) => _buildSection(context, section)),
          ],
        ),
      ),
    );
  }

  String _buildLoveLanguagesContent() {
    return insights.loveLanguages.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
  }

  Widget _buildSection(BuildContext context, _InsightSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: section.iconColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: section.iconColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(section.icon, color: section.iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: section.iconColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (section.isListFormat)
              Text(
                '• ${section.content}',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Text(
                section.content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}

class _InsightSection {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;
  final bool isListFormat;

  const _InsightSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
    this.isListFormat = false,
  });
}
