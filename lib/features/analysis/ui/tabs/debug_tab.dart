import 'package:flutter/material.dart';
import '../widgets/analysis_cards.dart';
import '../widgets/analysis_charts.dart';
import '../widgets/content_overview_widget.dart';
import '../widgets/insights_widget.dart';

class DebugTab extends StatelessWidget {
  final Map<String, dynamic> results;

  const DebugTab({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Debug Header
          _buildDebugHeader(context),
          
          const SizedBox(height: 24),
          
          // Data Structure Overview
          _buildDataStructureCard(context),
          
          const SizedBox(height: 24),
          
          // Summary Statistics (reuse existing widget)
          SummaryCards(summary: _convertToStringMap(results['summary']) ?? {}),
          
          const SizedBox(height: 24),
          
          // Quick Stats (reuse existing widget)
          QuickStatsCard(
            title: 'Key Metrics Debug',
            stats: _buildDebugQuickStats(),
          ),
          
          const SizedBox(height: 24),
          
          // User Statistics (reuse existing widgets)
          if (results['messagesByUser'] != null)
            TopUsersChart(data: results['messagesByUser'] as List<dynamic>),
          
          const SizedBox(height: 24),
          
          // Time Analysis (reuse existing widget)
          if (_extractTimeAnalysis(results).isNotEmpty)
            TimeActivityOverview(timeData: _extractTimeAnalysis(results)),
          
          const SizedBox(height: 24),
          
          // Content Analysis (reuse existing widget)
          ContentOverviewCards(contentAnalysis: _extractContentAnalysis(results)),
          
          const SizedBox(height: 24),
          
          // Conversation Dynamics (reuse existing widget)
          if (results.containsKey('conversationDynamics'))
            ConversationDynamicsWidget(
              data: _adaptConversationDynamicsData(results['conversationDynamics']),
            ),
          
          const SizedBox(height: 24),
          
          // Relationship Analysis (reuse existing widget)
          if (results.containsKey('relationshipDynamics'))
            RelationshipAnalysisWidget(
              data: _adaptRelationshipData(results['relationshipDynamics']),
            ),
          
          const SizedBox(height: 24),
          
          // Behavior Patterns (reuse existing widget)
          if (results.containsKey('behaviorPatterns'))
            BehaviorPatternsWidget(
              data: _adaptBehaviorData(results['behaviorPatterns']),
            ),
          
          const SizedBox(height: 24),
          
          // Content Intelligence (reuse existing widget)
          if (results.containsKey('contentIntelligence'))
            ContentIntelligenceWidget(
              data: _adaptContentIntelligenceData(results['contentIntelligence']),
            ),
          
          const SizedBox(height: 24),
          
          // Temporal Insights (reuse existing widget)
          if (results.containsKey('temporalInsights'))
            TemporalInsightsWidget(
              data: _adaptTemporalInsightsData(results['temporalInsights']),
            ),
          
          const SizedBox(height: 24),
          
          // Debug Footer
          _buildDebugFooter(context),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDebugHeader(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Debug Analysis View',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Complete view of all analyzers and their output using the same widgets as other tabs.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataStructureCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.data_object, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Data Structure Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: results.keys.map((key) {
                final dataType = results[key].runtimeType.toString();
                final color = _getDataTypeColor(dataType);
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getDataTypeIcon(dataType),
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        key,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugFooter(BuildContext context) {
    final totalKeys = results.keys.length;
    final mapKeys = results.keys.where((k) => results[k] is Map).length;
    final listKeys = results.keys.where((k) => results[k] is List).length;
    
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Debug Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDebugMetric(context, 'Total Data Keys', totalKeys.toString()),
                ),
                Expanded(
                  child: _buildDebugMetric(context, 'Map Objects', mapKeys.toString()),
                ),
                Expanded(
                  child: _buildDebugMetric(context, 'List Objects', listKeys.toString()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugMetric(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _buildDebugQuickStats() {
    final stats = <Map<String, dynamic>>[];
    
    // Total analyzers
    stats.add({
      'icon': Icons.analytics,
      'label': 'Analyzers',
      'value': results.keys.length.toString(),
    });
    
    // Content analysis words
    final contentAnalysis = _extractContentAnalysis(results);
    stats.add({
      'icon': Icons.text_fields,
      'label': 'Total Words',
      'value': contentAnalysis['totalWords']?.toString() ?? '0',
    });
    
    // Time analysis peak hour
    final timeAnalysis = _extractTimeAnalysis(results);
    if (timeAnalysis.containsKey('peakHour')) {
      final peakHour = timeAnalysis['peakHour'] as Map<String, dynamic>? ?? {};
      stats.add({
        'icon': Icons.access_time,
        'label': 'Peak Hour',
        'value': peakHour['timeRange']?.toString() ?? 'N/A',
      });
    }
    
    // Relationship health
    final relationshipData = results['relationshipDynamics'] as Map<String, dynamic>?;
    if (relationshipData != null) {
      stats.add({
        'icon': Icons.favorite,
        'label': 'Relationship Health',
        'value': relationshipData['relationshipHealthScore']?.toString() ?? '0',
      });
    }
    
    return stats;
  }

  Color _getDataTypeColor(String dataType) {
    if (dataType.contains('Map')) return Colors.blue;
    if (dataType.contains('List')) return Colors.green;
    if (dataType.contains('String')) return Colors.orange;
    if (dataType.contains('int') || dataType.contains('double')) return Colors.purple;
    return Colors.grey;
  }

  IconData _getDataTypeIcon(String dataType) {
    if (dataType.contains('Map')) return Icons.account_tree;
    if (dataType.contains('List')) return Icons.list;
    if (dataType.contains('String')) return Icons.text_fields;
    if (dataType.contains('int') || dataType.contains('double')) return Icons.numbers;
    return Icons.data_object;
  }

  // Data adapter methods (same as in insights_tab.dart)
  Map<String, dynamic> _adaptConversationDynamicsData(dynamic rawData) {
    final data = _convertToStringMap(rawData) ?? {};
    return {
      'totalConversations': data['totalConversations'] ?? 0,
      'healthScore': data['conversationHealthScore'] ?? 0,
      'avgConversationLength': data['averageConversationLength'] ?? 0,
      'initiationPatterns': data['initiationPatterns'] ?? {},
      'flowPatterns': data['flowPatterns'] ?? {},
      'responsePatterns': data['responsePatterns'] ?? {},
    };
  }

  Map<String, dynamic> _adaptRelationshipData(dynamic rawData) {
    final data = _convertToStringMap(rawData) ?? {};
    return {
      'relationshipHealthScore': data['relationshipHealthScore'] ?? 0,
      'supportPatterns': data['supportPatterns'] ?? {},
      'relationshipTrend': data['relationshipTrend'] ?? 'Stable',
      'engagementScore': 75, // Default value
      'reciprocityPatterns': data['reciprocityPatterns'] ?? {},
    };
  }

  Map<String, dynamic> _adaptBehaviorData(dynamic rawData) {
    Map<String, dynamic> data = {};
    if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
      data = _convertToStringMap(rawData['data']) ?? {};
    } else {
      data = _convertToStringMap(rawData) ?? {};
    }
    return data;
  }

  Map<String, dynamic> _adaptContentIntelligenceData(dynamic rawData) {
    Map<String, dynamic> data = {};
    if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
      data = _convertToStringMap(rawData['data']) ?? {};
    } else {
      data = _convertToStringMap(rawData) ?? {};
    }
    return data;
  }

  Map<String, dynamic> _adaptTemporalInsightsData(dynamic rawData) {
    Map<String, dynamic> data = {};
    if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
      data = _convertToStringMap(rawData['data']) ?? {};
    } else {
      data = _convertToStringMap(rawData) ?? {};
    }
    return data;
  }

  // Helper methods (same as other tabs)
  Map<String, dynamic>? _convertToStringMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Map<String, dynamic> _extractTimeAnalysis(Map<String, dynamic> results) {
    if (results.containsKey('timeAnalysis')) {
      final timeData = _convertToStringMap(results['timeAnalysis']);
      if (timeData != null && timeData.isNotEmpty) {
        return timeData;
      }
    }
    
    if (results.containsKey('time')) {
      final timeContainer = _convertToStringMap(results['time']);
      if (timeContainer != null && timeContainer.containsKey('timeAnalysis')) {
        final timeData = _convertToStringMap(timeContainer['timeAnalysis']);
        if (timeData != null && timeData.isNotEmpty) {
          return timeData;
        }
      }
    }
    
    return {};
  }

  Map<String, dynamic> _extractContentAnalysis(Map<String, dynamic> results) {
    if (results.containsKey('contentAnalysis')) {
      final contentData = _convertToStringMap(results['contentAnalysis']);
      if (contentData != null && contentData.isNotEmpty) {
        return contentData;
      }
    }
    
    if (results.containsKey('content')) {
      final contentContainer = _convertToStringMap(results['content']);
      if (contentContainer != null) {
        if (contentContainer.containsKey('data')) {
          final dataContainer = _convertToStringMap(contentContainer['data']);
          if (dataContainer != null && dataContainer.isNotEmpty) {
            return dataContainer;
          }
        }
        if (contentContainer.containsKey('contentAnalysis')) {
          final contentData = _convertToStringMap(contentContainer['contentAnalysis']);
          if (contentData != null && contentData.isNotEmpty) {
            return contentData;
          }
        }
        if (contentContainer.isNotEmpty) {
          return contentContainer;
        }
      }
    }
    
    return {};
  }
}