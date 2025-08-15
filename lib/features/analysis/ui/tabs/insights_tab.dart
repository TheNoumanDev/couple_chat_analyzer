import 'package:chatreport/features/analysis/ui/widgets/content_overview_widget.dart';
import 'package:flutter/material.dart';
import '../widgets/insights_widget.dart';

class InsightsTab extends StatelessWidget {
  final Map<String, dynamic> results;

  const InsightsTab({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint("🎯 InsightsTab: Building with all analyzer keys present");
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Insights',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Conversation Dynamics - Fixed with data adapter
          if (results.containsKey('conversationDynamics'))
            ConversationDynamicsWidget(
              data: _adaptConversationDynamicsData(results['conversationDynamics']),
            ),
          
          const SizedBox(height: 24),
          
          // Relationship Analysis - Fixed with data adapter
          if (results.containsKey('relationshipDynamics'))
            RelationshipAnalysisWidget(
              data: _adaptRelationshipData(results['relationshipDynamics']),
            ),
          
          const SizedBox(height: 24),
          
          // Behavior Patterns - Already works fine
          if (results.containsKey('behaviorPatterns'))
            BehaviorPatternsWidget(
              data: _convertToStringMap(results['behaviorPatterns']) ?? {},
            ),
          
          const SizedBox(height: 24),
          
          // Content Intelligence - Fixed with data adapter
          if (results.containsKey('contentIntelligence'))
            ContentIntelligenceWidget(
              data: _adaptContentIntelligenceData(results['contentIntelligence']),
            ),
          
          const SizedBox(height: 24),
          
          // Temporal Insights - Fixed with data adapter
          if (results.containsKey('temporalInsights'))
            TemporalInsightsWidget(
              data: _adaptTemporalInsightsData(results['temporalInsights']),
            ),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// Adapt ConversationDynamics data to match widget expectations
  Map<String, dynamic> _adaptConversationDynamicsData(dynamic rawData) {
    final data = _convertToStringMap(rawData) ?? {};
    
    debugPrint("🗣️ Adapting ConversationDynamics data:");
    debugPrint("  Raw keys: ${data.keys.join(', ')}");
    
    // Map the field names to what the widget expects
    final adaptedData = <String, dynamic>{
      // Map analyzer fields to widget expected fields
      'totalConversations': data['totalConversations'] ?? 0,
      'healthScore': _safeInt(data['conversationHealthScore']) ?? 0,  // Fix field name
      'avgConversationLength': _safeInt(data['averageConversationLength']) ?? 0,  // Fix field name
      'initiationPatterns': data['initiationPatterns'] ?? {},
      'flowPatterns': data['flowPatterns'] ?? {},
      'responsePatterns': data['responsePatterns'] ?? {},
      'conversationStats': data['conversationStats'] ?? {},
    };
    
    debugPrint("  Adapted keys: ${adaptedData.keys.join(', ')}");
    debugPrint("  healthScore: ${adaptedData['healthScore']}, totalConversations: ${adaptedData['totalConversations']}");
    
    return adaptedData;
  }

  /// Adapt RelationshipDynamics data to match widget expectations
  Map<String, dynamic> _adaptRelationshipData(dynamic rawData) {
    final data = _convertToStringMap(rawData) ?? {};
    
    debugPrint("💕 Adapting RelationshipDynamics data:");
    debugPrint("  Raw keys: ${data.keys.join(', ')}");
    
    // Extract engagement score from engagementLevels
    int engagementScore = 0;
    if (data['engagementLevels'] is Map) {
      final engagementLevels = data['engagementLevels'] as Map;
      // Calculate average engagement or use a representative value
      if (engagementLevels.isNotEmpty) {
        final values = engagementLevels.values.where((v) => v is int || v is double);
        if (values.isNotEmpty) {
          final average = values.fold(0.0, (sum, val) => sum + (val as num).toDouble()) / values.length;
          engagementScore = average.round();
        }
      }
    }
    
    final adaptedData = <String, dynamic>{
      'relationshipHealthScore': _safeInt(data['relationshipHealthScore']) ?? 0,
      'supportPatterns': data['supportPatterns'] ?? {},
      'relationshipTrend': data['relationshipTrend'] ?? 'Stable',
      'engagementScore': engagementScore,  // Calculated from engagementLevels
      'reciprocityPatterns': data['reciprocityPatterns'] ?? {},
      'emotionalDynamics': data['emotionalDynamics'] ?? {},
      'conflictPatterns': data['conflictPatterns'] ?? {},
      'overallAssessment': data['overallAssessment'] ?? {},
    };
    
    debugPrint("  Adapted keys: ${adaptedData.keys.join(', ')}");
    debugPrint("  relationshipHealthScore: ${adaptedData['relationshipHealthScore']}, engagementScore: ${adaptedData['engagementScore']}");
    
    return adaptedData;
  }

  /// Adapt ContentIntelligence data to match widget expectations
  Map<String, dynamic> _adaptContentIntelligenceData(dynamic rawData) {
    final data = _convertToStringMap(rawData) ?? {};
    
    debugPrint("🎓 Adapting ContentIntelligence data:");
    debugPrint("  Raw keys: ${data.keys.join(', ')}");
    
    // The data is nested under 'contentIntelligence' key
    if (data.containsKey('contentIntelligence')) {
      final nestedData = _convertToStringMap(data['contentIntelligence']) ?? {};
      debugPrint("  Nested keys: ${nestedData.keys.join(', ')}");
      return nestedData;
    }
    
    return data;
  }

  /// Adapt TemporalInsights data to match widget expectations
  Map<String, dynamic> _adaptTemporalInsightsData(dynamic rawData) {
    final data = _convertToStringMap(rawData) ?? {};
    
    debugPrint("⏰ Adapting TemporalInsights data:");
    debugPrint("  Raw keys: ${data.keys.join(', ')}");
    
    // The data is nested under 'temporalInsights' key
    if (data.containsKey('temporalInsights')) {
      final nestedData = _convertToStringMap(data['temporalInsights']) ?? {};
      debugPrint("  Nested keys: ${nestedData.keys.join(', ')}");
      return nestedData;
    }
    
    return data;
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
        debugPrint('❌ InsightsTab: Error converting map: $e');
        return {};
      }
    }
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