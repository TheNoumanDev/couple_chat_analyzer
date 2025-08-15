import 'package:flutter/material.dart';
import '../widgets/analysis_cards.dart';
import '../widgets/analysis_charts.dart';

class OverviewTab extends StatelessWidget {
  final Map<String, dynamic> results;

  const OverviewTab({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use safe conversion methods instead of direct casting
    final summary = _convertToStringMap(results['summary']) ?? {};
    final timeAnalysis = _extractTimeAnalysis(results);
    final messagesByUser = results['messagesByUser'] as List<dynamic>? ?? [];
    
    debugPrint("📊 OverviewTab: summary keys: ${summary.keys.join(', ')}");
    debugPrint("📊 OverviewTab: timeAnalysis keys: ${timeAnalysis.keys.join(', ')}");
    debugPrint("📊 OverviewTab: messagesByUser count: ${messagesByUser.length}");
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          SummaryCards(summary: summary),
          
          const SizedBox(height: 24),
          
          // Quick Stats
          if (messagesByUser.isNotEmpty)
            QuickStatsCard(
              title: 'Quick Overview',
              stats: _buildQuickStats(results),
            ),
          
          const SizedBox(height: 24),
          
          // Top Users Chart
          if (messagesByUser.isNotEmpty)
            TopUsersChart(
              data: messagesByUser,
            ),
          
          const SizedBox(height: 24),
          
          // Time Activity Overview
          if (timeAnalysis.isNotEmpty)
            TimeActivityOverview(
              timeData: timeAnalysis,
            ),
          
          const SizedBox(height: 24),
          
          // Chat Health Score (if available) - Fixed with safe conversion
          if (results.containsKey('conversationDynamics'))
            _buildHealthScoreCard(context, _convertToStringMap(results['conversationDynamics']) ?? {}),
          
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  /// Extract timeAnalysis data - it might be nested
  Map<String, dynamic> _extractTimeAnalysis(Map<String, dynamic> results) {
    // Check multiple possible locations for time analysis data
    if (results.containsKey('timeAnalysis')) {
      final timeData = _convertToStringMap(results['timeAnalysis']);
      if (timeData != null && timeData.isNotEmpty) {
        debugPrint("📊 Found timeAnalysis directly");
        return timeData;
      }
    }
    
    if (results.containsKey('time')) {
      final timeContainer = _convertToStringMap(results['time']);
      if (timeContainer != null && timeContainer.containsKey('timeAnalysis')) {
        final timeData = _convertToStringMap(timeContainer['timeAnalysis']);
        if (timeData != null && timeData.isNotEmpty) {
          debugPrint("📊 Found timeAnalysis nested in time");
          return timeData;
        }
      }
    }
    
    // If no nested structure, check for direct time fields at root level
    final directTimeFields = <String, dynamic>{};
    for (final key in results.keys) {
      if (key.contains('hourly') || key.contains('weekly') || key.contains('monthly') || key.contains('peak')) {
        directTimeFields[key] = results[key];
      }
    }
    
    if (directTimeFields.isNotEmpty) {
      debugPrint("📊 Found time fields at root level: ${directTimeFields.keys.join(', ')}");
      return directTimeFields;
    }
    
    debugPrint("📊 No timeAnalysis data found");
    return {};
  }

  List<Map<String, dynamic>> _buildQuickStats(Map<String, dynamic> results) {
    final List<Map<String, dynamic>> stats = [];
    
    // Messages per day - Use safe conversion
    final summary = _convertToStringMap(results['summary']) ?? {};
    if (summary.containsKey('avgMessagesPerDay')) {
      stats.add({
        'icon': Icons.message,
        'label': 'Messages/Day',
        'value': summary['avgMessagesPerDay'].toString(),
      });
    }
    
    // Total media
    if (summary.containsKey('totalMedia')) {
      stats.add({
        'icon': Icons.image,
        'label': 'Media Files',
        'value': summary['totalMedia'].toString(),
      });
    }
    
    // Duration
    if (summary.containsKey('durationDays')) {
      stats.add({
        'icon': Icons.calendar_today,
        'label': 'Duration',
        'value': '${summary['durationDays']} days',
      });
    }
    
    // Total words - Check multiple locations for content analysis
    final contentAnalysis = _extractContentAnalysis(results);
    if (contentAnalysis.containsKey('totalWords')) {
      stats.add({
        'icon': Icons.text_fields,
        'label': 'Total Words',
        'value': contentAnalysis['totalWords'].toString(),
      });
    }
    
    return stats;
  }

  /// Extract contentAnalysis data - it might be nested
  Map<String, dynamic> _extractContentAnalysis(Map<String, dynamic> results) {
    // Check multiple possible locations
    if (results.containsKey('contentAnalysis')) {
      final contentData = _convertToStringMap(results['contentAnalysis']);
      if (contentData != null && contentData.isNotEmpty) {
        return contentData;
      }
    }
    
    if (results.containsKey('content')) {
      final contentContainer = _convertToStringMap(results['content']);
      if (contentContainer != null && contentContainer.containsKey('contentAnalysis')) {
        final contentData = _convertToStringMap(contentContainer['contentAnalysis']);
        if (contentData != null && contentData.isNotEmpty) {
          return contentData;
        }
      }
    }
    
    // Check for direct content fields at root level
    final directContentFields = <String, dynamic>{};
    for (final key in results.keys) {
      if (key.contains('total') && (key.contains('Words') || key.contains('Emojis') || key.contains('Media'))) {
        directContentFields[key] = results[key];
      }
    }
    
    return directContentFields;
  }

  Widget _buildHealthScoreCard(BuildContext context, Map<String, dynamic> conversationDynamics) {
    // Check for both possible field names
    int healthScore = 0;
    if (conversationDynamics.containsKey('healthScore')) {
      healthScore = _safeInt(conversationDynamics['healthScore']) ?? 0;
    } else if (conversationDynamics.containsKey('conversationHealthScore')) {
      healthScore = _safeInt(conversationDynamics['conversationHealthScore']) ?? 0;
    }
    
    if (healthScore == 0) {
      debugPrint("📊 No health score found in conversationDynamics");
      return const SizedBox.shrink();
    }
    
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
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.health_and_safety,
              color: scoreColor,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conversation Health',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$healthScore/100 - $scoreLabel',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scoreColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            CircularProgressIndicator(
              value: healthScore / 100,
              backgroundColor: scoreColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to safely extract integer values
  int? _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Helper method to safely convert Map<dynamic, dynamic> to Map<String, dynamic>
  Map<String, dynamic>? _convertToStringMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      try {
        final result = <String, dynamic>{};
        data.forEach((key, value) {
          final stringKey = key.toString();
          // Recursively convert nested maps
          if (value is Map && value is! Map<String, dynamic>) {
            result[stringKey] = _convertToStringMap(value);
          } else if (value is List) {
            result[stringKey] = _convertList(value);
          } else {
            result[stringKey] = value;
          }
        });
        return result;
      } catch (e) {
        debugPrint('OverviewTab: Error converting map: $e');
        return {};
      }
    }
    debugPrint('OverviewTab: Data is not a map, type: ${data.runtimeType}');
    return {};
  }

  /// Helper method to safely convert lists with nested maps
  List<dynamic> _convertList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map && item is! Map<String, dynamic>) {
        return _convertToStringMap(item);
      }
      return item;
    }).toList();
  }
}