// ============================================================================
// FILE: features/analysis/ui/widgets/timeline_widget.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimelineWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const TimelineWidget({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Timeline Summary
        _buildTimelineSummary(context),
        
        const SizedBox(height: 24),
        
        // Milestones
        if (data.containsKey('milestones'))
          _buildMilestonesSection(context),
        
        const SizedBox(height: 24),
        
        // Evolution Phases
        if (data.containsKey('evolutionPhases'))
          _buildEvolutionPhasesSection(context),
        
        const SizedBox(height: 24),
        
        // Key Metrics Over Time
        if (data.containsKey('keyMetrics'))
          _buildKeyMetricsSection(context),
      ],
    );
  }

  Widget _buildTimelineSummary(BuildContext context) {
    final startDate = data['startDate'] as String?;
    final endDate = data['endDate'] as String?;
    final totalDays = data['totalTimeSpanDays'] as int? ?? 0;
    final relationshipTrend = data['relationshipTrend'] as String? ?? 'Unknown';

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
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Timeline Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Date Range
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    context,
                    'Start Date',
                    startDate ?? 'Unknown',
                    Icons.play_arrow,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoTile(
                    context,
                    'End Date',
                    endDate ?? 'Unknown',
                    Icons.stop,
                    Colors.red,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    context,
                    'Duration',
                    '$totalDays days',
                    Icons.access_time,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoTile(
                    context,
                    'Trend',
                    relationshipTrend,
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesSection(BuildContext context) {
    final milestones = data['milestones'] as List<dynamic>? ?? [];
    
    if (milestones.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Key Milestones',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text('No milestones detected'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Milestones',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Timeline with milestones
            ...milestones.asMap().entries.map((entry) {
              final index = entry.key;
              final milestone = entry.value as Map<String, dynamic>;
              final isLast = index == milestones.length - 1;
              
              return _buildMilestoneItem(
                context,
                milestone,
                isLast,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneItem(
    BuildContext context,
    Map<String, dynamic> milestone,
    bool isLast,
  ) {
    final date = milestone['date'] as String? ?? 'Unknown';
    final title = milestone['title'] as String? ?? 'Milestone';
    final description = milestone['description'] as String? ?? '';
    final type = milestone['type'] as String? ?? 'general';
    final impact = milestone['impact'] as String? ?? 'medium';

    final milestoneColor = _getMilestoneColor(type);
    final impactIcon = _getImpactIcon(impact);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and dot
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: milestoneColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    impactIcon,
                    size: 8,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: milestoneColor.withOpacity(0.3),
                ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Milestone content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: milestoneColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: milestoneColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          type.toUpperCase(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: milestoneColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    _formatDate(date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionPhasesSection(BuildContext context) {
    final phases = data['evolutionPhases'] as List<dynamic>? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolution Phases',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (phases.isEmpty)
              const Text('No evolution phases detected')
            else
              ...phases.map((phase) {
                final phaseData = phase as Map<String, dynamic>;
                return _buildPhaseCard(context, phaseData);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseCard(BuildContext context, Map<String, dynamic> phase) {
    final name = phase['name'] as String? ?? 'Unknown Phase';
    final startDate = phase['startDate'] as String? ?? '';
    final endDate = phase['endDate'] as String? ?? '';
    final characteristics = phase['characteristics'] as List<dynamic>? ?? [];
    final messageCount = phase['messageCount'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$messageCount messages',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          if (startDate.isNotEmpty && endDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${_formatDate(startDate)} - ${_formatDate(endDate)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
          
          if (characteristics.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: characteristics.map((char) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    char.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKeyMetricsSection(BuildContext context) {
    final metrics = data['keyMetrics'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Metrics Over Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (metrics.isEmpty)
              const Text('No key metrics available')
            else
              _buildMetricsGrid(context, metrics),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, Map<String, dynamic> metrics) {
    final List<Widget> metricCards = [];
    
    metrics.forEach((key, value) {
      metricCards.add(
        _buildMetricCard(
          context,
          _formatMetricName(key),
          value.toString(),
          _getMetricIcon(key),
          _getMetricColor(key),
        ),
      );
    });

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: metricCards,
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  // Helper methods
  Color _getMilestoneColor(String type) {
    switch (type.toLowerCase()) {
      case 'relationship':
        return Colors.pink;
      case 'communication':
        return Colors.blue;
      case 'milestone':
        return Colors.amber;
      case 'achievement':
        return Colors.green;
      case 'challenge':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getImpactIcon(String impact) {
    switch (impact.toLowerCase()) {
      case 'high':
        return Icons.star;
      case 'medium':
        return Icons.circle;
      case 'low':
        return Icons.radio_button_unchecked;
      default:
        return Icons.circle;
    }
  }

  IconData _getMetricIcon(String metricKey) {
    switch (metricKey.toLowerCase()) {
      case 'messages':
      case 'messagecount':
        return Icons.message;
      case 'engagement':
      case 'engagementlevel':
        return Icons.favorite;
      case 'frequency':
        return Icons.access_time;
      case 'responsetime':
        return Icons.reply;
      case 'words':
      case 'wordcount':
        return Icons.text_fields;
      default:
        return Icons.analytics;
    }
  }

  Color _getMetricColor(String metricKey) {
    switch (metricKey.toLowerCase()) {
      case 'messages':
      case 'messagecount':
        return Colors.blue;
      case 'engagement':
      case 'engagementlevel':
        return Colors.pink;
      case 'frequency':
        return Colors.green;
      case 'responsetime':
        return Colors.orange;
      case 'words':
      case 'wordcount':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatMetricName(String key) {
    // Convert camelCase to readable format
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .toLowerCase()
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ')
        .trim();
  }

  String _formatDate(String dateStr) {
    try {
      // Try to parse different date formats
      DateTime? date;
      
      // Try ISO format first
      try {
        date = DateTime.parse(dateStr);
      } catch (e) {
        // Try other common formats
        try {
          date = DateFormat('yyyy-MM-dd').parse(dateStr);
        } catch (e) {
          try {
            date = DateFormat('dd/MM/yyyy').parse(dateStr);
          } catch (e) {
            try {
              date = DateFormat('MM/dd/yyyy').parse(dateStr);
            } catch (e) {
              return dateStr; // Return original if can't parse
            }
          }
        }
      }
      
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr; // Return original string if parsing fails
    }
  }
}