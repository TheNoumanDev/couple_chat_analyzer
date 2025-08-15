import 'package:flutter/material.dart';

/// Helper class for safe type conversions
class SafeTypeConverter {
  /// Safely convert Map<dynamic, dynamic> to Map<String, dynamic>
  static Map<String, dynamic> convertToStringMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      try {
        final result = <String, dynamic>{};
        data.forEach((key, value) {
          final stringKey = key.toString();
          // Recursively convert nested maps
          if (value is Map && value is! Map<String, dynamic>) {
            result[stringKey] = convertToStringMap(value);
          } else if (value is List) {
            result[stringKey] = convertList(value);
          } else {
            result[stringKey] = value;
          }
        });
        return result;
      } catch (e) {
        debugPrint('SafeTypeConverter: Error converting map: $e');
        return {};
      }
    }
    debugPrint('SafeTypeConverter: Data is not a map, type: ${data.runtimeType}');
    return {};
  }

  /// Safely convert List with nested maps
  static List<dynamic> convertList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map && item is! Map<String, dynamic>) {
        return convertToStringMap(item);
      }
      return item;
    }).toList();
  }

  /// Safe integer extraction
  static int safeInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Safe string extraction
  static String safeString(dynamic value, {String defaultValue = ''}) {
    if (value is String) return value;
    if (value != null) return value.toString();
    return defaultValue;
  }

  /// Safe list extraction
  static List<dynamic> safeList(dynamic value) {
    if (value is List) return value;
    if (value == null) return [];
    return [value]; // Wrap single item in list
  }
}

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
        color: color.withOpacity(0.1),
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
                backgroundColor: scoreColor.withOpacity(0.2),
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
    final enders = SafeTypeConverter.convertToStringMap(initiationPatterns['enders']);
    
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
          ...initiators.entries.take(3).map((entry) {
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
          }).toList(),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
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
        color: trendColor.withOpacity(0.1),
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
                        backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
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
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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
        color: scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
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
        ...timeline.take(3).map((milestone) {
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
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
        }).toList(),
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
        ...milestones.take(3).map((milestone) {
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
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}