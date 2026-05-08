// ============================================================================
// CONTENT TAB - Refactored to use split widgets
// File: lib/features/analysis/ui/tabs/content_tab.dart
// ============================================================================

import 'package:flutter/material.dart';
import '../widgets/analysis_cards.dart';
import '../widgets/analysis_charts.dart';
import 'content_widgets/content_widgets.dart';

class ContentTab extends StatefulWidget {
  final Map<String, dynamic> results;

  const ContentTab({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  State<ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends State<ContentTab>
    with AutomaticKeepAliveClientMixin {
  // Cached extracted data to avoid re-extraction on every build
  late Map<String, dynamic> _contentAnalysis;
  late Map<String, dynamic> _timeAnalysis;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _extractData();
  }

  @override
  void didUpdateWidget(ContentTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.results != widget.results) {
      _extractData();
    }
  }

  void _extractData() {
    _contentAnalysis = _extractContentAnalysis(widget.results);
    _timeAnalysis = _extractTimeAnalysis(widget.results);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content Overview Cards
          ContentOverviewCards(contentAnalysis: _contentAnalysis),

          const SizedBox(height: 24),

          // Top Emojis Chart
          _buildTopEmojisSection(),

          const SizedBox(height: 24),

          // Message Length Distribution
          _buildMessageLengthSection(),

          const SizedBox(height: 24),

          // Peak Activity Times
          PeakActivitySection(timeAnalysis: _timeAnalysis),

          const SizedBox(height: 24),

          // Daily Activity Chart
          if (_timeAnalysis.containsKey('weeklyActivity'))
            WeeklyActivitySection(weeklyData: _timeAnalysis['weeklyActivity'])
          else
            const MissingDataCard(
              title: 'Daily Activity Pattern',
              message: 'Daily communication patterns will be shown here when more time analysis data is available.',
              icon: Icons.calendar_view_week,
              color: Colors.green,
            ),

          const SizedBox(height: 24),

          // Monthly Patterns
          if (_timeAnalysis.containsKey('monthlyActivity'))
            MonthlyActivitySection(monthlyData: _timeAnalysis['monthlyActivity'])
          else
            const MissingDataCard(
              title: 'Monthly Communication Trends',
              message: 'Monthly activity patterns will be displayed here when sufficient historical data is available.',
              icon: Icons.calendar_month,
              color: Colors.indigo,
            ),

          const SizedBox(height: 24),

          // Hourly Heatmap
          if (_timeAnalysis.containsKey('hourlyActivity'))
            HourlyHeatmapSection(hourlyData: _timeAnalysis['hourlyActivity'])
          else
            const MissingDataCard(
              title: 'Hourly Activity Heatmap',
              message: '24-hour activity patterns will be visualized here when hourly data becomes available.',
              icon: Icons.grid_view,
              color: Colors.red,
            ),

          const SizedBox(height: 24),

          // Most Shared Domains
          SharedDomainsSection(contentAnalysis: _contentAnalysis),

          const SizedBox(height: 24),

          // Content Statistics
          ContentStatisticsSection(contentAnalysis: _contentAnalysis),

          const SizedBox(height: 24),

          // Communication Insights
          CommunicationInsightsSection(
            contentAnalysis: _contentAnalysis,
            timeAnalysis: _timeAnalysis,
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ============================================================================
  // SECTION BUILDERS (using existing chart widgets)
  // ============================================================================

  Widget _buildTopEmojisSection() {
    if (_contentAnalysis.containsKey('topEmojis')) {
      final topEmojis = _contentAnalysis['topEmojis'];
      if (topEmojis is List && topEmojis.isNotEmpty) {
        return TopEmojisChart(data: topEmojis);
      }
    }

    return const MissingDataCard(
      title: 'Top Emojis',
      message: 'No emoji data available yet. Import more chat data to see emoji usage patterns.',
      icon: Icons.emoji_emotions,
      color: Colors.yellow,
    );
  }

  Widget _buildMessageLengthSection() {
    if (_contentAnalysis.containsKey('messageLengthDistribution') &&
        _hasValidLengthData(_contentAnalysis['messageLengthDistribution'])) {
      return MessageLengthChart(
        data: _convertToStringMap(_contentAnalysis['messageLengthDistribution']) ?? {},
      );
    }

    return const MissingDataCard(
      title: 'Message Length Distribution',
      message: 'Message length analysis will appear here after processing more chat data.',
      icon: Icons.bar_chart,
      color: Colors.green,
    );
  }

  // ============================================================================
  // DATA EXTRACTION HELPERS
  // ============================================================================

  bool _hasValidLengthData(dynamic data) {
    if (data == null) return false;
    if (data is Map) {
      final map = _convertToStringMap(data);
      if (map == null) return false;
      final short = map['short'] as int? ?? 0;
      final medium = map['medium'] as int? ?? 0;
      final long = map['long'] as int? ?? 0;
      return (short + medium + long) > 0;
    }
    return false;
  }

  Map<String, dynamic> _extractContentAnalysis(Map<String, dynamic> results) {
    if (results.containsKey('content')) {
      final contentContainer = _convertToStringMap(results['content']);
      if (contentContainer != null) {
        if (contentContainer.containsKey('contentAnalysis')) {
          final contentData = _convertToStringMap(contentContainer['contentAnalysis']);
          if (contentData != null && contentData.isNotEmpty) {
            return contentData;
          }
        }
        if (contentContainer.containsKey('totalWords')) {
          return contentContainer;
        }
      }
    }

    if (results.containsKey('contentAnalysis')) {
      final contentData = _convertToStringMap(results['contentAnalysis']);
      if (contentData != null && contentData.isNotEmpty) {
        return contentData;
      }
    }

    return {};
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
      if (timeContainer != null) {
        if (timeContainer.containsKey('timeAnalysis')) {
          final timeData = _convertToStringMap(timeContainer['timeAnalysis']);
          if (timeData != null && timeData.isNotEmpty) {
            return timeData;
          }
        }

        if (timeContainer.containsKey('peakHour') ||
            timeContainer.containsKey('hourlyActivity')) {
          return timeContainer;
        }
      }
    }

    if (results.containsKey('temporalInsights')) {
      final temporalData = _convertToStringMap(results['temporalInsights']);

      if (temporalData != null && temporalData.containsKey('temporalInsights')) {
        final nestedTemporal = _convertToStringMap(temporalData['temporalInsights']);
        if (nestedTemporal != null && nestedTemporal.isNotEmpty) {
          return nestedTemporal;
        }
      }

      if (temporalData != null && temporalData.isNotEmpty) {
        return temporalData;
      }
    }

    final directTimeFields = <String, dynamic>{};
    for (final key in results.keys) {
      if (key == 'peakHour' ||
          key == 'peakDay' ||
          key == 'hourlyActivity' ||
          key == 'weeklyActivity' ||
          key == 'monthlyActivity' ||
          key.contains('peak') ||
          key.contains('Activity')) {
        directTimeFields[key] = results[key];
      }
    }

    return directTimeFields;
  }

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
            result[stringKey] = value.map((item) {
              if (item is Map && item is! Map<String, dynamic>) {
                return _convertToStringMap(item);
              }
              return item;
            }).toList();
          } else {
            result[stringKey] = value;
          }
        });
        return result;
      } catch (e) {
        return {};
      }
    }
    return {};
  }
}
