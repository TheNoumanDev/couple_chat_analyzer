import 'package:flutter/material.dart';
import '../chart_constants.dart';
import 'safe_type_converter.dart';

class TemporalInsightsWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const TemporalInsightsWidget({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use safe conversion methods
    final evolutionTimeline = SafeTypeConverter.safeList(data['evolutionTimeline']);
    final communicationEvolution = SafeTypeConverter.convertToStringMap(data['communicationEvolution']);
    final relationshipMilestones = SafeTypeConverter.safeList(data['relationshipMilestones']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Temporal Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Evolution Timeline
            if (evolutionTimeline.isNotEmpty) ...[
              _buildTimelineSection(context, evolutionTimeline),
              const SizedBox(height: 16),
            ],

            // Communication Evolution
            if (communicationEvolution.isNotEmpty) ...[
              _buildEvolutionSection(context, communicationEvolution),
              const SizedBox(height: 16),
            ],

            // Relationship Milestones
            if (relationshipMilestones.isNotEmpty) ...[
              _buildMilestonesSection(context, relationshipMilestones),
            ] else ...[
              Text(
                'Temporal insights reveal how your conversation patterns and relationship dynamics have evolved over time.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection(BuildContext context, List<dynamic> timeline) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evolution Timeline',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...timeline.take(ChartConstants.maxInsightItems).map((milestone) {
          // Use safe conversion for milestone data
          final milestoneData = SafeTypeConverter.convertToStringMap(milestone);
          final milestoneText = SafeTypeConverter.safeString(milestoneData['milestone'], defaultValue: 'Milestone');
          final description = SafeTypeConverter.safeString(milestoneData['description']);
          final date = SafeTypeConverter.safeString(milestoneData['date']);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestoneText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (description.isNotEmpty)
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      if (date.isNotEmpty)
                        Text(
                          date,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEvolutionSection(BuildContext context, Map<String, dynamic> evolution) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Communication Evolution',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Shows how communication patterns have changed over time.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildMilestonesSection(BuildContext context, List<dynamic> milestones) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Milestones',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...milestones.take(ChartConstants.maxInsightItems).map((milestone) {
          // Use safe conversion for milestone data
          final milestoneData = SafeTypeConverter.convertToStringMap(milestone);
          final title = SafeTypeConverter.safeString(milestoneData['title'], defaultValue: 'Milestone');
          final date = SafeTypeConverter.safeString(milestoneData['date']);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.star,
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (date.isNotEmpty)
                  Text(
                    date,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
