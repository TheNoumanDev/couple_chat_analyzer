import 'package:flutter/material.dart';
import '../widgets/analysis_cards.dart';
import 'overview_widgets/overview_widgets.dart';

class OverviewTab extends StatefulWidget {
  final Map<String, dynamic> results;

  const OverviewTab({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final summary = _convertToStringMap(widget.results['summary']) ?? {};
    final timeAnalysis = _extractTimeAnalysis(widget.results);
    final totalWords = _extractTotalWords(widget.results);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Summary Cards
          SummaryCards(summary: summary),

          const SizedBox(height: 24),

          // Key Metrics
          KeyMetricsSection(
            summary: summary,
            totalWords: totalWords,
          ),

          const SizedBox(height: 24),

          // Activity Overview
          ActivityOverviewSection(timeAnalysis: timeAnalysis),

          const SizedBox(height: 24),

          // Conversation Health
          if (widget.results.containsKey('conversationDynamics'))
            HealthCardSection(
              conversationDynamics: _convertToStringMap(widget.results['conversationDynamics']) ?? {},
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ============================================================================
  // DATA EXTRACTION HELPERS
  // ============================================================================

  int _extractTotalWords(Map<String, dynamic> results) {
    final contentAnalysis = _extractContentAnalysis(results);
    if (contentAnalysis.containsKey('totalWords')) {
      final words = contentAnalysis['totalWords'];
      if (words is int) return words;
      if (words is String) return int.tryParse(words) ?? 0;
    }

    final userAnalysis = _extractUserAnalysis(results);
    if (userAnalysis.containsKey('userData')) {
      final userData = userAnalysis['userData'] as List?;
      if (userData != null) {
        int totalWords = 0;
        for (final user in userData) {
          if (user is Map<String, dynamic>) {
            final wordCount = user['wordCount'];
            if (wordCount is int) {
              totalWords += wordCount;
            } else if (wordCount is String) {
              totalWords += int.tryParse(wordCount) ?? 0;
            }
          }
        }
        if (totalWords > 0) return totalWords;
      }
    }

    final messagesByUser = results['messagesByUser'] as List<dynamic>? ?? [];
    int totalWords = 0;
    for (final user in messagesByUser) {
      if (user is Map<String, dynamic>) {
        final wordCount = user['wordCount'];
        if (wordCount is int) {
          totalWords += wordCount;
        } else if (wordCount is String) {
          totalWords += int.tryParse(wordCount) ?? 0;
        }
      }
    }

    return totalWords;
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

      if (timeContainer != null && (timeContainer.containsKey('peakHour') || timeContainer.containsKey('peakDay'))) {
        return timeContainer;
      }
    }

    final directTimeFields = <String, dynamic>{};
    for (final key in results.keys) {
      if (key == 'peakHour' || key == 'peakDay' || key == 'totalMessages' ||
          key.contains('hourly') || key.contains('weekly') || key.contains('monthly') ||
          key.contains('peak') || key.contains('activity')) {
        directTimeFields[key] = results[key];
      }
    }

    return directTimeFields;
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

    final directContentFields = <String, dynamic>{};
    for (final key in results.keys) {
      if (key.contains('total') && (key.contains('Words') || key.contains('Emojis') || key.contains('Media'))) {
        directContentFields[key] = results[key];
      }
    }

    return directContentFields;
  }

  Map<String, dynamic> _extractUserAnalysis(Map<String, dynamic> results) {
    if (results.containsKey('userAnalysis')) {
      final userData = _convertToStringMap(results['userAnalysis']);
      if (userData != null && userData.isNotEmpty) {
        return userData;
      }
    }

    if (results.containsKey('users')) {
      final usersContainer = _convertToStringMap(results['users']);
      if (usersContainer != null && usersContainer.containsKey('userAnalysis')) {
        final userData = _convertToStringMap(usersContainer['userAnalysis']);
        if (userData != null && userData.isNotEmpty) {
          return userData;
        }
      }
    }

    return {};
  }

  Map<String, dynamic>? _convertToStringMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }
}
