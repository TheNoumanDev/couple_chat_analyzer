import 'package:flutter/material.dart';
import '../widgets/analysis_cards.dart';
import '../widgets/analysis_charts.dart';
import '../widgets/content_overview_widget.dart';

class ContentTab extends StatelessWidget {
  final Map<String, dynamic> results;

  const ContentTab({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final contentAnalysis = _extractContentAnalysis(results);
    final timeAnalysis = _extractTimeAnalysis(results);
    
    debugPrint("📄 ContentTab: contentAnalysis keys: ${contentAnalysis.keys.join(', ')}");
    debugPrint("📄 ContentTab: timeAnalysis keys: ${timeAnalysis.keys.join(', ')}");
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content Overview Cards
          ContentOverviewCards(contentAnalysis: contentAnalysis),
          
          const SizedBox(height: 24),
          
          // Time-based Content Analysis
          if (timeAnalysis.isNotEmpty)
            _buildTimeBasedContent(context, timeAnalysis),
          
          const SizedBox(height: 24),
          
          // Top Emojis
          if (contentAnalysis.containsKey('topEmojis'))
            TopEmojisChart(
              data: contentAnalysis['topEmojis'] as List<dynamic>,
            ),
          
          const SizedBox(height: 24),
          
          // Top Domains
          if (contentAnalysis.containsKey('topDomains'))
            TopDomainsChart(
              data: contentAnalysis['topDomains'] as List<dynamic>,
            ),
          
          const SizedBox(height: 24),
          
          // Message Length Distribution
          if (contentAnalysis.containsKey('messageLengthDistribution'))
            MessageLengthChart(
              data: _convertToStringMap(contentAnalysis['messageLengthDistribution']) ?? {},
            ),
          
          const SizedBox(height: 24),
          
          // Content Intelligence (if available) - Fixed with safe conversion
          if (results.containsKey('contentIntelligence'))
            ContentIntelligenceWidget(
              data: _convertToStringMap(results['contentIntelligence']) ?? {},
            ),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// Extract contentAnalysis data - it might be nested
  Map<String, dynamic> _extractContentAnalysis(Map<String, dynamic> results) {
    // Check direct contentAnalysis key
    if (results.containsKey('contentAnalysis')) {
      final contentData = _convertToStringMap(results['contentAnalysis']);
      if (contentData != null && contentData.isNotEmpty) {
        debugPrint("📄 Found contentAnalysis directly");
        return contentData;
      }
    }
    
    // Check nested in content container
    if (results.containsKey('content')) {
      final contentContainer = _convertToStringMap(results['content']);
      if (contentContainer != null && contentContainer.containsKey('contentAnalysis')) {
        final contentData = _convertToStringMap(contentContainer['contentAnalysis']);
        if (contentData != null && contentData.isNotEmpty) {
          debugPrint("📄 Found contentAnalysis nested in content");
          return contentData;
        }
      }
    }
    
    // Check for direct content fields at root level
    final directContentFields = <String, dynamic>{};
    for (final key in results.keys) {
      if (key.contains('total') && (key.contains('Words') || key.contains('Emojis') || key.contains('Media') || key.contains('Urls')) ||
          key.contains('topEmojis') || key.contains('topDomains') || key.contains('messageLengthDistribution') ||
          key.contains('avg') && (key.contains('Words') || key.contains('Chars'))) {
        directContentFields[key] = results[key];
      }
    }
    
    if (directContentFields.isNotEmpty) {
      debugPrint("📄 Found content fields at root level: ${directContentFields.keys.join(', ')}");
      return directContentFields;
    }
    
    debugPrint("📄 No contentAnalysis data found");
    return {};
  }

  /// Extract timeAnalysis data - it might be nested
  Map<String, dynamic> _extractTimeAnalysis(Map<String, dynamic> results) {
    // Check direct timeAnalysis key
    if (results.containsKey('timeAnalysis')) {
      final timeData = _convertToStringMap(results['timeAnalysis']);
      if (timeData != null && timeData.isNotEmpty) {
        debugPrint("📄 Found timeAnalysis directly");
        return timeData;
      }
    }
    
    // Check nested in time container
    if (results.containsKey('time')) {
      final timeContainer = _convertToStringMap(results['time']);
      if (timeContainer != null && timeContainer.containsKey('timeAnalysis')) {
        final timeData = _convertToStringMap(timeContainer['timeAnalysis']);
        if (timeData != null && timeData.isNotEmpty) {
          debugPrint("📄 Found timeAnalysis nested in time");
          return timeData;
        }
      }
    }
    
    // Check for direct time fields at root level
    final directTimeFields = <String, dynamic>{};
    for (final key in results.keys) {
      if (key.contains('hourly') || key.contains('weekly') || key.contains('monthly') || 
          key.contains('peak') || key.contains('Activity')) {
        directTimeFields[key] = results[key];
      }
    }
    
    if (directTimeFields.isNotEmpty) {
      debugPrint("📄 Found time fields at root level: ${directTimeFields.keys.join(', ')}");
      return directTimeFields;
    }
    
    debugPrint("📄 No timeAnalysis data found");
    return {};
  }

  Widget _buildTimeBasedContent(BuildContext context, Map<String, dynamic> timeAnalysis) {
    return Column(
      children: [
        // Hourly Activity Chart
        if (timeAnalysis.containsKey('hourlyActivity'))
          HourlyActivityChart(
            data: timeAnalysis['hourlyActivity'] as List<dynamic>,
          ),
        
        const SizedBox(height: 24),
        
        // Weekly Activity Chart
        if (timeAnalysis.containsKey('weeklyActivity'))
          WeeklyActivityChart(
            data: timeAnalysis['weeklyActivity'] as List<dynamic>,
          ),
        
        const SizedBox(height: 24),
        
        // Monthly Activity Chart (if available)
        if (timeAnalysis.containsKey('monthlyActivity'))
          MonthlyActivityChart(
            data: timeAnalysis['monthlyActivity'] as List<dynamic>,
          ),
      ],
    );
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
        debugPrint('ContentTab: Error converting map: $e');
        return {};
      }
    }
    debugPrint('ContentTab: Data is not a map, type: ${data.runtimeType}');
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